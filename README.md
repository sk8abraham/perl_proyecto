# Proyecto perl  
## Alumnos:  
Manzano Cruz Isaías Abraham  
Gómez Flores Patricia Nallely  
## Dependencias  
Ejecutar los siguientes comandos para instalar las dependencias necesarias:  
* apt install libfile-tail-perl  
* apt install libconfig-tiny-perl  
* cpan -i File::Tail  
* cpan -i Config::Tiny  
* cpan -i Net::IP  
* cpan -i DateTime  
* cpan -i Proc::Daemon  
## Ejecución  
perl ssh_block.pl prog.conf  

**Actualmente el programa bloquea la IP identificada de hacer bruteforce al servicio SSH por 2 minutos, debido a especificaciones no se incluyo en el archivo de configurarción, pero se puede cambiar en la linea 99 del programa (el tiempo está en segundos).**  
