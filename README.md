# 📦 Manifest K8s - GitOps Repository

**Repositorio GitOps** que contiene los manifiestos Kubernetes y Helm charts para el sistema Cinema.

## 🎬 Arquitectura Completa del Sistema Cinema

### 📁 Estructura de Repositorios

#### 🔧 Repositorios de Aplicación
- **`cinema-food/`** - Microservicio para gestión de comida y bebidas
- **`cinema-seats/`** - Microservicio para gestión de asientos y reservas
- **`cinema-app/`** - Aplicación web frontend del sistema cinema

#### 🚀 Repositorios de Infraestructura
- **`pipeline-templates-helm-argo/`** - Templates de pipelines CI/CD
- **`manifest-k8s/`** (ESTE REPO) - Repositorio GitOps con manifiestos Kubernetes (**ArgoCD monitorea este**)
- **`config-argocd-minikube/`** - Recursos para configurar ArgoCD y Minikube

### 🔄 Flujo GitOps

```
Pipelines CI/CD
    ↓ actualizan values-[env].yml
manifest-k8s (ESTE REPO)
    ↓ ArgoCD monitorea cambios
Kubernetes Cluster
    ↓ estado deseado definido en Git
GitOps Completo
```

**Este es el repositorio central que ArgoCD monitorea para mantener el cluster sincronizado.**

> 📖 **Ver [README Principal](../README.md)** para el diagrama completo y detalles de la arquitectura.

## 🏗️ Arquitectura del Proyecto



Este repositorio contiene los charts Helm utilizados para desplegar las diferentes componentes de la aplicación de cine en un clúster de Kubernetes.

## 🏛️ Arquitectura de los Charts

La estrategia de despliegue se basa en cuatro charts principales que separan las responsabilidades:

1.  **shared**: Provee la base de recursos comunes (Ingress, Namespaces, etc.).
2.  **cinema-app**: Despliega la aplicación Frontend.
3.  **cinema-seats**: Despliega el microservicio Backend para la gestión de asientos.
4.  **cinema-food**: Despliega el microservicio Backend para la gestión de alimentos.



## 🚀 Charts Disponibles

A continuación, se describe el propósito de cada chart:

### 1. `shared`

Este chart es fundamental, ya que se encarga de desplegar recursos y objetos de Kubernetes que son **compartidos** por todas las demás aplicaciones. Su propósito principal es establecer una base común (como reglas de Ingress, namespaces o cuentas de servicio) y evitar la duplicidad de configuraciones.

**Uso:** Este chart debe ser desplegado **antes** que los demás charts de la aplicación.

### 2. `cinema-app` (Frontend)

Este chart es responsable del despliegue y la gestión de la aplicación **frontend** del cine. Contiene todas las definiciones necesarias para que la interfaz de usuario esté operativa y accesible.

### 3. `cinema-seats` (Backend)

Este chart gestiona el despliegue del servicio **backend** encargado de la lógica relacionada con la selección y gestión de **asientos** en el cine.

### 4. `cinema-food` (Backend)

Este chart es responsable del despliegue del servicio **backend** que maneja la lógica de pedidos y gestión de **alimentos y bebidas** para el cine.

---

## 🌎 Gestión de Entornos

Cada chart de aplicación (`cinema-app`, `cinema-seats`, `cinema-food`) incluye archivos de valores específicos para cada entorno, lo que permite personalizar las configuraciones (como número de réplicas, límites de recursos o variables de entorno) sin modificar la plantilla base del chart.

* `values-dev.yaml`: Valores para el entorno de **Desarrollo**.
* `values-qa.yaml`: Valores para el entorno de **QA (Calidad)**.
* `values-prod.yaml`: Valores para el entorno de **Producción**.


## ⚙️ Despliegue (Flujo GitOps con Argo CD)

El despliegue de las aplicaciones está completamente automatizado siguiendo un modelo GitOps, utilizando **Argo CD** como herramienta de despliegue continuo.

Este repositorio actúa como el **repositorio de manifests (GitOps)**, que define el estado deseado de las aplicaciones en Kubernetes.



### 🔄 Flujo GitOps Automatizado

El proceso se divide en tres etapas claras:

**1. Pipeline de Aplicación (CI):**

* Cada microservicio ([cinema-app](../cinema-app/), [cinema-seats](../cinema-seats/), [cinema-food](../cinema-food/)) tiene su propio pipeline de Integración Continua (CI) en su respectivo repositorio de código.
* Cuando se aprueba un cambio (ej. un *merge* a `main`), este pipeline se ejecuta:
    * **a. Construye** la imagen Docker con un nuevo *tag* de versión (ej. `v1.2.4` o un hash de commit).
    * **b. Publica** la nueva imagen en Docker Hub (o el registro de contenedores).
    * **c. Usa templates** de [pipeline-templates-helm-argo](../pipeline-templates-helm-argo/) según el tipo de aplicación

**2. Actualización del Repositorio de Manifests (¡Este Repo!):**

* Inmediatamente después de publicar la imagen, el **mismo pipeline de CI** de la aplicación tiene la responsabilidad de actualizar el estado deseado:
    * **a. Clona** este repositorio (el repositorio de los Helm Charts / Manifests).
    * **b. Actualiza** el archivo de valores correspondiente (ej. `helm-charts/cinema-app/values-dev.yml`) cambiando el valor de `image.tag` por el nuevo *tag* recién publicado.
    * **c. Ejecuta** `git add`, `git commit -m "Bump cinema-app image to v1.2.4"` y `git push` para sincronizar el cambio de vuelta a este repositorio.

**3. Sincronización con Argo CD (Despliegue Continuo):**

* **a. Detección:** Argo CD (configurado desde [config-argocd-minikube](../config-argocd-minikube/)) está configurado para monitorear constantemente **este** repositorio de Helm charts.
* **b. Comparación:** En cuanto Argo CD detecta el nuevo *commit* (con el *tag* de imagen actualizado), lo compara con el estado actual del clúster de Kubernetes y detecta una diferencia.
* **c. Sincronización (Deploy):** Argo CD aplica automáticamente los cambios en el clúster para que coincida con el estado definido en Git. Esto provoca que Kubernetes inicie un despliegue controlado (*rolling update*) de la aplicación correspondiente, descargando la nueva imagen y reemplazando los pods antiguos.

## 📋 Repositorios Relacionados

- **[Cinema App](../cinema-app/)** - Frontend Angular (actualiza cinema-app/values-[env].yml)
- **[Cinema Food](../cinema-food/)** - Microservicio backend (actualiza cinema-food/values-[env].yml)
- **[Cinema Seats](../cinema-seats/)** - Microservicio backend (actualiza cinema-seats/values-[env].yml)
- **[Pipeline Templates](../pipeline-templates-helm-argo/)** - Templates que actualizan este repo
- **[Config ArgoCD](../config-argocd-minikube/)** - Configuración de ArgoCD que monitorea este repo


