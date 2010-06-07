package Text::Xslate::PP::Method;
# xs/xslate-methods.xs in pure Perl
use strict;
use warnings;

use Text::Xslate::PP::Opcode qw(tx_error tx_warn);

use Text::Xslate::PP::Type::Pair;

use Scalar::Util ();
use Carp         ();

our @CARP_NOT = qw(Text::Xslate::PP::Opcode);

sub _bad_arg {
    Carp::carp("Wrong number of arguments for @_");
    return undef;
}

sub _array_size {
    my($array_ref) = @_;
    return _bad_arg('size') if @_ != 1;
    return scalar @{$array_ref};
}

sub _array_join {
    my($array_ref, $sep) = @_;
    return _bad_arg('join') if @_ != 2;
    return join $sep, @{$array_ref};
}

sub _array_reverse {
    my($array_ref) = @_;
    return _bad_arg('reverse') if @_ != 1;
    return [ reverse @{$array_ref} ];
}

sub _array_sort {
    my($array_ref) = @_;
    return _bad_arg('sort') if @_ != 1;
    return [ sort @{$array_ref} ];
}

sub _hash_size {
    my($hash_ref) = @_;
    return _bad_arg('size') if @_ != 1;
    return scalar keys %{$hash_ref};
}

sub _hash_keys {
    my($hash_ref) = @_;
    return _bad_arg('keys') if @_ != 1;
    return [sort { $a cmp $b } keys %{$hash_ref}];
}

sub _hash_values {
    my($hash_ref) = @_;
    return _bad_arg('values') if @_ != 1;
    return [map { $hash_ref->{$_} } @{ _hash_keys($hash_ref) } ];
}

sub _hash_kv {
    my($hash_ref) = @_;
    _bad_arg('kv') if @_ != 1;
    return [
        map { Text::Xslate::PP::Type::Pair->new(key => $_, value => $hash_ref->{$_}) }
        @{ _hash_keys($hash_ref) }
    ];
}

my %builtin_method = (
    'array::size'    => \&_array_size,
    'array::join'    => \&_array_join,
    'array::reverse' => \&_array_reverse,
    'array::sort'    => \&_array_sort,

    'hash::size'     => \&_hash_size,
    'hash::keys'     => \&_hash_keys,
    'hash::values'   => \&_hash_values,
    'hash::kv'       => \&_hash_kv,
);

sub tx_methodcall {
    my($st, $method) = @_;
    my($invocant, @args) = @{ pop @{ $st->{ SP } } };

    if(Scalar::Util::blessed($invocant)) {
        if($invocant->can($method)) {
            my $retval = eval { $invocant->$method(@args) };
            if($@) {
                tx_error($st, "%s", $@);
            }
            return $retval;
        }
        tx_error($st, "Undefined method %s called for %s",
            $method, $invocant);
    }

    if(!defined $invocant) {
        tx_warn($st, "Use of nil to invoke method %s", $method);
        return undef;
    }

    my $type = ref($invocant) eq 'ARRAY' ? 'array'
             : ref($invocant) eq 'HASH'  ? 'hash'
             :                             'scalar';
    my $fq_name = $type . "::" . $method;

    if(my $body = $st->function->{$fq_name} || $builtin_method{$fq_name}){
        my $retval = eval { $body->($invocant, @args) };
        if($@) {
            tx_error($st, "%s", $@);
        }
        return $retval;
    }
    tx_error($st, "Undefined method %s called for %s",
        $method, $invocant);

    return undef;
}

1;
__END__

=head1 NAME

Text::Xslate::PP::Method - Text::Xslate builtin method call in pure Perl

=head1 DESCRIPTION

This module is used by Text::Xslate::PP internally.

=head1 SEE ALSO

L<Text::Xslate>

L<Text::Xslate::PP>

=cut
