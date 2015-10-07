#este archivo toma un ns.conf y extrae los balanceos de carga para poder construir las
# tablas que hacen parte de la documentación. Las tablas resultantes estan en formato HTML.

use strict;
use warnings;
use Data::Dumper;


#input the config line, return a hash that the keys are the -someting in the config line
sub extract_params{
		my $line = $_[0];
		my %params;
        my @params_temp = split('-',$line);
        my @arr;
        #print "+++++++++ Dump split en - arreglo:\n".Dumper(@params_temp)."\n+++++++++++++arreglo fin -------- \n";
	for my $elem (@params_temp){
		@arr = split(/ /, $elem);
  		$params{$arr[0]} = $arr[1];
  		#print "\n Key ".$arr[0]." Value ".$arr[1]."\n";
  		#print "==========Dump sub split en ' ':\n".Dumper(@arr)."\n ========= arreglo fin --------------- \n";
  	}
  	
  	return %params;
}


my $file = $ARGV[0];
if($file !~ /conf/){
die "Not a valid argumet\n";
}

my %td = ();
my $has_td = 0;
my %ips = ();
my %server = ();
my %service = ();
my %vserver = ();
my %bindings = ();
my %cs_vserver = ();
my %cs_pols = ();
my %cs_bindings = ();
my %cs_bindings_target = ();
my %cs_bindings_all = ();

my %ldapPolicy = ();
my %ldapAction = ();
my %vpn_vserver = ();
my %vpn_pol_bindings = ();
my %vpn_sta_bindings = ();

my $out;
open($out, ">" ,"conf.html") or die "Cloud not open output file\n";





print $out "<html><head><h2>Currently only LB config is displayed in html table format<h2></head><body>";
print $out "<h3>Pase in work using the \"Paste Specil...\" and then Unformated Text.<h3>";
#first pass to detect servers
#print "IP list:\n";
open my $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>IP</td><td>Mask</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add ns ip/){
    	my @values = split(' ',$line);
    	$ips{ $values[3] } = $line; #3 es IP, 4 es netmask y 5 en aldelante son parms
        #print $values[3]."\n";
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>".$values[4]."</td><tr>\n";
        }
}
print $out "</table><br><br>\n";
close $info;

#print "Traffic Domains:\n";
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Traffic Domain</td><td>Alias</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add ns trafficDomain/){
    	my @values = split(' ',$line);
    	$td{ $values[3] } = $line; #3 es id, 5 es alias
        #print "ID: ".$values[3]." Alias: ".$values[5]."\n";
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>".$values[5]."</td><tr>\n";
        $has_td = 1;
    }
}
print $out "</table><br><br>\n";
close $info;


open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Node ID</td><td>IP</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add HA node/){
    	my @values = split(' ',$line);
        #print "HA Node ".$values[4]."\n";
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>".$values[4]."</td><tr>\n";
        }
}
print $out "</table><br><br>\n";
close $info;


open $info, $file or die "Could not open $file: $!";
#first pass to detect servers
#print "Server list:\n";
print $out "<table border=0pt><tr><td>Server Name</td><td>IP</td>";
if($has_td==1){
print $out "<td>TD</td>";
}
print $out "</tr>";
while( my $line = <$info>)  {   
   
    if($line =~ /add server/){
    	my @values = split(' ',$line);
    	$server{ $values[2] } = $line;
        #print $values[2]."\n";
        print $out "<tr><td>".$values[2]."</td>";
        print $out "<td>".$values[3]."</td>";
        if($has_td==1)
        {
        print $out "<td>".$values[5]."</td>";
        }
        print $out "<tr>";
        }
}
print $out "</table><br><br>\n";
close $info;
open $info, $file or die "Could not open $file: $!";

#print "Service List:\n";
print $out "<table border=1pt><tr><td>Service Name</td><td>Server</td><td>Port</td><td>Protocol</td>";
if($has_td==1){
print $out "<td>TD</td>";
}
print $out "</tr>";
while( my $line = <$info>)  {   
   
    if($line =~ /add service/){
    	my @values = split(' ',$line);
    	my %svc_params = extract_params($line);
    	$service{ $values[2] } = $line;
        #print $values[2]."\n";
        print $out "<tr><td>".$values[2]."</td>";
        print $out "<td>".$values[3]."</td>";
        #"<td>".$values[4]."</td>"; this is the type of service
        print $out "<td>".$values[5]."</td><td>".$values[4]."</td>";
        if($has_td==1){
			print $out "<td>".$svc_params{"td"}."</td>";
		}
        print $out "</tr>\n";
        }
}
print $out "</table><br><br>\n";


