# $Id$
package Bio::Phylo::Util::StackTrace;
use strict;

sub new {
	my $class = shift;
	my $self = [];
	my $i = 0;
	my $j = 0;
	package DB; # to get @_ stack from previous frames, see perldoc -f caller
	while( my @frame = caller($i) ) {
		my $package = $frame[0];
		if ( not Bio::Phylo::Util::StackTrace::_skip_me( $package ) ) {
			my @args = @DB::args;
			$self->[$j++] = [ @frame, @args ];
		}
		$i++;
	}
	package Bio::Phylo::Util::StackTrace;
	shift @$self; # to remove "throw" frame
	return bless $self, $class;
}

sub _skip_me {
	my $class = shift;
	my $skip = 0;
	if ( UNIVERSAL::isa( $class, 'Bio::Phylo::Util::Exceptions') ) {
		$skip++;
	}
	if ( UNIVERSAL::isa( $class, 'Bio::Phylo::Util::ExceptionFactory' ) ) {
		$skip++;
	}
	return $skip;
}

# fields in frame:
#  [
#  0   'main',
# +1   '/Users/rvosa/Desktop/exceptions.pl',
# +2   102,
# +3   'Object::this_dies',
#  4   1,
#  5   undef,
#  6   undef,
#  7   undef,
#  8   2,
#  9   'UUUUUUUUUUUU',
# +10  bless( {}, 'Object' ),
# +11  'very',
# +12  'violently'
#  ],

sub as_string {
	my $self = shift;
	my $string = "";
	for my $frame ( @$self ) {
		my $method = $frame->[3];
		my @args;
		for my $i ( 10 .. $#{ $frame } ) {
			push @args, $frame->[$i];
		}
		my $file = $frame->[1];
		my $line = $frame->[2];
		$string .= $method . "(" . join(', ', map { "'$_'" } @args ) . ") called at $file line $line\n";
	}
	return $string;
}

package Bio::Phylo::Util::Exceptions;
BEGIN {
	require Exporter;
	use vars qw($AUTOLOAD @EXPORT_OK @ISA);
	@ISA=qw(Exporter);
	@EXPORT_OK=qw(throw);
}
use strict;
use overload 'bool' => sub { 1 }, 'fallback' => 1, '""' => \&as_string;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {
#		'error'       => $args{'error'},
#		'description' => $args{'description'},
		'trace'       => Bio::Phylo::Util::StackTrace->new,
		'time'        => CORE::time(),
		'pid'         => $$,
		'uid'         => $<,
		'euid'        => $>,
		'gid'         => $(,
		'egid'        => $),
		%args
	};
	return bless $self, $class;
}

sub as_string {
	my $self = shift;
	my $error = $self->error;
	my $description = $self->description;
	my $class = ref $self;
	my $trace = join "\n", map { "STACK: $_" } split '\n', $self->trace->as_string;
	return <<"ERROR_HERE_DOC";
-------------------------- EXCEPTION ----------------------------
Message: $error

An exception of type $class
was thrown.

$description

Refer to the Bio::Phylo::Util::Exceptions documentation for more
information.
------------------------- STACK TRACE ---------------------------
$trace	
-----------------------------------------------------------------
ERROR_HERE_DOC
}

sub throw (@) {
	# called as static method, with odd args
	if ( scalar @_ % 2 ) {
		my $class = shift;
		my $self = $class->new(@_);
		die $self;	
	}
	# called as function, with even args e.g. throw BadArgs => 'msg';
	else {
		my $type = shift;
		my $class = __PACKAGE__ . '::' . $type;
		my $self = $class->new( 'error' => shift, @_ );
		die $self;
	}
}

sub rethrow {
	my $self = shift;
	die $self;
}

sub caught {
	my $class = shift;
	if ( @_ ) {
		$class = shift;
	}
	if ( $@ ) {
		if ( UNIVERSAL::isa( $@, $class ) ) {
			return $@;
		}
		else {
			die $@;
		}
	}
}

sub AUTOLOAD {
	my $self = shift;
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
	return $self->{$field};
}

