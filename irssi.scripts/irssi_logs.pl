#!/usr/bin/perl
#
# irssi_logs.pl
#
# irssi_logs.pl is a simple mysql database
# logging script. This will allow you to easily
# store all of your IRC logs into a central 
# database table, rather than flat text files.
#
# Copyleft (<) 2008 Sean O'Donnell <sean@seanodonnell.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# The complete text of the GNU General Public License can be found
# on the World Wide Web: <URL:http://www.gnu.org/licenses/gpl.html>
#
# $Id: irssi_logs.pl,v 1.4 2008/05/04 08:37:20 seanodonnell Exp $
#

use strict;
use DBI;
use Irssi;

#
# MySQL Database Connection Settings (EDIT THESE VARIABLES!)
#

my %mysql = (
	hostname 	=> 'localhost',
	username 	=> 'irssi_logs',
	password 	=> 'irssi_pass',
	db 			=> 'irssi_scripts',
	table 		=> 'irssi_logs',
);

### mysql database table structure...
#
# CREATE TABLE `irssi_logs` (
#  `id` mediumint(11) NOT NULL auto_increment,
#  `nick` varchar(25) default NULL,
#  `address` varchar(100) NOT NULL,
#  `chan` varchar(50) default NULL,
#  `server` varchar(50) default NULL,
#  `textinput` varchar(255) default NULL,
#  `logstamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
#  PRIMARY KEY  (`id`),
#  KEY `textinput` (`textinput`)
# ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='IRC logs via Irssi';
#
###

# mysql dsn connection string
my $mysql_dsn = 'DBI:mysql:'. $mysql{'db'} .':'.$mysql{'hostname'};

# variable declarations
my ($this,$quote,$sql,$str);
my ($db_conn,$db_query,$rs_row);
my ($server,$msg,$nick,$address,$target); # input message variables

our ($VERSION,%IRSSI);

$VERSION = "1.0.1";

%IRSSI = (
          name        => 'irssi_logs',
          authors     => 'Sean O\'Donnell',
          contact     => 'sean@seanodonnell.com',
          url         => 'http://www.seanodonnell.com/projects/irssi/logs/',
          license     => 'GPL',
          description => 'Sean\'s Database-Driven Logging System for the Irssi IRC Client',
          sbitems     => 'quotes',
);

sub mysql_query
{
	$sql = shift;

	if ($sql)
	{
		$db_conn = DBI->connect($mysql_dsn, $mysql{'username'}, $mysql{'password'}) 
			or return 'Connection Error: $DBI::err($DBI::errstr)';
		$db_query = $db_conn->prepare($sql) 
			or return 'SQL Error: $DBI::err($DBI::errstr)';
		$db_query->execute() 
			or return 'Query Error: $DBI::err($DBI::errstr)';
		$db_query->finish();
		$db_conn->disconnect();
	}
	return;
}

sub message_public
{
	($server,$msg,$nick,$address,$target) = @_;

	if ($msg)
	{
		# allow single-quotes to be added (as double-quotes, for now)
		$msg = sql_filter($msg);
		$sql = "INSERT INTO ". $mysql{'table'} ." (nick, address, chan, server, textinput) VALUES ('". $nick ."','". $address ."','". $target ."','". $server->{address} ."','". $msg ."')";
		mysql_query($sql);
	}
	return;
}

sub message_private
{
	($server,$msg,$nick,$address) = @_;

	if ($msg)
	{
		# allow single-quotes to be added (as double-quotes, for now)
		$msg = sql_filter($msg);
		$sql = "INSERT INTO ". $mysql{'table'} ." (nick, address, chan, server, textinput) VALUES ('". $nick ."','". $address ."','PRIVMSG','". $server->{address} ."','". $msg ."')";
		mysql_query($sql);
	}
	return;
}

sub message_own_public
{
	($server,$msg,$target) = @_;

	if ($msg)
	{
		# allow single-quotes to be added (as double-quotes, for now)
		$msg = sql_filter($msg);
		$sql = "INSERT INTO ". $mysql{'table'} ." (nick, address, chan, server, textinput) VALUES ('". $server->{nick} ."','localhost','". $target ."','". $server->{address} ."','". $msg ."')";
		mysql_query($sql);
	}
	return;
}

sub message_join
{
	($server,$target,$nick,$address) = @_;

	if ($msg)
	{
		# allow single-quotes to be added (as double-quotes, for now)
		$sql = "INSERT INTO ". $mysql{'table'} ." (nick, address, chan, server, textinput) VALUES ('". $nick ."','". $address ."','". $target ."','". $server->{address} ."','JOIN')";
		mysql_query($sql);
	}
	return;
}

sub sql_filter
{
	#
	# This method needs some serious work. There is still a minor bug 
	# that I have yet to identify as far as character handling is 
	# concerned. I'm pretty sure it's not single quotes that are 
	# causing the error, but I haven't really been able to catch 
	# text used to generate the error when it happens, as it usually
	# occurs at times when I'm in idle mode.
	#
	# -Sean
	#
	my $str = shift;
	$str =~ tr/[\'\\]/"/;
	return $str;
}
	
sub message_part
{
	($server,$target,$nick,$address,$msg) = @_;

	if ($msg)
	{
		# allow single-quotes to be added (as double-quotes, for now)
		$msg = sql_filter($msg);
		$sql = "INSERT INTO ". $mysql{'table'} ." (nick, address, chan, server, textinput) VALUES ('". $nick ."','". $address ."','". $target ."','". $server->{address} ."','". $msg ."')";
		mysql_query($sql);
	}
	return;
}

Irssi::signal_add("message public","message_public");
Irssi::signal_add("message private","message_private");
Irssi::signal_add("message own_public","message_own_public");
# Irssi::signal_add("message own_private","message_own_private");
Irssi::signal_add("message join","message_join");
Irssi::signal_add("message part","message_part");

#
# todo sub-routines...
#
# "message quit", SERVER_REC, char *nick, char *address, char *reason
# "message kick", SERVER_REC, char *channel, char *nick, char *kicker, char *address, char *reason
# "message nick", SERVER_REC, char *newnick, char *oldnick, char *address
# "message own_nick", SERVER_REC, char *newnick, char *oldnick, char *address
# "message invite", SERVER_REC, char *channel, char *nick, char *address
# "message topic", SERVER_REC, char *channel, char *topic, char *nick, char *address
#