close $info;
open $info, $file or die "Could not open $file: $!";


#print "Bindings for Virtual Server - Services:\n";
#first pass to detect services bound to virtual servers 
while( my $line = <$info>)  {   
   
    if($line =~ /bind lb vserver/){
        my @values = split(' ',$line);
        if(exists $bindings{$values[3]}){
        	my @svcs = @{$bindings{$values[3]}};
        	push @svcs,$values[4];
    		$bindings{$values[3]} = \@svcs;
    	}else{
    		my @svcs;
    		push @svcs,$values[4];
    		$bindings{$values[3]} = \@svcs;
    	}
        #print $values[3]." - ".$values[4]."\n";
    }
    
}

print $out "<table border=1pt><tr><td>Virtual Server Name</td><td>Service Name</td></tr>\n";
#print "VS services bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
for (keys %bindings){
     #print " Key:  ".$_." \n";
     my @value = @{$bindings{$_}};
     #print "=====\n".Dumper(@value)."======\n";
     print $out "<tr><td rowspan=".scalar @value.">".$_."</td>"; 
     for my $i (0 .. $#value){
     #for my $val (@value){
     	#print "      Val en i ".$i.": ".$value[$i]."\n";
     	if($i==0){ 
     	#print "      Val en i ".$i.": ".$value[$i]."\n";
     	#print "<tr>"; 
     	}else{
     		#print "      Val en i ".$i.": ".$value[$i]."\n";
     	}
     	print $out "<td>".$value[$i]."</td></tr>";
     }
}
print $out "</table><br><br>\n";
close $info;
open $info, $file or die "Could not open $file: $!";

