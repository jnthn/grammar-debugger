use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Debugger;

plan 49;


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
        lives_ok { $out = RemoteControl.do($t, :answers<r r>) };
        nok $out.result ~~ Exception, "$t with the tracer lives";
        diag $out.result
            if $out.result ~~ Exception;

        is $out.lines(StdStream::IN).elems, 1,
            "$t stopped once after TOP";

        { # the following should be made a bit more flexible...
            my @lines = $out.lines(); # all of them, non-filtered
            #diag $out.lines();
            is @lines[0], "TOP\n",              "printed starting rule 'TOP'";
            is @lines[1], "> r\n",              "then stopped and asked what to do ~> `r`";
            is @lines[2], "|  foo\n",           "then went into rule 'foo'";
            is @lines[3], "|  * MATCH \"x\"\n", "then reported match of rule 'foo'";
            is @lines[4], "* MATCH \"x\"\n",    "then reported match of rule 'TOP'";
            is @lines.elems, 5, "and that's it";
        }
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
