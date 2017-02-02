use Grammar::Debugger::WrapCache;
use Terminal::ANSIColor;

# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

my class TracedGrammarHOW is Metamodel::GrammarHOW does Grammar::Debugger::WrapCache {
    my $indent = 0;

    method find_method($obj, $name) {
        my \cached = %!cache{$name};
        return cached if cached.DEFINITE;
        my $meth := callsame;
        if $meth.^name eq 'NQPRoutine' || $meth !~~ Any || $meth !~~ Regex {
            self!cache-unwrapped: $name, $meth;
        }
        else {
            self!cache-wrapped: $name, $meth, -> $c, |args {
                # Method name.
                say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();

                # Call rule.
                $indent++;
                my $result := $meth($obj, |args);
                $indent--;

                # Dump result.
                my $match := $result.MATCH;
                say ('|  ' x $indent) ~ '* ' ~
                    ($result.MATCH ??
                        colored('MATCH', 'white on_green') ~ summary($match) !!
                        colored('FAIL', 'white on_red'));
                $result
            }
        }
    }

    sub summary($match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW {
    constant grammar = TracedGrammarHOW;
}
