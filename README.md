# 🚀 Config ArgoCD Minikube

**Repositorio de Configuración** para levantar un entorno de desarrollo local completo con Minikube y ArgoCD.

## 🎬 Arquitectura Completa del Sistema Cinema

### 📁 Estructura de Repositorios

#### 🔧 Repositorios de Aplicación
- **`cinema-food/`** - Microservicio para gestión de comida y bebidas
- **`cinema-seats/`** - Microservicio para gestión de asientos y reservas
- **`cinema-app/`** - Aplicación web frontend del sistema cinema

#### 🚀 Repositorios de Infraestructura
- **`pipeline-templates-helm-argo/`** - Templates de pipelines CI/CD
- **`manifest-k8s/`** - Repositorio GitOps con manifiestos Kubernetes (**ArgoCD monitorea este**)
- **`config-argocd-minikube/`** (ESTE REPO) - Recursos para configurar ArgoCD y Minikube

### 🔄 Flujo GitOps

```
config-argocd-minikube (ESTE REPO)
    ↓ configura y conecta
ArgoCD + Minikube
    ↓ monitorea
manifest-k8s/
    ↓ despliega
cinema-app + cinema-food + cinema-seats
```

**Este repositorio es el punto de entrada para configurar todo el entorno GitOps local.**

> 📖 **Ver [README Principal](../README.md)** para el diagrama completo y detalles de la arquitectura.

## 🏗️ Arquitectura del Proyecto



Este repositorio contiene los scripts de *bootstrap* para levantar un entorno de desarrollo local completo en Minikube.

El objetivo es preparar un clúster de Kubernetes local, instalar las herramientas de GitOps (Argo CD) y monitoreo (Prometheus), y conectarlo todo al repositorio central de manifests ([manifest-k8s](../manifest-k8s/)) que cada usuario tenga.

## 📋 Prerrequisitos

Antes de ejecutar el script, asegúrate de tener instaladas las siguientes herramientas en tu máquina:

* **Minikube:** Para crear el clúster local.
* **kubectl:** Para interactuar con el clúster.
* **Helm:** Para instalar paquetes (Argo CD, Prometheus).
* **Argo CD CLI:** Para registrar el clúster y el repositorio.
* **Git:** Para clonar este repositorio.

---

## ⚡ Paso 1: Instalación del Entorno Base (`minikube-start.sh`)

1.  Clona este repositorio:
    ```bash
    git clone <url-de-este-repositorio>
    cd <nombre-del-repositorio>
    ```

2.  **[¡IMPORTANTE!] Configura tu Repositorio de Manifests:**
    Antes de ejecutar el script, debes editar el archivo `minikube-start.sh`.
    
    Busca la función `register_cluster_and_repo` (Paso 5) y **modifica** dos líneas:
    
    * `argocd repo add ...`: Cambia la URL `git@ssh.dev.azure.com:v3/johanmaury/Inicio%20DevOps%20Johan/manifest-k8s` por la **URL SSH de tu propio repositorio [manifest-k8s](../manifest-k8s/)**.
    * `--ssh-private-key-path`: Asegúrate de que apunte a la **ubicación de tu clave SSH** (`~/.ssh/id_rsa_azure` o la que corresponda) que tenga acceso a *tu* repositorio.

3.  Dale permisos de ejecución al script:
    ```bash
    chmod +x minikube-start.sh
    ```

4.  Ejecuta el script:
    ```bash
    ./minikube-start.sh
    ```

El script se encargará de todo el proceso de forma automática y te mostrará un resumen al final.

---

## 🛠️ ¿Qué hace el script `minikube-start.sh`? (Paso a Paso)

El script automatiza toda la configuración del entorno local ejecutando las siguientes funciones:

### 1. `start_minikube`
Inicia el clúster de Minikube.

### 2. `enable_addons`
Activa dos addons esenciales de Minikube:
* **ingress:** Permite exponer servicios través de un Ingress Controller.
* **metrics-server:** Necesario para el autoscalado (HPA) y para comandos como `kubectl top nodes/pods`.

### 3. `install_argocd`
Instala Argo CD, la herramienta central de nuestra estrategia GitOps:
* Crea el namespace `argocd`.
* Usa Helm para instalar el chart oficial de `argo/argo-cd`.
* Configura el servicio de la interfaz web (`argocd-server`) como `NodePort` para poder acceder a él fácilmente desde el navegador.

### 4. `login_argocd`
Prepara el CLI de Argo CD para poder interactuar con la instalación:
* Obtiene la contraseña inicial de administrador (guardada en el secret `argocd-initial-admin-secret`).
* Obtiene la URL de acceso a la interfaz web (usando `minikube service`).
* Ejecuta `argocd login` para autenticar el CLI.

### 5. `register_cluster_and_repo`
Este es el paso **clave** que conecta todo el flujo de GitOps:
* `argocd cluster add minikube`: Registra el propio clúster de Minikube como un destino de despliegue válido para Argo CD.
* `argocd repo add ...`: Registra **tu repositorio `manifest-k8s`** como un repositorio "fuente". Aquí es donde utiliza tu clave SSH para autenticarse.



### 6. `install_prometheus_stack`
Despliega una pila completa de monitoreo (`kube-prometheus-stack`):
* Crea el namespace `monitoring`.
* Usa Helm para instalar Prometheus, Grafana y Alertmanager, que vienen preconfigurados para monitorear el clúster.

### 7. `print_summary`
Al finalizar, imprime la información más importante que necesitarás para empezar a trabajar:
* **URL de Argo CD:** Para acceder a la interfaz web.
* **Usuario:** `admin`
* **Password:** La contraseña inicial extraída.

