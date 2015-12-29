use 5.008;
use strict;
use warnings;

use XSLoader;

our $VERSION = '0.230000';
XSLoader::load('CommonMark', $VERSION);

package CommonMark;

use constant {
    NODE_NONE           =>  0,
    NODE_DOCUMENT       =>  1,
    NODE_BLOCK_QUOTE    =>  2,
    NODE_LIST           =>  3,
    NODE_ITEM           =>  4,
    NODE_CODE_BLOCK     =>  5,
    NODE_HTML_BLOCK     =>  6,
    NODE_CUSTOM_BLOCK   =>  7,
    NODE_PARAGRAPH      =>  8,
    NODE_HEADING        =>  9,
    NODE_THEMATIC_BREAK => 10,
    NODE_TEXT           => 11,
    NODE_SOFTBREAK      => 12,
    NODE_LINEBREAK      => 13,
    NODE_CODE           => 14,
    NODE_HTML_INLINE    => 15,
    NODE_CUSTOM_INLINE  => 16,
    NODE_EMPH           => 17,
    NODE_STRONG         => 18,
    NODE_LINK           => 19,
    NODE_IMAGE          => 20,
    # For compatibility
    NODE_HTML           =>  6,
    NODE_HEADER         =>  9,
    NODE_HRULE          => 10,
    NODE_INLINE_HTML    => 15,

    NO_LIST      => 0,
    BULLET_LIST  => 1,
    ORDERED_LIST => 2,

    NO_DELIM     => 0,
    PERIOD_DELIM => 1,
    PAREN_DELIM  => 2,

    EVENT_NONE  => 0,
    EVENT_DONE  => 1,
    EVENT_ENTER => 2,
    EVENT_EXIT  => 3,

    OPT_DEFAULT       => 0,
    OPT_SOURCEPOS     => 1 <<  1,
    OPT_HARDBREAKS    => 1 <<  2,
    OPT_SAFE          => 1 <<  3,
    OPT_NORMALIZE     => 1 <<  8,
    OPT_VALIDATE_UTF8 => 1 <<  9,
    OPT_SMART         => 1 << 10,
};

my @option_map = (
    sourcepos     => OPT_SOURCEPOS,
    hardbreaks    => OPT_HARDBREAKS,
    safe          => OPT_SAFE,
    normalize     => OPT_NORMALIZE,
    validate_utf8 => OPT_VALIDATE_UTF8,
    smart         => OPT_SMART,
);

sub parse {
    my ($class, %opts) = @_;

    my ($string, $file) = @opts{ qw(string file) };

    my $parser_opts = _extract_opts(\%opts);

    my $doc;
    if (defined($string)) {
        die("can't provide both string and file")
            if defined($file);
        $doc = $class->parse_document($string, $parser_opts);
    }
    elsif (defined($file)) {
        $doc = $class->parse_file($file, $parser_opts);
    }
    else {
        die("must provide either string or file");
    }

    return $doc;
}

sub _extract_opts {
    my $hash = shift;

    my $int = 0;

    for (my $i = 0; $i < @option_map; $i += 2) {
        my ($name, $val) = @option_map[$i,$i+1];
        $int |= $val if $hash->{$name};
    }

    return $int;
}

sub create_document {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_DOCUMENT);
    return _add_children($node, \%opts);
}

sub create_block_quote {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_BLOCK_QUOTE);
    return _add_children($node, \%opts);
}

sub create_list {
    my (undef, %opts) = @_;

    my $node = CommonMark::Node->new(NODE_LIST);

    my ($type, $delim, $start, $tight)
        = @opts{ qw(type delim start tight) };

    $node->set_list_type($type)   if defined($type);
    $node->set_list_delim($delim) if defined($delim);
    $node->set_list_start($start) if defined($start);
    $node->set_list_tight($tight) if defined($tight);

    return _add_children($node, \%opts);
}

sub create_item {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_ITEM);
    return _add_children($node, \%opts);
}

sub create_code_block {
    my (undef, %opts) = @_;

    my $node = CommonMark::Node->new(NODE_CODE_BLOCK);

    my $fence_info = $opts{fence_info};
    $node->set_fence_info($fence_info) if defined($fence_info);

    return _add_literal($node, \%opts);
}

sub create_html {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_HTML);
    return _add_literal($node, \%opts);
}

sub create_paragraph {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_PARAGRAPH);
    return _add_children_or_text($node, \%opts);
}

sub create_header {
    my (undef, %opts) = @_;

    my $node = CommonMark::Node->new(NODE_HEADER);

    my $level = $opts{level};
    $node->set_header_level($level) if defined($level);

    return _add_children_or_text($node, \%opts);
}

sub create_hrule {
    return CommonMark::Node->new(NODE_HRULE);
}

sub create_text {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_TEXT);
    return _add_literal($node, \%opts);
}

sub create_softbreak {
    return CommonMark::Node->new(NODE_SOFTBREAK);
}

sub create_linebreak {
    return CommonMark::Node->new(NODE_LINEBREAK);
}

sub create_code {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_CODE);
    return _add_literal($node, \%opts);
}

sub create_inline_html {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_INLINE_HTML);
    return _add_literal($node, \%opts);
}

sub create_emph {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_EMPH);
    return _add_children_or_text($node, \%opts);
}

sub create_strong {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_STRONG);
    return _add_children_or_text($node, \%opts);
}

sub create_link {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_LINK);
    return _add_link_opts($node, \%opts);
}

sub create_image {
    my (undef, %opts) = @_;
    my $node = CommonMark::Node->new(NODE_IMAGE);
    return _add_link_opts($node, \%opts);
}

sub _add_children {
    my ($node, $opts) = @_;

    my $children = $opts->{children};
    if (defined($children)) {
        for my $child (@$children) {
            $node->append_child($child);
        }
    }

    return $node;
}

sub _add_literal {
    my ($node, $opts) = @_;

    my $literal = $opts->{literal};
    $node->set_literal($literal) if defined($literal);

    return $node;
}

sub _add_children_or_text {
    my ($node, $opts) = @_;

    my $children = $opts->{children};
    my $literal  = $opts->{text};

    if (defined($children)) {
        die("can't set both children and text")
            if defined($literal);
        return _add_children($node, $opts);
    }

    if (defined($literal)) {
        my $text = __PACKAGE__->create_text(literal => $literal);
        $node->append_child($text);
    }

    return $node;
}

sub _add_link_opts {
    my ($node, $opts) = @_;

    my $url   = $opts->{url};
    my $title = $opts->{title};

    $node->set_url($url)     if defined($url);
    $node->set_title($title) if defined($title);

    return _add_children_or_text($node, $opts);
}

package CommonMark::Node;

sub render {
    my ($self, %opts) = @_;

    my $format = $opts{format};
    die("must provide format")
        if !defined($format);
    my $method = "render_$format";

    my $render_opts = CommonMark::_extract_opts(\%opts);

    if ($format =~ /^(html|xml)\z/) {
        return $self->$method($render_opts);
    }
    if ($format =~ /^(commonmark|latex|man)\z/) {
        return $self->$method($render_opts, $opts{width});
    }

    die("invalid format '$format'");
}

1;

