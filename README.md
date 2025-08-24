cert-script [--help|--cn|--ip|--dns|--pass]

options:
  * help    - Print this Help.
  * cn      - Commonname, one allowed.
  * ip  			 - List of SAN-IPs (separated by spaces).
  * dns  		 - List of SAN-DNS-entries (separated by spaces).
  * pass  	 - Passphrase for private key

Supports optional batch-mode if all data is supplied via command-line

Can be run via:
```
wget -O - https://raw.githubusercontent.com/swesharkie/create_csr/refs/heads/main/cert-script.sh | bash
```
