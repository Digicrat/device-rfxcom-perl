use strict;
use warnings;
package Device::RFXCOM::Base;

# ABSTRACT: module for RFXCOM device base class

=head1 SYNOPSIS

  ... abstract base class

=head1 DESCRIPTION

Module for RFXCOM device base class.

=cut

use 5.006;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_BASE_DEBUG},
  TESTING => $ENV{DEVICE_RFXCOM_TESTING},
};
use Carp qw/croak/;
use Fcntl;
use IO::Handle;
use IO::Select;
use Time::HiRes;

sub _new {
  my ($pkg, %p) = @_;
  my $self = bless
    {
     baud => 4800,
     port => 10001,
     discard_timeout => 0.03,
     ack_timeout => 2,
     dup_timeout => 0.5,
     _q => [],
     _buf => '',
     _last_read => 0,
     init_callback => undef,
     %p,
    }, $pkg;
  $self->{plugins} = [$self->plugins()] unless ($self->{plugins});
  $self->_open();
  $self->_init();
  $self;
}

sub DESTROY {
  my $self = shift;
  delete $self->{init};
}

=method C<queue()>

Returns the number of messages in the queue to be sent to the
device.

=cut

sub queue {
  scalar @{$_[0]->{_q}};
}


sub _write {
  my $self = shift;
  my %p = @_;
  $p{raw} = pack 'H*', $p{hex} unless (exists $p{raw});
  $p{hex} = unpack 'H*', $p{raw} unless (exists $p{hex});
  print STDERR "Queued: ", $p{hex}, ' ', ($p{desc}||''), "\n" if DEBUG;
  push @{$self->{_q}}, \%p;
  $self->_write_now unless ($self->{_waiting});
  1;
}

sub _write_now {
  my $self = shift;
  my $rec = shift @{$self->{_q}};
  my $wait_record = $self->{_waiting};
  if ($wait_record) {
    delete $self->{_waiting};
    my $cb = $wait_record->[1]->{callback};
    $cb->() if ($cb);
  }
  return unless (defined $rec);
  $self->_real_write($rec);
  $self->{_waiting} = [ $self->_time_now, $rec ];
}

sub _real_write {
  my ($self, $rec) = @_;
  print STDERR "Sending: ", $rec->{hex}, ' ', ($rec->{desc}||''), "\n" if DEBUG;
  syswrite $self->{fh}, $rec->{raw}, length $rec->{raw};
}

=method C<fh()>

This method returns the file handle for the device.

=cut

sub fh {
  shift->{fh}
}

sub _open {
  my $self = shift;
  $self->{device} =~ m!/! ?
    $self->_open_serial_port(@_) : $self->_open_tcp_port(@_)
}

sub _open_tcp_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as tcp socket\n" if DEBUG;
  require IO::Socket::INET; import IO::Socket::INET;
  $dev .= ':'.$self->{port} unless ($dev =~ /:/);
  my $fh = IO::Socket::INET->new($dev) or
    croak "TCP connect to '$dev' failed: $!";
  $self->{fh} = $fh;
  return 1;
}

sub _open_serial_port {
  my $self = shift;
  my $dev = $self->{device};
  print STDERR "Opening $dev as serial port\n" if DEBUG;
  require Device::SerialPort; import Device::SerialPort;
  my $ser =
    Device::SerialPort->new($dev) or
        croak "Failed to open '$dev' with Device::SerialPort: $!";
  $ser->baudrate($self->{baud});
  $ser->databits(8);
  $ser->parity('none');
  $ser->stopbits(1);
  $ser->write_settings;
  $ser->close;
  $self->{serialport} = $ser if TESTING; # keep mock object
  undef $ser;
  sysopen my $fh, $dev, O_RDWR|O_NOCTTY|O_NDELAY
    or croak "sysopen of '$dev' failed: $!";
  $fh->autoflush(1);
  binmode($fh);
  $self->{fh} = $fh;
  return 1;
}

sub _time_now {
  Time::HiRes::time
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
