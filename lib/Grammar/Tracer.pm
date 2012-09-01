use Term::ANSIColor;

my class TracedGrammarHOW is Metamodel::GrammarHOW {
    my $indent = 0;
    
    method find_method($obj, $name) {
        my $meth := callsame;
        substr($name, 0, 1) eq '!' || $name eq any(<parse CREATE BUILD Bool defined MATCH pos from>) ??
            $meth !!
            -> $c, |args {
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
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
