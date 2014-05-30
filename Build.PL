use strict;
use warnings;
use Alien::Base::ModuleBuild;

$Alien::Base::ModuleBuild::Verbose = 1;
$Alien::Base::ModuleBuild::Force = 1;

my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 0,
    create_license => (-e 'LICENSE' ? 0 : 1),
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Base' => 0,
        'Alien::Base::ModuleBuild' => 0,
        'Software::License' => 0,
    },
    build_requires => {
        'Alien::Base::ModuleBuild' => 0,
        'Test::More' => 0,
        'Module::Build' => 0,
        'Software::License' => 0,
    },
    requires => {
        'perl' => '5.10.0',
        'Alien::Base' => 0,
    },
    alien_name => 'ta_lib',
    alien_repository => {
        protocol => 'http',
        host => 'prdownloads.sourceforge.net',
        location => '/ta-lib/',
        exact_filename => 'ta-lib-0.4.0-src.tar.gz',
        exact_version => '0.4.0',
        sha1 => 'b326b91e79ca1e569e95aad91e87a38640dd5f1b',
        sha256 => '9ff41efcb1c011a4b4b6dfc91610b06e39b1d7973ed5d4dee55029a0ac4dc651',
    },
    alien_build_commands => [
        '%pconfigure --prefix=%s',
        'make',
        'make check'
    ],
    alien_install_commands => [
        'make install'
    ],
    alien_provides_cflags => "-DHAVE_CONFIG_H",
    alien_provides_libs => "-lpthread -ldl -lta_lib",
    alien_version_check => "ta-lib-config --version",
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
    },
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.
