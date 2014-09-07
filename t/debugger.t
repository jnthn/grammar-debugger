use v6;

use Test;
use Grammar::Debugger;

plan 1;


grammar Sample {
    token TOP { <foo> }
    token foo { x }
}

lives_ok
    {
        my $*OUT = class { method say(*@x) { }; method print(*@x) { }; method flush(*@x) { } };
        my $*IN  = class { method get(*@x) { '' } };
        Sample.parse('x')
    },
    'grammar.parse(...) with the debugger works';
