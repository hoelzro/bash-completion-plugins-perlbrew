## no critic (RequireUseStrict)
package Bash::Completion::Plugins::perlbrew;

## use critic (RequireUseStrict)
use strict;
use warnings;
use feature 'switch';
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(command_in_path prefix_match);

my @perlbrew_commands = qw/
init    install list use           switch    mirror    off
version help    env  install-cpanm available uninstall self-upgrade
alias exec switch-off install-patchperl lib install-ack
list-modules info download upgrade-perl
/;

my @perlbrew_options = qw/
 -h --help -f --force -j -n --notest -q --quiet -v --verbose --as -D -U -A
 --with --switch
/;

my @lib_subcommands = qw/
    create delete
/;

my @alias_subcommands = qw/
    create rename delete
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
        $r->candidates(prefix_match($word, @perlbrew_options));
    } else {
        my @args = $r->args;
        shift @args; # get rid of 'perlbrew'
        shift @args until @args == 0 || $args[0] !~ /^-/;

        my $command = $args[0] // '';

        given($command) {
            when($command eq $word) {
                $r->candidates(prefix_match($word, @perlbrew_commands,
                    @perlbrew_options));
            }
            when(qr/^(?:switch|env|use)$/) {
                my ( $current_perl, @perls ) = _get_perls();
                my @libs = map { '@' . _extract_lib($_) }
                    prefix_match($current_perl . '@', @perls);
                $r->candidates(prefix_match($word, @perls, @libs));
            }
            when('uninstall') {
                my ( undef, @perls ) = _get_perls();
                @perls = grep { !/\@/ } @perls;
                $r->candidates(prefix_match($word, @perls));
            }
            when(qr/^(?:install|download)$/) {
                my @perls = split /\n/, qx(perlbrew available);
                @perls = map { /^i?\s*(?<name>.*)/; $+{'name'}  } @perls;
                push @perls, 'blead';
                push @perls, 'perl-blead';
                push @perls, 'perl-stable';
                push @perls, 'stable';
                $r->candidates(prefix_match($word, @perls));
            }
            when('lib') {
                my ( $subcommand ) = grep { $_ !~ /^-/ } @args[ 1 .. $#args ];

                $subcommand //= '';

                if($subcommand eq $word) {
                    $r->candidates(prefix_match($word, @lib_subcommands));
                } else {
                    if($subcommand eq 'delete') {
                        my ( $current_perl, @perls ) = _get_perls();
                        my @full_libs    = grep { /\@/ } @perls;
                        my @current_libs = map { '@' . _extract_lib($_) }
                            prefix_match($current_perl . '@', @perls);

                        $r->candidates(prefix_match($word, @full_libs, @current_libs));
                    } else {
                        $r->candidates(); # we can't predict what you name your
                                          # libs!
                    }
                }
            }
            when('alias') {
                my @words = grep { $_ !~ /^-/ } @args[ 1.. $#args ];

                my $subcommand = $words[0] // '';

                if($subcommand eq $word) {
                    $r->candidates(prefix_match($word, @alias_subcommands));
                } else {
                    if($subcommand eq 'create') {
                        my $name = $words[1] // '';

                        if($name eq $word) {
                            my ( undef, @perls ) = _get_perls();
                            @perls               = grep { $_ !~ /\@/ } @perls;

                            $r->candidates(prefix_match($word, @perls));
                        } else {
                            $r->candidates();
                        }
                    } else {
                        $r->candidates(); # unfortunately, we can't list
                                          # aliases separately yet =(
                    }
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

sub generate_bash_setup {
    return [qw(default)];
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
