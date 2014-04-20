#!/usr/bin/perl

use strict;
use warnings;

sub sync_repo {
	my $p = {@_};
	my $github_user = $p->{github_user};
	my $bitbucket_user = $p->{bitbucket_user};
	my $private = $p->{private};
	my $repo_name = $p->{repo_name};
	my $base_dir = $p->{base_dir};
	
	print "Sync $github_user/$repo_name to $bitbucket_user/$repo_name (private=".$private.")\n";

	chdir $base_dir;
	system q( test -d ).$repo_name.q( || git clone git@github.com:).$github_user.q(/).$repo_name.q(.git );
	if (-d $base_dir."/".$repo_name) {
		chdir $base_dir."/".$repo_name;
		print "Pull all branches from github\n";
		system q( bash -c "git clean -xdf; git fetch origin; for i in $(git branch | sed 's/^.//'); do git checkout $i; git pull; done" );
		system q( git remote add bitbucket git@bitbucket.org:).$bitbucket_user.q(/).$repo_name.q(.git );
		print "Push all branches to bitbucket\n";
		system q( bash -c "echo -n | stdbuf -i0 -o0 -e0 git push -v bitbucket --all" );
	}
	else {
		print "Clone failed: $repo_name\n";
	}

	select undef, undef, undef, 1;
}

our @config;
require "config.pl";

my $base_dir = $ENV{HOME}."/tmp-github2bitbucket";
system qq( mkdir -p $base_dir );
print "base directory: ".$base_dir."\n";

foreach my $packed (@config) {
	foreach my $repo (@{$packed->{repos}}) {
		sync_repo (%$packed, repos => undef, repo_name => $repo, base_dir => $base_dir);
	}
}
