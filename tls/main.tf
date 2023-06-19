resource "tls_private_key" "vpn_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vpn_ca" {
  private_key_pem = tls_private_key.vpn_ca.private_key_pem

  subject {
    common_name  = "VPN CA"
  }

  # 1 year
  validity_period_hours = 8760

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
  ]
}