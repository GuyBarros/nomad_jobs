vault write auth/jwt-nomad/config \
  jwks_url="$NOMAD_ADDR/.well-known/jwks.json" \
  jwt_supported_algs=RS256,EdDSA \
  default_role=nomad-workloads

vault write nomad/config/access address=$NOMAD_ADDR token=$NOMAD_TOKEN  # optional, fixes the Nomad secrets engine
