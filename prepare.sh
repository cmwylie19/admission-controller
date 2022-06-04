#!/usr/bin/env bash

# prepare.sh
#
# Sets up the environment for the admission controller webhook in the active cluster.

set -euo pipefail

basedir="$(pwd)/deployment"
keydir="$(pwd)/keys"

# Generate keys into a directory.
echo "Generating TLS keys ..."
"$basedir/k8s-tls-keys.sh" "$keydir"

echo Key dir: $keydir

# Create the `admission` namespace. This cannot be part of the YAML file as we first need to create the TLS secret,
# which would fail otherwise.
echo "Creating Kubernetes objects ..."
kubectl create namespace admission --dry-run=client -oyaml > k8s/ns.yaml

# Create the TLS secret for the generated keys.
kubectl create secret tls webhook-server-tls -n admission \
    --cert "${keydir}/webhook-server-tls.crt" \
    --key "${keydir}/webhook-server-tls.key" --dry-run=client -oyaml > k8s/secret-webhook-server-tls.yaml

# Read the PEM-encoded CA certificate, base64 encode it, and replace the `${CA_PEM_B64}` placeholder in the YAML
# template with it. Then, create the Kubernetes resources.
ca_pem_b64="$(openssl base64 -A <"${keydir}/ca.crt")"
sed -e 's@${CA_PEM_B64}@'"$ca_pem_b64"'@g' <"${basedir}/deployment.yaml.template" \
    | kubectl create --dry-run=client -oyaml -f - > k8s/admission-controller.yaml

# Delete the key directory to prevent abuse (DO NOT USE THESE KEYS ANYWHERE ELSE).
# rm -rf "$keydir"

echo "The webhook server is ready for deployment"
