package Koha::Plugin::HKS3::AggregatedKeywords::Rewriter;
use 5.020;
use strict;
use warnings;
use Carp;

sub rewrite_keywords {
    my ($record) = @_;

    my @new_fields;

    my @tags = qw(630 648 650 651 655);
    my $keyword_index = 0;
    for my $tag (@tags) {
        my @fields = $record->field($tag);
        for my $field (@fields) {
            my $sf_a = $field->subfield('a');
            my $sf_6 = $field->subfield('6') // $keyword_index;
            my $sf_8 = $field->subfield('8') // ($keyword_index + 1);

            my @split_sf6 = split ';', $sf_6;
            my @split_sf8 = split ';', $sf_8;
            if (@split_sf6 != @split_sf8) {
                croak 'Record with controlnumber ' . $record->field('001')->data
                   . "has an invalid keyword entry at tag $tag: $sf_6 and $sf_8 don't have the same length";
            }

            for (my $i = 0; $i < @split_sf6; $i++) {
                push @new_fields, MARC::Field->new(
                    '689', $split_sf6[$i], $split_sf8[$i], a => $sf_a
                );
                $keyword_index++;
            }
        }
    }

    my @to_delete;
    my @f689 = $record->field('689');
    for (@f689) {
        my $sf_A = $_->subfield('A');
        unless ($sf_A) {
            push @to_delete, $_;
        }
    }

    $record->delete_fields(@to_delete);

    for (@new_fields) {
        $record->append_fields($_);
    }
}

1;
