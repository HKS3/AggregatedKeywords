package Koha::Plugin::HKS3::AggregatedKeywords;
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use Koha::Biblios;
use C4::Biblio qw(ModBiblio);

use Koha::Plugin::HKS3::AggregatedKeywords::Rewriter;
use Koha::Filter::MARC::AggregatedKeywords;

our $VERSION = "0.1.1";

our $metadata = {
    name            => 'AggregatedKeywords',
    author          => 'HKS3 - Tadeusz Sośnierz',
    description     => 'Aggregate keywords on details pages',
    date_authored   => '2026-04-15',
    date_updated    => '2026-04-23',
    minimum_version => '25.11',
    maximum_version => undef,
    namespace       => 'hks3_aggregatedkeywords',
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;
    
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);
    $self->{cgi} = CGI->new();

    return $self;
}

sub after_biblio_action {
    my ($self, $params) = @_;

    my $action = $params->{action};
    my $biblio_id = $params->{payload}->{biblio_id};

    if ($action eq 'add' || $action eq 'modify' || $action eq 'create') {
        my $biblio = Koha::Biblios->find($biblio_id);
        my $record = $biblio->metadata->record;

        my $before = $record->as_formatted;
        Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($record);
        # we run this here to make it indexed
        Koha::Filter::MARC::AggregatedKeywords->filter($record);
        my $after = $record->as_formatted;
        # funny infinite recursion without this :)
        if ($before ne $after) {
            ModBiblio($record, $biblio->biblionumber, $biblio->frameworkcode);
        }
    }

    return;
}

sub xslt_record_processor_filters {
    my ( $self, $params ) = @_;
    return; # we moved this to after_biblio_action for now

    $params->{filters} //= [];
    my $filters = $params->{filters};
    push @$filters, 'AggregatedKeywords';

    return;
}

sub record_display_customizations {
    my ( $self, $params ) = @_;

    return q|
    [% FOREACH field IN record.field('689') %]
      [% IF field.subfield('a') AND !field.subfield('A') %]
        <span class="results_summary swk">
            <span class="label">SWK: </span>
            [% field.subfield('a') %]
        </span>
      [% END %]
    [% END %]
    |;
}


1;
