my $ADDR = $ARGV[0] or "localhost";;
my $PORT = $ARGV[1] or 7000;
my $INTERVAL = 1;

use IO::Socket;
use IO::Select;

my $sel = IO::Select->new();
$sel->add(\*STDIN);

$| = 1;

while (1) {
  my $sock = undef;

  print "connecting to $ADDR:$PORT ";

  while (not $sock) {
    print ".";
    $sock = IO::Socket::INET->new(PeerAddr => $ADDR,
				  PeerPort => $PORT,
				  Proto    => 'tcp',
				  Blocking => 1);
    sleep($INTERVAL) if not $sock;
  }

  print " connected [$sock]\n";


  $sel->add($sock);

  read_loop: while (@handles = $sel->can_read()) {
    foreach my $handle (@handles) {
      my $data;
      sysread($handle, $data, 1024);
      chomp $data;
      if ($handle == $sock) {
	if (not $data) {
	  print "server closed connection\n";
	  $sel->remove($sock);
	  undef $sock;
	  last read_loop;
	}
	$data =~ s/\0/\n/g;
	chomp($data);
	my @lines = split(/\n/, $data);
	print join("\n", map {"<: " . $_} @lines) . "\n"
      } else {
	print ">: $data\n";
	syswrite($sock, $data . "\0");
      }
    }
  }

}
