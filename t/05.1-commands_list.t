use Test::More tests => 8;
use App::Rad::Tester;

my $c = get_controller;

is($c->commands, 1, 'only help command on startup');
is($c->is_command('help'), 1, 'help command not set on startup');
$c->unregister('help');

$c->register('cmd1', \&stub);
$c->register('cmd2', \&stub);
is($c->commands, 2, 'two commands should have been set');

$c->unregister('cmd1');
is($c->commands, 1, 'one command should have been set');

$c->register('cmd1', \&stub);
$c->register('cmd2', \&stub);
$c->register('cmd3', \&stub);
my @cmds = $c->commands;
is(scalar @cmds, 3, 'three commands should have been set');
foreach (@cmds) {
	is($c->is_command($_), 1, "$_ should be a valid command");
}

sub stub {};
