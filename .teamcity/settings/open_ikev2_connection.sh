#! /bin/sh

apt update
apt install -y strongswan strongswan-pki libstrongswan-extra-plugins libtss2-tcti-tabrmd0 libcharon-extra-plugins

USERNAME=$(hostname)

# inspired of https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-vpn-client-cert-linux#cli

cp vpn-config/Generic/VpnServerRoot.cer_0 /etc/ipsec.d/cacerts

# this is something like azuregateway-0dcb0077-2dd3-4fce-b68a-f6d98de7d247-a4f98d23f8b2.vpn.azure.com
vpnserver=$(grep -oPm1 "(?<=<VpnServer>)[^<]+" "vpn-config/Generic/VpnSettings.xml")

cat <<EOT >>/etc/ipsec.conf

conn azure
      keyexchange=ikev2
      type=tunnel
      leftfirewall=yes
      left=%any
      leftauth=eap-tls
      leftid=%${USERNAME}
      right=$vpnserver
      rightid=%$vpnserver
      rightsubnet=0.0.0.0/0
      leftsourceip=%config
      auto=add
EOT

cat <<EOT >>/etc/ipsec.d/private/key-file

: P12 ${USERNAME}.p12 'the-password'

EOT

ipsec restart
ipsec up azure