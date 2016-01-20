#!/usr/bin/perl
use DBI;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Encode;
use base qw(Bot::BasicBot);

package MyBot;
binmode (STDOUT, ":utf8");
my $driver   = "SQLite";
my $database = "IRC.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password,
	{
		RaiseError=>1,
		AutoCommit=>1,
		sqlite_unicode=>1
		
	}
);

my @statusCodes = ("Nyyppä", "Elvari-klubikandidaatti","Elvari-klubilainen", "Itse Elvari", "Yyber Elvari");
my $status;


sub said {
      
	our ($self, $message) = @_;
	our $boolean;
	
		if($message->{body} ne "" && $message =~ /([a-zA-Z0-9-_])\w+/ )
	{
		my $nick=$message->{who};

		
		my $nameQuery = qq(SELECT WHO FROM POSTAAJAT WHERE WHO = "$nick";);
		
		my $sth = $dbh -> prepare ($nameQuery);
		my $rv = $sth ->execute() or die $DBI::errstr;
		
		$boolean = $sth->fetchrow_array();
		
		if($boolean eq "")
		{
			my $stmt = qq(INSERT INTO POSTAAJAT (WHO, STATUS)
			VALUES ("$nick",  "$statusCodes[0]"));
			
			my $sth = $dbh -> prepare ($stmt);
			my $rv = $sth ->execute() or die $DBI::errstr;
	
		}
		else
		{
			my $postCountQuery = qq(SELECT POSTCOUNT FROM POSTAAJAT WHERE WHO = ?;);
		
			my $sth = $dbh -> prepare ($postCountQuery);
			my $rv = $sth ->execute($nick) or die $DBI::errstr;
			
			
			my $postCount = $sth->fetchrow_array();
			
			$postCount +=1;

			my $postCountUpdate = qq(UPDATE POSTAAJAT SET POSTCOUNT = "$postCount" WHERE WHO = ?;);
			

			$sth = $dbh -> prepare ($postCountUpdate);
			$rv = $sth ->execute($nick) or die $DBI::errstr;
		}
	}
	
	
	if($message->{body}=~m/!kek/)
	{
		my $split = $message->{body};
		my @values = split(' ', $split);
      
		my $nick = $values[1];
		
		my $query = qq(SELECT WHO, POSTCOUNT, SIGNATURE FROM POSTAAJAT WHERE WHO = ?;);
		
		
		my $sth = $dbh -> prepare ($query);
		my $rv = $sth->execute($nick) or die $DBI::errstr;
				

		my @row = $sth->fetchrow_array();
		
		if($row[0] eq "")
		{
			return "Postailijaa ei löytynyt:(";
		}
		
		my $count = $row[1];
		
		my $status ="";
		
		if ($count <=200)
		{
			$status = $statusCodes[0];
		} 
		elsif($count >200 && $count <=500)
		{
			$status= $statusCodes[1];
		}
		elsif($count >500 && $count <=600)
		{
			$status= $statusCodes[2];
		}
		elsif($count >600 && $count <=700)
		{
			$status= $statusCodes[3];
		}
		elsif($count >700)
		{
			$status= $statusCodes[4];
		}
		
		
		$self->say(
			channel =>"#yourchannelhere",
			body=>"Postaajan $row[0] postaukset: $row[1], status: $status, signature: $row[2]",
			
		);

	}
	
		if($message->{body}=~m/!signature/)
	{
		my $split = $message->{body};
		my @values = split(' ', $split);
      
		my $nick = $values[1];
		our $signature = $values[2];
		
		my $signCharCount = @{[$message =~ /(\.)/g]};;
				if($signCharCount > 20)
		{
			return "Liian pitkä sigu:( 20 merkkiä on maksimi";
		}
		
				my $query = qq(SELECT WHO FROM POSTAAJAT WHERE WHO = ?;);
		
		
		my $sth = $dbh -> prepare ($query);
		my $rv = $sth->execute($nick) or die $DBI::errstr;
		
		
		my @row = $sth->fetchrow_array();
		
		if($row[0] eq $nick && $row[0] eq $message->{who})
		{
			$query = qq(UPDATE POSTAAJAT SET SIGNATURE = ? WHERE WHO = ?;);
		
		
			$sth = $dbh -> prepare ($query);
			$rv = $sth->execute($signature, $nick) or die $DBI::errstr;
		}
		
		if($row[0] ne $nick && $row[0] ne $message->{who})
		{
			return "Ei saa asettaa toisten :(";
		}	}
}
      
      MyBot->new(
	server => 'yourserverhere',
	channels => [ '#yourchannelhere'],
	password=>'yourpasswordhere',
	nick => 'yournickhere',
)->run();