#!/usr/bin/perl
##
	#Revisión de logs en SSH
	
	#Manzano Cruz Isaías Abraham
	#Gómez Flores Patricia Nallely
##
use strict;
use warnings;
use utf8;
use Config::Tiny;
use File::Tail;
use Net::IP;
use Proc::Daemon;
our $dir_logfile = '/var/log/ssh_block';
our $log_file = $dir_logfile.'/ssh_block.log';
if(! -e $dir_logfile)
{
    `mkdir /var/log/ssh_block`;
}
`touch $log_file 2>&1 /dev/null`;

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };
while ($continue)
{
    open (my $log_fh,'>>',$log_file) or die ("Archivo no existente");
    print $log_fh "[+] Iniciando servicio ssh_block\n";
    close($$log_fh);
	#Lectura del archivo de configuración:
	my $file = $ARGV[0] or die "No se indico archivo de configuración\n";
	my $config = Config::Tiny->read( $file, 'utf8' );

	our $enable = $config->{ssh}{enable};
	our $log = $config->{ssh}{log};
	our $filter = $config->{ssh}{filter};
	our $attempts = $config->{ssh}{attempts};
	our $time = $config->{ssh}{time};

	our @direcciones;
	our %cuantas;
	our %blacklist;

	check_log();


	sub check_log 
	{
  	    my $infile = File::Tail->new(
    	name        => $log,
    	maxinterval => $time
  	);

        while (my $line = $infile->read and ($enable eq 'yes' or $enable eq 'Yes')) 
        {
                check_blacklist();
                if ( $line =~ $filter) 
                {
                    $line =~ /from (\S+)/g;
                    $cuantas{$1}+=1;
                    if ($cuantas{$1} >= $attempts and !($blacklist{$1}))
                    {
                            log_warn($1,$line);
                    }
             }
        }
	}

	sub log_warn 
	{
    		my $direccion = shift;
    		chomp($direccion);
    		my $linea = shift;
    		chomp($linea);
    		$linea =~ /(\d\d:\d\d:\d\d)/;
    		my $time = $1;
    		my $total = $cuantas{$direccion};
    		my $ip = new Net::IP($direccion) or die "$!";
    		my $version = $ip->version();
    		$blacklist{$direccion} = $time;
    		$cuantas{$direccion}=0;
    		`iptables -A INPUT -p tcp -s $direccion --dport 22 -j DROP`;
            open (my $log_fh,'>>',$log_file) or die ("Archivo no existente");
    		print $log_fh "[+] IP:$direccion\n\t[*] Intentos:$total\n\t[~] version:IPv$version\n";
        	print $log_fh "[+] La direccion IP: $direccion, fue bloqueada\n";
            close($$log_fh);
		    print "[+] La direccion IP: $direccion, fue bloqueada\n";
	}

	sub check_blacklist
	{
    		while(my ($ip,$date_str) = each(%blacklist))
    		{
        		my @s = split(':',$date_str);
        		my $inicio = $s[0]*3600+$s[1]*60+$s[2];
        		my ($sec,$min,$hour,@etc) = localtime();
        		my $fin = $hour*3600+$min*60+$sec;
        		my $res = $fin-$inicio;
        		if ($res > 120)
        		{
            			print "[+] La direccion IP: $ip, fue desbloqueada\n";
            			delete($blacklist{$ip});
            			`iptables -D INPUT -p tcp -s $ip --dport 22 -j DROP`;
                        open (my $log_fh,'>>',$log_file) or die ("Archivo no existente");
	    			    print $log_fh "[~]La direccion IP: $ip, fue desbloqueada\n";
                        close($log_fh);

        		}
    		}
	}	
}
END
{
    open (my $log_f,'>>',$log_file) or die ("Archivo no existente");
    print $log_f "[~] Deteniendo servicio ssh_block\n";
    close($log_f);
}

