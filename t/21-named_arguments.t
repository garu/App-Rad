use Test::More tests => 1;
use App::Rad::Tester;

#TODO test help output with arguments
my $c = get_controller;
$c->register('bar', \&foo, { foo => 'sets foo', bar => 'sets bar' } );

sub foo {
    my $c = shift;
    my $out = '*';
    $out .= 'foo' if ($c->options->{foo});
    $out .= 'bar' if ($c->options->{bar});
    return $out;
}

local @ARGV = qw(bar);
$c->parse_input;
is_deeply(\@ARGV, []);

@ARGV = qw(bar --foo);
$c->parse_input;

#TODO test output with illegal argument
