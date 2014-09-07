use v6;

use Test;
use Grammar::Tracer;

plan 2;


grammar Sample {
    token TOP { <foo> }
    token foo { x }
}


for (Sample, Sample.new) -> $gr { # test both, the class and an instance
    lives_ok {
        my $*OUT = class { method say(*@x) { }; method print(*@x) { }; method flush(*@x) { } }
        $gr.parse('x')
    }, 'grammar.parse(...) with the tracer lives';
}