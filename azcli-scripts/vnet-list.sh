#!/bin/bash -e
subscriptions=$(az account list --query "[].id" --output tsv)


for subscription in $subscriptions; do
    

    vnet_info=$(az network vnet list --subscription $subscription)


    length=$(echo "$vnet_info" | jq length)

    for ((i = 0; i < length; i++)); do
        id=$(echo "$vnet_info" | jq -r ".[$i].id")
        address_space=$(echo "$vnet_info" | jq -r ".[$i].addressSpace.addressPrefixes[]")
	subnets=$(echo "$vnet_info" | jq -c ".[$i].subnets[]")
	vnet_name=$(echo "$vnet_info" | jq -c ".[$i].name")

        echo "Subscription: $subscription"
        echo "ID: $vnet_name"
        echo "Address Space: $address_space"
        echo "Subnets: "
	ip_addresses+=("$address_space")
	while IFS= read -r subnet; do
            subnet_ip=$(echo "$subnet" | jq -r ".addressPrefix")
	    subnet_name=$(echo "$subnet" | jq -r ".name")
	    subnet_id=$(echo "$subnet" | jq -r ".id")
            echo "("$subnet_name - Subnet: $subnet_ip")"
	    echo "(Subnet ID: "$subnet_id")"
	    ip_subnets+=("$subnet_ip")
        done <<< "$subnets"
	echo
	echo
    done
done

sorted_ip_addresses=($(printf "%s\n" "${ip_addresses[@]}" | sort -r))
sorted_ip_addresses_subnets=($(printf "%s\n" "${ip_subnets[@]}" | sort -r))

# SHOW DATA:
echo "IP vnet:"
for ip in "${sorted_ip_addresses[@]}"; do
    echo "$ip"
done

echo "IP subnet:"
for ip in "${sorted_ip_addresses_subnets[@]}"; do
    echo "$ip"
done
