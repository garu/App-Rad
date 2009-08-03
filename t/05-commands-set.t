use Test::More tests => 3;
use App::Rad::Tester;

my $c = get_controller;

is($c->cmd, undef, 'no command should be set upon startup');

$c->cmd = 'somecommand';
is($c->cmd, 'somecommand', 'developer should be able to set $c->cmd');

$c->command = 'anothercommand';
is($c->cmd, 'anothercommand', 'developer should be able to set $c->cmd');
