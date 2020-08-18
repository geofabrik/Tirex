#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status/RequestsRendered.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Status;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status::RequestsRendered;
use base qw( Tirex::Munin::Status );

=head1 NAME

Tirex::Munin::Status::RequestsRendered - Number of requests rendered

=head1 DESCRIPTION

Munin plugin for number of metatile requests rendered per second or minute for a map.

=cut

sub config
{
    my $self = shift;

    my $map = $self->{'map'};
    my $per = $self->{'per'} // 'second';

    my $config = '';
    
    if ($map eq '*')
    {
        $config .= "graph_title Requests rendered\n";
    }
    else
    {
        $config .= sprintf("graph_title Requests rendered for map %s\n", $map);
    }

    $config .= <<EOF;
graph_vlabel requests/$per
graph_category tirex
graph_args --lower-limit 0
graph_scale no
graph_period $per
EOF

    if ($map eq '*')
    {
        $config .= "graph_info Number of metatile requests rendered per $per\n";
    }
    else
    {
        $config .= sprintf("graph_info Number of metatile requests rendered per $per for map %s\n", $map);
    }

    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $id   = $zoomrange->get_id();
        my $type = $zoomrange eq $self->{'zoomranges'}->[0] ? 'AREA' : 'STACK';

        $config .= sprintf("%s.info Zoomlevel %s\n", $id, $zoomrange->to_s());
        $config .= sprintf("%s.label %s\n",          $id, $zoomrange->get_name());
        $config .= sprintf("%s.type DERIVE\n",       $id);
        $config .= sprintf("%s.min 0\n",             $id);
        $config .= sprintf("%s.draw %s\n",           $id, $type);
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my $data = '';
    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $sum = 0;
        foreach my $z ($zoomrange->get_min() .. $zoomrange->get_max())
        {
            if ($self->{'map'} eq '*')
            {
                my $maps = $self->{'status'}->{'rm'}->{'stats'}->{'count_rendered'};
                while ( my ($map, $stats) = each( %$maps ) )
                {
                    $sum += ($stats->[$z] // 0);
                }
            }
            else
            {
                $sum += ($self->{'status'}->{'rm'}->{'stats'}->{'count_rendered'}->{$self->{'map'}}->[$z] // 0);
            }
        }
        $data .= sprintf("%s.value %d\n", $zoomrange->get_id(), $sum);
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
