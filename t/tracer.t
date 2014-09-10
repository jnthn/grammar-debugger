use v6;

use Test;
use Grammar::Test::Helper;

use Grammar::Tracer;

plan 18;


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
        lives_ok({ $out = RemoteControl.do($t) },
            $t.perl ~ " with the tracer lives");
        isa_ok($out.result, Match,
            $t.perl ~ " with the tracer succeeded")
            || diag $out.result;

        { # the following should be made a bit more flexible...
            my @lines = $out.lines(StdStream::OUT); # ignore STDERR
            is_deeply(@lines, [
                    "TOP\n",
                    "|  foo\n",
                    "|  * MATCH \"x\"\n",
                    "* MATCH \"x\"\n",
                ], $t.perl ~ " with the tracer gives correct output on STDOUT")
                || diag ' ' ~ @lines;
        }
    }
}

{ diag 'test-case proposed in pull-request #5';
    # Note: let's NOT use &parseTasks so we make sure it's on the very same thing
    my $out1;
    my $out2;
    my $out3;
    
    lives_ok({ $out1 = RemoteControl.do({Sample.parse("x")}) },
        'Sample.parse("x") with the tracer lives')
        || diag $out1.lines;
    
    # now let's descend into the rule that throws
    lives_ok({ $out2 = RemoteControl.do({Sample.parse("boom")}) },
        '*remote-controlling* Sample.parse("boom") survives');
    isa_ok($out2.result, Exception, 'Sample.parse("boom") with the tracer threw');
    is($out2.result, 'Boom!',
        'Sample.parse("boom") with the tracer threw the right thing')
        || diag $out2.lines;

    # again do successful parse
    lives_ok({ $out3 = RemoteControl.do({Sample.parse("x")}) },
        'Sample.parse("x") (again) with the tracer lives')
        || diag $out3.lines;

    # let's compare STDOUT only (not STDERR), as in the original test-case:
    is($out3.lines(StdStream::OUT).join(''), $out1.lines(StdStream::OUT).join(''),
        'the two successful parses should give identical output');
}

