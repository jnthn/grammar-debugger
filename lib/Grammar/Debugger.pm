use Term::ANSIColor;

my enum InterventionPoint <EnterRule ExitRule>;

multi trait_mod:<is>(Method $m, :$breakpoint!) is export {
    $m does role { method breakpoint { True } }
}
multi trait_mod:<will>(Method $m, $cond, :$break!) is export {
    $m does role {
        has $.breakpoint-condition is rw;
        method breakpoint { True }
    }
    $m.breakpoint-condition = $cond;
}

my class DebuggedGrammarHOW is Mu is Metamodel::GrammarHOW {
    has $!indent = 0;
    has $!auto-continue = False;
    has $!stop-at-fail = False;
    has $!stop-at-name = '';
    has @!breakpoints;
    has %!cond-breakpoints;
    
    method add_method(Mu $obj, $name, $code) {
        callsame;
        if $code.?breakpoint {
            if $code.?breakpoint-condition {
                %!cond-breakpoints{$code.name} = $code.breakpoint-condition;
            }
            else {
                @!breakpoints.push($code.name);
            }
        }
    }
    
    method find_method($obj, $name) {
        my $meth := callsame;
        substr($name, 0, 1) eq '!' || $name eq any(<parse CREATE BUILD Bool defined MATCH>) ??
            $meth !!
            -> $c, |$args {
                # Method name.
                say ('|  ' x $!indent) ~ BOLD() ~ $name ~ RESET();
                
                # Call rule.
                self.intervene(EnterRule, $name);
                $!indent++;
                my $result := $meth($c, |$args);
                $!indent--;
                
                # Dump result.
                my $match := $result.MATCH;
                say ('|  ' x $!indent) ~ '* ' ~
                    ($result.MATCH ??
                        colored('MATCH', 'white on_green') ~ self.summary($match) !!
                        colored('FAIL', 'white on_red'));
                self.intervene(ExitRule, $name, :$match);
                $result
            }
    }
    
    method intervene(InterventionPoint $point, $name, :$match) {
        # Any reason to stop?
        my $stop = 
            !$!auto-continue ||
            $point == EnterRule && $name eq $!stop-at-name ||
            $point == ExitRule && !$match && $!stop-at-fail ||
            $point == EnterRule && $name eq any(@!breakpoints) ||
            $point == ExitRule && $name eq any(%!cond-breakpoints.keys)
                && %!cond-breakpoints{$name}.ACCEPTS($match);
        if $stop {
            my $done;
            repeat {
                my @parts = split /\s+/, prompt("> ");
                $done = True;
                given @parts[0] {
                    when '' {
                        $!auto-continue = False;
                        $!stop-at-fail = False;
                        $!stop-at-name = '';
                    }
                    when 'r' {
                        given +@parts {
                            when 1 {
                                $!auto-continue = True;
                                $!stop-at-fail = False;
                                $!stop-at-name = '';
                            }
                            when 2 {
                                $!auto-continue = True;
                                $!stop-at-fail = False;
                                $!stop-at-name = @parts[1];
                            }
                            default {
                                usage();
                                $done = False;
                            }
                       }
                    }
                    when 'rf' {
                        $!auto-continue = True;
                        $!stop-at-fail = True;
                        $!stop-at-name = '';
                    }
                    when 'bp' {
                        if +@parts == 2 && @parts[1] eq 'list' {
                            say "Current Breakpoints:\n" ~
                                @!breakpoints.map({ "    $_" }).join("\n");
                        }
                        elsif +@parts == 3 && @parts[1] eq 'add' {
                            unless @!breakpoints.grep({ $_ eq @parts[2] }) {
                                @!breakpoints.push(@parts[2]);
                            }
                        }
                        elsif +@parts == 3 && @parts[1] eq 'rm' {
                            my @rm'd = @!breakpoints.grep({ $_ ne @parts[2] });
                            if +@rm'd == +@!breakpoints {
                                say "No breakpoint '@parts[2]'";
                            }
                            else {
                                @!breakpoints = @rm'd;
                            }
                        }
                        elsif +@parts == 2 && @parts[1] eq 'rm' {
                            @!breakpoints = [];
                        }
                        else {
                            usage();
                        }
                        $done = False;
                    }
                    when 'q' {
                        exit(0);
                    }
                    default {
                        usage();
                        $done = False;
                    }
                }
            } until $done;
        }
    }
    
    method summary($match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $!indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }
    
    sub usage() {
        say
            "    r              run (until breakpoint, if any)\n" ~
            "    <enter>        single step\n" ~
            "    rf             run until a match fails\n" ~
            "    r <name>       run until rule <name> is reached\n" ~
            "    bp add <name>  add a rule name breakpoint\n" ~
            "    bp list        list all active rule name breakpoints\n" ~
            "    bp rm <name>   remove a rule name breakpoint\n" ~
            "    bp rm          removes all breakpoints\n" ~
            "    q              quit"
    }
    
    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW.WHO.<grammar> = DebuggedGrammarHOW;
