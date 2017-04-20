#este archivo toma un ns.conf y extrae los balanceos de carga para poder construir las
# tablas que hacen parte de la documentación. Las tablas resultantes estan en formato HTML.

use strict;
use warnings;
use Data::Dumper;

#Using search and split with '-(?=(?:[^"]|"[^"]*")*$)' will ignore the searched character inside the double quotes.

#input the config line, return a hash that the keys are the -someting in the config line
sub extract_params {
    my $line = $_[0];
    my %params;
    my @params_temp = split( '-', $line );
    my @arr;

#print "+++++++++ Dump split en - arreglo:\n".Dumper(@params_temp)."\n+++++++++++++arreglo fin -------- \n";
    for my $elem (@params_temp) {
        @arr = split( / /, $elem );
        $params{ $arr[0] } = $arr[1];

#print "\n Key ".$arr[0]." Value ".$arr[1]."\n";
#print "==========Dump sub split en ' ':\n".Dumper(@arr)."\n ========= arreglo fin --------------- \n";
    }

    return %params;
}

my $file     = $ARGV[0];
my $hostname = "";

my @features           = ();
my %td                 = ();
my $has_td             = 0;
my %ips                = ();
my %server             = ();
my %service            = ();
my %vserver            = ();
my %bindings           = ();
my %cs_vserver         = ();
my %cs_pols            = ();
my %cs_bindings        = ();
my %cs_bindings_target = ();
my %cs_bindings_all    = ();

my %ldapPolicy       = ();
my %ldapAction       = ();
my %vpn_vserver      = ();
my %vpn_pol_bindings = ();    #vserver - array(policies bound)
my %vpn_sta_bindings = ();    #vserver - array(STA servers)
my %vpn_sesPolicies  = ();
my %vpn_sesAction    = ();

my %gslb_sites            = ();
my %gslb_services         = ();
my %gslb_vservers         = ();
my %gslb_vserver_bindings = ();
my %app_fw_profiles       = ();

#Get host name of netscaler to change output filename.
open my $info, $file or die "Could not open $file: $!";
while ( my $line = <$info> ) {
    if ( $line =~ /set ns hostName/ ) {
        my @values = split( ' ', $line );
        $hostname = $values[3];
        print "HOSTNAME " . $values[3] . "\n";
    }
}
if ( $hostname eq "" ) { $hostname = "conf"; }
close $info;

my $filename = $hostname . ".html";
my $out;
open( $out, ">", $filename ) or die "Cloud not open output file\n";

print $out
    "<html><head><h2>Currently only LB config is displayed in html table format<h2></head><body>";
print $out
    "<h3>Pase in MS Word using the \"Paste Specil...\" and then Unformated Text.<h3>";

open $info, $file or die "Could not open $file: $!";

#Feature verifications, will display relevant info based on this
print $out "<table border=1pt><tr><td>features enabled</td></tr>\n";
my $temp = 0;
while ( my $line = <$info> ) {
    if ( $line =~ /enable ns feature/ ) {
        @features = split( '\s', $line );
        foreach (@features) {
            if ( $temp > 3 ) {
                print $out "<tr><td>" . $_ . "</td></tr>";
            }
            $temp++;
        }
    }

}
print $out "</table><br><br>\n";
close $info;

