package Koha::Filter::MARC::AggregatedKeywords;

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

use MARC::Field;

use base qw(Koha::RecordProcessor::Base);

our $NAME = 'AggregatedKeywords';
our $VERSION = '0.1.5';

sub filter {
    my ( $self, $record ) = @_;

    return $record unless defined $record and ref($record) eq 'MARC::Record';

    my %fields_by_ind1;
    my @swks = $record->field('689');
    my @to_delete;
    for (@swks) {
        my $sf_a = $_->subfield('a');
        my $ind1 = $_->indicator(1);
        my $ind2 = $_->indicator(2);
        $fields_by_ind1{$ind1} //= [];
        push @{$fields_by_ind1{$ind1}}, [$sf_a, $ind2];
        push @to_delete, $_;
    }

    $record->delete_fields($record->field('653'));

    for my $ind1 (sort keys %fields_by_ind1) {
        my @sorted_a = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @{$fields_by_ind1{$ind1}};
        $record->append_fields(MARC::Field->new(
            '653', '', '', a => join(' :: ', @sorted_a),
        ));
    }

    return $record;
}

1;
