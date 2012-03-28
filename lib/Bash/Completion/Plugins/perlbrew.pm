## no critic (RequireUseStrict)
package Bash::Completion::Plugins::perlbrew;

## use critic (RequireUseStrict)
use strict;
use warnings;
use feature 'switch';
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(command_in_path);

my @perlbrew_commands = qw/
init    install list use           switch    mirror    off
version help    env  install-cpanm available uninstall self-upgrade
alias exec switch-off install-patchperl lib
/;

my @perlbrew_options = qw/
 -h --help -f --force -j -n --notest -q --quiet -v --verbose --as -D -U -A
/;

my @lib_subcommands = qw/
    create delete
/;

sub should_activate {
    return [ grep { command_in_path($_) } qw/perlbrew/ ];
}

sub _extract_perl {
    my ( $perl ) = @_;

    $perl =~ s/\@.*//;
    return $perl
}

sub _extract_lib {
    my ( $perl ) = @_;

    $perl =~ s/.*\@//;

    return $perl;
}

sub _get_perls {
    my @perls = split /\n/, qx(perlbrew list);
    my ( $current_perl ) = grep { /^\*\s*/ } @perls;
    ( $current_perl )    = $current_perl =~ /^\*\s*(\S+)/;

    $current_perl = _extract_perl($current_perl);

    return ( $current_perl, map { /^\*?\s*(?<name>\S+)/; $+{'name'} } @perls );
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
                my ( $current_perl, @perls ) = _get_perls();
                my @libs = map { '@' . _extract_lib($_) }
                    grep { /^\Q$current_perl\E\@/ } @perls;
                $r->candidates(grep { /^\Q$word\E/ } ( @perls, @libs ));
            }
            when('uninstall') {
                my ( undef, @perls ) = _get_perls();
                $r->candidates(grep { /^\Q$word\E/ } @perls);
            }
            when('install') {
                my @perls = split /\n/, qx(perlbrew available);
                @perls = map { /^i?\s*(?<name>.*)/; $+{'name'}  } @perls;
                push @perls, 'perl-blead';
                $r->candidates(grep { /^\Q$word\E/ } @perls);
            }
            when('lib') {
                my ( $subcommand ) = grep { $_ !~ /^-/ } @args[ 1 .. $#args ];

                $subcommand //= '';

                if($subcommand eq $word) {
                    $r->candidates(grep { /^\Q$word\E/ } @lib_subcommands);
                } else {
                    $r->candidates(); # we can't predict what you name your
                                      # libs!
                }
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

# ABSTRACT: Bash completion for perlbrew

=head1 DESCRIPTION

L<Bash::Completion> support for L<perlbrew|App::perlbrew>.  Completes perlbrew
options as well as installed perlbrew versions.

=head1 SEE ALSO

L<Bash::Completion>, L<Bash::Completion::Plugin>, L<App::perlbrew>

=begin comment

=over

=item should_activate

=item complete

=back

=end comment

=cut
