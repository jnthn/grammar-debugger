use v6;

use Test;
use Grammar::Tracer;

plan 1;


grammar Sample {
    token TOP { <foo> }
    token foo { x }
}

lives-ok
    {
        my $*OUT = class { method say(*@x) { }; method print(*@x) { }; method flush(*@x) { } }
        Sample.parse('x')
    },
    'grammar.parse(...) with the tracer works';
