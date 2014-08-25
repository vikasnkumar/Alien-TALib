use Test::More;

BEGIN { use_ok('Alien::TALib'); }

$Alien::TALib::FORCE = 0;
$Alien::TALib::VERBOSE = 1;
my $alien = new_ok('Alien::TALib');
can_ok($alien, 'cflags');
isnt($alien->cflags, undef, "has cflags()");
note($alien->cflags);
can_ok($alien, 'libs');
isnt($alien->libs, undef, "has libs()");
note($alien->libs);
can_ok($alien, 'is_installed');
can_ok($alien, 'ta_lib_config');

done_testing();
__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 12th Jan 2013
#### LICENSE: Refer LICENSE file.