#print "Virtual Server List:\n";
print $out "<b>Virtual Server List:</b></p><table border=1pt>
<tr><td>Virtual Server Name</td><td>Category</td><td>Value</td></tr>\n";
#first pass to detect virtual servers
while( my $line = <$info>)  {   
   
    if($line =~ /add lb vserver/){
    	#print "START ".$line."\n";
        my @values = split(' ',$line);
        my %params = extract_params($line);
    	$vserver{ $values[3] } = $line;
    	my @services = (); 
    	my $count_services = 0;
    	if(exists $bindings{$values[3]}){   	
    		$count_services = scalar @{$bindings{$values[3]}}."\n";
    	}
    	#print "VS: ".$values[3]." #servicios ".$count_services."\n";
    	if($count_services>0){
    	   	@services =  @{$bindings{$values[3]}};
    	}
    	else{
    		#print "VS: ".$values[3]." NO TIENE SERVICIOS\n";
    	}
    	for(my $y=0;$y<$count_services;$y++){
    		#print "VServer: ".$values[3]." Servicios: ".$y." bind: ".@services[$y]."\n";
    	}

    	#print "Dump arr".Dumper(@services)."\n";
		
    	#print "==============\n".Dumper(@services)."\n+++++++\n";
        #print $values[3]."\n";
        ##### determine how many lines will be printed#######
        my $rowspan = 5;
        #print "RowSpan para ".$values[3]." inicia en ".$rowspan."' 1 es Tipo, 2 es IP, 3 es puerto \n";
        if(exists $params{"cltTimeout"})
    	{ 
    	$rowspan++;
    	#print "1 cltTimeout RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
        if(exists $params{"timeout"})
    	{ 
    	$rowspan++;
    	#print "2 timeout RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
    	if(exists $params{"lbmethod"})
    	{ 
    	$rowspan++;
    	#print "3 lbmethod RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
    	if(exists $params{"td"})
    	{ 
    	$rowspan++;
    	#print "4 td RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
    	if(exists $params{"backupVServer"})
    	{ 
    	$rowspan++;
    	#print "5 backupVServer RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
    	if(exists $params{"persistenceType"})
    	{ 
    	$rowspan++;
    	#print "6 persistenceType RowSpan para ".$values[3]." es de ".$rowspan."\n";
    	}
        #####################################################
        #print "7 Se va a incrementar RowSpan de ".$values[3]." en ".scalar @services."\n";
        $rowspan += scalar @services;
        #print "RowSpan para ".$values[3]." es de ".$rowspan."\n";
        print $out "<tr><td rowspan=".$rowspan.">".$values[3]."</td><td>Tipo</td><td>".$values[4]."</td></tr>\n";
        print $out "<tr><td>IP</td><td>".$values[5]."</td></tr>\n";
        print $out "<tr><td>Puerto</td><td>".$values[6]."</td></tr>\n";
    	############## Add aditional lines if you need more rows with information, 
    	############## params is a hash that uses the key as the -param i.e. -persistenceType without the '-' 
    	if(exists $params{"persistenceType"})
    	{ 
    		print $out "<tr><td>persistenceType</td><td>".$params{"persistenceType"}."</td></tr>\n";
    	}
    	if(exists $params{"timeout"})
    	{ 
    	 	print $out "<tr><td>Persistence Timeout</td><td>".$params{"timeout"}."</td></tr>\n";
    	 }else{
    	 	print $out "<tr><td>Persistence Timeout</td><td>UNDEF</td></tr>\n";
    	 }
    	if(exists $params{"lbmethod"})
    	{ 
    		print $out "<tr><td>Loadbalance Method</td><td>".$params{"lbmethod"}."</td></tr>\n";
    	}else{
    		print $out "<tr><td>Loadbalance Method</td><td>ROUNDROBIN</td></tr>\n";
    	}
    	if(exists $params{"td"})
    	{   		
    		print $out "<tr><td>Traffic Domain</td><td>".$params{"td"}."</td></tr>\n";
    	}
    	if(exists $params{"cltTimeout"})
    	{   		
    		print $out "<tr><td>Client Timeout</td><td>".$params{"cltTimeout"}."</td></tr>\n";
    	}
    	if(exists $params{"backupVServer"})
    	{   		
    		print $out "<tr><td>Back Up VServer</td><td>".$params{"backupVServer"}."</td></tr>\n";
    	}
    	
    	
    	#print "\n++++++++++\n".Dumper(@services)."\n==========\n";
    	for my $i (0 .. @services-1){
    		#print "iteracion: ".$i." VS: ".$values[3]." Services: ".@services[$i]."\n";
    		if ($i==0){ 
    			print $out "<tr><td rowspan=".scalar @services.">Services</td><td>".$services[$i]."</td></tr>\n";
    		}else{
    			print $out "<tr><td>".$services[$i]."</td></tr>\n";	
    		}
    	}
    	#print "END\n";
    }
}
print $out "</table><br><br>\n";

#diffrent format for word paste
close $info;
open $info, $file or die "Could not open $file: $!";

print "Virtual Server List:\n";
print $out "The following is the Easy copy paste version, create an empty table in word using the sizes provided.";
print $out "Easy copy paste version of VS list:<br><table border=1pt><tr><td>erase me</td><td>Virtual Server Name</td><td>Category</td><td>Value</td><td>Justificacion</td></tr>\n";
#first pass to detect virtual servers
my $counter = 0;
while( my $line = <$info>)  {   
   
    if($line =~ /add lb vserver/){
        my @values = split(' ',$line);
        my %params = extract_params($line);
    	$vserver{ $values[3] } = $line;
    	my @services = (); 
    	my $count_services = 0;
    	if(exists $bindings{$values[3]}){   	
    		$count_services = scalar @{$bindings{$values[3]}}."\n";
    	}
    	#print "VS: ".$values[3]." #servicios ".$count_services."\n";
    	if($count_services>0){
    	   	@services =  @{$bindings{$values[3]}};
    	}
    	else{
    		print "VS: ".$values[3]." NO TIENE SERVICIOS\n";
    	}
    	#print "Dump arr".Dumper(@services)."\n";

    	#print "==============\n".Dumper(@services)."\n+++++++\n";
        print $values[3]."\n";
        my $rowspan = 6;
        if(exists $params{"td"}){$rowspan++;}
        $rowspan +=scalar @services;
        print $out "<tr><td>".$counter++."</td><td>".$values[3]."</td><td>Tipo</td><td>".$values[4]."</td><td>XX</td></tr>\n";
        print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>IP</td><td>".$values[5]."</td><td>XX</td></tr>\n";
        print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Puerto</td><td>".$values[6]."</td><td>XX</td></tr>\n";
    	############## Add aditional lines if you need more rows with information, 
    	############## params is a hash that uses the key as the -param i.e. -persistenceType without the '-' 
    	print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>persistenceType</td><td>".$params{"persistenceType"}."</td><td>XX</td></tr>\n";
    	if(exists $params{"timeout"})
    	{ 
    	 	print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Persistence Timeout</td><td>".$params{"timeout"}."</td><td>XX</td></tr>\n";
    	 }else{
    	 	print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Persistence Timeout</td><td>Default</td><td>XX</td></tr>\n";
    	 }
    	if(exists $params{"lbmethod"})
    	{ 
    		print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Loadbalance Method</td><td>".$params{"lbmethod"}."</td><td>XX</td></tr>\n";
    	}else{
    		print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Loadbalance Method</td><td>ROUNDROBIN</td><td>XX</td></tr>\n";
    	}
    	if(exists $params{"td"})
    	{   		
    		print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Traffic Domain</td><td>".$params{"td"}."</td><td>XX</td></tr>\n";
    	}if(exists $params{"backupVServer"})
    	{   		
    		print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Backup Virtual Server</td><td>".$params{"backupVServer"}."</td><td>XX</td></tr>\n";
    	}
    	
    	#print "\n++++++++++\n".Dumper(@services)."\n==========\n";
    	for my $i (0 .. @services-1){
    		#print "iteracion: ".$i." VS: ".$values[3]." Services: ".@services[$i]."\n";
    		if ($i==0){ 
    			print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>Services</td><td>".$services[$i]."</td><td>XX</td></tr>\n";
    		}else{
    			print $out "<tr><td>".$counter++."</td><td>vs_borrar</td><td>vs_borrar</td><td>".$services[$i]."</td><td>XX</td></tr>\n";	
    		}
    	}
    	#print "Dump hash".Dumper(\%params)."\n";
    #persistenceType
    #timeout
    #cltTimeout
    }
}
print $out "</table><br><br>\n";
############################################################## C O N T E N T    S W I T C H ###########

######seccion para Content Switch policies ##############
close $info;
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Policy Name</td><td>Type</td><td>Rule</td></tr>\n";
while( my $line = <$info>)  {   
    if($line =~ /add cs policy/){
    	my @values = split(' ',$line);
    	$cs_pols{ $values[3] } = $line; #3 es IP, 4 es netmask y 5 en aldelante son parm
        #print "POLITICA: ".$values[3]."\n";
        print $out "<tr>";
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>".$values[4]."</td>";
        print $out "<td>".$values[5]."</td><tr>\n";
        }
}
close $info;
print $out "</table><br><br>\n";

########seccion para Content Switch VSERVER ##############
# add cs vserver NAME TYPE IP PORT -cltTimeout 180 -Listenpolicy None
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Name</td><td>Type</td><td>IP</td><td>Port</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add cs vserver/){
    	my @values = split(' ',$line);
    	$cs_vserver{ $values[3] } = $line; #3 es name, 4 es type y 6 en aldelante son parms
        print $values[3]."\n";
        print $out "<tr>";
        print $out "<td>".$values[3]."</td>";
        print $out "<td>".$values[4]."</td>";
        print $out "<td>".$values[5]."</td>";
        print $out "<td>".$values[6]."</td>";
        print $out "<tr>\n";
        }
}
close $info;
print $out "</table><br><br>\n";
open $info, $file or die "Could not open $file: $!";
########seccion para bindings de Content Switch VSERVER y politicas -print sencillo##############

#print "CS Bindings for Virtual Server - Policy:\n";
#first pass to detect services bound to virtual servers 
while( my $line = <$info>)  {   
    if($line =~ /bind cs vserver/){
        my @values = split(' ',$line);
       	if($values[4] eq "-lbvserver"){   #es una linea del tipo bind cs vserver CS_VS_PRD -lbvserver LB_VS_PRD
    			$line = "bind cs vserver ".$values[3]." -policyName DEFAULT -lbvserver ".$values[5]." ";
    			$values[5] = "DEFAULT";
    	}
        if(exists $cs_bindings{$values[3]}){ 						#si ya existe
        	my @cs_binds = @{$cs_bindings{$values[3]}};
        	push @cs_binds,$values[5];
    		$cs_bindings{$values[3]} = \@cs_binds;
    	}else{														#primera itearacion
    		my @cs_binds;
    		push @cs_binds,$values[5];
    		$cs_bindings{$values[3]} = \@cs_binds;
    	}
    }
    
}

close $info;

open $info, $file or die "Could not open $file: $!";
########seccion para bindings de Content Switch VSERVER construye objetos##############
# puede ser de 2 tipos:
# 1 bind cs vserver CS_01_web_prod -lbvserver LB_Default1_web_prod
# 2 bind cs vserver CS_01_web_prod -policyName pol_obphotoalbum_web_prod -targetLBVserver LB_obphotoalbum_web_prod
#print "CS Bindings for Virtual Server - Policy:\n";
#first pass to detect services bound to virtual servers 
while( my $line = <$info>)  {   
    if($line =~ /bind cs vserver/){
        my @values = split(' ',$line); #rompe la linea en arrglo
        print "values[3] ".$values[3]."\n";
       	if($values[4] eq "-lbvserver"){   # caso 1; es una linea del tipo bind cs vserver CS_VS_PRD -lbvserver LB_VS_PRD
    			$line = "bind cs vserver ".$values[3]." -policyName DEFAULT -targetLBVserver ".$values[5]." ";
    			$values[6] = $values[5];
    			$values[7] = $values[5];
    			$values[5] = "DEFAULT";
    			print "LINE: ".$line."\n";
    	}
        if(exists $cs_bindings{$values[3]}){ 						#si ya existe
        	my @cs_binds = @{$cs_bindings{$values[3]}};
        	push @cs_binds,$values[5];
    		$cs_bindings{$values[3]} = \@cs_binds;
    		$cs_bindings_target{$values[5]} = $values[7]; #llena el hash politica-target
    		$cs_bindings_all{$values[5]} = $line;
    	}else{														#primera itearacion
    		my @cs_binds;
    		push @cs_binds,$values[5];
    		$cs_bindings{$values[3]} = \@cs_binds;
    		$cs_bindings_target{$values[3]} = $values[7]; #llena el hash politica-target
    		#print "DANI ".$values[5]." ".$values[7]."\n";
    		$cs_bindings_all{$values[5]} = $line;
    	}
    }
    
}

close $info;

open $info, $file or die "Could not open $file: $!";
########seccion para bindings de Content Switch VSERVER y politicas -detailed##############
print $out "<table border=1pt><tr><td>CS Vserver Name</td><td>Policy Name</td></tr>\n";
#print "CS VS Policy bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
for (keys %cs_bindings){
     #print " Key:  ".$_." \n";
     my @value = @{$cs_bindings{$_}};
     my $spaner = (scalar @value)+1;
     print $out "<tr><td rowspan=".$spaner.">".$_."</td>"; 
     for my $i (0 .. $#value){
     	if($i==0){
     		my $temp = $i+1;
     		#print "CS_POL_BIND       Val en i ".$i.": ".$value[$i]."\n";
     		print $out "<tr>"; 
     	}else{
     		#print "CS_POL_BIND      Val en i ".$i.": ".$value[$i]."\n";
     	}
     	print $out "<td>".$value[$i]."</td></tr>";
     }
}
print $out "</table><br><br>\n";


#detalles de politicas en CS
close $info;
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>CS Vserver Name</td><td>Policy Name</td><td>Rule</td><td>target</td></tr>\n";
#print "CS VS Policy bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
for (keys %cs_bindings){
     #print "CS VS Pol BIND Key:  ".$_." \n";
     my $curr_cs_vs = $_;
     my @POLvalue = @{$cs_bindings{$_}}; #contiene un arreglo de las politicas unidas al VS
     my $spaner = (scalar @POLvalue)+1; #cuantas politicas tengo para hacer el rowpsan
     print $out "<tr><td rowspan=".$spaner.">".$_."</td>";
     for my $i (0 .. $#POLvalue){    #itero sobre las politicas
     	#print "VS: ".$curr_cs_vs." POLvalue en ".$i." es ";
     	#print $POLvalue[$i]." || ";
		#print "cs_pol en POLvalue en i: ".$cs_pols{$POLvalue[$i]}." || ";
    	my $pol = $cs_pols{$POLvalue[$i]};  #contiene el add cs policy
     	my @pol_values = split(' ',$pol); #extra la linea del la creacion de la politica, en 5 esta la politica
     	if($i==0){
     		print $out "<td>".$POLvalue[$i]."</td>";
     		print $out "<td>".$pol_values[5]."</td><td>".$cs_bindings_target{$POLvalue[$i]}."</td><tr>";
		}
     	print $out "<td>".$POLvalue[$i]."</td><td>".$pol_values[5]."</td><td>".$cs_bindings_target{$POLvalue[$i]}."</td></tr>";
     	#print "RULE ".$pol_values[5]." TARGET: ".$cs_bindings_target{$POLvalue[$i]}." POLITICA ";
     	#print "add policy :".$pol."\n";
     }
}
print $out "</table><br><br>\n";

print $out "Configuración Access Gateway</p>";

######### Configuración Perfiles de autenticación #############
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Ldap Policy</td><td>rule</td><td>Action</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add authentication ldapPolicy/){
    	my @values = split(' ',$line);
    	$ldapPolicy{ $values[3] } = $line; #guarda la lindea
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>".$values[4]."</td>";
        print $out "<td>".$values[5]."</td><tr>\n";
        }
}
print $out "</table><br><br>\n";
close $info; 

######### Configuración Acciones de autenticación #############
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>LDAP Action</td><td>Config Param</td><td>Value</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add authentication ldapAction/){
    	my @values = split(' ',$line);
    	my %my_ldap_action = extract_params($line);
    	$ldapAction{ $values[3] } = %my_ldap_action; #store the hash that contains the values... 
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>Server IP</td><td>".$my_ldap_action{"serverIP"}."</td></tr>";
        print $out "<tr><td>erase_me</td><td>Base DN</td><td>".$my_ldap_action{"ldapBase"}."</td></tr>";
    	print $out "<tr><td>erase_me</td><td>Bind DN</td><td>".$my_ldap_action{"ldapBindDn"}."</td></tr>";
        print $out "<tr><td>erase_me</td><td>Login Attr</td><td>".$my_ldap_action{"ldapLoginName"}."</td></tr>";
        print $out "<tr><td>erase_me</td><td>Group Attr</td><td>".$my_ldap_action{"groupAttrName"}."</td><tr>\n";
        }
}
print $out "</table><br><br>\n";

