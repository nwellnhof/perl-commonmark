use strict;
use warnings;

use Symbol;
use Test::More tests => 4;

BEGIN {
    use_ok('CommonMark');
}

my $md = <<EOF;
normal, *emph*, **strong**
EOF

my $doc       = CommonMark->parse_document($md);
my $paragraph = $doc->first_child;
my $text      = $paragraph->first_child;
my $emph      = $text->next;
my $strong    = $paragraph->last_child;
my $space     = $strong->first_child->parent->previous;

my $expected_html = $doc->render_html;
$doc = undef;

my $result = CommonMark::Node->new(CommonMark::NODE_DOCUMENT);
$text->unlink;
$strong->unlink;
$result->append_child($paragraph);
$emph->insert_before($text);
$space->insert_after($strong);

is($result->render_html, $expected_html, 'tree manipulation');

for my $i (1..4) {
    $paragraph->first_child->insert_before($paragraph->last_child);
}
is($result->render_html, $expected_html, 'rotate right');

for my $i (1..4) {
    $paragraph->last_child->insert_after($paragraph->first_child);
}
is($result->render_html, $expected_html, 'rotate left');

