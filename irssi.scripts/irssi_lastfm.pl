#!/usr/bin/env perl
#
# irssi_lastfm.pl
# 
# This script is intended to print the 
# 'now playing' song title to your current IRC channel.
#
# Sean O'Donnell <sean@seanodonnell.com>
#

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use XML::RSS::Parser;

$VERSION = '1.0.0';

%IRSSI = (
    authors     => 'Sean O\'Donnell',
    contact     => 'sean@seanodonnell.com',
    name        => 'Now Playing on Last.FM (Updated)',
    description => 'Fetches the currently playing track and prints it to the current channel.',
    license     => 'GPL',
);

my $lastfmuser = "v3xt0r";
my $feed_url = "http://ws.audioscrobbler.com/2.0/user/".$lastfmuser."/recenttracks.rss";

my $parser = XML::RSS::Parser->new;

sub print_np
{
	my ($args, $server, $target) = @_;

	my $feed = $parser->parse_uri($feed_url);

	if (!$feed)
	{
	    $server->command("MSG ". $target->{'name'} ." Error parsing RSS feed (".$feed_url.")");
	    return;
	}

	my $count = $feed->item_count;
	my $max = 1;

	if ($count > 0)
	{
	    my $title;
	    my $link;
	    my $x = 0;
	
	    foreach my $i ( $feed->query('//item') ) 
	    { 
	
	        $title = $i->query('title');
	        $link = $i->query('link');
	    
	        if ($title->text_content)
	        {
			my $text = $title->text_content;
			# $text =~ s/\s//g;
			# $text =~ s/\t//g;
	        	$server->command("MSG ". $target->{'name'} ." np: ". $text);
	        }
	
	        $x++;
	
	        if ($x eq $max)
	        {
	            return;
	        }
	    }
	} 
	else
	{
	    $server->command("MSG ". $target->{'name'} ." Error: RSS Feed (".$feed_url.") could not be parsed.");
	}
	return;
}

Irssi::command_bind('np', 'print_np');
