use Test::More tests => 1;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 1 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents= <<'EOT';
use App::Rad;
App::Rad->run();

sub setup {
    my $c = shift;
    $c->register_commands({
        usernew => 'new user',
        userdel => 'delete user',
        userlist => 'list user',
        topicnew => 'new topic',
        topicdel => 'delete topic',
        topiclist => 'list topic',
    });
    $c->group_commands('User handling', 'usernew', );
    $c->group_commands('Topic handling', 'topicnew', 'topicdel', 'topiclist');
    $c->group_commands('User handling', 'userlist');
}

sub usernew { return 1; }

sub userdel :Group(User handling) { return 2; }

sub userlist { return 3; }

sub topicnew { return 4; }

sub topicdel { return 5; }

sub topiclist { return 6; }

EOT

    print $fh $contents;
    close $fh;

    my $ret = `$^X $filename`;

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
Topic handling:
    topicnew \tnew topic
    topicdel \tdelete topic
    topiclist\tlist topic

User handling:
    userdel  \tdelete user
    usernew  \tnew user
    userlist \tlist user

Other commands:
    help     \tshow syntax and available commands

EOHELP

   is($ret, $helptext);

}
