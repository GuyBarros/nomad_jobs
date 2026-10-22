variable "cert_ttl" {
  type    = number
  default = 5
}

job "febraban2026" {
  datacenters = ["eu-west-2a", "eu-west-2b", "eu-west-2c", "eu-west-2"]
  type        = "service"

  group "withvault" {
    count = 5

    vault {}

    # This Vault deployment doesn't expose its version on the unauthenticated
    # health endpoint, so Nomad's default vault.version fingerprint is never
    # set on any client. Override the implicit "semver >= 0.6.1" placement
    # constraint Nomad adds for jobs with a vault{} stanza.
    constraint {
      attribute = "${attr.vault.version}"
      operator  = "is_not_set"
    }

    network {
      port "http" {
        to = 80
      }
      port "https" {
        to = 443
      }
    }

    task "febraban2026-nginx" {
      driver = "docker"

      config {
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

            server_name febraban2026.service.consul;

            ssl_certificate     /etc/nginx/ssl/nginx.key;
            ssl_certificate_key /etc/nginx/ssl/nginx.key;

            location / {
              root /local/data/;
            }

            location /febraban2026/ {
              alias /local/data/febraban2026/;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      template {
        data = <<EOH
{{ with secret "pki/issue/consul-service" "common_name=febraban2026.service.consul" "ttl=${var.cert_ttl}m" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
        EOH

        destination = "secret/cert.key"
      }

      template {
        data = <<-EOH
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Febraban 2026 — {{ env "node.unique.name" }}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    /* ── Febraban 2026 palette ─────────────────────────────────────────── */
    :root {
      --feb-blue:    #003087;   /* deep institutional blue                 */
      --feb-gold:    #E8B84B;   /* accent gold                             */
      --feb-light:   #F0F4FA;   /* page background                        */
      --feb-surface: #FFFFFF;   /* card background                        */
      --feb-border:  #C9D5E8;   /* border                                 */
      --feb-text:    #1A2744;   /* body text                              */
      --feb-muted:   #5A6E96;   /* secondary text                         */
      --feb-green:   #1A7F4E;   /* valid pill                             */
    }

    body {
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
      background: var(--feb-light);
      color: var(--feb-text);
      min-height: 100vh;
      padding: 0;
    }

    /* ── Header bar ────────────────────────────────────────────────────── */
    header {
      background: var(--feb-blue);
      color: #fff;
      padding: 0 2rem;
      display: flex;
      align-items: center;
      gap: 1rem;
      height: 64px;
      border-bottom: 3px solid var(--feb-gold);
    }
    .header-logo {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #fff;
    }
    .header-logo span { color: var(--feb-gold); }
    .header-sub {
      font-size: 12px;
      color: rgba(255,255,255,0.65);
      border-left: 1px solid rgba(255,255,255,0.25);
      padding-left: 1rem;
      margin-left: 0.25rem;
    }
    .header-badge {
      margin-left: auto;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(255,255,255,0.1);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 20px;
      padding: 4px 12px;
      font-size: 12px;
      color: rgba(255,255,255,0.85);
    }
    .dot { width: 7px; height: 7px; border-radius: 50%; background: #4ade80; display: inline-block; }

    /* ── Main content ──────────────────────────────────────────────────── */
    main { max-width: 900px; margin: 0 auto; padding: 2rem 1.5rem; }

    h1 { font-size: 26px; font-weight: 700; color: var(--feb-blue); margin-bottom: 0.2rem; }
    .subtitle { color: var(--feb-muted); font-size: 14px; margin-bottom: 2rem; }

    /* ── Info grid ─────────────────────────────────────────────────────── */
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin-bottom: 2rem; }
    .card {
      background: var(--feb-surface);
      border: 1px solid var(--feb-border);
      border-top: 3px solid var(--feb-blue);
      border-radius: 8px;
      padding: 0.9rem 1.1rem;
    }
    .card-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--feb-muted); margin-bottom: 5px; }
    .card-value { font-size: 14px; font-weight: 600; color: var(--feb-text); word-break: break-all; }
    .card-value.mono { font-family: monospace; font-size: 12px; }

    /* ── Section panels ────────────────────────────────────────────────── */
    .section {
      background: var(--feb-surface);
      border: 1px solid var(--feb-border);
      border-radius: 10px;
      padding: 1.2rem 1.4rem;
      margin-bottom: 16px;
    }
    .section-title {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--feb-muted);
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 12px;
      font-weight: 600;
    }
    .section-title::after { content: ''; flex: 1; height: 1px; background: var(--feb-border); }

    /* ── Vault overview GIF ────────────────────────────────────────────── */
    .vault-overview {
      width: 100%;
      border-radius: 8px;
      border: 1px solid var(--feb-border);
      overflow: hidden;
      background: #fff;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 1rem;
    }
    .vault-overview svg { width: 100%; max-width: 780px; height: auto; }

    /* ── Certificate validity ──────────────────────────────────────────── */
    .validity-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; margin-bottom: 14px; }
    .vcard {
      background: var(--feb-light);
      border: 1px solid var(--feb-border);
      border-radius: 8px;
      padding: 0.7rem 1rem;
    }
    .vcard-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--feb-muted); margin-bottom: 4px; }
    .vcard-value { font-size: 13px; font-weight: 500; font-family: monospace; color: var(--feb-text); }
    .progress-label { display: flex; justify-content: space-between; font-size: 11px; color: var(--feb-muted); margin-bottom: 5px; }
    .progress-track { background: var(--feb-light); border: 1px solid var(--feb-border); border-radius: 4px; height: 8px; overflow: hidden; }
    .progress-bar { height: 8px; border-radius: 4px; background: var(--feb-green); }
    .status-pill { display: inline-flex; align-items: center; border-radius: 20px; padding: 3px 10px; font-size: 12px; font-weight: 600; background: #e6f4ee; color: var(--feb-green); border: 1px solid #b2ddc8; }

    /* ── Cert PEM blocks ───────────────────────────────────────────────── */
    .pki-label { font-size: 11px; color: var(--feb-muted); margin-bottom: 4px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em; }
    pre { font-family: monospace; font-size: 11px; color: var(--feb-muted); line-height: 1.6; white-space: pre-wrap; word-break: break-all; margin-bottom: 12px; background: var(--feb-light); border-radius: 6px; padding: 0.75rem 1rem; border: 1px solid var(--feb-border); }

    /* ── Footer ────────────────────────────────────────────────────────── */
    footer {
      text-align: center;
      padding: 1.5rem;
      font-size: 11px;
      color: var(--feb-muted);
      border-top: 1px solid var(--feb-border);
      margin-top: 1rem;
    }
  </style>
</head>
<body>

  <header>
    <div class="header-logo">Feb<span>raban</span> <span>2026</span></div>
    <div class="header-sub">HashiCorp Vault PKI Demo · Nomad</div>
    <div class="header-badge"><span class="dot"></span> nginx active</div>
  </header>

  <main>
    <h1>Vault PKI — Certificate Lifecycle</h1>
    <p class="subtitle">Serving allocation on node {{ env "node.unique.name" }} &mdash; certificates issued and rotated automatically by HashiCorp Vault.</p>

    <div class="grid">
      <div class="card"><p class="card-label">Node</p><p class="card-value mono">{{ env "node.unique.name" }}</p></div>
      <div class="card"><p class="card-label">Instance</p><p class="card-value">Nginx #{{ env "NOMAD_ALLOC_INDEX" }}</p></div>
      <div class="card"><p class="card-label">Region</p><p class="card-value">{{ env "node.region" }}</p></div>
      <div class="card"><p class="card-label">Datacenter</p><p class="card-value">{{ env "node.datacenter" }}</p></div>
      <div class="card"><p class="card-label">TTL</p><p class="card-value">${var.cert_ttl} min</p></div>
    </div>

    <!-- ── Vault PKI animated overview ──────────────────────────────── -->
    <div class="section">
      <p class="section-title">How Vault PKI works</p>
      <div class="vault-overview">
        <!--
          Inline animated SVG — illustrates the Vault PKI flow:
          Nomad task → Vault Agent → Vault PKI secrets engine → TLS cert → Nginx
          Each step fades in sequentially to simulate a GIF walkthrough.
        -->
        <svg viewBox="0 0 780 320" xmlns="http://www.w3.org/2000/svg"
             role="img" aria-label="Vault PKI certificate flow diagram">
          <defs>
            <style>
              .box { rx: 8; ry: 8; fill: #fff; stroke: #C9D5E8; stroke-width: 1.5; }
              .box-blue { fill: #003087; stroke: #003087; }
              .box-gold { fill: #E8B84B; stroke: #c9942e; }
              .box-green { fill: #1A7F4E; stroke: #155e3a; }
              .lbl { font-family: system-ui, sans-serif; font-size: 13px; font-weight: 600; fill: #1A2744; text-anchor: middle; }
              .lbl-white { fill: #fff; }
              .sub { font-family: system-ui, sans-serif; font-size: 10px; fill: #5A6E96; text-anchor: middle; }
              .sub-white { fill: rgba(255,255,255,0.75); }
              .arrow { stroke: #003087; stroke-width: 2; fill: none; marker-end: url(#ah); }
              .arrow-gold { stroke: #E8B84B; stroke-width: 2; fill: none; marker-end: url(#ahg); }
              .step-label { font-family: system-ui, sans-serif; font-size: 10px; fill: #5A6E96; text-anchor: middle; }

              /* sequential fade-in animation */
              .a0 { animation: fi 0.5s 0.2s both; }
              .a1 { animation: fi 0.5s 1.0s both; }
              .a2 { animation: fi 0.5s 1.8s both; }
              .a3 { animation: fi 0.5s 2.6s both; }
              .a4 { animation: fi 0.5s 3.4s both; }
              .a5 { animation: fi 0.5s 4.2s both; }
              .a6 { animation: fi 0.5s 5.0s both; }
              .a7 { animation: fi 0.5s 5.8s both; }
              /* loop: restart animation every 9 s */
              @keyframes fi { from { opacity: 0; } to { opacity: 1; } }
            </style>
            <marker id="ah" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
              <path d="M0,0 L0,6 L8,3 z" fill="#003087"/>
            </marker>
            <marker id="ahg" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
              <path d="M0,0 L0,6 L8,3 z" fill="#E8B84B"/>
            </marker>
          </defs>

          <!-- ① Nomad task -->
          <g class="a0">
            <rect class="box box-blue" x="20" y="120" width="120" height="64"/>
            <text class="lbl lbl-white" x="80" y="147">Nomad</text>
            <text class="sub sub-white" x="80" y="163">Task / Alloc</text>
            <text class="step-label" x="80" y="202">① Request cert</text>
          </g>

          <!-- arrow 1→2 -->
          <g class="a1">
            <line class="arrow" x1="140" y1="152" x2="192" y2="152"/>
            <text class="step-label" x="166" y="144">lease</text>
          </g>

          <!-- ② Vault Agent (sidecar) -->
          <g class="a2">
            <rect class="box" x="200" y="120" width="130" height="64"/>
            <text class="lbl" x="265" y="147">Vault Agent</text>
            <text class="sub" x="265" y="163">Auto-auth sidecar</text>
            <text class="step-label" x="265" y="202">② Authenticate</text>
          </g>

          <!-- arrow 2→3 -->
          <g class="a3">
            <line class="arrow" x1="330" y1="152" x2="382" y2="152"/>
            <text class="step-label" x="356" y="144">issue</text>
          </g>

          <!-- ③ Vault Server -->
          <g class="a4">
            <rect class="box box-blue" x="390" y="80" width="130" height="150"/>
            <text class="lbl lbl-white" x="455" y="108">Vault</text>
            <text class="sub sub-white" x="455" y="124">PKI Secrets Engine</text>
            <!-- CA icon hint -->
            <rect x="420" y="136" width="70" height="40" rx="5" fill="rgba(255,255,255,0.12)" stroke="rgba(255,255,255,0.3)" stroke-width="1"/>
            <text class="lbl lbl-white" x="455" y="158" font-size="11">Root CA</text>
            <text class="sub sub-white" x="455" y="172" font-size="10">Intermediate CA</text>
            <text class="step-label" x="455" y="244">③ Sign &amp; issue cert</text>
          </g>

          <!-- arrow 3→4 (cert back) -->
          <g class="a5">
            <path class="arrow-gold" d="M390,165 Q365,220 330,220 L200,220"/>
            <text class="step-label" x="300" y="240">④ cert + key</text>
          </g>

          <!-- ④ Template rendered -->
          <g class="a6">
            <rect class="box box-gold" x="20" y="240" width="160" height="56"/>
            <text class="lbl" x="100" y="263" fill="#1A2744">Template</text>
            <text class="sub" x="100" y="279" fill="#5A6E96">secret/cert.key</text>
          </g>

          <!-- arrow 4→5 -->
          <g class="a6">
            <line class="arrow" x1="180" y1="268" x2="232" y2="268"/>
          </g>

          <!-- ⑤ Nginx -->
          <g class="a7">
            <rect class="box box-green" x="240" y="240" width="120" height="56"/>
            <text class="lbl lbl-white" x="300" y="263">Nginx</text>
            <text class="sub sub-white" x="300" y="279">TLS termination</text>
            <text class="step-label" x="300" y="312">⑤ Serve HTTPS</text>
          </g>

          <!-- Renewal loop hint -->
          <g class="a7">
            <path d="M520,155 Q620,155 630,80 Q640,20 530,20 Q430,20 430,80" stroke="#E8B84B" stroke-width="1.5" stroke-dasharray="5,4" fill="none"/>
            <text font-family="system-ui,sans-serif" font-size="10" fill="#E8B84B" x="540" y="16">Auto-renew at 95% TTL</text>
          </g>
        </svg>
      </div>
    </div>
    <!-- ── end Vault PKI overview ──────────────────────────────────── -->

    {{ with secret "pki/issue/consul-service" "common_name=febraban2026.service.consul" "ttl=${var.cert_ttl}m" }}

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
      <div class="progress-track"><div class="progress-bar" id="progress-bar"></div></div>
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
          if (ms<=0) return 'expirado';
          var s=Math.floor(ms/1000), m=Math.floor(s/60), h=Math.floor(m/60);
          return h>0 ? h+'h '+(m%60)+'m' : m+'m '+(s%60)+'s';
        }
        var reloadAt = (issuedTs + (expiryTs - issuedTs) * 0.95) * 1000;
        setTimeout(function(){ window.location.reload(); }, Math.max(0, reloadAt - Date.now()));

        function update() {
          var now=Math.floor(Date.now()/1000);
          var total=expiryTs-issuedTs, elapsed=now-issuedTs;
          var pct=Math.min(100,Math.max(0,Math.round(elapsed/total*100)));
          var remaining=(expiryTs-now)*1000;
          document.getElementById('cert-issued').textContent=fmt(issuedTs);
          document.getElementById('cert-expiry').textContent=fmt(expiryTs);
          document.getElementById('cert-remaining').textContent=fmtRemaining(remaining);
          document.getElementById('pct-label').textContent=pct+'% decorrido';
          document.getElementById('progress-bar').style.width=pct+'%';
          var bar=document.getElementById('progress-bar'), pill=document.getElementById('cert-status');
          if(remaining<=0){
            bar.style.background='#dc2626';pill.style.background='#fef2f2';
            pill.style.color='#dc2626';pill.textContent='expirado';window.location.reload();
          } else if(pct>=80){
            bar.style.background='#d97706';pill.style.background='#fffbeb';
            pill.style.color='#d97706';pill.textContent='expirando';
          } else {
            bar.style.background='#1A7F4E';pill.style.background='#e6f4ee';
            pill.style.color='#1A7F4E';pill.textContent='válido';
          }
        }
        update();
        setInterval(update, 10000);
      })();
    </script>

    {{ end }}
  </main>

  <footer>
    Febraban 2026 &mdash; HashiCorp Vault PKI Demo &middot; Powered by Nomad
  </footer>

</body>
</html>
        EOH

        destination = "local/data/febraban2026/index.html"
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "febraban2026"
        port = "http"
        tags = [
          "global",
          "urlprefix-/febraban2026",
          "traefik.enable=true",
          "traefik.http.routers.febraban2026.rule=PathPrefix(`/febraban2026`)",
          "traefik.http.services.febraban2026.loadbalancer.sticky",
          "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto = https",
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