sub _make_exceptions {
	my $class = shift;
	my $root = shift;
	my %exceptions = @_;
	for my $exception ( keys %exceptions ) {
		my $isa = $exceptions{ $exception }->{'isa'};
		my @isa = ref $isa ? @$isa : ( $isa );
		my $description = $exceptions{ $exception }->{'description'};
		my $class = <<"EXCEPTION_CLASS";
package ${exception};
use vars '\@ISA';
\@ISA=qw(@isa);
my \$desc;
sub description { 
	my \$self = shift;
	if ( \@_ ) {
		\$desc = shift;
	}
	return \$desc;
}
1;
EXCEPTION_CLASS
		eval $class;
		$exception->description( $description );
	}
	
}

__PACKAGE__->_make_exceptions(
	# root classes
    'Bio::Phylo::Util::Exceptions',
    'Bio::Phylo::Util::Exceptions::Generic' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions',
        'description' => "No further details about this type of error are available." 
    },
    
    # exceptions on method calls
    'Bio::Phylo::Util::Exceptions::API' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::Generic',
        'description' => "No more details about this type of error are available." 
    },    
    'Bio::Phylo::Util::Exceptions::UnknownMethod' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::API',
        'description' => "This kind of error happens when a non-existent method is called.",
    },
    'Bio::Phylo::Util::Exceptions::NotImplemented' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::API',
        'description' => "This kind of error happens when a non-implemented\n(interface) method is called.",
    },    
    'Bio::Phylo::Util::Exceptions::Deprecated' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::API',
        'description' => "This kind of error happens when a deprecated method is called.", 
    },

	# exceptions on arguments
    'Bio::Phylo::Util::Exceptions::BadArgs' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::Generic',
        'description' => "This kind of error happens when bad or incomplete arguments\nare provided.",
    },    
    'Bio::Phylo::Util::Exceptions::BadString' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::BadArgs',
        'description' => "This kind of error happens when an unsafe string argument is\nprovided.",
    },
    'Bio::Phylo::Util::Exceptions::OddHash' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::BadArgs',
        'description' => "This kind of error happens when an uneven number\nof arguments (so no key/value pairs) was provided.",
    },
    'Bio::Phylo::Util::Exceptions::ObjectMismatch' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::BadArgs',
        'description' => "This kind of error happens when an invalid object\nargument is provided.",
    },
    'Bio::Phylo::Util::Exceptions::InvalidData' => {
        'isa' => [
            'Bio::Phylo::Util::Exceptions::BadString',
            'Bio::Phylo::Util::Exceptions::BadFormat',
        ],
        'description' => "This kind of error happens when invalid character data is\nprovided."
    },
    'Bio::Phylo::Util::Exceptions::OutOfBounds' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::BadArgs',
        'description' => "This kind of error happens when an index is outside of its range.",
    },
    'Bio::Phylo::Util::Exceptions::BadNumber' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::Generic',
        'description' => "This kind of error happens when an invalid numerical argument\nis provided.",
    },    

	# system exceptions
    'Bio::Phylo::Util::Exceptions::System' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::Generic',
        'description' => "This kind of error happens when there is a system misconfiguration.",
    },    
    'Bio::Phylo::Util::Exceptions::FileError' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::System',
        'description' => "This kind of error happens when a file can not be accessed.",
    },
    'Bio::Phylo::Util::Exceptions::ExtensionError' => {
        'isa'         => [
        	'Bio::Phylo::Util::Exceptions::System',
        	'Bio::Phylo::Util::Exceptions::BadFormat',
        ],
        'description' => "This kind of error happens when an extension module can not be\nloaded.",
    },
    'Bio::Phylo::Util::Exceptions::BadFormat' => {
        'isa'         => 'Bio::Phylo::Util::Exceptions::System',
        'description' => "This kind of error happens when a bad\nparse or unparse format was specified.",
    },

);


1;
__END__

=head1 NAME

Bio::Phylo::Util::Exceptions - Exception classes for Bio::Phylo.

=head1 SYNOPSIS

 use Bio::Phylo::Forest::Node;
 my $node = Bio::Phylo::Forest::Node->new;
 
 # now let's try something illegal
 eval {
    $node->set_branch_length( 'non-numerical value' );
 };

 # have an error
 if ( $@ && UNIVERSAL::isa( $@, 'Bio::Phylo::Util::Exception' ) ) {

    # print out where the error came from
    print $@->trace->as_string;
 }

