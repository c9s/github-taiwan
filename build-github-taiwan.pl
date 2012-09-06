#!/usr/bin/env perl
use feature ":5.10";
use warnings;
use strict;
use LWP::Simple;
use HTTP::Request::Common;
use JSON::XS;
use List::MoreUtils qw(uniq);
use pQuery;

my @list =  qw(
        audreyt clkao c9s gugod hlb Dannvix mrmoneyc freehaha BlueT shelling
        gslin xdite CindyLinz RJKing dryman keitheis drbean bobchao matrixneo
        gdxhsw darkhero pct zx1986 toomore oobe monoceroi hcchien medicalwei
        aminzai acelan othree EragonJ penk cclien alicekey zonble PCMan
        billy3321 chihchun fourdollars hychen yurenju appleboy lukhnos clsung
        kanru handlino gaod yrchen ajneok jeffhung MLChen tsung ihower ericsk
        chiehwen itszero tsechingho hypo tzangms julian9 shepjeng dlackty deduce yllan
        kcliu timdream pixnet drakeguan lightlycat mose wmh spin
);

# my $c_w = {}; #decode_json(get('http://github.com/api/v3/json/repos/show/c9s/github-taiwan/subscribers'));
# my $c_n = {}; # decode_json(get('http://github.com/api/v3/json/repos/show/c9s/github-taiwan/forks'));
# push @list,((map { $_->{'owner'}  } @{ $c_n->{network} }), (@{ $c_w->{watchers} }));

{
    my @locations = qw(Taiwan Taipei Tainan Taichung Kaohsiung Hsinchu);
    my %users;
    my $max_pages = 6;
    $|++;
    for my $k ( @locations ) {
        print "searching $k\n";
        my $page = 1;
        while( $page && $page <= $max_pages ) {
            print "page $page: ";
            my $query_uri = "http://github.com/search?langOverride=&language=&q=location:$k&repo=&start_value=$page&type=Users";
            my $html = get( $query_uri );

            my $retry = 5 unless $html ;
            while( ! $html && $retry ) {
                sleep 1;
                print "." ;
                $html = get( $query_uri );
            }

            $page++;
            my $found_title;
            pQuery($html)->find( 'h2' )->each( sub {
                    my $i = shift;
                    my $class = $_->getAttribute('class');

                    $found_title = 1 if $class && $class =~ /title/;
                    return unless( $class );

                    my $ident = pQuery($_)->find('a')->text;
                    $users{ $ident } = 1 if $ident;
                    print $ident . " " if $ident;
            });
            $page = 0 unless $found_title;
            print "\n";
        }
    }
    push @list, keys %users;
}

@list = uniq sort @list;


my $ua = LWP::UserAgent->new;
$ua->default_header( Accept => 'application/vnd.github.full+json' );

my @result = ();
print "Found " . scalar(@list) . " developers\n";
print "Gathering information...\n";
for my $id ( @list ) {
    print $id , " ";
    my $data;
    my $response;
    eval {
        # curl -L https://api.github.com/users/c9s -H "Accept: application/vnd.github.full+json"
        $response = $ua->request( GET 'https://api.github.com/users/' . $id );
        my $retry = 5 unless $response;
        while( ! $response && $retry-- ) {
            sleep 5;
            print ".";
            $response = $ua->request( GET 'https://api.github.com/users/' . $id );
        }
        $data = decode_json( $response->decoded_content );
    };
    if ( $@ ) {
        warn "ERROR!  " . $id . "  :  " . $@;
        warn $response->decoded_content;
        next;
    }
    push @result , $data if $data;

=pod

{
  "following": 608,
  "type": "User",
  "blog": "http://c9s.me",
  "location": "Taipei, Taiwan",
  "gravatar_id": "7490b4e3e9cb85a1f7dc0c8ea01a86e5",
  "public_repos": 211,
  "hireable": true,
  "bio": "Perl, C, C++, JavaScript, PHP, Haskell, Ruby, HTML5",
  "login": "c9s",
  "avatar_url": "https://secure.gravatar.com/avatar/7490b4e3e9cb85a1f7dc0c8ea01a86e5?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png",
  "created_at": "2009-02-01T15:20:08Z",
  "company": "",
  "email": "cornelius.howl@gmail.com",
  "url": "https://api.github.com/users/c9s",
  "public_gists": 286,
  "followers": 344,
  "name": "Yo-An Lin",
  "html_url": "https://github.com/c9s",
  "id": 50894
}

=cut

}

say "DONE";

@result = sort { $b->{followers} <=> $a->{followers} } @result;

say "Writing JSON...";
open FH , ">" , "github-users.json";
print FH encode_json( \@result );
close FH;
say "Done";
