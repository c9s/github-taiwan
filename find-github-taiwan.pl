use LWP::Simple;
use pQuery;
my @keywords = qw(Taiwan Taipei Tainan Taichung);
my %users;
$|++;
for my $k ( @keywords ) {
    print "searching $k\n";
    my $page = 1;
    while( $page ) {
        print "page: $page\n";
        my $html = get("http://github.com/search?langOverride=&language=&q=location:$k&repo=&start_value=$page&type=Users");
        $page++;
        my $found_title;
        pQuery($html)->find( 'h2' )->each( sub {
                my $i = shift;
                my $class = $_->getAttribute('class');

                $found_title = 1 if $class =~ /title/;
                return unless( $class );

                my $ident = pQuery($_)->find('a')->text;
                $users{ $ident } = 1 if $ident;
                print $ident . " " if $ident;
        });
        $page = 0 unless $found_title;
        print "\n";
    }
}

print "Summary:\n";
print 'Found:' . scalar( keys %users ) . "\n"; 
print join ',' , keys %users;
