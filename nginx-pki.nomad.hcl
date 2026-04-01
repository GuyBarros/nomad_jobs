variable "cert_ttl" {
  type = number
  default = 5
}
job "nginx" {
   datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "service"

  group "withvault" {
    count = 5

    vault {

    }
 network {
    port "http" {
        to = 80
    }
    port "https" {
        to = 443
    }
  }

    task "nginx-pki" {
      driver = "docker"

      config {
        # image = "nginx"
        image = "arm64v8/nginx"
         ports = ["http", "https"]
        
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf",
          "secret/cert.key:/etc/nginx/ssl/nginx.key",
        ]
      }

      template {
        data = <<EOH
          server {
            listen 80;
            listen 443 ssl;

            server_name nginx.service.consul;
            # note this is slightly wonky using the same file for
            # both the cert and key
            ssl_certificate /etc/nginx/ssl/nginx.key;
            ssl_certificate_key /etc/nginx/ssl/nginx.key;

            location / {
              root /local/data/;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      template {
        data = <<EOH
{{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=${var.cert_ttl}m" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
      EOH

        destination = "secret/cert.key"
      }

template {
  data = <<-EOH
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Nginx — {{ env "node.unique.name" }}</title>
      <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, -apple-system, sans-serif; background: #0f1117; color: #e2e8f0; padding: 2.5rem 2rem; min-height: 100vh; }
        .badge { display: inline-flex; align-items: center; gap: 6px; background: #1a2235; border: 0.5px solid #2d3a52; border-radius: 6px; padding: 4px 10px; font-size: 12px; color: #94a3b8; margin-bottom: 2rem; }
        .dot { width: 7px; height: 7px; border-radius: 50%; background: #22c55e; display: inline-block; }
        h1 { font-size: 28px; font-weight: 600; color: #f1f5f9; margin-bottom: 0.25rem; }
        .subtitle { color: #64748b; font-size: 14px; margin-bottom: 2rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin-bottom: 2rem; }
        .card { background: #1a2235; border: 0.5px solid #2d3a52; border-radius: 10px; padding: 1rem 1.25rem; }
        .card-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: #64748b; margin-bottom: 6px; }
        .card-value { font-size: 15px; font-weight: 500; color: #e2e8f0; word-break: break-all; }
        .card-value.mono { font-family: monospace; font-size: 13px; }
        .section { background: #1a2235; border: 0.5px solid #2d3a52; border-radius: 10px; padding: 1rem 1.25rem; margin-bottom: 12px; }
        .section-title { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: #64748b; display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
        .section-title::after { content: ''; flex: 1; height: 0.5px; background: #2d3a52; }
        .validity-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; margin-bottom: 14px; }
        .vcard { background: #111827; border: 0.5px solid #2d3a52; border-radius: 8px; padding: 0.75rem 1rem; }
        .vcard-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: #475569; margin-bottom: 4px; }
        .vcard-value { font-size: 13px; font-weight: 500; font-family: monospace; color: #94a3b8; }
        .progress-label { display: flex; justify-content: space-between; font-size: 11px; color: #475569; margin-bottom: 5px; }
        .progress-track { background: #111827; border-radius: 4px; height: 6px; overflow: hidden; }
        .progress-bar { height: 6px; border-radius: 4px; }
        .status-pill { display: inline-flex; align-items: center; border-radius: 20px; padding: 3px 10px; font-size: 12px; font-weight: 500; background: #1c2a1c; color: #4ade80; }
        .pki-label { font-size: 11px; color: #475569; margin-bottom: 4px; }
        pre { font-family: monospace; font-size: 11px; color: #94a3b8; line-height: 1.6; white-space: pre-wrap; word-break: break-all; margin-bottom: 12px; }
      </style>
    </head>
    <body>
      <div class="badge"><span class="dot"></span> nginx active</div>
      <h1>Hello World</h1>
      <p class="subtitle">Served by the Nomad allocation below</p>

      <div class="grid">
        <div class="card"><p class="card-label">Node</p><p class="card-value mono">{{ env "node.unique.name" }}</p></div>
        <div class="card"><p class="card-label">Instance</p><p class="card-value">Nginx #{{ env "NOMAD_ALLOC_INDEX" }}</p></div>
        <div class="card"><p class="card-label">Region</p><p class="card-value">{{ env "node.region" }}</p></div>
        <div class="card"><p class="card-label">Datacenter</p><p class="card-value">{{ env "node.datacenter" }}</p></div>
      </div>

      {{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=${var.cert_ttl}m" }}

      <div class="section">
        <p class="section-title">Certificate validity</p>
        <div class="validity-grid">
          <div class="vcard"><p class="vcard-label">Issued</p><p class="vcard-value" id="cert-issued">—</p></div>
          <div class="vcard"><p class="vcard-label">Expires</p><p class="vcard-value" id="cert-expiry">—</p></div>
          <div class="vcard"><p class="vcard-label">Time remaining</p><p class="vcard-value" id="cert-remaining">—</p></div>
          <div class="vcard" style="display:flex;flex-direction:column;justify-content:center;">
            <p class="vcard-label" style="margin-bottom:6px;">Status</p>
            <span class="status-pill" id="cert-status">valid</span>
          </div>
        </div>
        <div class="progress-label"><span>issued</span><span id="pct-label">—</span><span>expired</span></div>
        <div class="progress-track"><div class="progress-bar" id="progress-bar" style="width:0%;background:#22c55e;"></div></div>
      </div>

      <div class="section">
        <p class="section-title">TLS certificate</p>
        <p class="pki-label">Certificate</p>
        <pre>{{ .Data.certificate }}</pre>
        <p class="pki-label">Private key</p>
        <pre>{{ .Data.private_key }}</pre>
      </div>

      <script>
        (function() {
          var issuedTs = {{ .Data.expiration }} - (${var.cert_ttl} * 60);
          var expiryTs = {{ .Data.expiration }};

          function fmt(ts) {
            return new Date(ts*1000).toISOString().replace('T',' ').slice(0,19)+' UTC';
          }
          function fmtRemaining(ms) {
            if (ms<=0) return 'expired';
            var s=Math.floor(ms/1000), m=Math.floor(s/60), h=Math.floor(m/60);
            return h>0 ? h+'h '+(m%60)+'m' : m+'m '+(s%60)+'s';
          }
          function update() {
            var now=Math.floor(Date.now()/1000);
            var total=expiryTs-issuedTs, elapsed=now-issuedTs;
            var pct=Math.min(100,Math.max(0,Math.round(elapsed/total*100)));
            var remaining=(expiryTs-now)*1000;
            document.getElementById('cert-issued').textContent=fmt(issuedTs);
            document.getElementById('cert-expiry').textContent=fmt(expiryTs);
            document.getElementById('cert-remaining').textContent=fmtRemaining(remaining);
            document.getElementById('pct-label').textContent=pct+'% elapsed';
            document.getElementById('progress-bar').style.width=pct+'%';
            var bar=document.getElementById('progress-bar'), pill=document.getElementById('cert-status');
            if(remaining<=0){bar.style.background='#ef4444';pill.style.background='#2a1c1c';pill.style.color='#f87171';pill.textContent='expired';}
            else if(pct>=80){bar.style.background='#f59e0b';pill.style.background='#2a2010';pill.style.color='#fbbf24';pill.textContent='expiring soon';}
            else{bar.style.background='#22c55e';pill.style.background='#1c2a1c';pill.style.color='#4ade80';pill.textContent='valid';}
          }
          update();
          setInterval(update, 10000);
        })();
      </script>

      {{ end }}
    </body>
    </html>
  EOH

  destination = "local/data/nginx-pki/index.html"
}


      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        
      }

      service {
        name = "nginx-pki"
        port = "http"
        tags = [
          "global",
          "urlprefix-/nginx-pki",
          "traefik.enable=true",
          "traefik.http.routers.nginx-pki.rule=PathPrefix(`/nginx-pki`)",
          "traefik.http.services.nginx-pki.loadbalancer.sticky",
          "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto = https"
          ]
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

  }
}
