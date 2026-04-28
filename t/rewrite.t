use strict;
use warnings;
use 5.020;
use MARC::Record;
use Test::More;
use Test::Exception;
use Koha::Plugin::HKS3::AggregatedKeywords::Rewriter;

subtest 'Simple case', sub {
    my $rec = MARC::Record->new;
    $rec->add_fields('650', '', '', a => 'Category', 6 => '0', 8 => '1');
    Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($rec);
    my @f689s = $rec->field('689');
    is scalar(@f689s), 1, 'one field added';
    is $f689s[0]->indicator('1'), 0, 'ind1 ok';
    is $f689s[0]->indicator('2'), 1, 'ind2 ok';
    is $f689s[0]->subfield('a'), 'Category', 'a ok';

    Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($rec);
    @f689s = $rec->field('689');
    is scalar(@f689s), 1, 'safe to rerun';

    is $f689s[0]->subfield('D'), 's', 'subfield D set correctly';
};

subtest 'No 6-8 = no 689s', sub {
    my $rec = MARC::Record->new;
    $rec->add_fields('650', '', '', a => 'Category 1');
    $rec->add_fields('650', '', '', a => 'Category 2');
    Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($rec);
    my @f689s = $rec->field('689');
    is scalar(@f689s), 0, 'zero fields added';
};

subtest 'Multiple places', sub {
    my $rec = MARC::Record->new;
    $rec->add_fields('650', '', '', a => 'Category', 6 => '4;5', 8 => '6;7');
    Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($rec);
    my @f689s = $rec->field('689');
    is scalar(@f689s), 2, 'two fields added';

    is $f689s[0]->subfield('a'), 'Category', 'a ok';
    is $f689s[0]->indicator('1'), 4, 'ind1 ok';
    is $f689s[0]->indicator('2'), 6, 'ind2 ok';

    is $f689s[1]->subfield('a'), 'Category', 'a ok';
    is $f689s[1]->indicator('1'), 5, 'ind1 ok';
    is $f689s[1]->indicator('2'), 7, 'ind2 ok';
};

subtest 'Dies on invalid record', sub {
    my $rec = MARC::Record->new;
    $rec->add_fields('001', 'CN001');
    $rec->add_fields('650', '', '', a => 'Category', 6 => '4;5', 8 => '6');

    throws_ok sub {
        Koha::Plugin::HKS3::AggregatedKeywords::Rewriter::rewrite_keywords($rec);
    }, qr/CN001/, 'dies, mentions controlnumber';
};

done_testing;
