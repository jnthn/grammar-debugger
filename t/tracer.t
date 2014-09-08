use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Tracer;

plan 2;


grammar Sample {
    token TOP { <foo> }
    token foo { x }
}

sub grammars() {
    return (Sample, Sample.new); # test both, the class and an instance
}


{
    for grammars() -> $gr {
        lives_ok { RemoteControl.do({ $gr.parse('x'); }) },
            'grammar.parse(...) with the tracer lives';
    }
}
