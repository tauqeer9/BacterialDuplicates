#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
##############################################################################
##	Jose Fco. Sanchez Herrero, 25/09/2018 jfsanchezherrero@ub.edu			##
##############################################################################

my $duplicates_file = $ARGV[0];
my $protein_file = $ARGV[1];
my $output_name = $ARGV[2];

if (!@ARGV) {print "Usage:\nperl $0 duplicate_relations translated_cds output\n";exit();}

## get feature annotations
my ($annot_feature, $locus_tag_hash) = &get_feature($protein_file);

## get duplicate relations parsed from BLAST
my %better_relations;
open (IN, $duplicates_file);
while(<IN>) {
	chomp;
	my @items = split("\t", $_);
	my @subitems = split(",", $items[1]);
	for (my $i=0; $i < scalar @subitems; $i++) {
		$better_relations{$items[0]}{$subitems[$i]}++;
	}
}
close (IN);		
#print Dumper \%better_relations;

## possible: add get_feature_table for gtf/gff format files
my %new_annot = %{$annot_feature};
my %locus = %{$locus_tag_hash};

#print Dumper %new_annot;
#print Dumper %locus;
my $annotation_results = $output_name.".annotation_results.csv";          
open (ANNOT, ">$annotation_results");
print ANNOT "seq_id,locus_tag,origin,strand,start,end,gene,pseudo,prot_id,prot_name,annot\n";
foreach my $keys (keys %new_annot) {
	print ANNOT $new_annot{$keys}{"seq_id"}.",".$keys.",".$new_annot{$keys}{"origin"}.",".$new_annot{$keys}{"strand"}.",".$new_annot{$keys}{"start"}.",".$new_annot{$keys}{"end"}.",".$new_annot{$keys}{"gene"}.",". $new_annot{$keys}{"pseudo"}.",".$new_annot{$keys}{"prot_id"}.",\"".$new_annot{$keys}{"prot_name"}."\",\"".$new_annot{$keys}{"annot"}."\"\n";
	#print $keys.",".$new_annot{$keys}{""}.",".
}
close(ANNOT);

my $group=0; my (%annotation, %position, %group, %ids); my $count=0;
foreach my $keys (sort keys %better_relations) {

	my $locus_tag = $locus{$keys};
	$count++;
	
	#Protein1,symbol,name Prot1,Annotation,start,end,strand,Origin,pseudo
	my $string = $locus_tag.",".$new_annot{$locus_tag}{"prot_id"}.",";
	
	if ($new_annot{$locus_tag}{"gene"}) { $string .= $new_annot{$locus_tag}{"gene"}.","; } else { $string .=",";}
	
	$string .= $new_annot{$locus_tag}{"prot_name"}.",".$new_annot{$locus_tag}{"annot"}.",".$new_annot{$locus_tag}{"start"}.",".$new_annot{$locus_tag}{"end"}.",".$new_annot{$locus_tag}{"strand"}.",".$new_annot{$locus_tag}{"origin"}.",".$new_annot{$locus_tag}{"pseudo"};
	
	## save annotation for protein
	$annotation{$keys} = $string;
	#print $keys."\t".$string."\n";
	
	# save position
	if ($new_annot{$locus_tag}{"start"}) {
		if ($position{ $new_annot{$locus_tag}{"start"} }) {
			## already exists this position
		} else { $position{ $new_annot{$locus_tag}{"start"} } = $keys; }
	} else {print $keys."_ERROR\n";}
	
	## save group information
	push (@{ $group{"Group_".$count} },$keys);
	$ids{$keys} = "Group_".$count;	

		
	foreach my $subkeys (keys %{ $better_relations{$keys} } ) {
		my $locus_sub_tag = $locus{$subkeys};
		
		#Protein1,symbol,name Prot1,Annotation,start,end,strand,Origin,pseudo
		my $string_sub = $locus_sub_tag.",".$new_annot{$locus_sub_tag}{"prot_id"}.",";

		if ($new_annot{$locus_sub_tag}{"gene"}) { $string_sub .= $new_annot{$locus_sub_tag}{"gene"}.","; } else { $string_sub .= ",";}
		
		$string_sub .= $new_annot{$locus_sub_tag}{"prot_name"}.",".$new_annot{$locus_sub_tag}{"annot"}.",".$new_annot{$locus_sub_tag}{"start"}.",".$new_annot{$locus_sub_tag}{"end"}.",".$new_annot{$locus_sub_tag}{"strand"}.",".$new_annot{$locus_sub_tag}{"origin"}.",".$new_annot{$locus_sub_tag}{"pseudo"};
						
		## save annotation for protein
		$annotation{$subkeys} = $string_sub;
		
		#print $subkeys."\t".$string_sub."\n";

		# save position
		if ($new_annot{$locus_sub_tag}{"start"}) {
			if ($position{ $new_annot{$locus_sub_tag}{"start"} }) {
				## already exists this position
			} else { $position{ $new_annot{$locus_sub_tag}{"start"} } = $keys; }
		} else {
			print $subkeys."_ERROR\n";
		}

		## group information
		push ( @{ $group{"Group_".$count} } , $subkeys);
		$ids{$subkeys} = "Group_".$count;
}}
#print Dumper \%annotation; #print Dumper \%position; print Dumper \%ids; print Dumper \%group;
my @sort_array = sort {$a <=> $b} keys %position;
#print Dumper \%position; print Dumper \%annotation;

