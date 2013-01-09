use Test;
use Grammar::Tracer;

plan 1;

grammar Sample {
    token TOP { <foo> }
    token foo { x }
}

lives_ok
    {
        my $*OUT = class { method say(*@x) { }; method print(*@x) { } }
        Sample.parse('x')
    },
    'Parsing a grammar with the tracer works';