---

## ✅ Resultado del Script 1

Al terminar el script `minikube-start.sh`, tendrás un clúster Minikube funcional con Argo CD y Prometheus instalados. Argo CD estará **conectado** a tu repositorio `manifest-k8s`, pero **aún no estará desplegando nada**.

---

## 🚀 Paso 2: Despliegue de Aplicaciones (`deploy-apps-argocd.sh`)

Una vez que el entorno base está listo, este segundo script **activa los despliegues**.

El objetivo de este script es **crear las definiciones de las `Applications` dentro de Argo CD de forma automatizada**.

Este script **no** despliega `cinema-app` directamente. En su lugar, utiliza el patrón **"App of Apps"**: despliega un chart de Helm (`argocd-apps`) que le dice a Argo CD: "Estas son las aplicaciones que debes gestionar".

Inmediatamente después, Argo CD leerá estas definiciones y comenzará a **sincronizar** automáticamente las aplicaciones (`cinema-app`, `shared`, etc.) desde el repositorio de Git hacia el **clúster que registramos (Minikube)**.



### 📋 Prerrequisitos

* Haber ejecutado el primer script (`minikube-start.sh`) **exitosamente**.
* Argo CD debe estar instalado y corriendo en el namespace `argocd`.
* Argo CD debe tener acceso al repositorio de manifests en Azure DevOps (registrado).
* Argo CD debe tener el clúster Minikube registrado.

### ⚡ Uso

1.  **[¡IMPORTANTE!] Configura el Chart `argocd-apps`:**
    * Antes de ejecutar el script, debes **editar el archivo de valores** que usa el chart "App of Apps".
    * Ve a `./helm-charts/argocd-apps/values-dev.yml` (o el archivo de valores que corresponda, según el script).
    * Dentro de este archivo, **debes configurar dos parámetros cruciales**: `repoURL` y `targetRevision`.
    * *Ejemplo:*
        ```yaml
        # helm-charts/argocd-apps/values-dev.yml
        
        # ... otras configuraciones ...
        
        # 1. Asegúrate de que esto apunte a TU repositorio de manifests
        repoURL: git@ssh.dev.azure.com:v3/TU_USUARIO/TU_PROYECTO/manifest-k8s
        # Ver: ../manifest-k8s/ para el repositorio de manifiestos 
        
        # 2. Esta es la RAMA (branch) que Argo CD vigilará en ESE repositorio.
        #    Asegúrate de que coincida con la rama donde están tus manifests (ej. 'develop', 'main', etc.)
        targetRevision: develop
        
        # ... otras configuraciones ...
        ```

2.  Asegúrate de que el script tenga permisos de ejecución:
    ```bash
    chmod +x deploy-apps-argocd.sh
    ```

3.  Ejecuta el script:
    ```bash
    ./deploy-apps-argocd.sh
    ```

---

### 🛠️ ¿Qué hace el script `deploy-apps-argocd.sh`? (Paso a Paso)

El script orquesta el despliegue final de las aplicaciones:

#### 1. `deploy_apps`
* Usa `helm upgrade --install` para desplegar el chart "paraguas" (umbrella) local llamado **`argocd-apps`** en el namespace `argocd`, usando el archivo de valores que acabas de editar.
* Este chart (configurado con tus valores) le dice a Argo CD dónde está el código de las aplicaciones (`cinema-app`, etc.) y dónde desplegarlas (`minikube`).

#### 2. `wait_for_ingress`
* Se asegura de que el **Ingress Controller** (`ingress-nginx`) esté listo para aceptar conexiones antes de continuar.

#### 3. `check_frontend_ready`
* Una vez que Argo CD ha tenido tiempo de desplegar todo, este paso verifica que la aplicación `cinema-app` esté respondiendo.
* Hace un `curl` a la IP de Minikube y espera un `200 OK`.

#### 4. `print_summary`
* Al finalizar, muestra un resumen útil:
    * Ejecuta `argocd app list` para que puedas ver todas las aplicaciones que Argo CD está gestionando y su estado (Sincronizado, Saludable, etc.).
    * Imprime la **URL final** (`http://<minikube-ip>`) para que puedas acceder al frontend de la aplicación de cine ([cinema-app](../cinema-app/)) en tu navegador.

## 📋 Repositorios Relacionados

- **[Manifest K8s](../manifest-k8s/)** - Repositorio que ArgoCD monitorea (configurar URL en scripts)
- **[Cinema App](../cinema-app/)** - Frontend que se despliega via ArgoCD
- **[Cinema Food](../cinema-food/)** - Microservicio que se despliega via ArgoCD
- **[Cinema Seats](../cinema-seats/)** - Microservicio que se despliega via ArgoCD
- **[Pipeline Templates](../pipeline-templates-helm-argo/)** - Templates que actualizan manifest-k8s

## 🔗 Flujo Completo

1. **Ejecutar scripts** de este repositorio para configurar Minikube + ArgoCD
2. **ArgoCD monitorea** [manifest-k8s](../manifest-k8s/) continuamente
3. **Desarrolladores hacen commits** en [cinema-app](../cinema-app/), [cinema-food](../cinema-food/), [cinema-seats](../cinema-seats/)
4. **Pipelines actualizan** [manifest-k8s](../manifest-k8s/) usando [pipeline-templates](../pipeline-templates-helm-argo/)
5. **ArgoCD detecta cambios** y despliega automáticamente
6. **Aplicaciones se actualizan** en Minikube sin intervención manual