#!/usr/bin/perl
use IO::Socket::UNIX;
use IO::Socket::INET;
use JSON;
use Getopt::Long;
use Curses::UI;

my $mode = 'stats';
my $addr = undef;
my $freq = 3;

GetOptions( 'mode=s' => \$mode, 'addr=s' => \$addr, 'freq=i' => \$freq ) || die;

die "you need to specify an address" unless $addr;

my $sock = undef;

if ( $mode eq 'udp' ) {
    $sock = IO::Socket::INET->new(
        LocalAddr => $addr,
        ReusePort => 1,
        Blocking  => 0,
        Proto     => 'udp'
    );
    die unless $sock;
}

sub exit_dialog() { exit(0); }

my $cui = Curses::UI->new( -color_support => 1 );

my $win = $cui->add(
    'win1', 'Window',
    -border => 1,
    -y      => 0,
    -bfg    => 'green',
);

my @metrics;
my $bar_y = 0;
foreach (@ARGV) {
    my ( $key, $max, $threshold ) = split /:/;
    $max = 100 unless $max;
    my $progress = $win->add(
        $key, 'Progressbar',
        -max          => $max,
        -pos          => 0,
        -y            => $bar_y,
        -color        => 'red',
        -nopercentage => 1,
        -nocenterline => 1,
        -border       => 1,
        -showvalue    => 1,
        -title        => $key,
    );
    push @metrics,
      { 'metric' => $key, 'bar' => $progress, 'threshold' => $threshold };
    $progress->draw;
    $bar_y += 3;
}

my $messages;

sub parse_message {
    my ( $key, $type, $value ) = @_;

    # not gauge ?
    # for absolute values we need at least 2 values for having the delta
    if ( $type ne '1' ) {
        my $old_value = 0;
        if ( exists( $messages->{$key} ) ) {
            $old_value = $messages->{$key}->{absolute};
            $messages->{$key}->{absolute} = $value;
        }
        else {
            $messages->{$key} = { 'absolute' => $value };
	    return;
        }

        if ( $messages->{$key}->{absolute} > $old_value ) {
            $messages->{$key}->{'value'} =
              $messages->{$key}->{absolute} - $old_value;
        }
        else {
            $messages->{$key}->{'value'} = 0;
        }
    }
    else {
        $messages->{$key} = { absolute => $value, value => $value };
    }
}

sub update_bars {

    # get messages from udp
    if ($sock) {
        while (1) {
            $sock->recv( my $msg, 4096 );
            last unless $msg;
            my ( $key, $type, $value ) = split /\s+/, $msg;

            # skip aliases
            next if $type eq '3';
            parse_message( $key, $type, $value );
        }
    }
    else {
        my $client = undef;
        if ( $addr =~ /:/ ) {
            $client =
              IO::Socket::INET->new( PeerAddr => $addr, Proto => 'tcp' );
        }
        else {
            $client = IO::Socket::UNIX->new( Peer => $addr );
        }
        return unless $client;

        my $json = '';
        while (1) {
            $client->recv( my $buf, 4096 );
            last unless $buf;
            $json .= $buf;
        }

        $client->close;

        my $j = decode_json($json);

        foreach(keys(%{$j->{metrics}})) {
		# skip aliases
		next if $j->{metrics}->{$_}->{type} eq '3';
		parse_message( $_, $j->{metrics}->{$_}->{type}, $j->{metrics}->{$_}->{value} );	
	}
    }

    foreach (@metrics) {
        my $m = $_->{metric};
        if ( exists( $messages->{$m} ) ) {
            $_->{'bar'}->set_color_fg('white');
            if (   $_->{threshold} > 0
                && $messages->{$m}->{value} >= $_->{threshold} )
            {
                $_->{'bar'}->set_color_fg('red');
            }
            $_->{'bar'}->pos( $messages->{$m}->{value} );
        }
    }
}

$cui->set_binding( \&exit_dialog, "q" );
$cui->set_timer( 'update_bars', \&update_bars, $freq );

$cui->mainloop;
