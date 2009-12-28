#!/usr/bin/perl -w

use lib 'C:\repos\App-Rad\lib';
use App::Rad qw(Abbrev);

# title takes constant, scalar variable, arrayref, or filehandle
App::Rad->shell({
    title      => [<DATA>],
    prompt     => 'app-rad:',
    autocomp   => 1,
    abbrev     => 1,
    ignorecase => 0,
    history    => 1, # or 'path/to/histfile.txt'
});
    
sub write :Help('Say hello!') {
    my $c = shift;
    return "I am called " . ($c->prompt({
        ask => 'What\'s your name?',
        opt => 'name'
    }) || "Something...?");
}

sub read :Help('Read a file!') {
    my $c = shift;
    return "I am called " . ($c->prompt({
        ask => 'What\'s your name?',
        set => 'GOD',
        opt => 'name'
    }) || "Something...?");
}
__DATA__
Welcome to the App::Rad shell program...