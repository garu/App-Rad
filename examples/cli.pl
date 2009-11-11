#!/usr/bin/perl -w

use lib 'C:\repos\App-Rad\lib';
use App::Rad;

App::Rad->shell({
    title      => 'Welcome to the App::Rad shell program',
    prompt     => 'app-rad:',
    autocomp   => 1,
    abbrev     => 1,
    ignorecase => 0,
    history    => 1, # or 'path/to/histfile.txt'
});
    
sub write :Help('Say hello!') {
    my $c = shift;
    return "I am called " . ($c->prompt({
        ask => 'What\'s your name?'
    }) || "Something...?");
}