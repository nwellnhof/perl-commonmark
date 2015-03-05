use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('CommonMark');
}

{
    my $filename = 't/files/test.md';
    my $file;

    open($file, '<', $filename) or die("$filename: $!");
    my $doc1 = CommonMark->parse_file($file);
    close($file);

    open($file, '<', $filename) or die("$filename: $!");
    my $doc2 = CommonMark->parse(file => $file);
    close($file);

    is($doc2->render_html, $doc1->render_html, 'parse works with file');
}

{
    my $md  = q{Pretty "smart" -- don't you think?};
    my $doc = CommonMark->parse(string => $md, smart => 1);
    my $expected_html = <<EOF;
<p>Pretty \x{201C}smart\x{201D} \x{2013} don\x{2019}t you think?</p>
EOF
    utf8::encode($expected_html);

    is($doc->render_html, $expected_html, 'parse works with string and smart');
}

