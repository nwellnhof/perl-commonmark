use strict;
use warnings;

use Symbol;
use Test::More tests => 2;

BEGIN {
    use_ok('CommonMark');
}

my $doc = CommonMark->create_document(
    children => [
        CommonMark->create_header(
            level    => 2,
            children => [
                CommonMark->create_text(
                    literal => 'Header',
                ),
            ],
        ),
        CommonMark->create_block_quote(
            children => [
                CommonMark->create_paragraph(
                    text => 'Block quote',
                ),
            ],
        ),
        CommonMark->create_list(
            type     => CommonMark::ORDERED_LIST,
            delim    => CommonMark::PAREN_DELIM,
            start    => 2,
            tight    => 1,
            children => [
                CommonMark->create_item(
                    children => [
                        CommonMark->create_paragraph(
                            text => 'Item 1',
                        ),
                    ],
                ),
                CommonMark->create_item(
                    children => [
                        CommonMark->create_paragraph(
                            text => 'Item 2',
                        ),
                    ],
                ),
            ],
        ),
        CommonMark->create_code_block(
            fence_info => 'perl',
            literal    => 'Code block',
        ),
        CommonMark->create_html(
            literal => '<div>html</html>',
        ),
        CommonMark->create_hrule,
        CommonMark->create_paragraph(
            children => [
                CommonMark->create_emph(
                    children => [
                        CommonMark->create_text(
                            literal => 'emph',
                        ),
                    ],
                ),
                CommonMark->create_softbreak,
                CommonMark->create_link(
                    url   => '/url',
                    title => 'link title',
                    children => [
                        CommonMark->create_strong(
                            text => 'link text',
                        ),
                    ],
                ),
                CommonMark->create_linebreak,
                CommonMark->create_image(
                    url   => '/facepalm.jpg',
                    title => 'image title',
                    text  => 'alt text',
                ),
            ],
        ),
    ],
);

my $expected_html = <<EOF;
<h2>Header</h2>
<blockquote>
<p>Block quote</p>
</blockquote>
<ol start="2">
<li>Item 1</li>
<li>Item 2</li>
</ol>
<pre><code>Code block</code></pre>
<div>html</html>
<hr />
<p><em>emph</em>
<a href="/url" title="link title"><strong>link text</strong></a><br />
<img src="/facepalm.jpg" alt="alt text" title="image title" /></p>
EOF
is($doc->render_html, $expected_html, 'create_* helpers');

