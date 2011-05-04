#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Data::Dumper;
use Reprof::Parser::Pssm;
use Reprof::Tools::Set;

my $file = shift;

my $parser = Reprof::Parser::Pssm->new($file);

#--------------------------------------------------
# say join ' ', @{$parser->get("pos")};
# say join ' ', @{$parser->get("res")};
# say join ' ', @{$parser->get("info")};
# say join ' ', @{$parser->get("weight")};
# 
# foreach my $field (@{$parser->get("raw_score")}) {
#     say join ' ', @$field;
# }
# foreach my $field (@{$parser->get("norm_score")}) {
#     say join ' ', @$field;
# }
# foreach my $field (@{$parser->get("pc_score")}) {
#     say join ' ', @$field;
# }
#-------------------------------------------------- 

#--------------------------------------------------
# my $result = $parser->get_fields("res", "raw_score", "pc_score");
# foreach my $i (@$result) {
#     say join " ", @$i;
# }
#-------------------------------------------------- 

my $descs = $parser->get_fields("pos");
my $feats = $parser->get_fields("loc");
my $outs = $parser->get_fields("res");

#say Dumper($feats);

my $set = Reprof::Tools::Set->new(3);
$set->add($descs, $feats, $outs) foreach (1 .. 10);

my $subset = $set->subset(5, 0 .. 2);

say Dumper($subset);

$set->reset_iter_original;

#--------------------------------------------------
# while (my $dp = $set->next_dp) {
#     #say Dumper($dp);
# }
#-------------------------------------------------- 


#--------------------------------------------------
# _file       => $file || warn "No file given to parser\n",
# _pos        => [],
# _res        => [],
# _raw_score  => [],
# _norm_score => [],
# _pc_score   => [],
# _info       => [],
# _weight     => [],
# _iter       => 0
#-------------------------------------------------- 
