package Bio::Phylo::Parsers::Tolweb;
use strict;
use warnings;
use Bio::Phylo::IO;
use Bio::Phylo::Util::Exceptions 'throw';
use Bio::Phylo::Factory;
use UNIVERSAL 'isa';
use vars qw(@ISA $VERSION);
@ISA = qw(Bio::Phylo::IO);

eval { require XML::Twig };
if ( $@ ) {
	throw 'ExtensionError' => "Error loading the XML::Twig extension: $@";
}

=head1 NAME

Bio::Phylo::Parsers::Nexml - Parses nexml data. No serviceable parts inside.

=head1 DESCRIPTION

This module parses nexml data. It is called by the L<Bio::Phylo::IO> facade,
don't call it directly.

=head1 SEE ALSO

=over

=item L<Bio::Phylo::IO>

The newick parser is called by the L<Bio::Phylo::IO> object.
Look there to learn how to parse nexml (or any other data Bio::Phylo supports).

=item L<Bio::Phylo::Manual>

Also see the manual: L<Bio::Phylo::Manual> and L<http://rutgervos.blogspot.com>.

=item L<http://www.nexml.org>

For more information about the nexml data standard, visit L<http://www.nexml.org>

=back

=head1 REVISION

 $Id: Nexml.pm 530 2008-05-22 17:34:05Z rvos $

=cut

# The factory object, to instantiate Bio::Phylo objects
my $factory = Bio::Phylo::Factory->new;

# We re-use the core Bio::Phylo version number.
$VERSION = $Bio::Phylo::VERSION;

# I factored the logging methods in Bio::Phylo (debug, info,
# warning, error, fatal) out of the inheritance tree and put
# them in a separate logging object.
my $logger = Bio::Phylo::Util::Logger->new;

# this is the constructor that gets called by Bio::Phylo::IO,
# here we create the object instance that will process the file/string
sub _new {
	my $class = shift;
	$logger->debug("instantiating $class");

	# this is the actual parser object, which needs to hold a reference
	# to the XML::Twig object and to the tree
	my $self = bless { '_tree' => undef }, $class;

	# here we put the two together, i.e. create the actual XML::Twig object
	# with its handlers, and create a reference to it in the parser object
	$self->{'_twig'} = XML::Twig->new( 
		'TwigHandlers' => {
			'TREE' => sub { &_handle_tree( $self, @_ ) },			
		}		
	);
	return $self;
}

# the official interface for Bio::Phylo::IO parser subclasses requires a
# _from_handle method (to process data on a file handle) and a _from_string
# method, for data in a string variable. Since XML::Twig can parse both
# from handle and string with the same XML::Twig->parse method call, we can
# suffice with aliases that point to the same method _from_both
*_from_handle = \&_from_both;
*_from_string = \&_from_both;

# this method will be called by Bio::Phylo::IO, indirectly, through
# _from_handle if the parse function is called with the -file => $filename
# argument, or through _from_string if called with the -string => $string
# argument
sub _from_both {
	my $self = shift;
	$logger->debug("going to parse xml");
	my %opt = @_;

	# XML::Twig doesn't care if we parse from a handle or a string
	my $xml = $opt{'-handle'} || $opt{'-string'};
	$self->{'_twig'}->parse($xml);
	$logger->debug("done parsing xml");

	# we're done, now grab the tree from its field
	my $tree = $self->{'_tree'};

	# reset everything in its initial state: Bio::Phylo::IO caches parsers
	$self->{'_tree'} = undef;

	return $tree;
}

sub _handle_tree {
	my ( $self, $twig, $tree_elt ) = @_;
	$logger->debug("handling tree");
	$self->{'_tree'} = $factory->create_tree;
	for my $node_elt ( $tree_elt->children('NODE') ) {
		$self->_handle_node($node_elt,undef);
	}
}

sub _handle_node {
	my ($self,$node_elt,$parent_obj) = @_;
	my $node_obj = $factory->create_node;
	$self->{'_tree'}->insert($node_obj);
	$node_obj->set_parent($parent_obj) if $parent_obj;
	my %dict;
	for my $child_elt ( $node_elt->children ) {		
		if ( $child_elt->tag eq 'NODES' or $child_elt->tag eq 'OTHERNAMES' ) {
			next;
		}
		elsif ( $child_elt->tag eq 'NAME' ) {
			my $name = $child_elt->text;
			if ($name) {
				if ( $name =~ m/[ ()]/ ) {
					$node_obj->set_name("'". $name . "'");
				}
				else {
					$node_obj->set_name($name);
				}
			}
		}
		elsif ( $child_elt->tag eq 'DESCRIPTION' ) {
			$node_obj->set_desc($child_elt->text);
		}
		elsif ( my $text = $child_elt->text ) {
			$dict{$child_elt->tag} = [ 'string', $text ];
		}
	}
	for my $att_name ( $node_elt->att_names ) {
		if ( $att_name eq 'COMBINATION_DATE' ) {
			$dict{$att_name} = [ 'string', $node_elt->att($att_name) ];
		}
		else {
			$dict{$att_name} = [ 'integer', $node_elt->att($att_name) ];
		}
	}
	$node_obj->set_generic( 'dict' => \%dict );
	if ( my $nodes_elt = $node_elt->first_child('NODES') ) {
		for my $child_node_elt ( $nodes_elt->children('NODE') ) {
			$self->_handle_node($child_node_elt,$node_obj);
		}
	}
}

1;