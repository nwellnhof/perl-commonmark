use strict;
use warnings;

use Test::More tests => 26;

BEGIN {
    use_ok('CommonMark');
}

my $filename = 't/files/test.md';
open(my $file, '<', $filename)
    or die("$filename: $!");
my $doc = CommonMark->parse_file($file);
close($file);

isa_ok($doc, 'CommonMark::Node', 'parse_file');

my $header = $doc->first_child;
is($header->get_type, CommonMark::NODE_HEADER, 'get_type');
is($header->get_type_string, 'header', 'get_type_string');
is($header->get_header_level, 1, 'get_header_level');
$header->set_header_level(6);
is($header->get_header_level, 6, 'set_header_level works');

my $text = $header->first_child;
is($text->get_literal, "Header \x{263A}", 'get_literal');
$text->set_literal("New \x{263A} header");
is($text->get_literal, "New \x{263A} header", 'set_literal works');

my $ol = $header->next;
is($ol->get_list_tight, 1, 'get_list_tight');
is($ol->get_list_delim, CommonMark::PAREN_DELIM, 'get_list_delim');
is($ol->get_list_start, 4, 'get_list_start');
is($ol->get_list_type, CommonMark::ORDERED_LIST, 'get_list_type');
$ol->set_list_tight(0);
is($ol->get_list_tight, 0, 'set_list_tight works');
$ol->set_list_delim(1);
is($ol->get_list_delim, 1, 'set_list_delim works');
$ol->set_list_start(7);
is($ol->get_list_start, 7, 'set_list_start works');
$ol->set_list_type(1);
is($ol->get_list_type, 1, 'set_list_type works');

my $fenced = $ol->next;
is($fenced->get_fence_info, "perl \x{263A}", 'get_fence_info');
$fenced->set_fence_info("C \x{2639}");
is($fenced->get_fence_info, "C \x{2639}", 'set_fence_info works');

my $paragraph = $fenced->next;
is($paragraph->get_start_line, 10, 'get_start_line');
is($paragraph->get_start_column, 1, 'get_start_column');
is($paragraph->get_end_line, 10, 'get_end_line');
is($paragraph->get_end_column, 40, 'get_end_column');

my $link = $paragraph->first_child;
is($link->get_url, 'http://example.com/', 'get_url');
is($link->get_title, 'title', 'get_title');
$link->set_url('https://example.com/');
is($link->get_url, 'https://example.com/', 'set_url works');
$link->set_title('new title');
is($link->get_title, 'new title', 'set_title works');

