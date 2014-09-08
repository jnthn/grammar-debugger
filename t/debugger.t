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
    return ( # test both, the class and an instance
        Sample,
        Sample.new,
    );
}

sub triggers(Grammar $g, |args) {
    return (
        -> { $g.parse(|args)    } does role { method Str { '.parse' } },
        -> { $g.subparse(|args) } does role { method Str { '.subparse' } },
    );
}


{ diag 'can switch off auto-continue with `r`';
    for grammars() -> $g { for triggers($g, 'x') -> $t {
        my $out;
        lives_ok { $out = RemoteControl.do($t, :answers<r r>) },
            $g.perl ~ $t ~ '(...) with the debugger lives';

        is $out.lines(StdStream::IN).elems, 1,
            $g.perl ~ $t ~ '(...) stopped once after TOP';
        #diag $out.lines();
    }}
}

{ diag 'can add breakpoint manually via `bp add <name>`; is reset on subsequent parse';
    for grammars() -> $g { for triggers($g, 'baz') -> $t {
        my $out;
        $out = RemoteControl.do($t, :answers('bp add baz', 'r', 'r', 'r'));
        is $out.lines(StdStream::IN).elems, 4, 
            $g.perl ~ $t ~ ' stopped after TOP and breakpoints';
        #diag $out.lines();

        $out = RemoteControl.do($t, :answers('r', 'r'));
        is $out.lines(StdStream::IN).elems, 2, 
            $g.perl ~ $t ~ ' has reset manual breakpoint for subsequent parse';
        #diag $out.lines();
    }}
}
