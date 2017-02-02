role Grammar::Debugger::WrapCache {
    has %!cache;

    method !cache-unwrapped(Str $name, Mu \unwrapped) {
        %!cache{$name} := unwrapped;
        unwrapped
    }

    method !cache-wrapped(Str $name, \wrapped) {
        %!cache{$name} := wrapped;
        wrapped
    }
}
