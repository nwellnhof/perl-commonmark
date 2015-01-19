use strict;
use warnings;

use Test::More tests => 132;

BEGIN {
    use_ok('CommonMark');
}

my $md = <<EOF;
- Item 1
  - *__Text__*
- Item 2
EOF

my $doc = CommonMark->parse_document($md);
isa_ok($doc, 'CommonMark::Node', 'parse_document');

my @expected_events = (
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_DOCUMENT  ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_LIST      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_TEXT      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_LIST      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_EMPH      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_STRONG    ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_TEXT      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_STRONG    ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_EMPH      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_LIST      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_ENTER, CommonMark::NODE_TEXT      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_PARAGRAPH ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_ITEM      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_LIST      ],
    [ CommonMark::EVENT_EXIT,  CommonMark::NODE_DOCUMENT  ],
);

{
    my $iter = $doc->iterator;
    isa_ok($iter, 'CommonMark::Iterator', 'iterator');

    for (my $i = 0; $i < @expected_events; ++$i) {
        my ($ev_type, $node) = $iter->next;
        my $expected = $expected_events[$i];

        is($ev_type, $expected->[0], "event $i: next ev_type, list context");
        is($iter->get_event_type, $ev_type, "event $i: get_event_type");

        is($node->get_type, $expected->[1],
           "event $i: next node, list context");
        is($iter->get_node, $node, "event $i: get_node");
    }

    my @list = $iter->next;
    is(scalar(@list), 0, 'iterator done, list context');
}

{
    my $iter = $doc->iterator;

    for (my $i = 0; $i < @expected_events; ++$i) {
        my $ev_type  = $iter->next;
        my $expected = $expected_events[$i];
        is($ev_type, $expected->[0], "event $i: next ev_type, scalar context");
    }

    my $ev_type = $iter->next;
    is($ev_type, CommonMark::EVENT_DONE, 'iterator done, scalar context');
}

{
    my $iter = $doc->iterator;

    # Make sure iterator survives destruction of document.
    $doc  = undef;
    # Cause some allocations.
    CommonMark->parse_document($md)
        for 1..5;

    my $num  = 0;

    $iter->next for 1..11;
    my $strong = $iter->get_node;
    is($strong->get_type, CommonMark::NODE_STRONG, '11th node is strong');

    $iter = undef;
    # Cause some allocations.
    CommonMark->parse_document($md)
        for 1..5;

    my $literal = $strong->first_child->get_literal;
    is($literal, 'Text', 'node survives destruction of iter');
}