=head1 DESCRIPTION

Sometimes, Bio::Phylo dies. If this happens because you did something that
brought Bio::Phylo into an undefined and dangerous state (such as might happen
if you provide a non-numerical value for a setter that needs numbers),
Bio::Phylo will throw an "exception", a special form of the C<$@> variable
that is a blessed object with useful methods to help you diagnose the problem.

This package defines the exceptions that can be thrown by Bio::Phylo. There are
no serviceable parts inside. Refer to the L<Exception::Class>
perldoc for more examples on how to catch exceptions and show traces.

=head1 EXCEPTION CLASSES

=over

=item Bio::Phylo::Util::Exceptions::BadNumber

Thrown when anything other than a number that passes L<Scalar::Util>'s 
looks_like_number test is given as an argument to a method that expects a number.

=item Bio::Phylo::Util::Exceptions::BadString

Thrown when a string that contains any of the characters C<< ():;, >>  is given
as an argument to a method that expects a name.

=item Bio::Phylo::Util::Exceptions::BadFormat

Thrown when a non-existing parser or unparser format is requested, in calls
such as C<< parse( -format => 'newik', -string => $string ) >>, where 'newik'
doesn't exist.

=item Bio::Phylo::Util::Exceptions::OddHash

Thrown when an odd number of arguments has been specified. This might happen if 
you call a method that requires named arguments and the key/value pairs don't 
seem to match up.

=item Bio::Phylo::Util::Exceptions::ObjectMismatch

Thrown when a method is called that requires an object as an argument, and the
wrong type of object is specified.

=item Bio::Phylo::Util::Exceptions::UnknownMethod

Trown when an indirect method call is attempted through the 
C<< $obj->get('unknown_method') >> interface, and the object doesn't seem to 
implement the requested method.

=item Bio::Phylo::Util::Exceptions::BadArgs

Thrown when something undefined is wrong with the supplied arguments.

=item Bio::Phylo::Util::Exceptions::FileError

Thrown when a file specified as an argument does not exist or is not readable.

=item Bio::Phylo::Util::Exceptions::ExtensionError

Thrown when there is an error loading a requested extension.

=item Bio::Phylo::Util::Exceptions::OutOfBounds

Thrown when an entity is requested that falls outside of the range of
objects contained by a L<Bio::Phylo::Listable> subclass, probably through 
the C<< $obj->get_by_index($i) >> method call.

=item Bio::Phylo::Util::Exceptions::NotImplemented

Thrown when an interface method is called instead of the implementation
by the child class.

=item Bio::Phylo::Util::Exceptions::Deprecated

Thrown when a deprecated method is called.

=back

=head1 METHODS

=over

=item new()

Constructor

 Type    : Constructor
 Title   : new
 Usage   : $class->new( error => 'An exception was thrown!' );
 Function: Constructs exception
 Returns : A Bio::Phylo::Util::Exceptions object
 Args    : error => 'Error message'

=item throw()

Throws exception.

 Type    : Exception
 Title   : throw
 Usage   : $class->throw( error => 'An exception was thrown!' );
 Function: Throws exception
 Returns : A Bio::Phylo::Util::Exceptions object
 Args    : error => 'Error message'

=item caught()

Catches an exception by class.

 Type    : Handler
 Title   : caught
 Usage   : my $e = Bio::Phylo::Util::Exceptions->caught;
 Function: Catches an exception
 Returns : A Bio::Phylo::Util::Exceptions object
 Args    : None

=item rethrow()

Rethrows a caught exception.

 Type    : Exception
 Title   : rethrow
 Usage   : $@->rethrow;
 Function: Rethrows exception
 Returns : A Bio::Phylo::Util::Exceptions object
 Args    : None

=item as_string()

Serializes exception.

 Type    : Serializer
 Title   : as_string
 Usage   : print $@->as_string;
 Function: Serializes exception with description and stack trace.
 Returns : String
 Args    : None

=back

=head1 SEE ALSO

=over

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>

=back

=head1 REVISION

 $Id$

=cut

