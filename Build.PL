use strict;
use warnings;
use Module::Build;
use Alien::Base::ModuleBuild;

my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 0,
    create_license => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Base::ModuleBuild' => 0,
    },
    build_requires => {
        'Alien::Base::ModuleBuild' => 0,
        'Test::More' => 0,
        'Data::Dumper' => 0,
    },
    requires => {
        'perl' => '5.10.0',
        'Alien::Base' => 0,
        'Carp' => 0,
    },
);

$build->create_build_script;
$build->dispatch('clean');
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.
