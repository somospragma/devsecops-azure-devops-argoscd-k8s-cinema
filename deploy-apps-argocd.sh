#!/bin/bash

set -e

deploy_apps() {
  echo "📦 Desplegando aplicaciones de ArgoCD..."

  RELEASE_NAME="argocd-apps"
  CHART_PATH="./helm-charts/argocd-apps"
  VALUES_FILE="./helm-charts/argocd-apps/values-dev.yml"
  NAMESPACE="argocd"

  kubectl get namespace $NAMESPACE > /dev/null 2>&1 || kubectl create namespace $NAMESPACE

  echo "🚀 Desplegando Helm release '$RELEASE_NAME'..."
  helm upgrade --install $RELEASE_NAME $CHART_PATH -f $VALUES_FILE -n $NAMESPACE --create-namespace

  helm status $RELEASE_NAME -n $NAMESPACE
}

wait_for_ingress() {
  echo "⏳ Verificando disponibilidad del Ingress Controller..."
  for i in {1..30}; do
    READY=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller \
      -o jsonpath="{.items[0].status.containerStatuses[0].ready}" 2>/dev/null || echo "false")

    if [ "$READY" == "true" ]; then
      echo "✅ Ingress Controller listo."
      return
    fi

    echo "⌛ Esperando... ($i/30)"
    sleep 5
  done

  echo "⚠️ El Ingress Controller no se activó a tiempo. Verifica manualmente."
}

check_frontend_ready() {
  MINIKUBE_IP=$(minikube ip)
  FRONTEND_URL="http://$MINIKUBE_IP"

  echo "🌐 Esperando a que el frontend esté disponible..."
  for i in {1..12}; do
    if curl -s --head $FRONTEND_URL | grep "200 OK" > /dev/null; then
      echo "✅ Frontend disponible: $FRONTEND_URL"
      return
    fi
    echo "⌛ Esperando frontend... ($i/12)"
    sleep 5
  done

  echo "⚠️ Frontend aún no responde. Puede tardar un poco más."
}

print_summary() {
  echo "📦 Aplicaciones desplegadas:"
  argocd app list
  echo ""
  echo "🌐 Acceso al frontend de la aplicación:"
  echo "👉 URL: http://$(minikube ip)"
}

main() {
  deploy_apps
  wait_for_ingress
  check_frontend_ready
  print_summary
}

main