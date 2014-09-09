use v6;

use Test;
use Grammar::Test::Helper;
# do NOT put `use Grammar::Debugger` here!

plan 15;


my $some-file = IO::Path.new(IO::Path.new($?FILE).directory ~ '/some.txt').absolute;
ok($some-file.e, "got sample input file $some-file");

my grammar Sample {  rule TOP { xyz }  }

{
    my @pts = parseTasks(Sample, :text('xyz'));

    isa_ok(@pts[0], Code, "a ParseTask is actually callable");
    my $match;
    lives_ok({ $match = @pts[0]() }, 
        "calling it invokes the grammars's parse/subparse/parsefile method");
    isa_ok($match, Match, "it returns what the grammar's method returned");

    my @ts = @pts>>.perl;
    is_deeply(@ts, [
            'Sample.parse("xyz")',
            'Sample.subparse("xyz")',
            'Sample.new().parse("xyz")',
            'Sample.new().subparse("xyz")',
        ], '4 combinations with named param :text')
        || diag @ts;
}

{
    my @ts = parseTasks(Sample, :file('some.txt'))>>.perl;
    is_deeply(@ts, [
            'Sample.parsefile("some.txt")',
            'Sample.new().parsefile("some.txt")',
        ], '2 combinations with named param :file')
        || diag @ts;
}

{
    my @ts = parseTasks(Sample, :text('xyz'), :file('some.txt'))>>.perl;
    is_deeply(@ts, [
            'Sample.parse("xyz")',
            'Sample.subparse("xyz")',
            'Sample.parsefile("some.txt")',
            'Sample.new().parse("xyz")',
            'Sample.new().subparse("xyz")',
            'Sample.new().parsefile("some.txt")',
        ], '6 combinations with named param :file and :text')
        || diag @ts;
}

{
    my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :text('xyz'))>>.perl;
    is_deeply(@ts, [
            'Sample.parse("xyz")',
            'Sample.subparse("xyz")',
        ], '2 combinations with InvokeOn::ClassOnly and named param :text')
        || diag @ts;
}

{
    my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :file('some.txt'))>>.perl;
    is_deeply(@ts, [
            'Sample.parsefile("some.txt")'
        ], '1 combinations with InvokeOn::ClassOnly and named param :file')
        || diag @ts;
}

{ diag "let's try with a file that actually exists - unsuccessful parse";
    my @pts = parseTasks(InvokeOn::ClassAndInstance, Sample, :file(~$some-file));

    my $match;
    my $pt = @pts[0];
    lives_ok({ $match = $pt() }, $pt.perl ~ " lives");
    nok($match.defined, $pt.perl ~ " does NOT succeed parsing")
        || diag "MATCH: " ~ ($match // '');
}

{ diag "let's try with a file that actually exists - successful parse";
    my grammar G {
        rule TOP {
            some text [for us]? to parse
        }
    }

    my @pts = parseTasks(InvokeOn::ClassAndInstance, G, :file(~$some-file));

    my $match;
    my $pt = @pts[0];
    lives_ok({ $match = $pt() }, $pt.perl ~ " lives");
    ok($match.defined, 
        $pt.perl ~ " does succeed parsing (MATCH: " ~ ($match // '') ~ ')');
}

{
    my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :text('xyz'), :file('some.txt'))>>.perl;
    is_deeply(@ts, [
            'Sample.parse("xyz")',
            'Sample.subparse("xyz")',
            'Sample.parsefile("some.txt")',
        ], '3 combinations with InvokeOn::ClassOnly and named param :file and :text')
        || diag @ts;
}

{
    my @ts = parseTasks(Sample, :text('xyz'), :file('some.txt'), :rule<foo>)>>.perl;
    is_deeply(@ts, [
            'Sample.parse("xyz", :rule("foo"))',
            'Sample.subparse("xyz", :rule("foo"))',
            'Sample.parsefile("some.txt", :rule("foo"))',
            'Sample.new().parse("xyz", :rule("foo"))',
            'Sample.new().subparse("xyz", :rule("foo"))',
            'Sample.new().parsefile("some.txt", :rule("foo"))',
        ], 'can add additional parameters that will be passed on to the parsemethod')
        || diag @ts;
}