#first pass to detect servers
#print "IP list:\n";
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>IP</td><td>Mask</td></tr>\n";
while ( my $line = <$info> ) {

    if ( $line =~ /add ns ip/ ) {
        my @values = split( ' ', $line );
        $ips{ $values[3] }
            = $line;    #3 es IP, 4 es netmask y 5 en aldelante son parms
                        #print $values[3]."\n";
        print $out "<tr><td>" . $values[3] . "</td>";
        print $out "<td>"
            . $values[4] . " "
            . $values[5] . " "
            . $values[6] . " "
            . $values[7] . " "
            . $values[8]
            . "</td><tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

############# bind vlan ####################
open $info, $file or die "Could not open $file: $!";
print $out
    "<table border=1pt><tr><td>vlan</td><td>Interface-ip</td><td>Tagged-Netmask</td></tr>\n";
while ( my $line = <$info> ) {

    #bind vlan 400 -ifnum LA/2
    if ( $line =~ /bind vlan/ ) {
        my @values = split( ' ', $line );
        $ips{ $values[3] }
            = $line;    #3 es IP, 4 es netmask y 5 en aldelante son parms
                        #print $values[3]."\n";
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[3] . " " . $values[4] . "</td>";
        print $out "<td>" . $values[5] . " " . $values[6] . "</td>";
        print $out "</tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

############## add route #########################
## TODO add PBR.... soon
open $info, $file or die "Could not open $file: $!";
print $out
    "<table border=1pt><tr><td>Network</td><td>Mask</td><td>Gateway</td></tr>\n";
while ( my $line = <$info> ) {

    #bind vlan 400 -ifnum LA/2
    if ( $line =~ /add route/ ) {
        my @values = split( ' ', $line );
        $ips{ $values[3] }
            = $line;    #3 es IP, 4 es netmask y 5 en aldelante son parms
                        #print $values[3]."\n";
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[3] . "</td>";
        print $out "<td>" . $values[4] . "</td>";
        print $out "</tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

############# net Profiles ##########
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Net Profile Name</td><td>IP</td></tr>\n";
while ( my $line = <$info> ) {

    if ( $line =~ /add netProfile/ ) {
        my @values = split( ' ', $line );
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[4] . "</td><tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;


##########################print "Traffic Domains:\n";
open $info, $file or die "Could not open $file: $!";
print $out
    "<table border=1pt><tr><td>Traffic Domain</td><td>Alias</td></tr>\n";
while ( my $line = <$info> ) {

    if ( $line =~ /add ns trafficDomain/ ) {
        my @values = split( ' ', $line );
        $td{ $values[3] } = $line;    #3 es id, 5 es alias
             #print "ID: ".$values[3]." Alias: ".$values[5]."\n";
        print $out "<tr><td>" . $values[3] . "</td>";
        print $out "<td>" . $values[5] . "</td><tr>\n";
        $has_td = 1;
    }
}
print $out "</table><br><br>\n";
close $info;

############# HA NODE ##########
open $info, $file or die "Could not open $file: $!";
print $out "<table border=1pt><tr><td>Node ID</td><td>IP</td></tr>\n";
while ( my $line = <$info> ) {

    if ( $line =~ /add HA node/ ) {
        my @values = split( ' ', $line );

        #print "HA Node ".$values[4]."\n";
        print $out "<tr><td>" . $values[3] . "</td>";
        print $out "<td>" . $values[4] . "</td><tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

############### SERVER ####################
open $info, $file or die "Could not open $file: $!";

#first pass to detect servers
#print "Server list:\n";
print $out "<table border=1pt><tr><td>Server Name</td><td>IP</td>";
if ( $has_td == 1 ) {
    print $out "<td>TD</td>";
}
print $out "</tr>";
while ( my $line = <$info> ) {

    if ( $line =~ /add server/ ) {
        my @values = split( ' ', $line );
        $server{ $values[2] } = $line;

        #print $values[2]."\n";
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[3] . "</td>";
        if ( $has_td == 1 ) {
            print $out "<td>" . $values[5] . "</td>";
        }
        print $out "<tr>";
    }
}
print $out "</table><br><br>\n";
close $info;
open $info, $file or die "Could not open $file: $!";

###################### SERVICE ##################
print $out
    "<table border=1pt><tr><td>Service Name</td><td>Server</td><td>Port</td><td>Protocol</td>";
if ( $has_td == 1 ) {
    print $out "<td>TD</td>";
}
print $out "</tr>";
while ( my $line = <$info> ) {

#add service EXTDNS2 KNXEXTDNS02 DNS 53 -gslb NONE -maxClient 0 -maxReq 0 -cip DISABLED -usip NO -useproxyport NO -sp OFF -cltTimeout 120 -svrTimeout 120 -CKA YES -TCPB YES -CMP NO

    if ( $line =~ /add service/ ) {
        my @values = split( ' ', $line );
        my %svc_params = extract_params($line);
        $service{ $values[2] } = $line;

        #print $values[2]."\n";
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[3] . "</td>";

        #"<td>".$values[4]."</td>"; this is the type of service
        print $out "<td>" . $values[5] . "</td><td>" . $values[4] . "</td>";
        if ( $has_td == 1 ) {
            print $out "<td>" . $svc_params{"td"} . "</td>";
        }
        print $out "</tr>\n";
    }
}
print $out "</table><br><br>\n";

close $info;
open $info, $file or die "Could not open $file: $!";

#   #add serviceGroup "Ext_Prod_Ex2013_ActiveSync" SSL -maxClient 0 -maxReq 0 -cacheable YES -cip DISABLED -usip NO -useproxyport NO -cltTimeout 180 -svrTimeout 360 -CKA YES -TCPB NO -CMP NO
##################### SERVICE GROUP ######################
print $out
    "<table border=1pt><tr><td>Service Group</td><td>Protocol</td><td>USIP</td></tr>";
while ( my $line = <$info> ) {

    if ( $line =~ /add serviceGroup/ ) {
        my @values = split( ' ', $line );
        my %svc_params = extract_params($line);
        $service{ $values[2] } = $line;

        #print $values[2]."\n";
        print $out "<tr><td>" . $values[2] . "</td>";
        print $out "<td>" . $values[3] . "</td>";
        print $out "<td>" . $values[13] . "</td>";
        print $out "</tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

### TODO ####### Member of Service Groups as well as monitors bound to servers #######

######

open $info, $file or die "Could not open $file: $!";

#  add lb monitor "Prod_Ex2013_OWA" HTTP-ECV -send "GET /owa/healthcheck.htm" -recv "200 OK" -LRTM ENABLED -interval 15 -resptimeout 10 -secure YES

print $out
    "<table border=1pt><tr><td>Name</td><td>TYPE</td><td>GET</td><td>Response</td></tr>";
while ( my $line = <$info> ) {

    if ( $line =~ /add lb monitor/ ) {
        my @values = split(' (?=(?:[^"]|"[^"]*")*$)', $line );
        print $out "<tr><td>" . $values[3] . "</td>";
        print $out "<td>" . $values[4] . "</td>";
        print $out "<td>" . $values[7] . "</td>";
        print $out "<td>" . $values[9] . "</td>";
        print $out "</tr>\n";
    }
}
print $out "</table><br><br>\n";
close $info;

open $info, $file or die "Could not open $file: $!";

#print "Bindings for Virtual Server - Services:\n";
#first pass to detect services bound to virtual servers
while ( my $line = <$info> ) {

    if ( $line =~ /bind lb vserver/ ) {
        my @values = split( ' ', $line );
        if ( exists $bindings{ $values[3] } ) {
            if ( $values[4] eq "-policyName" ) {
                $values[4]
                    = $values[4] . " "
                    . $values[5] . " "
                    . $values[6] . " "
                    . $values[7];
            }
            my @svcs = @{ $bindings{ $values[3] } };
            push @svcs, $values[4];
            $bindings{ $values[3] } = \@svcs;
        }
        else {
            my @svcs;
            if ( $values[4] eq "-policyName" ) {
                $values[4]
                    = $values[4] . " "
                    . $values[5] . " "
                    . $values[6] . " "
                    . $values[7];
            }
            push @svcs, $values[4];
            $bindings{ $values[3] } = \@svcs;
        }

        #print $values[3]." - ".$values[4]."\n";
    }

}

print $out
    "<table border=1pt><tr><td>Virtual Server Name</td><td>Service Name</td></tr>\n";

#print "VS services bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
for ( keys %bindings ) {

    #print " Key:  ".$_." \n";
    my @value = @{ $bindings{$_} };

    #print "=====\n".Dumper(@value)."======\n";
    print $out "<tr><td rowspan=" . scalar @value . ">" . $_ . "</td>";
    for my $i ( 0 .. $#value ) {

        #for my $val (@value){
        #print "      Val en i ".$i.": ".$value[$i]."\n";
        if ( $i == 0 ) {

            #print "      Val en i ".$i.": ".$value[$i]."\n";
            #print "<tr>";
        }
        else {
            #print "      Val en i ".$i.": ".$value[$i]."\n";
        }
        print $out "<td>" . $value[$i] . "</td></tr>";
    }
}
print $out "</table><br><br>\n";
close $info;
open $info, $file or die "Could not open $file: $!";

#print "Virtual Server List:\n";
print $out "<b>Virtual Server List:</b></p><table border=1pt>
<tr><td>Virtual Server Name</td><td>Category</td><td>Value</td></tr>\n";

#first pass to detect virtual servers
while ( my $line = <$info> ) {

    if ( $line =~ /add lb vserver/ ) {

        #print "START ".$line."\n";
        my @values = split( ' ', $line );
        my %params = extract_params($line);
        $vserver{ $values[3] } = $line;
        my @services       = ();
        my $count_services = 0;
        if ( exists $bindings{ $values[3] } ) {
            $count_services = scalar @{ $bindings{ $values[3] } } . "\n";
        }

        #print "VS: ".$values[3]." #servicios ".$count_services."\n";
        if ( $count_services > 0 ) {
            @services = @{ $bindings{ $values[3] } };
        }
        else {
            #print "VS: ".$values[3]." NO TIENE SERVICIOS\n";
        }
        for ( my $y = 0; $y < $count_services; $y++ ) {

 #print "VServer: ".$values[3]." Servicios: ".$y." bind: ".@services[$y]."\n";
        }

        #print "Dump arr".Dumper(@services)."\n";

        #print "==============\n".Dumper(@services)."\n+++++++\n";
        #print $values[3]."\n";
        ##### determine how many lines will be printed#######
        my $rowspan = 5;

#print "RowSpan para ".$values[3]." inicia en ".$rowspan."' 1 es Tipo, 2 es IP, 3 es puerto \n";
        if ( exists $params{"cltTimeout"} ) {
            $rowspan++;

       #print "1 cltTimeout RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"timeout"} ) {
            $rowspan++;

          #print "2 timeout RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"lbmethod"} ) {
            $rowspan++;

         #print "3 lbmethod RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"td"} ) {
            $rowspan++;

            #print "4 td RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"backupVServer"} ) {
            $rowspan++;

    #print "5 backupVServer RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"persistenceType"} ) {
            $rowspan++;

  #print "6 persistenceType RowSpan para ".$values[3]." es de ".$rowspan."\n";
        }
        if ( exists $params{"Authentication"} ) {
            $rowspan++;
        }
        if ( exists $params{"AuthenticationHost"} ) {
            $rowspan++;
        }
        if ( exists $params{"authnProfile"} ) {
            $rowspan++;
        }
        #####################################################
#print "7 Se va a incrementar RowSpan de ".$values[3]." en ".scalar @services."\n";
        $rowspan += scalar @services;

#print "RowSpan para ".$values[3]." es de ".$rowspan."\n";
# TODO solve this print $out "<tr><td rowspan=".$rowspan.">".$values[3]."</td><td>Tipo</td><td>".$values[4]."</td></tr>\n";
        print $out "<tr><td>"
            . $values[3]
            . "</td><td>Type</td><td>"
            . $values[4]
            . "</td></tr>\n";

        print $out "<tr><td>erase_me</td><td>IP</td><td>"
            . $values[5]
            . "</td></tr>\n";
        print $out "<tr><td>erase_me</td><td>Port</td><td>"
            . $values[6]
            . "</td></tr>\n";
        ############## Add aditional lines if you need more rows with information,
        ############## params is a hash that uses the key as the -param i.e. -persistenceType without the '-'
        if ( exists $params{"persistenceType"} ) {
            print $out "<tr><td>erase_me</td><td>persistenceType</td><td>"
                . $params{"persistenceType"}
                . "</td></tr>\n";
        }
        if ( exists $params{"timeout"} ) {
            print $out "<tr><td>erase_me</td><td>Persistence Timeout</td><td>"
                . $params{"timeout"}
                . "</td></tr>\n";
        }
        else {
            print $out
                "<tr><td>erase_me</td><td>Persistence Timeout</td><td>UNDEF</td></tr>\n";
        }
        if ( exists $params{"lbmethod"} ) {
            print $out "<tr><td>erase_me</td><td>Loadbalance Method</td><td>"
                . $params{"lbmethod"}
                . "</td></tr>\n";
        }
        else {
            print $out
                "<tr><td>erase_me</td><td>Loadbalance Method</td><td>ROUNDROBIN</td></tr>\n";
        }
        if ( exists $params{"td"} ) {
            print $out "<tr><td>erase_me</td><td>Traffic Domain</td><td>"
                . $params{"td"}
                . "</td></tr>\n";
        }
        if ( exists $params{"cltTimeout"} ) {
            print $out "<tr><td>erase_me</td><td>Client Timeout</td><td>"
                . $params{"cltTimeout"}
                . "</td></tr>\n";
        }
        if ( exists $params{"backupVServer"} ) {
            print $out "<tr><td>erase_me</td><td>Back Up VServer</td><td>"
                . $params{"backupVServer"}
                . "</td></tr>\n";
        }
        if ( exists $params{"Authentication"} ) {
            print $out "<tr><td>erase_me</td><td>Authentication</td><td>"
                . $params{"Authentication"}
                . "</td></tr>\n";
        }
        if ( exists $params{"AuthenticationHost"} ) {
            print $out "<tr><td>erase_me</td><td>Authentication Host</td><td>"
                . $params{"AuthenticationHost"}
                . "</td></tr>\n";
        }
        if ( exists $params{"authnProfile"} ) {
            print $out
                "<tr><td>erase_me</td><td>Authentication Profile</td><td>"
                . $params{"authnProfile"}
                . "</td></tr>\n";
        }

        #print "\n++++++++++\n".Dumper(@services)."\n==========\n";
        for my $i ( 0 .. @services - 1 ) {

  #print "iteracion: ".$i." VS: ".$values[3]." Services: ".@services[$i]."\n";
            if ( $i == 0 ) {
                print $out "<tr><td>"
                    . $values[3]
                    . "</td><td rowspan="
                    . scalar @services
                    . ">Services</td><td>"
                    . $services[$i]
                    . "</td></tr>\n";
            }
            else {
                print $out "<tr><td>"
                    . $values[3]
                    . "</td><td>"
                    . $services[$i]
                    . "</td></tr>\n";
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
print $out
    "The following is the Easy copy paste version, create an empty table in word using the sizes provided.";
print $out
    "Easy copy paste version of VS list:<br><table border=1pt><tr><td>erase me</td><td>Virtual Server Name</td><td>Category</td><td>Value</td><td>Justificacion</td></tr>\n";

#first pass to detect virtual servers
my $counter = 0;
while ( my $line = <$info> ) {

    if ( $line =~ /add lb vserver/ ) {
        my @values = split( ' ', $line );
        my %params = extract_params($line);
        $vserver{ $values[3] } = $line;
        my @services       = ();
        my $count_services = 0;
        if ( exists $bindings{ $values[3] } ) {
            $count_services = scalar @{ $bindings{ $values[3] } } . "\n";
        }

        #print "VS: ".$values[3]." #servicios ".$count_services."\n";
        if ( $count_services > 0 ) {
            @services = @{ $bindings{ $values[3] } };
        }
        else {
            print "VS: " . $values[3] . " No services\n";
        }

        #print "Dump arr".Dumper(@services)."\n";

        #print "==============\n".Dumper(@services)."\n+++++++\n";
        print $values[3] . "\n";
        my $rowspan = 6;
        if ( exists $params{"td"} ) { $rowspan++; }
        $rowspan += scalar @services;
        print $out "<tr><td>"
            . $counter++
            . "</td><td>"
            . $values[3]
            . "</td><td>Type</td><td>"
            . $values[4]
            . "</td><td>XX</td></tr>\n";
        print $out "<tr><td>"
            . $counter++
            . "</td><td>vs_borrar</td><td>IP</td><td>"
            . $values[5]
            . "</td><td>XX</td></tr>\n";
        print $out "<tr><td>"
            . $counter++
            . "</td><td>vs_borrar</td><td>Port</td><td>"
            . $values[6]
            . "</td><td>XX</td></tr>\n";
        ############## Add aditional lines if you need more rows with information,
        ############## params is a hash that uses the key as the -param i.e. -persistenceType without the '-'
        print $out "<tr><td>"
            . $counter++
            . "</td><td>vs_borrar</td><td>Persistence Type</td><td>"
            . $params{"persistenceType"}
            . "</td><td>XX</td></tr>\n";
        if ( exists $params{"timeout"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Persistence Timeout</td><td>"
                . $params{"timeout"}
                . "</td><td>XX</td></tr>\n";
        }
        else {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Persistence Timeout</td><td>Default</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"lbmethod"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Loadbalance Method</td><td>"
                . $params{"lbmethod"}
                . "</td><td>XX</td></tr>\n";
        }
        else {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Loadbalance Method</td><td>ROUNDROBIN</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"td"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Traffic Domain</td><td>"
                . $params{"td"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"backupVServer"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Backup Virtual Server</td><td>"
                . $params{"backupVServer"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"Authentication"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Authentication</td><td>"
                . $params{"Authentication"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"AuthenticationHost"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Authentication Host</td><td>"
                . $params{"AuthenticationHost"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $params{"authnProfile"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>vs_borrar</td><td>Authentication Profile</td><td>"
                . $params{"authnProfile"}
                . "</td><td>XX</td></tr>\n";
        }

        #print "\n++++++++++\n".Dumper(@services)."\n==========\n";
        for my $i ( 0 .. @services - 1 ) {

  #print "iteracion: ".$i." VS: ".$values[3]." Services: ".@services[$i]."\n";
            if ( $i == 0 ) {
                print $out "<tr><td>"
                    . $counter++
                    . "</td><td>vs_borrar</td><td>Services</td><td>"
                    . $services[$i]
                    . "</td><td>XX</td></tr>\n";
            }
            else {
                print $out "<tr><td>"
                    . $counter++
                    . "</td><td>vs_borrar</td><td>vs_borrar</td><td>"
                    . $services[$i]
                    . "</td><td>XX</td></tr>\n";
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
if ( "CS" ~~ @features ) {
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>Policy Name</td><td>Type</td><td>Rule</td></tr>\n";
    while ( my $line = <$info> ) {
        if ( $line =~ /add cs policy/ ) {
            my @values = split( '\s(?=(?:[^"]|"[^"]*")*$)', $line );
            $cs_pols{ $values[3] }
                = $line;    #3 es IP, 4 es netmask y 5 en aldelante son parm
                            #print "POLITICA: ".$values[3]."\n";
            print $out "<tr>";
            print $out "<tr><td>" . $values[3] . "</td>";
            print $out "<td>" . $values[4] . "</td>";
            print $out "<td>" . $values[5] . "</td><tr>\n";
        }
    }
    close $info;
    print $out "</table><br><br>\n";

########seccion para Content Switch VSERVER ##############
    # add cs vserver NAME TYPE IP PORT -cltTimeout 180 -Listenpolicy None

    open $info, $file or die "Could not open $file: $!";
    print $out "<h3>Content Switch Section</h3><br>";
    print $out
        "<table border=1pt><tr><td>Name</td><td>Type</td><td>IP</td><td>Port</td></tr>\n";
    while ( my $line = <$info> ) {

        if ( $line =~ /add cs vserver/ ) {
            my @values = split( ' ', $line );
            $cs_vserver{ $values[3] }
                = $line;    #3 es name, 4 es type y 6 en aldelante son parms
            print $values[3] . "\n";
            print $out "<tr>";
            print $out "<td>" . $values[3] . "</td>";
            print $out "<td>" . $values[4] . "</td>";
            print $out "<td>" . $values[5] . "</td>";
            print $out "<td>" . $values[6] . "</td>";
            print $out "<tr>\n";
        }
    }
    close $info;
    print $out "</table><br><br>\n";
    open $info, $file or die "Could not open $file: $!";
########seccion para bindings de Content Switch VSERVER y politicas -print sencillo##############

    #print "CS Bindings for Virtual Server - Policy:\n";
    #first pass to detect services bound to virtual servers
    while ( my $line = <$info> ) {
        if ( $line =~ /bind cs vserver/ ) {
            my @values = split( ' ', $line );
            if ( $values[4] eq "-lbvserver" )
            { #es una linea del tipo bind cs vserver CS_VS_PRD -lbvserver LB_VS_PRD
                $line
                    = "bind cs vserver "
                    . $values[3]
                    . " -policyName DEFAULT -lbvserver "
                    . $values[5] . " ";
                $values[5] = "DEFAULT";
            }
            if ( exists $cs_bindings{ $values[3] } ) {    #si ya existe
                my @cs_binds = @{ $cs_bindings{ $values[3] } };
                push @cs_binds, $values[5];
                $cs_bindings{ $values[3] } = \@cs_binds;
            }
            else {                                        #primera itearacion
                my @cs_binds;
                push @cs_binds, $values[5];
                $cs_bindings{ $values[3] } = \@cs_binds;
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
    while ( my $line = <$info> ) {
        if ( $line =~ /bind cs vserver/ ) {
            my @values = split( ' ', $line );    #rompe la linea en arrglo
            print "values[3] " . $values[3] . "\n";
            if ( $values[4] eq "-lbvserver" )
            { # caso 1; es una linea del tipo bind cs vserver CS_VS_PRD -lbvserver LB_VS_PRD
                $line
                    = "bind cs vserver "
                    . $values[3]
                    . " -policyName DEFAULT -targetLBVserver "
                    . $values[5] . " ";
                $values[6] = $values[5];
                $values[7] = $values[5];
                $values[5] = "DEFAULT";
                print "LINE: " . $line . "\n";
            }
            if ( exists $cs_bindings{ $values[3] } ) {    #si ya existe
                my @cs_binds = @{ $cs_bindings{ $values[3] } };
                push @cs_binds, $values[5];
                $cs_bindings{ $values[3] } = \@cs_binds;
                $cs_bindings_target{ $values[5] }
                    = $values[7];    #llena el hash politica-target
                $cs_bindings_all{ $values[5] } = $line;
            }
            else {                   #primera itearacion
                my @cs_binds;
                push @cs_binds, $values[5];
                $cs_bindings{ $values[3] } = \@cs_binds;
                $cs_bindings_target{ $values[3] }
                    = $values[7];    #llena el hash politica-target
                    #print "DANI ".$values[5]." ".$values[7]."\n";
                $cs_bindings_all{ $values[5] } = $line;
            }
        }

    }

    close $info;

    open $info, $file or die "Could not open $file: $!";
########seccion para bindings de Content Switch VSERVER y politicas -detailed##############
    print $out
        "<table border=1pt><tr><td>CS Vserver Name</td><td>Policy Name</td></tr>\n";

#print "CS VS Policy bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
    for ( keys %cs_bindings ) {

        #print " Key:  ".$_." \n";
        my @value  = @{ $cs_bindings{$_} };
        my $spaner = ( scalar @value ) + 1;
        print $out "<tr><td rowspan=" . $spaner . ">" . $_ . "</td>";
        for my $i ( 0 .. $#value ) {
            if ( $i == 0 ) {
                my $temp = $i + 1;

                #print "CS_POL_BIND       Val en i ".$i.": ".$value[$i]."\n";
                print $out "<tr>";
            }
            else {
                #print "CS_POL_BIND      Val en i ".$i.": ".$value[$i]."\n";
            }
            print $out "<td>" . $value[$i] . "</td></tr>";
        }
    }
    print $out "</table><br><br>\n";

    #detalles de politicas en CS
    close $info;
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>CS Vserver Name</td><td>Policy Name</td><td>Rule</td><td>target</td></tr>\n";

#print "CS VS Policy bindings:\n";
#print "=======================\n".Dumper(%bindings)."\n++++++++++++++++++++";
    for ( keys %cs_bindings ) {

        #print "CS VS Pol BIND Key:  ".$_." \n";
        my $curr_cs_vs = $_;
        my @POLvalue   = @{ $cs_bindings{$_} }
            ;    #contiene un arreglo de las politicas unidas al VS
        my $spaner = ( scalar @POLvalue )
            + 1;    #cuantas politicas tengo para hacer el rowpsan
        print $out "<tr><td rowspan=" . $spaner . ">" . $_ . "</td>";
        for my $i ( 0 .. $#POLvalue ) {    #itero sobre las politicas
                #print "VS: ".$curr_cs_vs." POLvalue en ".$i." es ";
                #print $POLvalue[$i]." || ";
             #print "cs_pol en POLvalue en i: ".$cs_pols{$POLvalue[$i]}." || ";
            my $pol = $cs_pols{ $POLvalue[$i] };    #contiene el add cs policy
            my @pol_values = split( ' ', $pol )
                ; #extra la linea del la creacion de la politica, en 5 esta la politica
            if ( $i == 0 ) {
                print $out "<td>" . $POLvalue[$i] . "</td>";
                print $out "<td>"
                    . $pol_values[5]
                    . "</td><td>"
                    . $cs_bindings_target{ $POLvalue[$i] }
                    . "</td><tr>";
            }
            print $out "<td>"
                . $POLvalue[$i]
                . "</td><td>"
                . $pol_values[5]
                . "</td><td>"
                . $cs_bindings_target{ $POLvalue[$i] }
                . "</td></tr>";

#print "RULE ".$pol_values[5]." TARGET: ".$cs_bindings_target{$POLvalue[$i]}." POLITICA ";
#print "add policy :".$pol."\n";
        }
    }
    print $out "</table><br><br>\n";
}

###VPN Serction
print "VPN check is: ".("SSLVPN" ~~ @features)."\n";
if ( "SSLVPN" ~~ @features ) {

    print $out "NetScaler Gateway Config</p>";

######### Configuración Perfiles de autenticación #############
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>Ldap Policy</td><td>rule</td><td>Action</td></tr>\n";
    while ( my $line = <$info> ) {

        if ( $line =~ /add authentication ldapPolicy/ ) {
            my @values = split( ' (?=(?:[^"]|"[^"]*")*$)', $line );
            $ldapPolicy{ $values[3] } = $line;    #guarda la lindea
            print $out "<tr><td>" . $values[3] . "</td>";
            print $out "<td>" . $values[4] . "</td>";
            print $out "<td>" . $values[5] . "</td><tr>\n";
        }
    }
    print $out "</table><br><br>\n";
    close $info;

######### Authentication LDAP Actions #############
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>LDAP Action</td><td>Config Param</td><td>Value</td></tr>\n";
    while ( my $line = <$info> ) {

        if ( $line =~ /add authentication ldapAction/ ) {
            my @values = split( ' ', $line );
            my %my_ldap_action = extract_params($line);
            $ldapAction{ $values[3] }
                = %my_ldap_action; #store the hash that contains the values...
            print $out "<tr><td>" . $values[3] . "</td>";
            print $out "<td>Server IP</td><td>"
                . $my_ldap_action{"serverIP"}
                . "</td></tr>";
            print $out "<tr><td>erase_me</td><td>Base DN</td><td>"
                . $my_ldap_action{"ldapBase"}
                . "</td></tr>";
            print $out "<tr><td>erase_me</td><td>Bind DN</td><td>"
                . $my_ldap_action{"ldapBindDn"}
                . "</td></tr>";
            print $out "<tr><td>erase_me</td><td>Login Attr</td><td>"
                . $my_ldap_action{"ldapLoginName"}
                . "</td></tr>";
            print $out "<tr><td>erase_me</td><td>Group Attr</td><td>"
                . $my_ldap_action{"groupAttrName"}
                . "</td><tr>\n";
        }
    }
    print $out "</table><br><br>\n";

    open $info, $file or die "Could not open $file: $!";
########seccion para bindings de VPN VSERVER construye objetos##############
    # puede ser de 2 tipos:
    # 1 bind vpn vserver VSRV_AGE -staServer "http://172.18.232.205:8080"
    # 2 bind vpn vserver VSRV_AGE -policy POL_AUTH -priority 100
    #
    while ( my $line = <$info> ) {
        if ( $line =~ /bind vpn vserver/ ) {

            #print "\n".$line."\n";
            my @values = split( ' ', $line );    #rompe la linea en arrglo
            if ( $values[4] eq "-staServer" ) {
                if ( exists $vpn_sta_bindings{ $values[3] } ) {
                    my @vpn_vs_binds = @{ $vpn_sta_bindings{ $values[3] } };

#print $values[3]." Existe STA binds\n".Dumper(@vpn_vs_binds)."\nRef: ".\@vpn_vs_binds."\n";
                    push @vpn_vs_binds, $values[5];
                    $vpn_sta_bindings{ $values[3] } = \@vpn_vs_binds;

#print $values[3]." Hago push de ".$values[5]." resulta Dumper Test STA binds\n".Dumper(@vpn_vs_binds)."\nRef: ".\@vpn_vs_binds."\n";
                }
                else {
                    my @vpn_vs_binds;
                    push @vpn_vs_binds, $values[5];
                    $vpn_sta_bindings{ $values[3] } = \@vpn_vs_binds;

#print $values[3]." NUEVO STACreate binds\n".Dumper(@vpn_vs_binds)."\n Ref: ".\@vpn_vs_binds."\n";
                }
            }
            elsif ( $values[4] eq "-policy" )
            {    #si es una polictica guardo la linea
                if ( exists $vpn_pol_bindings{ $values[3] } ) {
                    my @vpn_vs_pols = @{ $vpn_pol_bindings{ $values[3] } };

#print $values[3]." EXISTE POL pol\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
                    my %this_policy = extract_params($line);
                    $vpn_sesPolicies{ $this_policy{"policy"} }
                        = \%this_policy;    #llena el hash
                    push @vpn_vs_pols, $this_policy{"policy"};
                    $vpn_pol_bindings{ $values[3] } = \@vpn_vs_pols;

#print $values[3]." Hago push de ".$values[5]." Dumper Test POL pol\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
                }
                else {    #si es una polictica guardo la linea
                    my @vpn_vs_pols;
                    my %this_policy = extract_params($line);
                    $vpn_sesPolicies{ $this_policy{"policy"} }
                        = \%this_policy;    #llena el hash
                    push @vpn_vs_pols, $this_policy{"policy"};
                    $vpn_pol_bindings{ $values[3] } = \@vpn_vs_pols;

#print $values[3]." NUEVO POLCreate pols\n".Dumper(@vpn_vs_pols)."\n Ref: ".\@vpn_vs_pols."\n";
                }
            }
        }
    }
    close $info;

######### Configuración VS VPN #############
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>Count</td><td>Virtual Server</td><td>Config Param</td><td>Value</td><td>Explanation</td></tr>\n";
    my $tot_vpn_lines = 0;
    while ( my $line = <$info> ) {

        if ( $line =~ /add vpn vserver/ ) {
            my $vpn_lines = 0;
            my @values    = split( ' ', $line );
            my %my_vpn_vs = extract_params($line);
            $ldapAction{ $values[3] }
                = %vpn_vserver;    #store the hash that contains the values...
            print $out "<tr><td>"
                . $tot_vpn_lines++ . " - "
                . $vpn_lines++
                . "</td><td>"
                . $values[3] . "</td>";
            print $out "<td>IP</td><td>"
                . $values[5]
                . "</td><td>X</td></tr>";
            if ( exists $my_vpn_vs{"icaOnly"} ) {
                print $out "<tr><td>"
                    . $tot_vpn_lines++ . " - "
                    . $vpn_lines++
                    . "</td><td>erase_me</td><td>Ica Only</td><td>";
                if ( $my_vpn_vs{"icaOnly"} eq "On" ) {
                    print $out "On</td><td>X</td></tr>";
                }
                else {
                    print $out
                        "Off</td><td>Smart Access Enabled, this consumes one Universal License per concurrent user.</td></tr>";
                }
            }
            else {
                print $out "<tr><td>"
                    . $tot_vpn_lines++ . " - "
                    . $vpn_lines++
                    . "</td><td>erase_me</td><td>Ica Only</td><td>Off</td><td>Smart Access Enabled, this consumes one Universal License per concurrent user.</td></tr>";
            }
            print $out "<tr><td>"
                . $tot_vpn_lines++ . " - "
                . $vpn_lines++
                . "</td><td>erase_me</td><td>Max failed Logins</td><td>"
                . $my_vpn_vs{"maxLoginAttempts"}
                . "</td><td>X</td></tr>";
            print $out "<tr><td>"
                . $tot_vpn_lines++ . " - "
                . $vpn_lines++
                . "</td><td>erase_me</td><td>Max Concrr Users</td><td>"
                . $my_vpn_vs{"maxAAAUsers"}
                . "</td><td>X</td></tr>";
            print $out "<tr><td>"
                . $tot_vpn_lines++ . " - "
                . $vpn_lines++
                . "</td><td>erase_me</td><td>cginfraHomePageRedirect</td><td>"
                . $my_vpn_vs{"cginfraHomePageRedirect"}
                . "</td><td>X</td><tr>\n";

#contiene un arreglo de las lineas de politicas (permite diferenciar RW de AUTH de SESS...)
            my @vpn_vs_binds;
            my @vpn_vs_pols;
            if ( exists $vpn_sta_bindings{ $values[3] } ) {
                @vpn_vs_binds = @{ $vpn_sta_bindings{ $values[3] } }
                    ;    #contiene un arreglo de los STA
            }
            else {
                @vpn_vs_binds = ();
            }
            if ( exists $vpn_pol_bindings{ $values[3] } ) {
                @vpn_vs_pols = @{ $vpn_pol_bindings{ $values[3] } };
            }
            else {
                @vpn_vs_pols = ();
            }

#$Data::Dumper::Indent = 3;
#print "VS".$values[3]." - #POLS: ".(scalar @vpn_vs_pols)." - ".Dumper(@vpn_vs_pols)."\n\n";
#print "VS".$values[3]." - #STAS: ".(scalar @vpn_vs_binds)." - ".Dumper(@vpn_vs_binds)."\n\n";

            for my $i ( 0 .. $#vpn_vs_binds )
            {    # foreach my $sta (\@vpn_vs_binds){
                print $out "<tr><td>"
                    . $tot_vpn_lines++ . " - "
                    . $vpn_lines++
                    . "</td><td>erase_me</td><td>STA Server</td><td>"
                    . $vpn_vs_binds[$i]
                    . "</td><td>X</td></tr>\n";
            }

            for my $i ( 0 .. $#vpn_vs_pols ) {

                #print "TOTAL Policies: ".Dumper($vpn_vs_pols)."\n";
                my $temp = $vpn_vs_pols[$i];

                #print "POLITICA: ".$temp."\n";
                my %curr_pol = %{ $vpn_sesPolicies{$temp} };

                #print "Otro error: ".Dumper(%curr_pol)."\n";
                print $out "<tr><td>"
                    . $tot_vpn_lines++ . " - "
                    . $vpn_lines++
                    . "</td><td>erase_me</td><td>POL</td><td>"
                    . $curr_pol{"priority"} . ""
                    . $curr_pol{"policy"}
                    . "</td><td>X</td></tr>\n";
            }
        }
    }
    print $out "</table><br><br>\n";

######### Configuración Politicas-Perfiles de session #############
    open $info, $file or die "Could not open $file: $!";
    print $out
        "<table border=1pt><tr><td>Policy</td><td>rule</td><td>Action</td></tr>\n";
    while ( my $line = <$info> ) {

        if ( $line =~ /add vpn sessionPolicy/ ) {
            my @values = split( '\s(?=(?:[^"]|"[^"]*")*$)', $line );
            $ldapPolicy{ $values[3] } = $line;    #guarda la lindea
            print $out "<tr><td>" . $values[3] . "</td>";
            print $out "<td>" . $line . "</td>";
            print $out "<td>" . $values[5] . "</td><tr>\n";
        }
    }
    print $out "</table><br><br>\n";
    close $info;

    #add vpn sessionAction
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add vpn sessionAction/ ) {
            my @values = split( '\s(?=(?:[^"]|"[^"]*")*$)', $line );
            my %my_vpn_act = extract_params($line);
            $vpn_sesAction{ $values[3] } = \%my_vpn_act;
        }
    }
    $counter = 2;
    print $out "Session Profiles Configured\n";
    print $out
        "<table border=1><tr><<td>#</td><td>Session Profile</td><td>Param</td><td>value</td><td>Explanation/Justiofication</td></tr>\n";
    my $sess_prof;
    foreach $sess_prof ( keys %vpn_sesAction ) {
        print "ERROR: " . Dumper($sess_prof) . "\n";
        print $out "<tr><td>"
            . $counter++
            . "</td><td><b>"
            . $sess_prof
            . "</b></td><td>Name</td><td>"
            . $sess_prof
            . "</td><td>XX</td></tr>\n";
        if ( exists $vpn_sesAction{$sess_prof}{"dnsVserverName"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>dnsVserverName</td><td>"
                . $vpn_sesAction{$sess_prof}{"dnsVserverName"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"splitDns"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>splitDns</td><td>"
                . $vpn_sesAction{$sess_prof}{"splitDns"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"splitTunnel"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>splitTunnel</td><td>"
                . $vpn_sesAction{$sess_prof}{"splitTunnel"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"defaultAuthorizationAction"} )
        {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>defaultAuthorizationAction</td><td>"
                . $vpn_sesAction{$sess_prof}{"defaultAuthorizationAction"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"authorizationGroup"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>authorizationGroup</td><td>"
                . $vpn_sesAction{$sess_prof}{"authorizationGroup"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"ssoCredential"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>ssoCredential</td><td>"
                . $vpn_sesAction{$sess_prof}{"ssoCredential"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"windowsAutoLogon"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>windowsAutoLogon</td><td>"
                . $vpn_sesAction{$sess_prof}{"windowsAutoLogon"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"homePage"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>homePage</td><td>"
                . $vpn_sesAction{$sess_prof}{"homePage"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"icaProxy"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>icaProxy</td><td>"
                . $vpn_sesAction{$sess_prof}{"icaProxy"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"wihome"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>wihome</td><td>"
                . $vpn_sesAction{$sess_prof}{"wihome"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"citrixReceiverHome"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>citrixReceiverHome</td><td>"
                . $vpn_sesAction{$sess_prof}{"citrixReceiverHome"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"wiPortalMode"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>wiPortalMode</td><td>"
                . $vpn_sesAction{$sess_prof}{"wiPortalMode"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"ClientChoices"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>ClientChoices</td><td>"
                . $vpn_sesAction{$sess_prof}{"ClientChoices"}
                . "</td><td>XX</td></tr>\n";
        }

        if ( exists $vpn_sesAction{$sess_prof}{"ntDomain"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>ntDomain</td><td>"
                . $vpn_sesAction{$sess_prof}{"ntDomain"}
                . "</td><td>XX</td></tr>\n";
        }
        if ( exists $vpn_sesAction{$sess_prof}{"clientlessVpnMode"} ) {
            print $out "<tr><td>"
                . $counter++
                . "</td><td>erase_me</td><td>clientlessVpnMode</td><td>"
                . $vpn_sesAction{$sess_prof}{"clientlessVpnMode"}
                . "</td><td>XX</td></tr>\n";
        }
    }
    print $out "</table>\n";

}

##### GSLB
if ( "GSLB" ~~ @features ) {
    print $out "GSLB</p>";

    print $out "GSLB Site</p>";

#add gslb sites add gslb site GSLB_ASC_SITE 10.128.70.245 -publicIP 10.128.70.245
    print $out
        "<table border=1><tr><td>GSLB Site</td><td>Param</td><td>value</td><td>Explanation/Justiofication</td></tr>\n";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add gslb site/ ) {
            my @values = split( ' ', $line );
            print $out "<tr><td>"
                . $values[3]
                . "</td><td>erase_me</td><td>erase_me</td><td>erase_me</td></tr>";
            print $out "<tr><td>erase_me</td><td>";
            if ( ( $values[4] ) =~ /^\d/ )
            {    ##starts with number the IP, otherwise is site type
                print $out "IP</td><td>"
                    . $values[4]
                    . "</td><td>erase_me</td></tr>";    ##optional Type
            }
            else {
                print $out "Type</td><td>"
                    . $values[4]
                    . "</td><td>erase_me</td></tr>";    ##optional Type
            }
            print $out "<tr><td>erase_me</td><td>"
                . $values[5] . "<td>"
                . $values[6]
                . "</td><td>erase_me</td></tr>";        ##Can be type or IP
        }
    }
    print $out "</table>\n";
    close $info;

    print $out "GSLB Service</p>";

#add gslb services add gslb service GSLB_SVC_WILDCARDAUTH_MYVIRTUALWORKPLACE_ASC 172.31.4.56 SSL 443 -publicIP 172.31.4.56 -publicPort 443 -maxClient 0 -siteName GSLB_SITE_ASC -cltTimeout 180 -svrTimeout 360 -downStateFlush DISABLED
    print $out
        "<table border=1><tr><td>GSLB Sercice</td><td>Param</td><td>value</td><td>Explanation/Justiofication</td></tr>\n";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add gslb service/ ) {
            my @values = split( ' ', $line );
            my %my_gslb_services = extract_params($line);
            $gslb_services{ $values[3] } = \%my_gslb_services;
            print $out "<tr><td>"
                . $values[3]
                . "</td><td>IP</td><td>"
                . $values[4]
                . "</td><td>";
            if ( $values[4] =~ /^\d/ ) {
                print $out "erase_me";
            }
            else {
                print $out
                    "Is remote service and server was not created using IP-IP but Name-IP\n";
            }
            print $out "</td></tr>";
            print $out "<tr><td>erase_me</td><td>Type</td><td>"
                . $values[5]
                . "</td><td>erase_me</td></tr>";
            print $out "<tr><td>erase_me</td><td>Port</td><td>"
                . $values[6]
                . "</td><td>erase_me</td></tr>";
            print $out "<tr><td>erase_me</td><td>publicIP</td><td>"
                . $gslb_services{ $values[3] }{"publicIP"}
                . "</td><td>erase_me</td></tr>";
            print $out "<tr><td>erase_me</td><td>publicPort</td><td>"
                . $gslb_services{ $values[3] }{"publicPort"}
                . "</td><td>erase_me</td></tr>";
            print $out "<tr><td>erase_me</td><td>siteName</td><td>"
                . $gslb_services{ $values[3] }{"siteName"}
                . "</td><td>erase_me</td></tr>";

            #print $line."\n\n";
        }
    }
    print $out "</table>\n";
    close $info;

#TODO: the add gslb line is also included in the hash that contains all elements! this need to be resolved.
#add gslb vservers add gslb vserver GSLB_INV_SF_PROD_vsrv SSL -backupLBMethod ROUNDROBIN -tolerance 0 -appflowLog DISABLED
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add gslb vserver/ ) {
            my @values = split( ' ', $line );
            my %my_gslb_vservers = extract_params($line);
            print "Dumper add GSLB: " . Dumper(%my_gslb_vservers);
            print $line. "\n\n";

            #print Dumper(%my_gslb_vservers);
            my $gslb_vs = $values[3];
            $gslb_vservers{$gslb_vs} = \%my_gslb_vservers;
        }
    }
    close $info;

#this line will find the set gslb vserver command and append all params to the already existing add gslb vserver hash
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /set gslb vserver/ ) {
            my @values = split( ' ', $line );
            my %my_gslb_vservers = extract_params($line);

            #print "Dumper ARRAY: ".Dumper(@values);
            #print "Dumper HASH: ".Dumper(%my_gslb_vservers);
            my %original = \$gslb_vservers{ $values[3] };
            foreach ( keys %my_gslb_vservers ) {
                print "KEY " . $_ . " VAL " . $my_gslb_vservers{$_} . "\n";
                $original{$_} = $my_gslb_vservers{$_};
            }
            print "Dumper " . Dumper(%my_gslb_vservers) . "\n";
            $gslb_vservers{ $values[3] } = \%original;
            print $line. "\n\n";
        }
    }
    close $info;

    #this will find the bind gslb vserver
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /bind gslb vserver/ ) {
            my @values = split( ' ', $line );

#gslb_vserver_bindings
#bind gslb vserver GSLB_INV_SF_PROD_vsrv -serviceName GSLB_INV_SF_PROD_svc
#if serviceName add to vserver binding array
#bind gslb vserver GSLB_INV_EPIC-P-HSWEB_PROD_vsrv -domainName epic-p-hsweb.intgslb.centura.org -TTL 5
#if domainName add to vserver hash with manually created hash.
            if ( $values[4] eq "-serviceName" ) {
                if ( exists $gslb_vserver_bindings{ $values[3] } ) {
                    my @gslb_vs_binds
                        = @{ $gslb_vserver_bindings{ $values[3] } };
                    push @gslb_vs_binds, $values[5];
                    $gslb_vserver_bindings{ $values[3] } = \@gslb_vs_binds;
                }
                else {
                    my @gslb_vs_binds;
                    push @gslb_vs_binds, $values[5];
                    $gslb_vserver_bindings{ $values[3] } = \@gslb_vs_binds;
                }
            }
            if ( $values[4] eq "-domainName" ) {
                $gslb_vservers{ $values[3] }{ $values[4] } = $values[5];

                #print Dumper($gslb_vservers{$values[3]});
            }

        }
    }
    close $info;

    print $out "GSLB Vserver</p>";

#used to print the glsb vservers
#gslb_vservers
#add gslb vserver GSLB_INV_EPIC-P-HSWEB_PROD_vsrv SSL -backupLBMethod ROUNDROBIN -tolerance 0 -appflowLog DISABLED
#found in %gslb_vserver_bindings has an array inside
#bind gslb vserver GSLB_ASC_EPIC-P-HSWEB_PROD_vsrv -serviceName GSLB_ASC_EPIC-P-HSWEB
#found in gslb_vservers{"$values[3]"}{"-domainName"}
#bind gslb vserver GSLB_INV_EPIC-P-HSWEB_PROD_vsrv -domainName epic-p-hsweb.intgslb.centura.org -TTL 5
    print $out
        "<table border=1><tr><td>GSLB Vserver</td><td>Param</td><td>value</td><td>Explanation/Justiofication</td></tr>\n";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add gslb vserver/ ) {
            my @values = split( ' ', $line );
            print $out "<tr><td>"
                . $values[3]
                . "</td><td>Type</td><td>"
                . $values[4]
                . "</td><td>erase_me</td></tr>";
            foreach ( keys $gslb_vservers{ $values[3] } ) {
                print $out "<tr><td>erase_me</td><td>"
                    . $_
                    . "</td><td>"
                    . $gslb_vservers{ $values[3] }{$_}
                    . "</td><td>erase_me</td></tr>\n";
            }

            #services bound, can be improved, see line 893
            #print Dumper($gslb_vserver_bindings{$values[3]});
            my @gslb_services = $gslb_vserver_bindings{ $values[3] };
            foreach my $i ( 0 .. $#gslb_services ) {
                print $out "<tr><td>erase_me</td><td>Service</td><td>"
                    . $gslb_services[$i][0]
                    . "</td><td>erase_me</td></tr>\n";
            }
        }

    }
    print $out "</table>\n";
    close $info;
}

if ( "AppFw" ~~ @features ) {

    print $out "Application Firewall Policies</p>";    #add appfw policy
    print $out
        "<table border=1><tr><td>Policy</td><td><Rule></td><td>Profile</td></tr>";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add appfw policy/ ) {
            my @values = split( '\s(?=(?:[^"]|"[^"]*")*$)', $line );
            print $out "<tr><td>"
                . $values[3]
                . "</td><td>"
                . $values[4]
                . "</td><td>"
                . $values[5]
                . "</td><td></tr>";

        }
    }
    print $out "</table>\n";
    close $info;

    print $out "AppFirewall Profiles</p>";

    print $out
        "<table border=1><tr><td>Profile</td><td><configs></td><td>Values</td></tr>";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /add appfw profile/ ) {
            my @values = split( ' ', $line );
            my @params = split( '-(?=(?:[^"]|"[^"]*")*$)', $line );
            print $out "<tr><td>"
                . $values[3]
                . "</td><td></td><td></td></tr>";
            my $count = 0;
            foreach my $i (@params) {
                if ( $count > 0 ) {
                    print $out "<tr><td></td><td>";
                    my @temp = split( ' ', $i, 2 );
                    print $out " "
                        . $temp[0]
                        . "</td><td>"
                        . $temp[1]
                        . "</td></tr>";
                }
                $count++;
            }
        }
    }
    print $out "</table>\n";
    close $info;

    print $out
        "AppFirewall Profiles Details. This can very big and long, final formating to be defined.</p>";

    #bind appfw profile
    print $out "<table border=1><tr><td>Profile</td><td>Relaxation</td></tr>";
    open $info, $file or die "Could not open $file: $!";
    while ( my $line = <$info> ) {
        if ( $line =~ /bind appfw profile/ ) {
            my @values = split( '\s', $line );
            my $print = 1;
            if ( "-denyURL" ~~ @values )
            {    #line is a denyURL, usually comes by deafult.
                $print = 0;
            }
            if ( $values[4] eq "-comment" )
            { #line is like bind appfw profile AF_PROF_DESA_DISPLAY_PDF -comment "For all images" -excludeResContentType "image/.*"
                $print = 0;
            }
            if ( $print == 1 ) {
                print $out "<tr><td>" . $values[3] . "</td><td>";
                my $count = 0;
                foreach my $i (@values) {
                    if ( $count > 3 ) {
                        print $out " " . $i . " ";
                    }
                    $count++;
                }
                print $out "</td></tr>";
            }
            $print = 1;
        }
    }
    print $out "</table>\n";
    close $info;

}    #closing bracket for appfw

