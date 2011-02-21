package Net::Riak::Bucket;
use Moose;
use Carp;
use Net::Riak::Object;
use Net::Riak::Types Client => {-as => 'Client_T'};
with 'Net::Riak::Role::Replica' => {keys => [qw/r w dw/]};

has client => (
    is       => 'rw',
    isa      => Client_T,
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);
has content_type => (
    is      => 'rw',
    isa     => 'Str',
    default => 'application/json'
);

sub n_val {
    my $self = shift;
    if (my $val = shift) {
        $self->set_property('n_val', $val);
    }
    else {
        $self->get_property('n_val');
    }
}

sub allow_multiples {
    my $self = shift;

    if (my $val = shift) {
        my $bool = ($val == 1 ? JSON::true : JSON::false);
        $self->set_property('allow_mult', $bool);
    }
    else {
        return $self->get_property('allow_mult');
    }
}

sub get_keys {
    my ($self, $params) = @_;
    $self->client->get_keys($self->name, $params);
}

sub get {
    my ($self, $key, $r) = @_;
    my $obj = Net::Riak::Object->new(
        client => $self->client,
        bucket => $self,
        key    => $key
    );
    $r ||= $self->r;
    $obj->load($r);
    $obj;
}

sub delete_object {
    my ($self, $key) = @_;
    Net::Riak::Object->new(
        client => $self->client,
        bucket => $self,
        key    => $key
    )->delete;
}

sub set_property {
    my ($self, $key, $value) = @_;
    $self->set_properties({$key => $value});
}

sub get_property {
    my ($self, $key, $params) = @_;
    my $props = $self->get_properties($params);
    return $props->{props}->{$key};
}

sub get_properties {
    my ($self, $params) = @_;
    $self->client->get_properties($self->name, $params);
}

sub set_properties {
    my ($self, $props) = @_;
    $self->client->set_properties($self, $props);
}

sub new_object {
    my ($self, $key, $data, @args) = @_;
    my $object = Net::Riak::Object->new(
        key    => $key,
        data   => $data,
        bucket => $self,
        client => $self->client,
        @args,
    );
    $object;
}

1;

=head1 SYNOPSIS

    my $client = Net::Riak->new(...);
    my $bucket = $client->bucket('foo');

    # retrieve an existing object
    my $obj1 = $bucket->get('foo');

    # create/store a new object
    my $obj2 = $bucket->new_object('foo2', {...});
    $object->store;

    $bucket->delete_object($key);

=head1 DESCRIPTION

The L<Net::Riak::Bucket> object allows you to access and change information about a Riak bucket, and provides methods to create or retrieve objects within the bucket.

=head2 ATTRIBUTES

=over 4

=item B<name>

    my $name = $bucket->name;

Get the bucket name

=item B<r>

    my $r_value = $bucket->r;

R value setting for this client (default 2)

=item B<w>

    my $w_value = $bucket->w;

W value setting for this client (default 2)

=item B<dw>

    my $dw_value = $bucket->dw;

DW value setting for this client (default 2)

=back

=head2 METHODS

=over 4

=item new_object

    my $obj = $bucket->new_object($key, $data, @args);

Create a new L<Net::Riak::Object> object. Additional Object constructor arguments can be passed after $data. If $data is a reference and no explicit Object content_type is given in @args, the data will be serialised and stored as JSON.

=item get

    my $obj = $bucket->get($key, [$r]);

Retrieve an object from Riak.

=item delete_object

    $bucket->delete_object($key);

Delete an object by key

=item n_val

    my $n_val = $bucket->n_val;

Get/set the N-value for this bucket, which is the number of replicas that will be written of each object in the bucket. Set this once before you write any data to the bucket, and never change it again, otherwise unpredictable things could happen. This should only be used if you know what you are doing.

=item allow_multiples

    $bucket->allow_multiples(1|0);

If set to True, then writes with conflicting data will be stored and returned to the client. This situation can be detected by calling has_siblings() and get_siblings(). This should only be used if you know what you are doing.

=item get_keys

    my $keys = $bucket->get_keys;
    my $keys = $bucket->get_keys($args);

Return an arrayref of the list of keys for a bucket. Optionally takes a hashref of named parameters. Supported parameters are:

=over 4

=item stream => 1

Uses key streaming mode to fetch the list of keys, which may be faster for large keyspaces.

=item cb => sub { }

A callback subroutine to be called for each key found (passed in as the only parameter). get_keys() returns nothing in callback mode.

=back

=item set_property

    $bucket->set_property({n_val => 2});

Set a bucket property. This should only be used if you know what you are doing.

=item get_property

    my $prop = $bucket->get_property('n_val');

Retrieve a bucket property.

=item set_properties

Set multiple bucket properties in one call. This should only be used if you know what you are doing.

=item get_properties

Retrieve an associative array of all bucket properties, containing 'props' and 'keys' elements.

Accepts a hashref of parameters. Supported parameters are:

=over 4

=item props => 'true'|'false'

Whether to return bucket properties. Defaults to 'true' if no parameters are given.

=item keys => 'true'|'false'|'stream'

Whether to return bucket keys. If set to 'stream', uses key streaming mode, which may be faster for large keyspaces.

=item cb => sub { }

A callback subroutine to be called for each key found (passed in as the only parameter). Implies keys => 'stream'. Keys are omitted from the results hashref in callback mode.

=back

=back
