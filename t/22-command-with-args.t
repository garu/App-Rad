use Test::More tests => 29;

use App::Rad::Command;

# testing empty (global) command
my $cmd = App::Rad::Command->new();

is($cmd->name, '', "default name should be set to ''.");
is($cmd->help, undef, "default help should not be defined");

# testing empty (global) command with options
$cmd = App::Rad::Command->new({
        opts => {
            'opt1' => 'help for opt1',
            'opt2' => { type => 'num' },
            'opt3' => { type => 'num',
                        help => 'help for opt3',
                      }
        }
     });

is($cmd->{opts}->{'opt1'}->{help}, 'help for opt1');
foreach (qw(type condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{opts}->{'opt1'}->{$_}, undef, "type $_ should be undef on opt1");
}

is($cmd->{opts}->{'opt2'}->{type}, 'num');
foreach (qw(help condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{opts}->{'opt2'}->{$_}, undef, "type $_ should be undef on opt2");
}

is($cmd->{opts}->{'opt3'}->{type}, 'num');
is($cmd->{opts}->{'opt3'}->{help}, 'help for opt3');
foreach (qw(condition  aliases  to_stash required 
            default error_msg  conflicts_with)) {
    is($cmd->{opts}->{'opt3'}->{$_}, undef, "type $_ should be undef on opt3");
}
