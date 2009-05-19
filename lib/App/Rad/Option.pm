package App::Rad::Option;
use strict;
use warnings;

sub new {
   my $class = shift;
   my $name  = shift;
   my %pars  = %{ shift() };

   my $self = bless {
                     error_message => "ERROR",
                     required      => 0      ,
                    }, $class;

   $self->{name} = $name;

   $self->{types} = {
                       "int"     => "=i",
                       "float"   => "=f",
                       "str"     => "=s",
                       "bool"    => "!" ,
                       "counter" => "+",
                    };
   $self->{post_test} = {
                           "int"     => q(^-?\d+$)      ,
                           "float"   => q(^-?\d*\.?\d+$),
                           "str"     => q(^.*$)         ,
                           "bool"    => q(^[01]$)       ,
                           "counter" => q(^\d+$)        ,
                        };

   $self->set_type           ($pars{type})            if exists $pars{type};
   $self->set_conflicts_with ($pars{conflicts_with})  if exists $pars{conflicts_with};
   $self->set_argument       ($pars{argument})        if exists $pars{argument};
   $self->set_condition      ($pars{condition})       if exists $pars{condition};
   $self->set_help           ($pars{help})            if exists $pars{help};
   $self->set_aliases        ($pars{aliases})         if exists $pars{aliases};
   $self->set_to_stash       ($pars{to_stash})        if exists $pars{to_stash};
   $self->set_required       ($pars{required})        if exists $pars{required};
   $self->set_separator      ($pars{separator})       if exists $pars{separator};
   $self->set_default        ($pars{default})         if exists $pars{default};
   $self->set_error_message  ($pars{error_message})   if exists $pars{error_message};

   $self;
}

sub get_name {
   my $self = shift;
   $self->{name};
}

sub get_conflicts {
   my $self = shift;
   @{ $self->{conflicts} }
}

sub get_opt_str {
	my $self = shift;
	my $type = $self->{type};
	$type = "str" if exists $self->{separator};
	if(exists $self->{aliases} and ref $self->{aliases} eq "ARRAY") {
		return join("|", $self->{name}, @{$self->{aliases}})
		     . (defined $type 
		        and exists $self->{types}->{$type}
				and $self->{types}->{$type} 
		        ? $self->{types}->{$type} 
				: ""
		      );
	else {
		return $self->{name}
		     . (defined $type
		        and exists $self->{types}->{$type}
		        and $self->{types}->{$type} 
		        ? $self->{types}->{$type} 
		        : ""
			);
	}
}


sub order {
   my $self = shift;

   my $order;
   $order += 9 if exists $self->{argument};
   $order += 3 if not $self->required;
   my $pl = $1 if $self->{name} =~ /^(\w)/;
   sprintf "%02d%03d", $order, ord $pl
}

sub usage {
   my $self = shift;

   my $ret;
   $ret = "--" unless exists $self->{argument};
   if($self->{type} eq "bool" or $self->{type} eq "counter"){
      $ret .= $self->{name};
   } elsif(exists $self->{argument}){
      if(exists $self->{separator}){
         $ret = sprintf "%s[%s%s]", uc $self->{name}, $self->{separator}, uc $self->{name};
      } else {
         $ret = uc $self->{name};
      }
   } else {
      $ret .= $self->{name} . "=" . uc(exists $self->{type} ? $self->{type} : $self->{name});
      $ret .= sprintf "[%s%s]", $self->{separator}, uc $self->{type} if exists $self->{separator};
   }
   unless($self->required){
      $ret = sprintf "[%s]", $ret;
   }
   $ret;
}

sub help {
   my $self = shift;
   my $len  = shift || 20;

   sprintf "    %-*s\t%s", $len, $self->{name}, $self->{help}
}

sub post_get {
   my $self       = shift;
   my $pre_result = shift;
   my $result = $self->{default};
   $result = $pre_result if defined $pre_result;
   $self->{result} = $result;
   if(not defined $pre_result){
      $self->_die if $self->required;
      return;
   }
   if(exists $self->{separator}){
      $self->{result} = $result = [split $self->{separator}, $result];
   }
   my $post_test = $self->{post_test}->{$self->{type}};
   $self->_die if scalar grep {not m/$post_test/} ref $result eq "ARRAY" ? @$result : $result;
   if(exists $self->{condition}){
      $self->_die if scalar grep {not $self->{condition}->()} ref $result eq "ARRAY" ? @$result : $result;
   }
   $result;
}

sub _die {
   my $self = shift;
   die $self->{name}, ": ", $self->{error_message}, $/;
}

sub argument {
   my $self = shift;
   return unless defined $self->{argument};
   $self->{argument};
}

sub to_stash {
   my $self = shift;
   $self->{to_stash}
}

sub required {
   my $self = shift;
   exists $self->{required} and $self->{required};
}

sub set_type {
   my $self = shift;
   my $type = shift;

   $self->{type} = "$type";
}

sub set_conflicts_with {
   my $self      = shift;
   my $conflicts = shift;

   $self->{conflicts} = [ref $conflicts eq "ARRAY" ? @$conflicts : $conflicts];
}

sub set_argument {
   my $self     = shift;
   my $argument = shift;

   if(ref $argument eq "ARRAY"){
      $self->{argument} = [map {$_ - 1} @$argument];
   } else {
      $self->{argument} = $argument - 1;
   }
}

sub set_condition {
    my $self      = shift;
    my $condition = shift;

    die "'condition' must be a CODEREF" unless ref $condition eq "CODE";
    $self->{condition} = $condition;
}

sub set_help {
   my $self = shift;
   my $help = shift;
   $self->{help} = $help;
}

sub set_aliases {
   my $self    = shift;
   my $aliases = shift;
   $self->{aliases} = $aliases;
}

sub set_to_stash {
   my $self     = shift;
   my $to_stash = shift;
   if($to_stash){
      $self->{to_stash} = int($to_stash) ? $self->{name} : $to_stash;
   }
}

sub set_required {
   my $self     = shift;
   my $required = shift;
   $self->{required} = $required;
}

sub set_separator {
   my $self      = shift;
   my $separator = shift;
   $self->{separator} = $separator;
}

sub get_default {
   my $self    = shift;
   $self->{default};
}

sub set_default {
   my $self    = shift;
   my $default = shift;
   $self->{default} = $default;
}

sub set_error_message {
   my $self          = shift;
   my $error_message = shift;
   $self->{error_message} = $error_message;
}

42
