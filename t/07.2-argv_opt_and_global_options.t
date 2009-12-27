use Test::More skip_all => 'further testing required'; #tests => 18;

use App::Rad::Tester;

### TODO: if we try it without registering 'commandname', 
### it should trigger 'invalid'. But what do we do with the options() and argv()?

# kids, don't try this at home...
@ARGV = qw(-x -abc --def --test1=2 --test2=test commandname -vvv -x ble --test1=3);
my $c = get_controller;
$c->register('commandname', sub {});
$c->parse_input();

TODO: {
    local $TODO = 'how should we handle @ARGV in such cases?';
    
is(scalar @ARGV, 4, '@ARGV should have 4 elements');
is_deeply(\@ARGV, ['-x', '-abc', '--def', '--test1=2', '--test2=test', 'ble', '-vvv', '-x'], 
   '@ARGV should have just the passed arguments, not the command name'
  );
}

is(scalar @{$c->argv}, 1, '$c->argv should have 1 argument');
is(keys %{$c->options}, 3, '$c->options should have 3 elements');

is($c->cmd, 'commandname', 'command name should be set');


is_deeply($c->argv, ['ble'], '$c->argv arguments should be consistent');
is($c->globals->{'a'}, 1, "'-a' should be set");
is($c->globals->{'b'}, 1, "'-b' should be set");
is($c->globals->{'c'}, 1, "'-c' should be set");

ok(!defined $c->globals->{'abc'}, "'--abc' should *not* be set");
ok(!defined $c->globals->{'d'}  , "'-d' should *not* be set");
ok(!defined $c->globals->{'e'}  , "'-e' should *not* be set");
ok(!defined $c->globals->{'f'}  , "'-f' should *not* be set");

ok(defined $c->options->{'def'}, "'--def' should be set");
is($c->options->{'test1'}, 2, "'--test1' should be set to '2'");
is($c->options->{'test2'}, 'test', "'--test2' should be set to 'test'");
is($c->options->{'v'}, 3, "single arguments can be incremented when put together");
is($c->options->{'x'}, 2, "single arguments can be incremented when invoked separately");
