# $Id: $
package Bio::Phylo::Util::DOM::Document;
use strict;
use Bio::Phylo::Util::Exceptions qw(throw);
use Bio::Phylo::Util::CONSTANT qw(_DOCUMENT_ looks_like_hash looks_like_class);

=head1 NAME

Bio::Phylo::Util::DOM::Document - Abstract class for
flexible XML document object model implementation

=head1 SYNOPSIS

Not used directly.

=head1 DESCRIPTION

This module describes an abstract implementation of a DOM document as
expected by Bio::Phylo. The methods here must be overridden in any
concrete implementation. The idea is that different implementations
use a particular XML DOM package, binding the methods here to
analogous package methods.

This set of methods is intentionally minimal. The concrete instances
of this class should inherit both from DocumentI and the underlying XML DOM
object class, so that package-specific methods can be directly
accessed from the instantiated object.

=head1 AUTHOR

Mark A. Jensen - maj -at- fortinbras -dot- us

=cut

=head2 Constructor

=over

=item new()

 Type    : Constructor
 Title   : new
 Usage   : $doc = Bio::Phylo::Util::Dom::Document->new(@args)
 Function: Create a Document object using the underlying package
 Returns : Document object or undef on fail
 Args    : Package-specific arguments

=cut

sub new {
    my $class = shift;
    if ( my %args = looks_like_hash @_ ) {
	$class = __PACKAGE__ . '::' . lc $args{'-format'};
	delete $args{'-format'};
	return looks_like_class($class)->new(%args);
    }
}

=back

=cut 

=head2 Document property accessors/mutators

=over

=item set_encoding()

 Type    : Mutator
 Title   : set_encoding
 Usage   : $doc->set_encoding($enc)
 Function: Set encoding for document
 Returns : True on success
 Args    : Encoding descriptor as string

=cut

sub set_encoding {
    throw 'NotImplemented' => "Can't call 'set_encoding' on interface";
}

=item get_encoding()

 Type    : Accessor
 Title   : get_encoding
 Usage   : $doc->get_encoding()
 Function: Get encoding for document
 Returns : Encoding descriptor as string
 Args    : none

=cut

sub get_encoding {
    throw 'NotImplemented' => "Can't call 'get_encoding' on interface";
}

=item set_root()

 Type    : Mutator
 Title   : set_root
 Usage   : $doc->set_root($elt)
 Function: Set the document's root element
 Returns : True on success
 Args    : Element object

=cut

sub set_root {
    throw 'NotImplemented' => "Can't call 'set_root' on interface";
}

=item get_root()

 Type    : Accessor
 Title   : get_root
 Usage   : $doc->get_root()
 Function: Get the document's root element
 Returns : Element object or undef if DNE
 Args    : none

=cut

sub get_root {
    throw 'NotImplemented' => "Can't call 'get_root' on interface";
}

=back

=cut 

=head2 Document element accessors

=over 

=item get_element_by_id()

 Type    : Accessor
 Title   : get_element_by_id
 Usage   : $doc->get_element_by_id($id)
 Function: Get element having id $id
 Returns : Element object or undef if DNE
 Args    : id designator as string

=cut

sub get_element_by_id {
    throw 'NotImplemented' => "Can't call 'get_element_by_id' on interface";
}

=item get_elements_by_tagname()

 Type    : Accessor
 Title   : get_elements_by_tagname
 Usage   : $elt->get_elements_by_tagname($tagname)
 Function: Get array of elements having given tag name 
 Returns : Array of elements or undef if no match
 Args    : tag name as string

=cut

sub get_elements_by_tagname {
    throw 'NotImplemented' => "Can't call 'get_elements_by_tagname' on interface";
}

=back

=head2 Output methods

=over

=item to_xml()

 Type    : Serializer
 Title   : to_xml
 Usage   : $doc->to_xml
 Function: Create XML string from document
 Returns : XML string
 Args    : Formatting arguments as allowed by underlying package

=cut

sub to_xml {
    throw 'NotImplemented' => "Can't call 'to_xml_string' on interface";
}

=back

=cut

1;