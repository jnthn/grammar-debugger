use Terminal::ANSIColor;

# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

my class TracedGrammarHOW is Metamodel::GrammarHOW {
    my $level = 0;
    my @traces;

    method find_method($obj, $name) {
        my $meth := callsame;
        return $meth if $meth.WHAT.^name eq 'NQPRoutine';
        return $meth unless $meth ~~ Any;
        return $meth unless $meth ~~ Regex;
        return -> $c, |args {

            @traces = () if $level == 0 ;

            @traces.append: Any ;

            my $this = @traces.end ;
            my $indentation = '   ' x $level ;

            # Call rule.
            $level++;
            my $result := $meth($obj, |args);
            $level--;

            if $result.MATCH {
                my $width = 79 - (3 * $level);

                @traces[$this] = $indentation ~ colored($name, 'bold green') ~ RESET( ) ~ ' '
                                   ~ ( $width > 0 ?? $result.MATCH.Str.substr(0, $width).perl !! '' )
            }
            else{
                @traces[$this] = $indentation ~ colored($name, 'bold red') ~ RESET()
            }

            # Dump result.
            @traces.join("\n").say if $level == 0 ;

            $result
        }
    }
    
    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
