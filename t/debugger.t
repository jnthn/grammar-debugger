use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Debugger;

plan *;


grammar Sample {
    rule  TOP               { <foo> }
    token foo               { x | <bar> | <baz> }
    regex bar is breakpoint { bar }
    regex baz               { baz }

    method fizzbuzz {}
}

sub grammars() {
    return (Sample, Sample.new); # test both, the class and an instance
}


{
    for grammars() -> $gr {
        my $out;
        lives_ok { $out = RemoteControl.do(:answers<r r>, { $gr.parse('x'); }) },
            'grammar.parse(...) with the debugger lives';

        is $out.lines(StdStream::IN).elems, 1, "stopped once after TOP";
        diag $out.lines();

    }
}
