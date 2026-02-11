# Cloudflare DNS Record
resource "cloudflare_record" "wordpress" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  value   = aws_lb.main.dns_name
  type    = "CNAME"
  proxied = true

  comment = "WordPress site on AWS ECS"
}

# Cloudflare Page Rule for HTTPS redirect (optional)
resource "cloudflare_page_rule" "https_redirect" {
  zone_id  = var.cloudflare_zone_id
  target   = "${var.subdomain}.${var.domain_name}/*"
  priority = 1

  actions {
    always_use_https = true
  }
}

# Cloudflare Page Rule for caching
resource "cloudflare_page_rule" "cache_everything" {
  zone_id  = var.cloudflare_zone_id
  target   = "${var.subdomain}.${var.domain_name}/wp-content/*"
  priority = 2

  actions {
    cache_level = "cache_everything"
    edge_cache_ttl = 86400  # 24 hours
  }
}
