use Test::More tests => 36;
use App::Rad::Tester;

# kids, don't try this at home...
@ARGV = qw(commandname bla -x -abc --def --test1=0 --test2=test ble -vvv -x);
my $c = get_controller;
parse_input($c);

is(scalar @ARGV, 10, '@ARGV should have all 10 elements when Rad finds an invalid command');
is(scalar @{$c->argv}, 2, '$c->argv should have 2 arguments');
is(keys %{$c->options}, 8, '$c->options should have 8 elements');

is($c->cmd, '', 'command name should NOT be set for unknown command');

is_deeply(\@ARGV, [qw(commandname bla -x -abc --def --test1=0 --test2=test ble -vvv -x)],
   '@ARGV should have all passed arguments for an unknown command'
  );

is_deeply($c->argv, ['bla', 'ble'], '$c->argv arguments should be consistent');
is($c->options->{'a'}, 1, "'-a' should be set");
is($c->options->{'b'}, 1, "'-b' should be set");
is($c->options->{'c'}, 1, "'-c' should be set");

ok(!defined $c->options->{'abc'}, "'--abc' should *not* be set");
ok(!defined $c->options->{'d'}  , "'-d' should *not* be set");
ok(!defined $c->options->{'e'}  , "'-e' should *not* be set");
ok(!defined $c->options->{'f'}  , "'-f' should *not* be set");

ok(defined $c->options->{'def'}, "'--def' should be set");
is($c->options->{'test1'}, 0, "'--test1' should be set to '0'");
is($c->options->{'test2'}, 'test', "'--test2' should be set to 'test'");
is($c->options->{'v'}, 3, "single arguments can be incremented when put together");
is($c->options->{'x'}, 2, "single arguments can be incremented when invoked separately");


### rerun tests, this time with the simplest 'commandname' command

# kids, don't try this at home...
@ARGV = qw(commandname bla -x -abc --def --test1=0 --test2=test ble -vvv -x);
$c = get_controller;
$c->register(commandname, sub {});
parse_input($c);

is(scalar @{$c->argv}, 2, '$c->argv should have 2 arguments');
is(keys %{$c->options}, 8, '$c->options should have 8 elements');

is($c->cmd, 'commandname', 'command name should be set');

TODO: {
    local $TODO = 'handle @ARGV on a per-command basis';
    
is(scalar @ARGV, 9, '@ARGV should have 9 elements');
is_deeply(\@ARGV, ['bla', '-x', '-abc', '--def', '--test1=0', '--test2=test', 'ble', '-vvv', '-x'], 
   '@ARGV should have just the passed arguments, not the command name'
  );
}

is_deeply($c->argv, ['bla', 'ble'], '$c->argv arguments should be consistent');
is($c->options->{'a'}, 1, "'-a' should be set");
is($c->options->{'b'}, 1, "'-b' should be set");
is($c->options->{'c'}, 1, "'-c' should be set");

ok(!defined $c->options->{'abc'}, "'--abc' should *not* be set");
ok(!defined $c->options->{'d'}  , "'-d' should *not* be set");
ok(!defined $c->options->{'e'}  , "'-e' should *not* be set");
ok(!defined $c->options->{'f'}  , "'-f' should *not* be set");

ok(defined $c->options->{'def'}, "'--def' should be set");
is($c->options->{'test1'}, 0, "'--test1' should be set to '0'");
is($c->options->{'test2'}, 'test', "'--test2' should be set to 'test'");
is($c->options->{'v'}, 3, "single arguments can be incremented when put together");
is($c->options->{'x'}, 2, "single arguments can be incremented when invoked separately");
