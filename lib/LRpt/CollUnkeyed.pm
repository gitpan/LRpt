#####################################################################
#
# $Id: CollUnkeyed.pm,v 1.8 2006/02/10 22:32:16 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Collection of unkeyed rows. Unkeyed means that there is no key specified
# for these rows. This collection is used for Expected-Actual comparison.
# Sometimes the key of the row is not known or diffucult to predict (if
# this is a unique ID automaticaly generated by the server). 
#
# $Log: CollUnkeyed.pm,v $
# Revision 1.8  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.7  2005/09/02 19:59:31  pkaluski
# Next refinement of PODs. Ready for distribution. Some work on clarity still to be done
#
# Revision 1.6  2005/09/01 20:00:18  pkaluski
# Refined PODs. Separation between public and private methods still to be done
#
# Revision 1.5  2005/01/24 21:22:51  pkaluski
# Added pod documentation
#
# Revision 1.4  2005/01/22 06:17:43  pkaluski
# Improved column coloring and underlining in differences reports
#
# Revision 1.3  2005/01/18 20:46:50  pkaluski
# Fixed Bug 1095692 - Incorrect comparison of numerical fields
#
# Revision 1.2  2004/12/21 21:21:29  pkaluski
# Columns ordering introduced for reporting rows different from expected
#
# Revision 1.1  2004/10/17 08:29:03  pkaluski
# Initial revision
#
#
####################################################################
package LRpt::CollUnkeyed;
use strict;

=head1 NAME

LRpt::CollUnkeyed - Object of this class represents a collection of unkeyed
rows

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
Object of this class represents a collection of unkeyed rows. Unkeyed 
means that there is no key specified for these rows. This collection 
is used for Expected-Actual comparison. Sometimes a key of the exected row is 
not known or diffucult to predict (if this is a unique ID automaticaly 
generated by the server). 

=head1 METHODS

=cut

############################################################################

=head2 C<new>

  my $uk_coll = LRpt::CollUnkeyed->new();

Constructor. Initializes fields.

=cut

############################################################################
sub new
{
    my $proto         = shift;
    my $class         = ref( $proto ) || $proto;
    my $self          = {};
    bless( $self, $class ); 
    $self->{ 'groups ' } = {};
    return $self;
}


#########################################################################

=head2 C<add_row>

  $uk_coll->add_row( $row );

Adds a row to a group. A group contains all rows, which have have same 
amount of fields defined. Each group is devided on groups of rows having
the same values of all defined columns.

=cut

#########################################################################
sub add_row
{
    my $self = shift;
    my $row  = shift;

    my $nbr_defined = keys %$row;
    if( not exists $self->{ 'groups' }->{ $nbr_defined } ){
        $self->{ 'groups' }->{ $nbr_defined } = [ { 'row' => $row,
                                                  'quantity' => 1 } ];
    }else{
        $self->add_to_group( $row ) ;
    }
}


#########################################################################

=head2 C<add_to_group>

  $uk_coll->add_to_group( $row );

It increases the number of equal rows (the same amount of fields, all 
fields have the same values).

=cut

#########################################################################
sub add_to_group
{
    my $self = shift;
    my $row  = shift;

    my $nbr_defined = scalar( keys %$row );
    my $group = $self->{ 'groups' }->{ $nbr_defined };
    foreach my $gr_row ( @$group ){
        if( $self->is_equal( $gr_row->{ 'row' }, $row ) ){
            $gr_row->{ 'quantity' }++;
            return;
        }
    }
    push( @$group, { 'row' => $row, 'quantity' => 1 } );
}


#########################################################################

=head2 C<is_equal>

  my $res = $uk_coll->is_equal( $row1, $row2 );

Checks that C<$row1> and C<$row2> are totally equal - 
the same amount of fields, 
all fields have the same values.

=cut

################################################################
sub is_equal
{
    my $self = shift;
    my $row1 = shift;
    my $row2 = shift;

    my @all_cols = ( keys %$row1 );

    foreach my $col ( @all_cols ){
        if( ! exists $row1->{ $col } ){
            return 0;
        }
        if( ! exists $row2->{ $col } ){
            return 0;
        }
        if( $row1->{ $col } ne $row2->{ $col } ){
            return 0;
        }
    }
    return 1;
}


#########################################################################

=head2 C<is_matching>

  my $res = $uk_coll->is_matching( $row1, $row2 );

Checks if a given row matches a row in collection. By matching, I mean 
that the row matches all fields from the row in the collection.

=cut

########################################################################
sub is_matching
{
    my $self = shift;
    my $row1 = shift;
    my $row2 = shift;
    my @unm_cols = ();

    foreach my $col ( keys %$row1 ){
        if( $row1->{ $col } =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ and
            $row2->{ $col } =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ )
        {
            if( $row1->{ $col } != $row2->{ $col } ){
                push( @unm_cols, $col );
            }
        }else{
            if( $row1->{ $col } ne $row2->{ $col } ){
                push( @unm_cols, $col );
            }
        }
    }
    if( @unm_cols ){
        return ( 0, @unm_cols );
    }else{
        return 1;
    }
}


#########################################################################

=head2 C<find_matching_row>

  my $res = $uk_coll->find_matching_row( $row );

Finds a row in a collection, which matches a given row. It tries to find a
 matching row starting from the row, which has the biggest number of 
fields defined.

=cut

###############################################################################
sub find_matching_row
{
    my $self = shift;
    my $row  = shift;
    
    my @ordered_groups = 
        reverse sort { $a <=> $b } keys %{ $self->{ 'groups' } };

    #
    # Start with a row, which has the biggest number of columns defined
    #
    foreach my $n_col_def ( @ordered_groups ){
        my $group = $self->{ 'groups' }->{ $n_col_def };
        foreach my $gr_row ( @$group ){
            if( $gr_row->{ 'quantity' } == 0 ){
                next;
            }
            my ( $cmp_res, @unm_cols ) = 
                $self->is_matching( $gr_row->{ 'row' }, $row );
            if( $cmp_res ){
                $gr_row->{ 'quantity' }--;
                return 1;
            }
            else{
                if( not exists $gr_row->{ 'unm_cols' } or
                    @{ $gr_row->{ 'unm_cols' } } > @unm_cols )
                {
                    $gr_row->{ 'unm_cols' } = [ @unm_cols ];
                }
            }
        }
    }
    return 0;
}


#########################################################################

=head2 C<is_empty>

  my $res = $uk_coll->is_empty();

Returns 1 if a collection is empty. O otherwise

=cut

#########################################################################
sub is_empty
{
    my $self = shift;
    if( scalar( keys %{ $self->{ 'groups' } } ) ){
        return 0;
    }else{
        return 1;
    }
}


#########################################################################

=head2 C<get_remaining_row>

  my @rows = $uk_coll->get_remaining_rows();

Returns all rows, which are not matched by anything.

=cut

###############################################################################
sub get_remaining_rows
{
    my $self   = shift;
    my @output = ();

    foreach my $grp ( keys %{ $self->{ 'groups' } } ){
        foreach my $r_grp ( @{ $self->{ 'groups' }->{ $grp } } ){
            if( $r_grp->{ 'quantity' } > 0 ){
                push( @output, $r_grp );
            }
        }
    }
    return @output;
}

=head1 SEE ALSO

The project is maintained on Source Forge L<http://lreport.sourceforge.net>. 
You can find there links to some helpful documentation like tutorial.

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut

1;