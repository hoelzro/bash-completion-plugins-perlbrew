use Module::Build;

my $build = Module::Build->new(
    dist_author => 'Rob Hoelz <rob@hoelz.ro>',
    module_name => 'Bash::Completion::Plugins::perlbrew',
    license     => 'perl',
    requires    => {
        perl               => '5.10.0',
        'Bash::Completion' => '0.001',
    },
);
$build->create_build_script;
