use Grammar::Debugger::WrapCache;
use Terminal::ANSIColor;

=begin pod

=head1 NAME

Grammer::Tracer - non-interactive debugger for Perl 6 grammars

=head1 SYNOPSIS

In the file that has your grammar definition, merely load the module
in the same lexical scope:

	use Grammar::Tracer;

	grammar Some::Grammar { ... }

=head1 DESCRIPTION

L<Grammar::Tracer> is the non-interactive version of L<Grammar::Debugger>.
It runs through the entire grammar without stopping.

=head1 AUTHOR

Jonathan Worthington, C<< <jnthn@jnthn.net> >>

=end pod

enum TraceModes <Always Never Error>;
my TraceModes $mode = Always;

sub GrammarTraceMode(TraceModes $mode_in) is export {
    $mode = $mode_in;
}


my class TracedGrammarHOW is Metamodel::GrammarHOW does Grammar::Debugger::WrapCache {
   my $level = 0;
   my @traces;

    method find_method($obj, $name) {
        my \cached = %!cache{$name};
        return cached if cached.DEFINITE;
        my $meth := callsame;
        if $meth.^name eq 'NQPRoutine' || $meth !~~ Any || $meth !~~ Regex {
            self!cache-unwrapped: $name, $meth;
        }
        else {
            self!cache-wrapped: $name, $meth, -> $c, |args {

                @traces = () if $level == 0 ;

                @traces.append: Any ;
                
                my $this = @traces.end ;
                my $indentation = '   ' x $level ;
            
                # Call rule.
                $level++;
                my $result;
                try {
                    $result := $meth($c, |args);
                    CATCH {
                        $level--;
                    }
                }
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
                @traces.join("\n").say if $level == 0 && ($mode == Always || ($mode == Error && !$result.MATCH));
                
                $result
            }
        }
    }

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW {
    constant grammar = TracedGrammarHOW;
}
