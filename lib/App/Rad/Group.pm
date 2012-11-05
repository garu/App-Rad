package App::Rad::Group;
use Attribute::Handlers;
use strict;
use warnings;

our $VERSION = '0.01';
    

sub group_commands {
        my ($c, $description, @commands) = @_;
        
        # only group existing commands
        foreach my $check_command (@commands) {
                Carp::croak("$check_command is not a registered command") unless $c->{'_commands'}->{$check_command};
        }
        
        push @{$c->{'_command_groups'}->{$description}}, @commands;
        return ;
}


{
        my %group_attr = ();
        sub UNIVERSAL::Group :ATTR(CODE) {
                my ($package, $symbol, $code, undef, $data) = (@_);

                if ($package eq 'main') {
                        # If data is a single word, it is received as an array ref. Don't ask.
                        $data = join(' ', @$data) if ref($data) eq 'ARRAY';
                        $group_attr{ *{$symbol}{NAME} } = $data;
                }
        }
        sub get_group_attr_for {
                my ($self, $cmd) = (@_);
                return $group_attr{$cmd};
        }

}
42;
__END__

=head1 NAME

App::Rad::Group - grouping extension for App::Rad

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

When you have many commands you probably want help to group them instead of
printing them in alphabetical order. You can define such groups with C<< $c->group_commands() >>:

    use App::Rad;
    App::Rad->run();
    
    sub setup {
        my $c = shift;
        
        $c->register_commands( {
                foo => 'expand your foo!',
                bar => 'have a drink! arguments: --drink=DRINK',
                baz => 'do your thing',
            });
            
        $c->group_commands('Commands with o', 'foo');
        $c->group_commands('Commands with a', 'bar', 'baz');
        $c->group_commands('Commands with 3 letters', 'foo', 'bar', 'baz');
    }
    
You see commands can be in multiple groups.

You can also do it with the attribute 'Group' in your subs

    sub my_command :Group(My commands) {
        ...
    }
    
    sub another_cmd
    :Group(My commands)
    {
        ...
    }
    
Note, that you can only set one group per command with atttributes.

=head1 DESCRIPTION

This is an internal module for App::Rad and should not be used separately. Please refer to L<< App::Rad >> for further documentation.


=head1 INTERNAL METHODS

=head2 Methods exported into App::Rad's API

=head3 group_commands

Expects a group name and a list of existing commands. Adds the commands to the
group. Can be called multiple times.

=head2 Methods you really don't need to worry about

=head3 get_group_attr_for

given a command name, returns it's its group attribute string (if one was set
with the :Group() attribute). Currently, only one group can be set via
attribute so the return value is a scalar.

=head1 DEPENDENCIES

=over 4

=item * Attribute::Handlers, which is core as of Perl 5.8.

=back


=head1 AUTHOR

Maik Hentsche, C<< <caldrin at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Much of the module was taken from App::Rad::Help. This made escpecially the
development of the attribute feature much easier.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Maik Hentsche C<< <caldrin at cpan.org> >>. All rights reserved.
Copyright 2008 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.



=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