open $info, $file or die "Could not open $file: $!";
########seccion para bindings de VPN VSERVER construye objetos##############
# puede ser de 2 tipos:
# 1 bind vpn vserver VSRV_AGE -staServer "http://172.18.232.205:8080"
# 2 bind vpn vserver VSRV_AGE -policy POL_AUTH -priority 100
#
while( my $line = <$info>)  {   
    if($line =~ /bind vpn vserver/){
    	print "\n".$line."\n";
        my @values = split(' ',$line); #rompe la linea en arrglo
        if(exists $vpn_pol_bindings{$values[3]} || exists $vpn_pol_bindings{$values[3]}){ 						#si ya existe
        	if($values[4] eq "-staServer"){
        		my @vpn_vs_binds = @{$vpn_sta_bindings{$values[3]}};
        		print $values[3]." Dumper Test STA binds\n".Dumper(@vpn_vs_binds)."\nRef: ".\@vpn_vs_binds."\n";
        		push @vpn_vs_binds,$values[5];
        		$vpn_sta_bindings{$values[3]} = \@vpn_vs_binds;
        		print $values[3]." Hago push de ".$values[5]." resulta Dumper Test STA binds\n".Dumper(@vpn_vs_binds)."\nRef: ".\@vpn_vs_binds."\n";

        	}
        	elsif ($values[4] eq "-policy"){                   #si es una polictica guardo la linea
        		my @vpn_vs_pols = @{$vpn_pol_bindings{$values[3]}};
        		print $values[3]." Dumper Test POL pol\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
        		push @vpn_vs_pols,$line;
        		$vpn_pol_bindings{$values[3]} = \@vpn_vs_pols;
        		print $values[3]." Hago push de ".$values[5]." Dumper Test POL pol\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
        	}
        	else{
        		print "ERROR in VPN VS Bindings\n";
        	}
    	}else{															#no existe y creo todo.
			#primera itearacion
			if($values[4] eq "-staServer"){
        		my @vpn_vs_binds;
        		push @vpn_vs_binds,$values[5];
        		$vpn_sta_bindings{$values[3]} = \@vpn_vs_binds;
        		print $values[3]." Dumper Test STACreate binds\n".Dumper(@vpn_vs_binds)."\n Ref: ".\@vpn_vs_binds."\n";
        	}
        	elsif ($values[4] eq "-policy"){                   #si es una polictica guardo la linea
        		my @vpn_vs_pols;
        		push @vpn_vs_pols,$line;
        		$vpn_pol_bindings{$values[3]} = \@vpn_vs_pols;
        		print $values[3]." Dumper Test POLCreate pols\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
        	}
    	}
    }
    
}
close $info;