my $csv_results = $output_name.".results.csv"; 		open (CSV, ">$csv_results");
my $coordinates = $output_name.".coordinates.csv"; 	open (OUT, ">$coordinates");
print CSV "Group,ID-1,Locus_Tag,Protein1,symbol,name Prot1,Annotation,start,end,strand,Origin,pseudo,ID-2,Locus_tag,Protein2,symbol,name Prot2,Annotation,start,end,strand,Origin,pseudo\n";
my %done; my $set=1;
#print Dumper \%group;
my @all_seqs;
for (my $i=0; $i < scalar @sort_array; $i++) {
	my $ident = $position{ $sort_array[$i] };
	if ($done{ $ids{$ident} } ) { next; } else {	
		#CSV 
		print CSV $set.",".$ident.",".$annotation{$ident}."\n";
		my @array = split(",", $annotation{$ident});
		print OUT $set.",".$array[8].",".$array[5].",".$array[6].",".$locus{$ident}.",".$array[3].",".$array[7]."\n";
			# $array[4]: START
			# $array[5]: END
			# $array[6]: STRAND
			# $array[7]: LOCATION
		push (@all_seqs, $ident);
		my @group = @{ $group{$ids{$ident} } };
		$done{$ids{$ident}}++;
		
		for (my $j=0; $j < scalar @group; $j++) {
			my $id = $group[$j];		
			if ($id eq $ident) {next;} else {
		                push (@all_seqs, $id);
				#CSV
				print CSV $set.",,,,,,,,,,,".$id.",".$annotation{$id}."\n";
				# OUT	
				my @array2 = split(",", $annotation{$id});
				print OUT $set.",".$array2[8].",".$array2[5].",".$array2[6].",".$locus{$id}.",".$array2[3].",".$array2[7]."\n";
		}}
		$set++;
}}

my $allseqs = $output_name.".allseqs_duplicated.ids.txt";
open (ALL, ">$allseqs");
for(my $i=0; $i<scalar @all_seqs; $i++){
	print ALL $all_seqs[$i]."\n";
}
close(ALL);

