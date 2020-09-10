#Requirements 
# Helm should be installed
helm repo add hashicorp https://helm.releases.hashicorp.com

# Using vault in development mode, we don't need to concern ourself with unsealing at this point.
helm install vault hashicorp/vault --set "server.dev.enabled=true"

#Enable kv-v2 secrets at path internal
kubectl exec -it vault-0 -- \
vault secrets enable -path=internal kv-v2

# Create secret at path
kubectl exec -it vault-0 -- \
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"


# Verify secret is defined 

kubectl exec -it vault-0 -- \
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"


# Configure Kubernetes Authentication
kubectl exec -it vault-0 -- \
vault auth enable kubernetes


# Configure kubernetes authentication method to use kubernetes service account token, location of kubernetes host and its ca certificate.

kubectl exec -it vault-0 -- \
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create a vault policy and give it read capabilities for database config

kubectl exec -it vault-0 -- \
vault policy write internal-app - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOF

# Create a Kubernetes authentication role named internal-app.

kubectl exec -it vault-0 -- \
vault write auth/kubernetes/role/internal-app \
    bound_service_account_names=internal-app \
    bound_service_account_namespaces=default \
    policies=internal-app \
    ttl=24h


#Create a kubernetes service account called internal-app

kubectl create serviceaccount internal-app


# Apply deployment specified in deployment-orgchart.yml

kubectl apply -f vault-agent-sidecar/deployment-orgchart.yml 


# Verify that no secrets are written to the orgchart container in the orgchart pod
# You should get "No such file or directory"

kubectl exec \
    $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
    --container orgchart -- ls /vault/secrets

# Inject the secret into the pod by patching the specfile - patch-inject-secrets-as-template.yml using templating.

kubectl patch deployment orgchart --patch "$(cat vault-agent-sidecar/patch-inject-secrets-as-template.yml)"


# Verify that secret is written to orgchart container in the orgchart pod

kubectl exec \
    $(kubectl get pod -l app=orgchart -o jsonpath="{.items[0].metadata.name}") \
    -c orgchart -- cat /vault/secrets/database-config.txt