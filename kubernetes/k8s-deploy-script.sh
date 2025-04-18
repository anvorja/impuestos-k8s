#!/bin/bash

# Script para desplegar la aplicación en Kubernetes
# Autor: [Tu nombre]
# Fecha: $(date +"%d-%m-%Y")

echo "==== Sistema de Impuestos - Despliegue en Kubernetes ===="
echo "Este script desplegará todos los componentes en un clúster de Kubernetes"

# Función para verificar errores
check_error() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1"
    exit 1
  fi
}

# Verificar prerequisitos
command -v kubectl >/dev/null 2>&1 || { echo "Se requiere kubectl. Por favor, instálalo."; exit 1; }

# Determinar el entorno (desarrollo o producción)
if [ "$1" == "prod" ]; then
  ENVIRONMENT="producción"
  K8S_CONTEXT="minikube" # Cambiar por tu contexto de producción
else
  ENVIRONMENT="desarrollo"
  K8S_CONTEXT="minikube" # Contexto para desarrollo local
fi

echo "Desplegando en entorno de $ENVIRONMENT usando contexto $K8S_CONTEXT"

# Cambiar al contexto correcto
kubectl config use-context $K8S_CONTEXT
check_error "Error al cambiar al contexto $K8S_CONTEXT"

# Crear imágenes de Docker y cargarlas en Minikube (solo para desarrollo)
if [ "$1" != "prod" ]; then
  echo "=== Construyendo y cargando imágenes en Minikube ==="
  
  # Asegurarse de usar Docker de Minikube
  eval $(minikube docker-env)
  check_error "Error al configurar entorno Docker de Minikube"
  
  # Construir imágenes
  echo "Construyendo API Gateway..."
  docker build -t api-gateway:latest ./api-gateway
  check_error "Error al construir API Gateway"
  
  echo "Construyendo Portal Impuestos..."
  docker build -t portal-impuestos:latest ./portal_impuestos
  check_error "Error al construir Portal Impuestos"
  
  echo "Construyendo Impuesto Vehicular Frontend..."
  docker build -t impuesto-vehicular-frontend:latest ./impuesto-vehicular/frontend
  check_error "Error al construir Impuesto Vehicular Frontend"
  
  echo "Construyendo Impuesto Vehicular Backend..."
  docker build -t impuesto-vehicular-backend:latest ./impuesto-vehicular/backend
  check_error "Error al construir Impuesto Vehicular Backend"
  
  echo "Construyendo Impuesto Predial..."
  docker build -t impuesto-predial-app:latest ./predial_cata
  check_error "Error al construir Impuesto Predial"
  
  echo "Construyendo Impuesto Consumo..."
  docker build -t impuesto-consumo-app:latest ./impuestoConsumo
  check_error "Error al construir Impuesto Consumo"
  
  echo "Construyendo Impuesto Ganado Mayor..."
  docker build -t impuesto-ganado-app:latest ./ganadoMayor
  check_error "Error al construir Impuesto Ganado Mayor"
fi

# Aplicar configuraciones de Kubernetes
echo "=== Aplicando configuraciones de Kubernetes ==="

echo "Creando namespace..."
kubectl apply -f kubernetes/namespace.yaml
check_error "Error al crear namespace"

echo "Aplicando secrets..."
kubectl apply -f kubernetes/secrets.yaml
check_error "Error al aplicar secrets"

echo "Aplicando configmaps..."
kubectl apply -f kubernetes/configmap.yaml
check_error "Error al aplicar configmaps"

echo "Aplicando persistent volume claims..."
kubectl apply -f kubernetes/persistent-volume-claims.yaml
check_error "Error al aplicar persistent volume claims"

echo "Desplegando API Gateway..."
kubectl apply -f kubernetes/api-gateway.yaml
check_error "Error al desplegar API Gateway"

echo "Desplegando Portal Impuestos..."
kubectl apply -f kubernetes/portal-impuestos.yaml
check_error "Error al desplegar Portal Impuestos"

echo "Desplegando Impuesto Vehicular..."
kubectl apply -f kubernetes/impuesto-vehicular.yaml
check_error "Error al desplegar Impuesto Vehicular"

echo "Desplegando otros impuestos..."
kubectl apply -f kubernetes/otros-impuestos.yaml
check_error "Error al desplegar otros impuestos"

echo "Configurando Ingress..."
kubectl apply -f kubernetes/ingress.yaml
check_error "Error al configurar Ingress"

# Esperar a que todos los pods estén listos
echo "Esperando a que todos los pods estén listos..."
kubectl wait --for=condition=ready pod --all -n impuestos-system --timeout=300s
check_error "Error al esperar que los pods estén listos"

# Obtener información de acceso
if [ "$1" == "prod" ]; then
  echo "Sistema desplegado en producción."
  echo "Verifique la URL de acceso definida en su DNS."
else
  # Para Minikube, mostrar cómo acceder
  echo "Sistema desplegado en Minikube."
  echo "Para acceder al sistema, ejecute los siguientes comandos:"
  echo ""
  echo "# Habilitar ingress en Minikube (si no está habilitado)"
  echo "minikube addons enable ingress"
  echo ""
  echo "# Obtener la IP de Minikube"
  echo "minikube ip"
  echo ""
  echo "# Agregar la entrada en /etc/hosts"
  echo "echo \"$(minikube ip) impuestos.local\" | sudo tee -a /etc/hosts"
  echo ""
  echo "Luego podrá acceder a:"
  echo "- Portal principal: http://impuestos.local"
  echo "- API Gateway: http://impuestos.local/api"
  echo "- Impuesto Vehicular: http://impuestos.local/vehicular"
  echo "- Impuesto Predial: http://impuestos.local/predial"
  echo "- Impuesto Consumo: http://impuestos.local/consumo"
  echo "- Impuesto Ganado Mayor: http://impuestos.local/ganado"
fi

echo "==== Despliegue completado ===="
