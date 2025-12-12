#!/bin/bash

set -e

start_minikube() {
  echo "🚀 Iniciando Minikube..."
  minikube start
}

enable_addons() {
  echo "✅ Habilitando addons: ingress y metrics-server..."
  minikube addons enable ingress
  minikube addons enable metrics-server
}

install_argocd() {
  echo "📁 Creando namespace argocd..."
  kubectl create namespace argocd || echo "Namespace ya existe"

  echo "📦 Instalando ArgoCD con Helm..."
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  helm install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=NodePort

  echo "⏳ Esperando a que los pods de ArgoCD estén listos..."
  kubectl wait --for=condition=available --timeout=180s -n argocd deployment/argocd-server
}

login_argocd() {
  echo "🔐 Obteniendo password de ArgoCD..."
  ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)

  echo "🌐 Obteniendo URL del servicio ArgoCD..."
  ARGOCD_URL=$(minikube service argocd-server -n argocd --url | head -n1 | sed 's|http://||')

  echo "📡 Logueando a ArgoCD CLI..."
  argocd login $ARGOCD_URL --username admin --password $ARGOCD_PWD --insecure
}

register_cluster_and_repo() {
  echo "🔗 Registrando el clúster Minikube..."
  argocd cluster add minikube --yes

  echo "🔁 Agregando repositorio azure a ArgoCD..."
  argocd repo add git@ssh.dev.azure.com:v3/johanmaury/Inicio%20DevOps%20Johan/manifest-k8s \
    --ssh-private-key-path ~/.ssh/id_rsa_azure \
    --name azure-repo
}

install_prometheus_stack() {
  echo "📁 Creando namespace monitoring..."
  kubectl create namespace monitoring || echo "Namespace monitoring ya existe"
  echo "Agregando repositorios de Helm..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  echo "Instalando kube-prometheus-stack..."
  helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

  echo "Esperando a que Prometheus esté listo..."
  kubectl wait --for=condition=Ready pod --all -n monitoring --timeout=300s
}

print_summary() {
  echo ""
  echo "✅ Todo listo. ArgoCD instalado, clúster registrado, repo sincronizado y apps desplegadas 💥"
  echo "🌐 URL de ArgoCD: $ARGOCD_URL"
  echo "👤 Usuario: admin"
  echo "🔑 Password: $ARGOCD_PWD"
}

main() {
  start_minikube
  enable_addons
  install_argocd
  login_argocd
  register_cluster_and_repo
  install_prometheus_stack
  print_summary
}

main
