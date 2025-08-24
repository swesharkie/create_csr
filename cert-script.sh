#!/bin/bash
############################################################
# Input                                                    #
############################################################
Input()  
{
   echo "Please input CN"
   read CN
   echo "Validating input"
   result=`echo $CN | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`
   if [[ -z "$result" ]]
   then
     echo "$CN is NOT a valid FQDN"
     exit 1
   fi
   echo "Ok"
   echo "Enter a list of SAN-IPs (separated by spaces) or press enter to skip:"
   read -a aSANIP
   
   echo "Validating input"
   for item in "${aSANIP[@]}"
   do
     if expr "$item" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
       for i in 1 2 3 4; do
         if [ $(echo "$item" | cut -d. -f$i) -gt 255 ]; then
           echo "$item is not a valid IP-adress"
           exit 1
         fi
       done
     else
       echo "$item is not even an IP-adress"
     exit 1
     fi
   done
   echo "Ok"
   
   echo "Enter a list of SAN-DNS-entries (separated by spaces) or press enter to skip:"
   read -a aSANDNS
   
   echo "Validating input"
   for item in "${aSANDNS[@]}"
   do
     result=`echo $item | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'`
     if [[ -z "$result" ]]
     then
         echo "$item is NOT a valid FQDN"
   	  exit 1
     fi
   done
   Main "$CN" "${aSANIP[@]}" "${aSANDNS[@]}"
}


############################################################
############################################################
# Main                                                     #
############################################################
############################################################
Main()
{
   if [[ ${aSANDNS[@]} =~ $CN ]]
   then
     echo "Ok"
   else
     echo "$CN not found in SAN, adding.."
     aSANDNS+=($CN)
     echo "Ok"
   fi
   
   echo "Creating OpenSSL config-file in subdirectory $CN"
   [ -d ./$CN ] || mkdir ./$CN
   touch ./$CN/openssl.cnf
	cat > "./$CN/openssl.cnf" <<-EOF
	HOME = ./$CN
	
	[req]
	default_bits = 4096
	default_keyfile = privkey.pem
	distinguished_name = req_distinguished_name
	default_md = sha512
	prompt = no
	req_extensions = v3_ext
	
	[req_distinguished_name]
	commonName = $CN
	
	[v3_ext]
	subjectKeyIdentifier=hash
	basicConstraints=critical, CA:FALSE
	keyUsage=critical, nonRepudiation, digitalSignature, keyEncipherment
	extendedKeyUsage = serverAuth, clientAuth
	subjectAltName = @alt_names
	
	[alt_names]
	$(
	i=1
	for item in "${aSANIP[@]}"
	do
	echo "IP.$i=$item"
	i=$((i+1))
	done
	)
	$(
	i=1
	for item in "${aSANDNS[@]}"
	do
	echo "DNS.$i=$item"
	i=$((i+1))
	done
	)
	EOF
   
   openssl req -new -config ./$CN/openssl.cnf -keyout ./$CN/private.key -out ./$CN/signingrequest.csr -batch
   
   echo "Done, certificate signing request and private key can be found in the folder $CN"
}

############################################################
# Init.                                                    #
############################################################
if [ $# -eq 0 ]; then
    Input
fi

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo
   echo "Syntax: cert-script [--help|--cn|--ip|--dns|--pass]"
   echo "options:"
   echo "help       Print this Help."
   echo "cn         Commonname, one allowed."
   echo "ip         List of SAN-IPs (separated by spaces)."
   echo "dns        List of SAN-DNS-entries (separated by spaces)."
   echo "pass       Passphrase for private key"
   echo
}

############################################################
# Process the input options.                               #
############################################################
while [ $# -gt 0 ]; do
  case "$1" in
    --cn*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      CN="${1#*=}"
	  echo "$1"
      ;;
    --ip*)
      if [[ "$1" != ip="*" ]]; then shift; fi
      aSANIP="${1[@]*=}"
	  echo "$1"
      ;;
    --dns*)
      if [[ "$1" != dns="*" ]]; then shift; fi
      aSANDNS="${1[@]*=}"
	  echo "$1"
      ;;
    --pass*)
      if [[ "$1" != pass="*" ]]; then shift; fi
      pass="${1#*=}"
	  echo "$1"
      ;;
    --help)
      Help
      exit 0
      ;;
  esac
  shift
done
echo "$CN" "${aSANIP[@]}" "${aSANDNS[@]}"
