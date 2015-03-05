use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok('CommonMark');
}

my $md = <<EOF;
# Header

Paragraph *emph*, **strong**
EOF

my $expected_html = <<EOF;
<h1>Header</h1>
<p>Paragraph <em>emph</em>, <strong>strong</strong></p>
EOF

is(CommonMark->markdown_to_html($md), $expected_html, 'markdown_to_html');

my $doc = CommonMark->parse_document($md);
isa_ok($doc, 'CommonMark::Node', 'parse_document');

is($doc->render_html, $expected_html, 'parse_document works');

like($doc->render_xml, qr/^<\?xml /, 'render_xml');
like($doc->render_man, qr/^\.SH\n/, 'render_man');

is(CommonMark->markdown_to_html("\x{263A}"), "<p>\xE2\x98\xBA</p>\n",
   'render functions return encoded utf8');

is(CommonMark->markdown_to_html("\xC2\xA9"), "<p>\xC3\x82\xC2\xA9</p>\n",
   'render functions expect decoded utf8');

