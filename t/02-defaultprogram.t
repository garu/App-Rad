use Test::More tests => 2;
use App::Rad::Tester;

my ($out, $filename) = test_app(\*DATA);

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help\tshow syntax and available commands

EOHELP

is($out, $helptext);

$out = test_app($filename, 'help');
is($out, $helptext);

__DATA__
use App::Rad;
App::Rad->run();
