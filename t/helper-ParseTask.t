use v6;

use Test;
use Grammar::Test::Helper;
# do NOT put `use Grammar::Debugger` here!

plan 39;


my $some-file = IO::Path.new(IO::Path.new($?FILE).directory ~ '/some.txt').absolute;
ok $some-file.e, "got sample input file $some-file";

{ diag "&parseTasks tests";
# ------------------------------------

    my grammar Sample {
        rule TOP { xyz }
    }

    {
        my @pts = parseTasks(Sample, :text('xyz'));

        isa_ok @pts[0], Code, "a ParseTask is actually callable";
        my $match;
        lives_ok { $match = @pts[0]() }, 
            "calling it invokes the grammars's parse/subparse/parsefile method";
        isa_ok $match, Match, "it returns what the grammar's method returned";

        my @ts = @pts>>.perl;

        is @ts.elems, 4, '4 combinations with named param :text';
        is @ts[0], 'Sample.parse("xyz")';
        is @ts[1], 'Sample.subparse("xyz")';
        is @ts[2], 'Sample.new().parse("xyz")';
        is @ts[3], 'Sample.new().subparse("xyz")';
    }

    {
        my @ts = parseTasks(Sample, :file('some.txt'))>>.perl;

        is @ts.elems, 2, '2 combinations with named param :file';
        is @ts[0], 'Sample.parsefile("some.txt")';
        is @ts[1], 'Sample.new().parsefile("some.txt")';
    }
    {
        my @ts = parseTasks(Sample, :text('xyz'), :file('some.txt'))>>.perl;

        is @ts.elems, 6, '6 combinations with named param :file and :text';
        is @ts[0], 'Sample.parse("xyz")';
        is @ts[1], 'Sample.subparse("xyz")';
        is @ts[2], 'Sample.parsefile("some.txt")';
        is @ts[3], 'Sample.new().parse("xyz")';
        is @ts[4], 'Sample.new().subparse("xyz")';
        is @ts[5], 'Sample.new().parsefile("some.txt")';
    }

    {
        my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :text('xyz'))>>.perl;

        is @ts.elems, 2, '2 combinations with InvokeOn::ClassOnly and named param :text';
        is @ts[0], 'Sample.parse("xyz")';
        is @ts[1], 'Sample.subparse("xyz")';
    }
    {
        my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :file('some.txt'))>>.perl;

        is @ts.elems, 1, '1 combinations with InvokeOn::ClassOnly and named param :file';
        is @ts[0], 'Sample.parsefile("some.txt")';
    }

    { diag "let's try with a file that actually exists - unsuccessful parse";
        my @pts = parseTasks(InvokeOn::ClassAndInstance, Sample, :file(~$some-file));

        my $match;
        my $pt = @pts[0];
        lives_ok { $match = $pt() }, $pt.perl ~ " lives";
        nok $match.defined, 
            "$pt does NOT succeed parsing (MATCH: " ~ ($match // '') ~ ')';
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
        lives_ok { $match = $pt() }, $pt.perl ~ " lives";
        ok $match.defined, 
            "$pt does succeed parsing (MATCH: " ~ ($match // '') ~ ')';
    }

    { diag 'parseTasks(InvokeOn::ClassOnly, Sample, :text("xyz"), :file("some.txt")';
        my @ts = parseTasks(InvokeOn::ClassOnly, Sample, :text('xyz'), :file('some.txt'))>>.perl;

        is @ts.elems, 3, '3 combinations with InvokeOn::ClassOnly and named param :file and :text';
        is @ts[0], 'Sample.parse("xyz")';
        is @ts[1], 'Sample.subparse("xyz")';
        is @ts[2], 'Sample.parsefile("some.txt")';
    }

    { diag 'can add additional parameters that will be passed on to the parsemethod';
        my @ts = parseTasks(Sample, :text('xyz'), :file('some.txt'), :rule<foo>)>>.perl;

        is @ts.elems, 6, '6 combinations with named param :file and :text';
        is @ts[0], 'Sample.parse("xyz", :rule("foo"))';
        is @ts[1], 'Sample.subparse("xyz", :rule("foo"))';
        is @ts[2], 'Sample.parsefile("some.txt", :rule("foo"))';
        is @ts[3], 'Sample.new().parse("xyz", :rule("foo"))';
        is @ts[4], 'Sample.new().subparse("xyz", :rule("foo"))';
        is @ts[5], 'Sample.new().parsefile("some.txt", :rule("foo"))';
    }

}

