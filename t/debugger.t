use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Debugger;

plan 21;


my $baz-file = IO::Path.new(IO::Path.new($?FILE).directory ~ '/baz.txt').absolute;
ok $baz-file.e, "got sample input file $baz-file";


grammar Sample {
    rule  TOP               { <foo> }
    token foo               { x | <bar> | <baz> }
    regex bar is breakpoint { bar }
    regex baz               { baz }

    method fizzbuzz {}
}


{ diag 'can switch on auto-continue with `r`';
    for parseTasks(Sample, :text('x')) -> $t {
        my $out;
        lives_ok { $out = RemoteControl.do($t, :answers<r r>) },
            "$t with the debugger lives";

        is $out.lines(StdStream::IN).elems, 1,
            "$t stopped once after TOP";
        #diag $out.lines();
    }
}

{ diag 'can add breakpoint manually via `bp add <name>`; is reset on subsequent parse';
    for parseTasks(Sample, :text('baz'), :file(~$baz-file)) -> $t {
        my $out;
        $out = RemoteControl.do($t, :answers('bp add baz', 'r', 'r', 'r'));
        is $out.lines(StdStream::IN).elems, 4, 
            "$t stopped after TOP and breakpoints";
        #diag $out.lines();

        $out = RemoteControl.do($t, :answers('r', 'r'));
        is $out.lines(StdStream::IN).elems, 2, 
            "$t has reset manual breakpoint for subsequent parse";
        #diag $out.lines();
    }
}
