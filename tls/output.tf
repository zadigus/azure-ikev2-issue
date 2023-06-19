output "cert" {
  value = tls_self_signed_cert.vpn_ca.cert_pem
}

output "trimmed_cert" {
  value = replace(replace(tls_self_signed_cert.vpn_ca.cert_pem, "-----BEGIN CERTIFICATE-----", ""), "-----END CERTIFICATE-----", "")
}