sub get_feature {

	my $file = $_[0];
	my %hash;
	open(FILE, $file) || die "Could not open the file $file\n";
	$/ = ">"; ## Telling perl where a new line starts
	while (<FILE>) {		
		#next if /^#/ || /^\s*$/;
		chomp;
    	my ($titleline, $sequence) = split(/\n/,$_,2);
    	next unless ($sequence && $titleline);
    	chop $sequence;
    	my @split = split("\\[", $titleline);
    	my $ident = $split[0]; chop $ident;
    	$hash{$ident} = join("\t",@split);
	}
	close(FILE); 
	$/ = "\n";

	my %new_annot;
	my %locus;
	foreach my $keys (keys %hash) {
		my $locus_tag;
		my @array = split("\t",$hash{$keys});
		for (my $i=0; $i < scalar @array; $i++) {
			my $id = $array[$i];
			if ($id =~ /locus_tag=(.*)\]/) {
				$locus_tag = $1;
				$new_annot{$locus_tag}{"id"} = $keys;
				$locus{$keys} = $locus_tag;

		}}
		
		## init all
		$new_annot{$locus_tag}{"pseudo"} = "false";
		$new_annot{$locus_tag}{"origin"} = "n.a";
		$new_annot{$locus_tag}{"start"} = "n.a";
		$new_annot{$locus_tag}{"end"} = "n.a";
		$new_annot{$locus_tag}{"strand"} = "n.a";
		$new_annot{$locus_tag}{"annot"} = "n.a";
		$new_annot{$locus_tag}{"prot_name"} = "n.a";
		$new_annot{$locus_tag}{"prot_id"} = "n.a";
		$new_annot{$locus_tag}{"gene"} = "n.a";	

		### seq id
		$new_annot{$locus_tag}{"seq_id"} = $array[0];	
		
		## set origin
		my @sequence_id = split("_prot_", $array[0]);
		my @seq_id = split("lcl\\_", $sequence_id[0]);
		$new_annot{$locus_tag}{"origin"} = $seq_id[1];

		for (my $i=0; $i < scalar @array; $i++) {
			my $id = $array[$i];
			if ($id =~ /db_xref=(.*)\]/) {
				my $temp = $1;
				$temp =~ s/,/;/g;
				$new_annot{$locus_tag}{"annot"} = $temp;

			} elsif ($id =~ /protein=(.*)\]/) {
				my $temp = $1;
				$temp =~ s/,/;/g;
				$new_annot{$locus_tag}{"prot_name"} = $temp;

			} elsif ($id =~ /pseudo=(.*)\]/) {
                                my $temp = $1;
				if ($temp eq "true") {
	                                $new_annot{$locus_tag}{"pseudo"} = "true";                                 
				}
			#$new_annot{$locus_tag}{"pseudo"} = "false";
                              
			} elsif ($id =~ /protein_id=(.*)\]/) {
				$new_annot{$locus_tag}{"prot_id"} = $1;

			} elsif ($id =~ /gene=(.*)\]/) {
				$new_annot{$locus_tag}{"gene"} = $1;

			} elsif ($id =~ /location=(.*)\]/) {		
				my $locat = $1;
				my $location;			
				if ($locat=~ /join\((.*)\)/) {
					$location = $1;
					if ($locat=~ /complement\((.*)\)/) {
						$new_annot{$locus_tag}{"strand"} = "-";
					} else {
						$new_annot{$locus_tag}{"strand"} = "+";
					}
				} else {
					if ($locat=~ /complement\((.*)\)/) {
						$location = $1;
						$new_annot{$locus_tag}{"strand"} = "-";
					} else {
						$location = $locat;
						$new_annot{$locus_tag}{"strand"} = "+";
					}
				}
				$location =~ s/\../,/g;
				my @position = split(",",$location);
				$new_annot{$locus_tag}{"start"} = $position[0];
				$new_annot{$locus_tag}{"end"} = $position[-1];

			}
		}
	}

	my $hashRef = \%new_annot;
	my $hash_locus = \%locus;
	return ($hashRef, $hash_locus);
}

sub get_feature_TABLE {
	## get information from table, gff/gtf file
}

__END__

	my $id = $_[0];
	my $output = $output_name.".results.tmp";

    system("grep -w $id $gff_file > $output");
    open (TMP, "<$output");
    my $tmp = <TMP>;
    close (TMP);
    my @array = split("\t", $tmp);
    my @array_split = split("\;",$array[8]);
	my $substi = $array_split[2]; $substi =~ s/,/;/g;
	 
    system("grep -w $id $feature_table > $output");
    open (TMP1, "<$output");
    my $tmp_out = <TMP1>;
    close (TMP1);
    my @array_tmp = split("\,", $tmp_out);
	
	my @return_a = ($array_tmp[16],$array_tmp[14],$array_tmp[13],$substi,$array_tmp[7], $array_tmp[8], $array_tmp[9], $array_tmp[4]);
    return \@return_a;
}


