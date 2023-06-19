#! /bin/sh

set -e

OS=ubuntu
STORAGE_ACCOUNT_NAME=vbtfstatenonprod
STORAGE_CONTAINER_NAME=state
STORAGE_BLOB_NAME=vision-builder-p-hub/master
STORAGE_RG_NAME=visionbuilder_tfstate_nonprod
RG_NAME=vision-builder-p-master_hub_rg
VNET_GW_NAME=vnetgw
USERNAME=$(hostname)
DNS_RESOLVER_IP=10.60.32.4

usage() {
  echo "Usage: $0 [-o <ubuntu|alpine> default=$OS] [-a <terraform-state-storage-account-name> default=$STORAGE_ACCOUNT_NAME] [-c <terraform-state-storage-container-name> default=$STORAGE_CONTAINER_NAME] [-s <terraform-state-storage-resource-group-name default=$STORAGE_RG_NAME] [-b <terraform-state-storage-blob-name> default=$STORAGE_BLOB_NAME] [-r <hub-resource-group-name> default=$RG_NAME] [-v <vnet-gateway-name> default=$VNET_GW_NAME] [-u <username> default=$USERNAME] [-d <private-dns-resolver-ip> default=$DNS_RESOLVER_IP]"
  echo "Example: $0 -o $OS -s $STORAGE_ACCOUNT_NAME -c $STORAGE_CONTAINER_NAME -b $STORAGE_BLOB_NAME -r $RG_NAME -v $VNET_GW_NAME -d $DNS_RESOLVER_IP -u $USERNAME"
  echo "On the staging environment, you should not have to specify any of those optional values, except if you connect to anything else than master."
}

while getopts o:a:c:b:r:s:v:d:u:h opt; do
  case $opt in
  o) OS="$OPTARG" ;;
  a) STORAGE_ACCOUNT_NAME="$OPTARG" ;;
  c) STORAGE_CONTAINER_NAME="$OPTARG" ;;
  s) STORAGE_RG_NAME="$OPTARG" ;;
  b) STORAGE_BLOB_NAME="$OPTARG" ;;
  r) RG_NAME="$OPTARG" ;;
  v) VNET_GW_NAME="$OPTARG" ;;
  d) DNS_RESOLVER_IP="$OPTARG" ;;
  u) USERNAME="$OPTARG" ;;
  h) usage; exit 0 ;;
  *) echo "Invalid option: -$OPTARG" ; usage ; exit 1 ;;
  esac
done

access_key=$(az storage account keys list --resource-group "${STORAGE_RG_NAME}" --account-name "${STORAGE_ACCOUNT_NAME}" --query "[0].value" -o tsv)
expiry_date=$(date -d "+5 minutes" "+%Y-%m-%dT%H:%MZ")
sas_token=$(az storage blob generate-sas \
  --account-key "$access_key" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --container-name "${STORAGE_CONTAINER_NAME}" \
  --name "${STORAGE_BLOB_NAME}" \
  --permissions r \
  --expiry "$expiry_date" | jq -r .)

# TODO: as soon as we have certificate rotation in place, this function will not work anymore
# because I doubt the state should / will be updated with the latest certificate / private key
extract_root_ca_cert_and_private_key_from_gateway() {
  az storage blob download --account-name "${STORAGE_ACCOUNT_NAME}" \
    --container-name "${STORAGE_CONTAINER_NAME}" \
    --name "${STORAGE_BLOB_NAME}" \
    --sas-token "${sas_token}" --file state.json

  jq -jr '.resources[] | select(.type == "tls_self_signed_cert") | .instances[0].attributes.cert_pem' state.json >ca.crt
  jq -jr '.resources[] | select(.type == "tls_self_signed_cert") | .instances[0].attributes.private_key_pem' state.json >ca.key
}

generate_vpn_client_cert_and_private_key() {
  ipsec pki --gen --outform pem >${USERNAME}.key
  ipsec pki --pub --in ${USERNAME}.key | ipsec pki --issue --cacert ca.crt --cakey ca.key --dn "CN=${USERNAME}" --san "${USERNAME}" --flag clientAuth --outform pem >${USERNAME}.crt
}

generate_basic_openvpn_config() {
  config_url=$(az network vnet-gateway vpn-client generate --resource-group "${RG_NAME}" \
    --name "${VNET_GW_NAME}" \
    --processor-architecture Amd64 \
    --client-root-certificates "$(sed 's/$/\\n/' ca.crt | tr -d '\n')" | jq -r '.')

  wget "$config_url" -O config.zip

  # if we really have issues with windows-formatted zip files, we can proceed as explained here:
  #  https://unix.stackexchange.com/a/375846 --> apt install 7zip; 7zz rn config.zip $(7zz l config.zip | grep '\\' | awk '{ print $6, gensub(/\\/, "/", "g", $6); }' | paste -s)
  # the config is under vpn-config/OpenVPN/vpnconfig.ovpn
  unzip -q -d vpn-config config.zip || true
}

generate_openvpn_config_with_user_cert_and_key() {
  CLIENTCERTIFICATE=$(cat ${USERNAME}.crt)
  export CLIENTCERTIFICATE
  PRIVATEKEY=$(cat ${USERNAME}.key)
  export PRIVATEKEY

  envsubst <vpn-config/OpenVPN/vpnconfig.ovpn >vpnconfig.ovpn
}

configure_private_dns_server() {
  up="up.sh"
  down="down.sh"
  if [ "$OS" = "ubuntu" ]; then
    up="update-resolv-conf"
    down=$up
  fi

  cat <<EOT >>vpnconfig.ovpn

dhcp-option DNS ${DNS_RESOLVER_IP}
dhcp-option DOMAIN azurecr.io
dhcp-option DOMAIN azmk8s.io

setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
script-security 2
up /etc/openvpn/$up
down /etc/openvpn/$down
down-pre
EOT
}

generate_p12_package() {
  openssl pkcs12 -in ${USERNAME}.crt -inkey ${USERNAME}.key -certfile ca.crt -export -out ${USERNAME}.p12 -password pass:the-password
}

extract_root_ca_cert_and_private_key_from_gateway
generate_vpn_client_cert_and_private_key
generate_basic_openvpn_config
generate_openvpn_config_with_user_cert_and_key
configure_private_dns_server
generate_p12_package
