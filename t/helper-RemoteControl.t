use v6;

use Test;
use Grammar::Test::Helper;

plan 47;


sub invocants {
    #return (RemoteControl);     # test on class only
    #return (RemoteControl.new); # test on instance only
    return (RemoteControl, RemoteControl.new); # test on both
}


{ diag 'RemoteControl catches exceptions thrown in &block and returns them as result';
    for invocants() -> $rc {
        my $out;
        lives_ok({ $out = $rc.do( -> {
            say "last";
            say "words";
            die "Boom!";
        })}, $rc.perl ~ " lives even if given block dies");

        is($out.result, "Boom!", $rc.perl ~ " returns the exception thrown as .result");
        is_deeply($out.lines, [
                "last\n",
                "words\n"
            ], $rc.perl ~ " still records lines up to where it was thrown")
            || diag $out.lines;
    }
}

{
    my $rc1 = RemoteControl.do(->{});
    my $rc2 = RemoteControl.do(->{});
    isnt($rc1, $rc2, ".do on the class returns new instance every time");
}

{ for invocants() -> $rc {
    my $out = $rc.do({ say 42; 23; });
    isa_ok($out, RemoteControl, $rc.perl ~ ".do returns a RemoteControl");
    is($out.result, 23, $rc.perl ~ '.do(->{ ...}) .result is the block\'s result');
}}

{ # neither print, say nor note should output anything:
    { for invocants() -> $rc {
        my $called = '';
        { # replace $*OUT for this scope only:
            my $*OUT = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ print "foo"; });
        }
        is($called, '', $rc.perl ~ " captures calls to print (STDOUT)");
    }}

    { for invocants() -> $rc {
        my $called = '';
        { # replace $*OUT for this scope only:
            # say simply calls print:
            my $*OUT = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ say "asdf"; });
        }
        is($called, '', $rc.perl ~ " captures calls to say (STDOUT)");
    }}

    { for invocants() -> $rc {
        my $called = '';
        { # replace $*ERR for this scope only:
            # note prints to STDERR:
            my $*ERR = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ note "baz"; });
        }
        is($called, '', $rc.perl ~ " captures calls to note (STDERR)");
    }}
}

{ diag 'should record all calls to print, say or note:';
    { for invocants() -> $rc {
        my $out = $rc.do({
            print("Hello", " ", "world!");
            print("", "\n");    # line 1: multiple args are merged
            say "foo\nbar";     # lines 2 and 3: inline \n makes new line, say adds one
            note "on STDERR!";  # line 4: note adds a \n
            print "FIN.";       # line 5: no newline here!
        });

        is($out.lines.elems,    5,                  $rc.perl ~ " records lines")
            || diag $out.lines.map(*.perl);
        # not using is_deeply for more specific comments:
        is($out.lines[0],       "Hello world!\n",   $rc.perl ~ " multiple args are merged");
        is($out.lines[1],       "foo\n",            $rc.perl ~ " inline NL makes new line");
        is($out.lines[2],       "bar\n",            $rc.perl ~ " say appends an NL");
        is($out.lines[3],       "on STDERR!\n",     $rc.perl ~ " note appends an NL");
        is($out.lines[4],       "FIN.",             $rc.perl ~ " doesn't add NL to incomplete line");
    }}
    { for invocants() -> $rc {
        my $out = $rc.do({ 
            say("Hello world!"); 
            say("Have fun!"); 
        });
        is_deeply($out.lines, [
                "Hello world!\n",
                "Have fun!\n"
            ], $rc.perl ~ " doesn't add spurious NL to last line")
            || diag $out.lines;
    }}
}


{ # provides (empty) answers if $*IN.get is called (as eg from prompt)
    { for invocants() -> $rc {
        my $in;
        my $out = $rc.do({
            say "something";
            $in = prompt "> ";
            say "done.";
        });
        #diag $out.lines.map(*.perl);
        is($out.lines[1], "> \n", $rc.perl ~ " logs prompt line");
        is($in, '', $rc.perl ~ " returns answer to client code without NL");
    }}
}


{ # provides given answers (and then empty ones) if $*IN.get is called (as eg from prompt)
    { for invocants() -> $rc {
        my @in = ();
        my $out = $rc.do(:answers<foo bar>, {
            say "something";
            @in.push(prompt "> ");
            @in.push(prompt "> ");
            @in.push(prompt "> ");
            say "done.";
        });
        is_deeply($out.lines[1..3].list, (
                "> foo\n",
                "> bar\n",
                "> \n",
            ).list, $rc.perl ~ " logs prompt lines with answers and NL")
            || diag $out.lines.map(*.perl);
        is_deeply(@in, ['foo', 'bar', ''],
            $rc.perl ~ " returns answer to client code without NL");
    }}
}


{ diag 'can filter .lines by passing a StdStream';
    { for invocants() -> $rc {
        my $out = $rc.do(:answers<foo bar>, {
            say "something";
            prompt "> ";
            note "on STDERR";
            prompt "> ";
            say "done.";
        });
        my @lines-IN = $out.lines(StdStream::IN);
        is_deeply(@lines-IN, ["foo\n", "bar\n"], 
            $rc.perl ~ ".lines(IN) contains answers plus NL")
            || diag @lines-IN;
        
        my @lines-ERR = $out.lines(StdStream::ERR);
        is_deeply(@lines-ERR, ["on STDERR\n"],
            $rc.perl ~ ".lines(ERR) contains exactly the line on STDERR")
            ||  diag @lines-ERR;
        
        my @lines-OUT = $out.lines(StdStream::OUT);
        is_deeply(@lines-OUT, [
                "something\n",
                "> foo\n",
                "> bar\n",
                "done.\n",
            ], $rc.perl ~ ".lines(OUT) contains prompt text and answers plus NL")
            || diag @lines-OUT && diag $out.calls;
    }}

    { for invocants() -> $rc {
        my $out = $rc.do({
            say "something";
            note "on STDERR";
            say "done.";
        });
        my @lines-IN = $out.lines(StdStream::IN);
        is_deeply(@lines-IN, [],
            $rc.perl ~ ".lines(IN) yields only lines with calls to get (none here)")
            || diag @lines-IN;
    }}

}
