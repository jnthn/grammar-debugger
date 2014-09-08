use v6;

use Test;
use Grammar::Test::Helper;

plan 49;


diag "RemoteControl tests";
# ------------------------------------


sub invocants {
    #return (RemoteControl);     # test on class only
    #return (RemoteControl.new); # test on instance only
    return (RemoteControl, RemoteControl.new); # test on both
}

{
    my $rc1 = RemoteControl.do(->{});
    my $rc2 = RemoteControl.do(->{});
    isnt $rc1, $rc2, ".do on the class returns new instance every time";
}

{ for invocants() -> $rc {
    my $out = $rc.do({ say 42; 23; });
    isa_ok $out, RemoteControl, $rc.perl ~ ".do returns a RemoteControl";
    is $out.result, 23, $rc.perl ~ '.do(->{ ...}) .result is the block\'s result';
}}

{ # neither print, say nor note should output anything:
    { for invocants() -> $rc {
        my $called = '';
        { # replace $*OUT for this scope only:
            my $*OUT = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ print "foo"; });
        }
        is $called, '', $rc.perl ~ " captures calls to print (STDOUT)";
    }}

    { for invocants() -> $rc {
        my $called = '';
        { # replace $*OUT for this scope only:
            # say simply calls print:
            my $*OUT = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ say "asdf"; });
        }
        is $called, '', $rc.perl ~ " captures calls to say (STDOUT)";
    }}

    { for invocants() -> $rc {
        my $called = '';
        { # replace $*ERR for this scope only:
            # note prints to STDERR:
            my $*ERR = class { method print(*@args) { $called = "should not be called" } };
            $rc.do({ note "baz"; });
        }
        is $called, '', $rc.perl ~ " captures calls to note (STDERR)";
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
        #diag $out.lines.map(*.perl);
        is $out.lines.elems,    5,                  $rc.perl ~ " records lines";
        is $out.lines[0],       "Hello world!\n",   $rc.perl ~ " multiple args are merged";
        is $out.lines[1],       "foo\n",            $rc.perl ~ " inline NL makes new line";
        is $out.lines[2],       "bar\n",            $rc.perl ~ " say appends an NL";
        is $out.lines[3],       "on STDERR!\n",     $rc.perl ~ " note appends an NL";
        is $out.lines[4],       "FIN.",             $rc.perl ~ " doesn't add NL to incomplete line";
    }}
    { for invocants() -> $rc {
        my $out = $rc.do({ 
            say("Hello world!"); 
            say("Have fun!"); 
        });
        is $out.lines.elems,    2,                  $rc.perl ~ " doesn't add spurious NL to last line";
        is $out.lines[0],       "Hello world!\n",   $rc.perl ~ " logs 1st line";
        is $out.lines[1],       "Have fun!\n",      $rc.perl ~ " doesn't add spurious NL to last line";
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
        is $out.lines[1], "> \n", $rc.perl ~ " logs prompt line";
        is $in, '', $rc.perl ~ " returns answer to client code without NL";
    }}
}


{ # provides given answers (and then empty ones) if $*IN.get is called (as eg from prompt)
    { for invocants() -> $rc {
        my $in1;
        my $in2;
        my $in3;
        my $out = $rc.do(:answers<foo bar>, {
            say "something";
            $in1 = prompt "> ";
            $in2 = prompt "> ";
            $in3 = prompt "> ";
            say "done.";
        });
        #diag $out.lines.map(*.perl);
        is $out.lines[1], "> foo\n", $rc.perl ~ " logs 1st prompt line";
        is $out.lines[2], "> bar\n", $rc.perl ~ " logs 2nd prompt line";
        is $out.lines[3], "> \n",    $rc.perl ~ " logs 3rd prompt line";
        is $in1, 'foo', $rc.perl ~ " returns 1st answer to client code without NL";
        is $in2, 'bar', $rc.perl ~ " returns 2nd answer to client code without NL";
        is $in3, '',    $rc.perl ~ " returns 3rd answer to client code without NL";
    }}
}


{ # can filter .lines by passing a StdStream
    { for invocants() -> $rc {
        my $out = $rc.do(:answers<foo bar>, {
            say "something";
            prompt "> ";
            prompt "> ";
            say "done.";
        });
        my $lines = $out.lines(StdStream::IN);
        #diag $lines;
        is $lines.elems, 2, $rc.perl ~ " lines(IN) yields only lines with calls to get";
    }}
    { for invocants() -> $rc {
        my $out = $rc.do({
            say "something";
            say "done.";
        });
        my $lines = $out.lines(StdStream::IN);
        #diag $lines;
        is $lines.elems, 0, $rc.perl ~ " lines(IN) yields only lines with calls to get";
    }}

}
