package Bash::Completion::Plugins::perlbrew;

use strict;
use warnings;
use feature 'switch';
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(command_in_path);

our $VERSION = '0.01';

my @perlbrew_commands = qw/
init install list use switch mirror off version help env install-cpanm
/;

my @perlbrew_options = qw/
 -h --help -f --force -j -n --notest -q --quiet -v --verbose --as -D -U -A
/;

sub should_activate {
    return [ grep { command_in_path($_) } qw/perlbrew/ ];
}

sub complete {
    my ( $self, $r ) = @_;

    my $word = $r->word;

    if($word =~ /^-/) {
        $r->candidates(grep { /^\Q$word\E/ } @perlbrew_options);
    } else {
        my @args = $r->args;
        shift @args; # get rid of 'perlbrew'
        shift @args until @args == 0 || $args[0] !~ /^-/;

        my $command = $args[0] // '';

        given($command) {
            when($command eq $word) {
                $r->candidates(grep { /^\Q$word\E/ }
                    ( @perlbrew_commands, @perlbrew_options ));
            }
            when(qr/^switch|env|use$/) {
                my @perls = split /\n/, qx(perlbrew list);
                @perls = map { /^\*?\s*(?<name>\S+)/; $+{'name'} } @perls;
                $r->candidates(grep { /^\Q$word\E/ } @perls);
            }
            when('install') {
                continue; # for now (complete Perls later)
            }
            default {
                # all other commands (including unrecognized ones) get
                # no completions
                $r->candidates();
            }
        }
    }
}

1;

__END__

=head1 NAME

Bash::Completion::Plugins::perlbrew - Bash completion for perlbrew

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Bash::Completion> support for L<perlbrew|App::perlbrew>.  Completes perlbrew
options as well as installed perlbrew versions.

=head1 AUTHOR

Rob Hoelz C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Bash-Completion-Plugins-perlbrew at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bash-Completion-Plugins-perlbrew>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Bash::Completion>, L<Bash::Completion::Plugin>, L<App::perlbrew>

=begin comment

=over

=item should_activate

=item complete

=back

=end comment

=cut