######### Configuración VS VPN #############
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Virtual Server</td><td>Config Param</td><td>Value</td></tr>\n";
while( my $line = <$info>)  {   
   
    if($line =~ /add vpn vserver/){
    	my @values = split(' ',$line);
    	my %my_vpn_vs = extract_params($line);
    	$ldapAction{ $values[3] } = %vpn_vserver; #store the hash that contains the values... 
        print $out "<tr><td>".$values[3]."</td>";
        print $out "<td>IP</td><td>".$values[4]."</td></tr>";
        if(exists $my_vpn_vs{"icaOnly"}){
        	print $out "<tr><td>erase_me</td><td>Ica Only</td><td>".$my_vpn_vs{"icaOnly"}."</td></tr>";
        }else{
        	print $out "<tr><td>erase_me</td><td>Ica Only</td><td>OFF</td></tr>";
        }
    	print $out "<tr><td>erase_me</td><td>Max failed Logins</td><td>".$my_vpn_vs{"maxLoginAttempts"}."</td></tr>";
        print $out "<tr><td>erase_me</td><td>Max Concrr Users</td><td>".$my_vpn_vs{"maxAAAUsers"}."</td></tr>";
        print $out "<tr><td>erase_me</td><td>cginfraHomePageRedirect</td><td>".$my_vpn_vs{"cginfraHomePageRedirect"}."</td><tr>\n";
       	#contiene un arreglo de las lineas de politicas (permite diferenciar RW de AUTH de SESS...)
		my @vpn_vs_binds;
		my @vpn_vs_pols;
		if(exists $vpn_sta_bindings{$values[3]}){
			@vpn_vs_binds = $vpn_sta_bindings{$values[3]};    #contiene un arreglo de los STA
		}else{
			@vpn_vs_binds = ();
		}
		if(exists $vpn_pol_bindings{$values[3]}){
        	@vpn_vs_pols = $vpn_pol_bindings{$values[3]};	
        }else{
        	@vpn_vs_pols = ();
        }
        #$Data::Dumper::Indent = 3;
		print "VS".$values[3]." - #POLS: ".(scalar @vpn_vs_pols)." - ".Dumper(@vpn_vs_pols)."\n\n";
		print "VS".$values[3]." - #STAS: ".(scalar @vpn_vs_binds)." - ".Dumper(@vpn_vs_binds)."\n\n";

        	for my $i (0 .. $#vpn_vs_binds){    # foreach my $sta (\@vpn_vs_binds){
        		print "ARR STAs en i ".$i." es val: ".$vpn_vs_binds[0][$1]."Ref: ".\@vpn_vs_binds."\n";
        		print $out "<tr><td>erase_me</td><td>STA Server</td><td>".$vpn_vs_binds[0][$1]."</td></tr>\n";
        	}

         	for my $i (0 .. $#vpn_vs_pols){
         		print "ARR POLS en i ".$i." es val: ".$vpn_vs_pols[0][$1]."Ref: ".\@vpn_vs_pols."\n";
        		print $out "<tr><td>erase_me</td><td>POL</td><td>".$vpn_vs_pols[0][$1]."</td></tr>\n";
        	}
    }
}
print $out "</table><br><br>\n";