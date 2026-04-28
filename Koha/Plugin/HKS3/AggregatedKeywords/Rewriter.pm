package Koha::Plugin::HKS3::AggregatedKeywords::Rewriter;
use 5.020;
use strict;
use warnings;
use Carp;

sub rewrite_keywords {
    my ($record) = @_;

    my @new_fields;

    my %tags = (
        600 => { D => 'p' },
        610 => { D => 'b' },
        630 => { D => 't' },
        650 => { D => 's' },
        648 => { D => 'h' }, # or 'z' ?
        651 => { D => 'g' },
        655 => { A => 'f' },
    );
    my $keyword_index = 0;
    for my $tag (keys %tags) {
        my @fields = $record->field($tag);
        for my $field (@fields) {
            my $sf_a = $field->subfield('a');

            # it's okay if these are empty,
            # the loop below will do 0 iterations and generate no 689s
            my $sf_6 = $field->subfield('6') // '';
            my $sf_8 = $field->subfield('8') // '';

            my @split_sf6 = split ';', $sf_6;
            my @split_sf8 = split ';', $sf_8;
            if (@split_sf6 != @split_sf8) {
                croak 'Record with controlnumber ' . $record->field('001')->data
                   . "has an invalid keyword entry at tag $tag: $sf_6 and $sf_8 don't have the same length";
            }

            for (my $i = 0; $i < @split_sf6; $i++) {
                push @new_fields, MARC::Field->new(
                    '689', $split_sf6[$i], $split_sf8[$i], a => $sf_a, %{$tags{$tag}},
                );
                $keyword_index++;
            }
        }
    }

    $record->delete_fields($record->field('689'));

    for (@new_fields) {
        $record->append_fields($_);
    }
}

1;
