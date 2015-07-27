use strict;
use warnings;

use Test::More tests => 6;

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

    is($doc->render_html, $expected_html, 'parse works with string and smart');

    my $html = $doc->render(format => 'html');
    is($html, $expected_html, 'render works with HTML format');
}

{
    my $all_opts = CommonMark::_extract_opts({
        sourcepos     => 1,
        hardbreaks    => 'yes',
        normalize     => '0e0',
        smart         => 'true',
        validate_utf8 => '1',
        safe          => 100,
    });
    is($all_opts, 63, 'extracting options works');

    my $no_opts = CommonMark::_extract_opts({
        sourcepos     => undef,
        hardbreaks    => 0,
        normalize     => 0e100,
        smart         => '',
        validate_utf8 => '0',
        safe          => -0.0,
    });
    is($no_opts, 0, 'extracting unset options works');
}

