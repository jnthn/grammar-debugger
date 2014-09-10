use v6;
use Term::ANSIColor;

use Grammar::InterceptedGrammarHOW;


# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

my class TracedGrammarHOW is InterceptedGrammarHOW {

    # Use same pattern for keeping state as in Debugger (see there)
    # TODO: to be refactored sometime...
    has $!state = (().hash does role {
        multi method reset() {
            self<indent> = 0;
            return self;
        }
    }).reset;
    
    method find_method(Mu $obj, $name) {
        my $meth := callsame;

        if $name eq any(<parse subparse>) {
            
            # Wrapped: tag role st *we* (here) wrap only once
            # There's more to code wrapping than one might
            # think (see Routine.pm) and they use a role named 
            # Wrapped there, too. It's not public - for a reason...!
            # Hence we cannot use it here - it would be
            # incorrect anyways as someone else could have
            # wrapped it before (in which case we still need
            # to wrap our own stuff around).
            my role Wrapped {};

            if !$meth.does(Wrapped) {
                $meth.wrap(-> |args {
                    $!state.reset();   # TODO: unify with Debugger
                    callsame;
                });
                $meth does Wrapped;
            }
            #note ">>>>>>>>>>>>> find_method(..., $name) ~> " ~ ($meth ~~ Any ?? $meth.perl !! '???');
        }

        return $meth unless $meth ~~ Regex;
        return -> Mu $c, |args {
            # Announce that we're about to enter the rule/token/regex
            self.onRegexEnter($name, $!state<indent>);
            
            # Call rule.
            $!state<indent>++;
            my $result := $meth($c, |args);
            $!state<indent>--;
            
            # Announce that we've returned from the rule/token/regex
            my $match := $result.MATCH;
            self.onRegexExit($name, $!state<indent>, $match);

            $result;
        }
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
