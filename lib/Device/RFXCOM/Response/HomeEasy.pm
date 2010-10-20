use strict;
use warnings;
package Device::RFXCOM::Response::HomeEasy;

# ABSTRACT: Device::RFXCOM::Response class for Home Easy message from RFXCOM receiver

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Home Easy messages from an RFXCOM receiver.

=cut

use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_HOMEEASY_DEBUG};
use Carp qw/croak/;

=head2 C<new(%params)>

This constructor returns a new response object.

=cut

sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}

sub type { 'homeeasy' }
sub address { shift->{address} }
sub unit { shift->{unit} }
sub command { shift->{command} }
sub level { shift->{level} }

sub summary {
  my $self = shift;
  sprintf('%s/%s.%s/%s%s',
          $self->type,
          $self->address,$self->unit,
          $self->command,
          $self->level ? '['.$self->level.']' : '');
}

1;

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/
