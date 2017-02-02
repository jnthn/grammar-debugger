use v6;

use Test;
use Grammar::Tracer;

plan 1;

# Test case taken from GitHub Issue #13

grammar CppGrammar {
    proto token type { * }
    token type:builtin {
        [
            || 'const char *'
            || 'void'
        ]
    }

    rule type:identifier {
        <?>
        'const'?
        \w+
        $<pointy>=[<[&*]>* % <.ws>]

    }
}

class MyActions {
    method type:builtin ($/) {
        make 'builtin'
    }

    method type:identifier ($/) {
        make 'identifier'
    }
}

my $outcome = do {
    my $*OUT = class { method say(*@x) { }; method print(*@x) { }; method flush(*@x) { } }
	CppGrammar.parse('const char *', :rule<type>, :actions(MyActions)).made
}
todo 'Grammar::Tracer busts LTM';
is $outcome, 'identifier', 'Picked longest token';
