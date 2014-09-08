use v6;
use Term::ANSIColor;

use Grammar::InterceptedGrammarHOW;


# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

my class TracedGrammarHOW is Metamodel::GrammarHOW does InterceptedGrammarHOW {
    my $indent = 0;
    
    method find_method($obj, $name) {
        my $meth := callsame;
        return $meth unless $meth ~~ Regex;
        return -> $c, |args {
            # Announce that we're about to enter the rule/token/regex
            self.onRegexEnter($name, $indent);
            
            # Call rule.
            $indent++;
            my $result := $meth($obj, |args);
            $indent--;
            
            # Dump result.
            my $match := $result.MATCH;
            say ('|  ' x $indent) ~ '* ' ~
                ($result.MATCH ??
                    colored('MATCH', 'white on_green') ~ self.summary($match, $indent) !!
                    colored('FAIL', 'white on_red'));
            $result
        }
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
