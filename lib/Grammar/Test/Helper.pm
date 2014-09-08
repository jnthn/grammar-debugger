module Grammar::Test::Helper;

use Term::ANSIColor;

enum StdStream is export <IN OUT ERR>;


class RemoteControl is export {

    class Out-capture {
        has StdStream     $.stdStream;
        has RemoteControl $.rc;
        method print(*@args) { $.rc.record($.stdStream, 'print', @args) }
        method flush(*@args) { $.rc.record($.stdStream, 'flush', @args) }
    }

    class In-capture {
        has                 @.answers;
        has RemoteControl   $.rc;
        method get(*@args) {
            my $out = @.answers ?? shift @.answers !! '';
            $.rc.record(IN, 'get', :$out, @args);
            return $out;
        }
    }

    has @!calls = ().hash;

    multi method calls() {
        return @!calls;
    }

    multi method calls(StdStream:D $stdStream) {
        return @!calls.grep({ $_<where> == $stdStream });
    }

    method record(StdStream:D $stdStream, Str:D $which, :$out?, *@args) {
        my $entry = {
            when  => now,
            where => $stdStream,
            which => $which,
            args  => @args,
            out   => $out,
        };
        $entry does role {
            method Str(Bool :$colorstrip = False) {
                self.perl(:$colorstrip);
            }
            method perl(Bool :$colorstrip = False) {
                '$*' ~ self<where> ~ '.' ~ self<which>
                    ~ ( self<args>.elems
                        ?? '(' ~ self<args>.map({ ($colorstrip ?? colorstrip($_) !! $_).perl }) ~ ');' 
                        !! ';' )
                    ~ ( self<out>.defined 
                        ?? ' # ~> ' ~ self<out>.perl
                        !! '' )
                    ~ '        # @' ~ self<when>
                    ~ "\n"
            }
        };
        @!calls.push($entry);
    }

    has $!result;   # should not be set via constructor
    method result { $!result }

    method do (|args) {
        (self // RemoteControl.new)!do(|args);
    }

    method !do (&block, :@answers = ()) {
        my ($oldOUT, $oldERR, $oldIN) = ($*OUT, $*ERR, $*IN);
        ($*OUT, $*ERR, $*IN) = Out-capture.new(:stdStream(OUT), :rc(self)), Out-capture.new(:stdStream(ERR), :rc(self)), In-capture.new(:rc(self), :@answers);
        $!result = &block();
        ($*OUT, $*ERR, $*IN) = ($oldOUT, $oldERR, $oldIN);
        return self;
    }

    multi method lines(Bool :$colorstrip = True) {
        self!lines(@!calls, :$colorstrip);
    }

    multi method lines(StdStream:D $where, Bool :$colorstrip = True) {
        self!lines( self.calls($where), :$colorstrip );
    }

    method !lines(@calls, Bool :$colorstrip = True) {
        my @out = @calls.grep({
            $_<which> ne 'flush'
        }).map({
            $_<where> == IN
                ?? $_<out> ~ "\n"
                !! $_<args>.join('')
        }).map({
            $colorstrip ?? colorstrip($_) !! $_
        }).join('').split(/\n/);
        my $last = pop @out;
        @out = @out.map({
            $_ ~ "\n";
        });
        if ($last ne '') {
            @out.push($last);
        }
        return @out;
    }
}






my enum InvokeOn is export <ClassOnly InstanceOnly ClassAndInstance>;

class ParseTask is Code does Callable {
    has Grammar $!grammar;
    has Method  $!parseMethod;
    has Capture $!args;

    submethod BUILD(Grammar:U :$grammarType, Bool:D :$callOnClass, :$!parseMethod, :$!args ) {
        $!grammar = $callOnClass ?? $grammarType !! $grammarType.new;
    }

    method postcircumfix:<( )>(|ignoredArgs) {
        return $!parseMethod($!grammar, |$!args);
    }

    method !str($argStr = '...') {
        $!grammar.perl ~ '.' ~ $!parseMethod.name ~ "($argStr)";
    
    }

    method Str() { self!str }

    method perl() {
        self!str(
            $!args.list>>.perl.list.push(
                $!args.hash.pairs.map({':' ~ $_.key ~ '(' ~ $_.value.perl ~ ')'})
            ).join(', ')
        );
    }
}


multi sub parseTasks (
    Grammar:U $grammarType,
    Str :$file, # file to parse with parsefile
    Str :$text, # text to parse or subparse
    |args
) is export {
    return parseTasks(ClassAndInstance, $grammarType, :$file, :$text, |args);
}

multi sub parseTasks (
    InvokeOn:D $invokeOn!,
    Grammar:U $grammarType,
    Str :$file, # file to parse with parsefile
    Str :$text, # text to parse or subparse
    |args
) is export {
    die "must provide one or both, :file and :text"
        unless $file.defined || $text.defined;
    my @invocants = ();
    @invocants.push(True)
        if $invokeOn == (ClassAndInstance, ClassOnly).any;
    @invocants.push(False)
        if $invokeOn == (ClassAndInstance, InstanceOnly).any;
    my @parseMethods = <parse subparse parsefile>.map({ $grammarType.HOW.find_method($grammarType, $_) });
    return (@invocants X @parseMethods).tree.map({
        my $parseMethod = $_[1];
        my $p = $parseMethod.name eq 'parsefile' ?? $file !! $text;
        #say $p ~ ' ' ~ args.perl;
        $p.defined
            ?? ParseTask.new(
                :$grammarType,
                :callOnClass($_[0]),
                :$parseMethod,
                :args(Capture.new(:list($p,), :hash(args.hash)))
            )
            !! Nil
        ;
    });
}
