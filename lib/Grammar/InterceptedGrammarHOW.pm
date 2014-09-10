use v6;

use Term::ANSIColor;    # TODO: get rid of ANSIColor here; see also TODO at end of file


class InterceptedGrammarHOW is Metamodel::GrammarHOW {

    # TODO: associate state to the right thing, sometime...
    has $!state = (().hash does role {
        multi method reset() {
            self<indent> = 0;
            return self;
        }
    }).reset;

    method !resetState() {
        $!state.reset();    # reset our own
        self.resetState;    # tell subclass to reset their's
    }

    method !onRegexEnter(Str $name) {
        self.onRegexEnter($name, $!state<indent>);
        $!state<indent>++; # let's *explicitly* put the *post*-increment here!
    }

    method !onRegexExit(Str $name, Match $match) {
        --$!state<indent>; # let's *explicitly* put the *pre*(sic!)-decrement here!
        self.onRegexExit($name, $!state<indent>, $match);
    }

    ## those are to be overridden by subclass:
    method resetState() {}
    #method onRegexEnter(Str $name, Int $indent) {} # TODO: see TODO at end of file
    #method onRegexExit(Str $name, Match $match, Int $indent) {}    # TODO: see TODO at end of file

    method find_method(Mu $obj, $name) {
        my $meth := callsame;

        # TODO: parsefile actually calls parse in the current implementation
        # but that may change.
        # So here again we have kind of a "magic" list of method names for
        # intercepting the *start of a new parse*.
        # This should be abstracted somehow.
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
                    self!resetState;
                    callsame;
                });
                $meth does Wrapped;
            }
            #note ">>>>>>>>>>>>> find_method(..., $name) ~> " ~ ($meth ~~ Any ?? $meth.perl !! '???');
        }

        return $meth unless $meth ~~ Regex;

        return -> |args {
            # Announce that we're about to enter the rule/token/regex
            self!onRegexEnter($name);
            
            # Actually call the rule/token/regex
            my $result := $meth(|args);
            
            # Announce that we've returned from the rule/token/regex
            self!onRegexExit($name, $result.MATCH);

            $result;
        };
    }

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }


# -----------------------------------------------------------------------------
# TODO: all the stuff below should go somewhere else - although it
# is still common to both, Debugger *and* Tracer...

    method onRegexEnter(Str $name, Int $indent) {
        # Issue the rule's/token's/regex's name
        say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        say ('|  ' x $indent) ~ '* ' ~
            ($match ??
                colored('MATCH', 'white on_green') ~ self.summary($match, $indent) !!
                colored('FAIL', 'white on_red'));
    }

    method summary(Match $match, Int $indent) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }



}

