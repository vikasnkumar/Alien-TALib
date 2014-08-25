use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 1,
    create_license => (-e 'LICENSE' ? 0 : 1),
    needs_compiler => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Software::License' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
        'Software::License' => 0,
    },
    requires => {
        'File::Spec' => 0,
        'File::Which' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
    },
);
my $pref = $build->install_destination('bin');
$pref =~ s/bin\/?$//g; # remove the bin. Maybe use File::Basename
$build->config_data(prefix => $ENV{PREFIX} || $build->prefix() || $pref);
$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.
