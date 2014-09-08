use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Tracer;

plan 30;


grammar Sample {
    token TOP  { <foo> | <boom> }
    token foo  { x }
    token boom {
        { die "Boom!" }
    }
}


{ diag 'check output for very simple successful parse';
    for parseTasks(Sample, :text('x')) -> $t {
        my $out;
        lives_ok { $out = RemoteControl.do($t) },
            $t.perl ~ " with the tracer lives";

        { # the following should be made a bit more flexible...
            my @lines = $out.lines; # all of them, non-filtered
            is @lines[0], "TOP\n",              "printed starting rule 'TOP'";
            is @lines[1], "|  foo\n",           "then went into rule 'foo'";
            is @lines[2], "|  * MATCH \"x\"\n", "then reported match of rule 'foo'";
            is @lines[3], "* MATCH \"x\"\n",    "then reported match of rule 'TOP'";
            is @lines.elems, 4, "and that's it";
            #diag $out.lines();
        }
    }
}

{ diag 'test-case proposed in pull-request #5';
    # Note: let's NOT use &parseTasks so we make sure it's on the very same thing
    my $out1;
    my $out2;
    my $out3;
    
    lives_ok { $out1 = RemoteControl.do({Sample.parse("x")}) },
        'Sample.parse("x") with the tracer lives';
    #diag $out1.lines;
    
    # now let's descend into the rule that throws
    lives_ok { $out2 = RemoteControl.do({Sample.parse("boom")}) },
        '*remote-controlling* Sample.parse("boom") survives';
    isa_ok $out2.result, Exception, 'Sample.parse("boom") with the tracer threw';
    is $out2.result, 'Boom!', 'Sample.parse("boom") with the tracer threw the right thing';
    #diag $out2.lines;

    # again do successful parse
    lives_ok { $out3 = RemoteControl.do({Sample.parse("x")}) },
        'Sample.parse("x") (again) with the tracer lives';
    #diag $out3.lines;

    is $out3.lines.join(''), $out1.lines.join(''), 
        'the two successful parses should give identical output';
}

