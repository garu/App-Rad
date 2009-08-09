use Test::More tests => 56;

use App::Rad::Command;

# testing empty (global) command
my $cmd = App::Rad::Command->new();

is($cmd->name, '', "default name should be set to ''.");
is($cmd->help, undef, "default help should not be defined");

# testing empty (global) command with arguments
$cmd = App::Rad::Command->new({
        args => {
            'arg1' => 'help for arg1',
            'arg2' => { type => 'num' },
            'arg3' => { type => 'num',
                        help => 'help for arg3',
                      }
        }
     });

is($cmd->{args}->{'arg1'}->{help}, 'help for arg1');
foreach (qw(type condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{args}->{'arg1'}->{$_}, undef, "type $_ should be undef on arg1");
}

is($cmd->{args}->{'arg2'}->{type}, 'num');
foreach (qw(help condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{args}->{'arg2'}->{$_}, undef, "type $_ should be undef on arg2");
}

is($cmd->{args}->{'arg3'}->{type}, 'num');
is($cmd->{args}->{'arg3'}->{help}, 'help for arg3');
foreach (qw(condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{args}->{'arg3'}->{$_}, undef, "type $_ should be undef on arg3");
}

# okay, no more new commands, let's just use the API
# to test further arguments
$cmd->set_arg('arg4');
ok(defined $cmd->{args}->{'arg4'}, 'arg4 argument should be defined');
foreach (qw(help condition  aliases  to_stash required 
            type default error_msg  conflicts_with)) {
    is($cmd->{args}->{'arg4'}->{$_}, undef, "type $_ should be undef on arg4");
}

## invalid argument settings
eval {
    $cmd->set_arg('arg5', { type => 1});
};
ok(defined $@, 'error should be raised on invalid type definition');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid type)');

eval {
    $cmd->set_arg('arg5', { help => \'this is a help text reference'});
};
ok(defined $@, 'error should be raised on invalid help definition');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid help)');

eval {
    $cmd->set_arg('arg5', { condition => 'invalid' });
};
ok(defined $@, 'error should be raised on invalid condition definition');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid condition)');

eval {
    $cmd->set_arg('arg5', { aliases => \'whatever' });
};
ok(defined $@, 'error should be raised on invalid aliases definition');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid aliases)');

eval {
    $cmd->set_arg('arg5', { to_stash => \'whatever' });
};
ok(defined $@, 'error should be raised on invalid to_stash definition');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid to_stash)');

eval {
    $cmd->set_arg('arg5', { error_msg => \1 });
};
ok(defined $@, 'error should be raised on invalid error_msg');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid error_msg)');

eval {
    $cmd->set_arg('arg5', { conflicts_with => \'whatever' });
};
ok(defined $@, 'error should be raised on invalid conflicts_with');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid conflicts_with)');

eval {
    $cmd->set_arg('arg5', { typo => 1 });
};
ok(defined $@, 'error should be raised on invalid attribute');
ok(!defined $cmd->{args}->{'arg5'}, 'arg5 argument should NOT be defined (invalid attribute)');

#we set this test to last as it is the only one that, under eval,
# will not croak and leave 'arg5' defined
eval {
    $cmd->set_arg('arg5', { required => 1, default => 'something' });
};
ok(defined $@, 'error should be raised when required and default are used at the same time');

