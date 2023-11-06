[[_TOC_]]

# bash
Bash script to automate

- vnet-list.sh
- aks-bkp.sh
- blackdk.sh
- full-scan.sh

## vnet-list.sh

The script uses the Azure CLI (az) and the jq tool to retrieve information about Azure virtual networks (VNets) and subnets in Azure subscriptions and then display the sorted results.

Here's what the script does:

It obtains a list of Azure subscriptions and stores their identifiers in the subscriptions variable.

It then iterates through each subscription and retrieves information about the virtual networks (VNets) in that subscription using the az network vnet list command.

For each VNet found in a subscription, the script extracts relevant information such as the subscription name, VNet name, VNet address space, and subnets within the VNet.

It uses jq to parse and extract the desired information from the JSON data returned by Azure.

It displays the information on the standard output, including the subscription name, VNet name, VNet address space, and subnets within the VNet.

It stores the IP addresses of the VNets and subnets in the ip_addresses and ip_subnets arrays, respectively.

Finally, it sorts the IP addresses in reverse order and displays the sorted IP addresses of the VNets and subnets.

If you need specific documentation on the commands used and how each part of the script works, I recommend referring to the Azure CLI documentation (https://docs.microsoft.com/en-us/cli/azure) and the jq documentation (https://stedolan.github.io/jq/manual/).

Additionally, please note that this script relies on the Azure CLI and jq, so you should ensure that both tools are installed on your system and that you have logged in to Azure before running the script.

## aks-bkp.sh

Script to backup AKS Databases and Key Vault.

Features:
-   Backup from Keycloak SQL Database in format BACPAC.
-   Backup for all Key Vault.

How this works:
This script make backup from SQL Database by sqlpackage(cli) and backup all Key Vault Secrets. The vars required:

#####SQL_BACPAC_FILE -> Name of output file ".bacpac" from sql database
#####KV_SUBSCRIPTION -> Key Vault Subscription ID
#####KV_NAME -> Key Vault Name

With this variables takes all secrets needed to make a backup.

#####note: Permissions are required for your user to make backups. You can add them from Key Vault Access policies.

### blackdk.sh
Make BlackDuck scan to repository ( `Node` / `Pyton` ) and `docker images`.

#### to run
```
./blackd.sh -p <project> -t <tag> -c <credential_file> -y
./blackd.sh -p <project> -t <tag> -c <credential_file> -d <docker_image:tag>
```
**project:** project already created in BlackDuck.
**tag:** tag to project, this is created automatically but the limit is 10.
**credential_file:** file with credentials to login in BlackDuck.
**docker_image:** docker image name and tag to download and scan. (You need already logged on ACR).

### full-scan.sh
Make BlackDuck scan to list of repositories ( `Node` / `Pyton` ) and `docker images`.