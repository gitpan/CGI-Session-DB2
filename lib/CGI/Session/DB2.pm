package CGI::Session::DB2;

use strict;
use base qw(
    CGI::Session
    CGI::Session::ID::MD5
    CGI::Session::Serialize::Default
);

our $VERSION = '0.01';

=head1 NAME

CGI::Session::DB2 - DB2 driver for CGI::Session

=head1 SYNOPSIS

    use CGI::Session;
    $session = new CGI::Session("driver:DB2", undef, {DB=>'dbname', Schema=>'cgisess',Table=>'cgisess'});

For more examples, consult L<CGI::Session> manual

=head1 DESCRIPTION

CGI::Session::DB2 is a CGI::Session driver to store session data in a DB2 table.
To write your own drivers for B<CGI::Session> refere L<CGI::Session> manual.

Options accepted:

=over 4

=item Database

Database name to use.  Defaults to 'cgisess'.

=item DB2Driver

DB2::db object or package to latch on to, rather than using the internal
version.  Will simply add the internal table to the existing DB2::db object.

=item Table

Table name to use.  Defaults to 'cgisess'.

=item Schema

Schema name to use.  Defaults to 'cgisess'.

=item UserName

User name for authentication

=item UserPW

User password for authentication

=cut

# stores the serialized data. Returns 1 for sucess, undef otherwise
sub store
{
    my ($self, $sid, $options, $data) = @_;

    my $table = $self->get_table($options);
    my $row   = $table->find_id($sid);
    unless ($row)
    {
        $row = $table->create_row();
        $row->column(id => $sid);
    }
    $row->column(asession => $self->freeze($data));

    $row->save();
}

# retrieves the serialized data and deserializes it
sub retrieve {
    my ($self, $sid, $options) = @_;

    my $table = $self->get_table($options);
    my $row = $table->find_id($sid);

    $row ? $self->thaw($row->column('asession')) : undef;
}


# removes the given data and all the disk space associated with it
sub remove
{
    my ($self, $sid, $options) = @_;

    my $table = $self->get_table($options);
    my $row = $table->find_id($sid);
    $table->delete($row) if $row;

    1;
}


# called right before the object is destroyed to do cleanup
sub teardown
{
    my ($self, $sid, $options) = @_;

    return 1;
}

sub get_table
{
    my ($self, $options) = @_;

    return $self->{_table} if $self->{_table};

    my ($db, $table) = _setup_db($options);
    $self->{_db} = $db;
    $self->{_table} = $table;

    $table;
}

sub _setup_db
{
    my $options = shift;
    $options = $options->[1] if $options and ref $options and ref $options eq 'ARRAY';
    
    my $db = $options->{DB2Driver} || 'CGI::Session::DB2::db';
    unless (ref $db)
    {
        $db = $db->new();
        unless ($options->{DB2Driver})
        {
            $db->{db_name} = $options->{Database} || 'cgisess';
            $db->{user_name} = $options->{UserName};
            $db->{user_pw} = $options->{UserPW};
        }
    }
    $db->add_table($options->{Table} || 'Cgisess');
    my $table = $db->get_table($options->{Table} || 'Cgisess');
    $table->{schema_name} = $options->{Schema} || 'cgisess';
    $table->{table_name} = $options->{Table} || 'cgisess';

    ($db,$table);
}

sub create
{
    my $name = shift;
    my $options = $_[0];
    unless (ref $options eq 'HASH')
    {
        $options = { @_ };
    }
    my ($db, $table) = _setup_db($options);

    $db->create_db();
}

=item Table

Table name to use.  Defaults to 'cgisess'.

=item Schema

Schema name to use.  Defaults to 'cgisess'.
    
=cut

package CGI::Session::DB2::db;

use base 'DB2::db';

sub db_name { shift->{db_name} }
sub user_name { shift->{user_name} }
sub user_pw { shift->{user_pw} }

sub setup_row_table_relationships {}

package CGI::Session::DB2::Cgisess;

use base 'DB2::Table';

sub schema_name { shift->{schema_name} }
sub table_name { shift->{table_name} }

sub data_order {
    [
     {
         COLUMN => 'ID',
         TYPE   => 'CHAR',
         LENGTH => 32,
         PRIMARY => 1,
     },
     {
         COLUMN => 'ASESSION',
         TYPE   => 'LONG VARCHAR',
     },
    ];
}

# cannot use distinct for VARCHAR tables.  DB2::db probably should
# be smarter than this, but this works in the meantime.
sub _prepare_attributes {
    { distinct => 0 }
}

1;

=head1 STORAGE

To store session data in a DB2 database, you first need to create a suitable
table for it with the following command:

    perl -MCGI::Session::DB2 -e 'CGI::Session::DB2->create(DBName=>q[dbname],Schema=>q[cgisess],Table=>q[cgisess]);

For more information on database creation, see C<DB2::db>.  Also note DB2::db's
requirement for DB2INSTANCE to be set.  You will need to set this in your own
application script(s).

=head1 COPYRIGHT

Copyright (C) 2004 Darin McBride. All rights reserved.

This library is free software and can be modified and distributed under the same
terms as Perl itself. 


=head1 AUTHOR

Darin McBride <dmcbride@cpan.org>

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut


