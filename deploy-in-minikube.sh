#!/bin/bash

# Prompt the user for their GitHub token
read -p "Enter your GitHub token: " GITHUB_TOKEN
read -p "Enter your GitHub auth cliend ID: " AUTH_GITHUB_CLIENT_ID
read -p "Enter your GitHub auth client secret: " AUTH_GITHUB_CLIENT_SECRET
# read -p "What image tag should be used for Backstage deployment?: " IMAGE_TAG

# Start cluster. Extra beefy beause Backstage is a bit heavy.
minikube start --cpus 4 --memory 4096

# Install ArgoCD
helm install argocd -n argocd helm-charts/infra/argo-cd --values helm-charts/infra/argo-cd/values-custom.yaml --dependency-update --create-namespace

# Get ArgoCD admin password
until kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; do
  echo "Waiting for secret 'argocd-initial-admin-secret' to be available..."
  sleep 3
done
echo "#############################################################################"
echo "#############################################################################"
echo "#############################################################################"
echo " "
echo "TO ACCESS THE ARGOCD DASHBOARD, RUN THE FOLLOWING COMMAND:"
echo "kubectl port-forward svc/argocd-server -n argocd 8081:443"
echo " "
echo "user: admin"
echo "password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo " "
echo "#############################################################################"
echo "#############################################################################"
echo "#############################################################################"

# Then we create an application that will monitor the helm-charts/infra/argo-cd directory, the same we used to deploy ArgoCD, making ArgoCD self-managed. Any changes we apply in the helm/infra/argocd directory will be automatically applied.
kubectl create -n argocd -f argo-cd/self-manage/argocd-application.yaml  

# Finally, we create an application that will automatically deploy any ArgoCD Applications we specify in the argo-cd/applications directory (App of Apps pattern).
kubectl create -n argocd -f argo-cd/self-manage/argocd-app-of-apps-application.yaml  

# This is for the ArgoCD plugin. We need to get the ArgoCD token for the Backstage service account
# We expose argocd on port 8081 in the background so we can then login to get the token
kubectl port-forward -n argocd service/argocd-server 8081:443 &
sleep 10
argocd login localhost:8081 --plaintext --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
sleep 10
export BACKSTAGE_SERVICEACCOUNT_ARGOCD_TOKEN=$(argocd account generate-token --account backstage-service-account)
# echo "BACKSTAGE_SERVICEACCOUNT_ARGOCD_TOKEN=$BACKSTAGE_SERVICEACCOUNT_ARGOCD_TOKEN"
export ARGOCD_AUTH_TOKEN="argocd.token=$BACKSTAGE_SERVICEACCOUNT_ARGOCD_TOKEN"
echo "#############################################################################"
echo "#############################################################################"
echo "#############################################################################"
echo " "
echo "ARGOCD_AUTH_TOKEN=$ARGOCD_AUTH_TOKEN"
echo " "
echo "#############################################################################"
echo "#############################################################################"
echo "#############################################################################"

# We create the secret for every require env var. This way the secrets won't get pushed to Github.
kubectl create ns backstage
kubectl create secret generic github-token -n backstage --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN"
kubectl create secret generic auth-github-client-id -n backstage --from-literal=AUTH_GITHUB_CLIENT_ID="$AUTH_GITHUB_CLIENT_ID"
kubectl create secret generic auth-github-client-secret -n backstage --from-literal=AUTH_GITHUB_CLIENT_SECRET="$AUTH_GITHUB_CLIENT_SECRET"
kubectl create secret generic argocd-auth-token -n backstage --from-literal=ARGOCD_AUTH_TOKEN="$ARGOCD_AUTH_TOKEN"

# Wait for the Postgres pod to be ready
echo "Waiting for postgres pod to be ready..."
until [[ $(kubectl -n backstage get pods -l "app.kubernetes.io/name=postgresql" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == "True" ]]; do
  echo "Waiting for postgres pod to be ready... It's required for backstage to start."
  sleep 3
done

# Wait for the Backstage pod to be ready
echo "Waiting for backstage pod to be ready..."
until [[ $(kubectl -n backstage get pods -l "app.kubernetes.io/name=backstage" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') == "True" ]]; do
  echo "Waiting for backstage pod to be ready..."
  sleep 3
done

# Port forward the Backstage service
kubectl port-forward -n backstage service/backstage 8080:7007