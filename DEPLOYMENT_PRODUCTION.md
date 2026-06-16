# Guía de Despliegue en Producción - Emplea Humboldt

Esta guía explica el proceso completo para desplegar Emplea Humboldt en AWS utilizando **GitHub Actions** (sin necesidad de ejecutar comandos locales).

---

## Tabla de Contenidos

1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Prerequisitos](#prerequisitos)
3. [Paso 1: Configurar Secrets de Infraestructura](#paso-1-configurar-secrets-de-infraestructura)
4. [Paso 2: Desplegar Infraestructura](#paso-2-desplegar-infraestructura)
5. [Paso 3: Obtener Outputs de Infraestructura](#paso-3-obtener-outputs-de-infraestructura)
6. [Paso 4: Configurar Secrets de Microservicios](#paso-4-configurar-secrets-de-microservicios)
7. [Paso 5: Desplegar Microservicios](#paso-5-desplegar-microservicios)
8. [Paso 6: Configurar y Desplegar Frontend](#paso-6-configurar-y-desplegar-frontend)
9. [Verificación Manual en AWS](#verificación-manual-en-aws)
10. [Troubleshooting](#troubleshooting)

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                                  │
│                                                                      │
│  ┌────────────────┐                                                 │
│  │  AWS Amplify   │ ◄── Frontend (Next.js)                         │
│  │   Frontend     │                                                 │
│  └────────┬───────┘                                                 │
│           │                                                          │
│           ▼                                                          │
│  ┌────────────────┐         ┌──────────────────┐                   │
│  │  API Gateway   │────────►│  Application     │                   │
│  │   (HTTP API)   │         │  Load Balancer   │                   │
│  └────────────────┘         └────────┬─────────┘                   │
│                                       │                              │
│                      ┌────────────────┼────────────────┐            │
│                      ▼                ▼                ▼             │
│              ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│              │ ECS Service  │  │ ECS Service  │  │ ECS Service │  │
│              │ Autenticación│  │   Empleos    │  │Postulaciones│  │
│              └──────┬───────┘  └──────┬───────┘  └──────┬──────┘  │
│                     │                 │                 │           │
│                     └─────────────────┼─────────────────┘           │
│                                       ▼                              │
│                              ┌─────────────────┐                    │
│                              │  RDS PostgreSQL │                    │
│                              │   (5 databases) │                    │
│                              └─────────────────┘                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

Repositorios GitHub:
- emplea-humboldt-infraestructura (Terraform)
- microservicio-autenticacion-usuarios (Python/FastAPI)
- microservicio-empleos (Python/FastAPI)
- microservicio-postulaciones (Python/FastAPI)
- microservicio-seguimiento (Python/FastAPI)
- microservicio-notificaciones (Python/FastAPI)
- emplea-humboldt-frontend (Next.js)
```

---

## Prerequisitos

### Accesos Necesarios

1. **Cuenta AWS** con permisos de administrador
2. **Cuenta GitHub** con acceso a todos los repositorios del proyecto
3. **Acceso a GitHub Settings** para configurar secrets

### Repositorios del Proyecto

Todos los repositorios deben estar en la organización/usuario: `123samuel10`

- https://github.com/123samuel10/emplea-humboldt-infraestructura
- https://github.com/123samuel10/microservicio-autenticacion-usuarios
- https://github.com/123samuel10/microservicio-empleos
- https://github.com/123samuel10/microservicio-postulaciones
- https://github.com/123samuel10/microservicio-seguimiento
- https://github.com/123samuel10/microservicio-notificaciones
- https://github.com/123samuel10/emplea-humboldt-frontend

---

## Paso 1: Configurar Secrets de Infraestructura

### 1.1 Crear usuario IAM en AWS

1. Ve a **AWS Console** → **IAM** → **Users**
2. Click en **Create user**
3. Nombre: `github-actions-deployer`
4. Click **Next**
5. **Permissions**: Selecciona **Attach policies directly**
6. Adjunta la política: **AdministratorAccess** (para desarrollo; en producción usa permisos más restrictivos)
7. Click **Next** → **Create user**

### 1.2 Crear Access Keys

1. Click en el usuario recién creado
2. Tab **Security credentials**
3. Scroll down → **Access keys** → **Create access key**
4. Use case: **Application running outside AWS**
5. Click **Next** → **Create access key**
6. **IMPORTANTE:** Copia el **Access key ID** y **Secret access key** (no podrás verlo de nuevo)

### 1.3 Configurar GitHub Secrets para Infraestructura

Ve a: **https://github.com/123samuel10/emplea-humboldt-infraestructura/settings/secrets/actions**

Click en **New repository secret** para cada uno:

| Secret Name | Value | Descripción |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | El Access Key ID del paso anterior |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtn...` | El Secret Access Key del paso anterior |
| `AWS_REGION` | `us-east-1` | Región de AWS donde se desplegará |

---

## Paso 2: Desplegar Infraestructura

### 2.1 Ejecutar Pipeline de Infraestructura

1. Ve a: **https://github.com/123samuel10/emplea-humboldt-infraestructura/actions**
2. Click en **Terraform CI/CD** (en el panel izquierdo)
3. Click en **Run workflow** (botón a la derecha)
4. Branch: **main**
5. Click **Run workflow** (botón verde)

### 2.2 Monitorear el Despliegue

El workflow tiene las siguientes etapas:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Checkout Code                 (~5 segundos)              │
│ 2. Setup Terraform                (~10 segundos)            │
│ 3. Terraform Format Check         (~5 segundos)             │
│ 4. Terraform Init                 (~30 segundos)            │
│ 5. Terraform Validate             (~10 segundos)            │
│ 6. Terraform Plan                 (~2-3 minutos)            │
│ 7. Terraform Apply                (~10-15 minutos)          │
└─────────────────────────────────────────────────────────────┘
Total: ~15-20 minutos
```

### 2.3 Verificar que el Pipeline Completó Exitosamente

✅ **Señales de éxito:**
- El workflow muestra un ✓ verde
- El último paso "Terraform Apply" completó sin errores
- En los logs del Apply verás: `Apply complete! Resources: XX added, 0 changed, 0 destroyed.`

❌ **Si falla:**
- Click en el job que falló
- Expande el paso con error
- Lee el mensaje de error
- Consulta la sección [Troubleshooting](#troubleshooting)

### 2.4 Recursos que se Crean

El despliegue de infraestructura crea:

**Networking:**
- 1 VPC (`10.0.0.0/16`)
- 2 Subnets públicas (`10.0.1.0/24`, `10.0.2.0/24`)
- 2 Subnets privadas (`10.0.101.0/24`, `10.0.102.0/24`)
- 1 Internet Gateway
- 2 NAT Gateways
- Route Tables

**Database:**
- 1 RDS PostgreSQL instance (`db.t3.micro`)
- 1 DB Subnet Group
- 1 Security Group para RDS

**Container Infrastructure:**
- 1 ECS Cluster
- 5 ECS Services (uno por microservicio)
- 5 Task Definitions
- 5 ECR Repositories
- Security Groups para ECS

**Load Balancing:**
- 1 Application Load Balancer
- 5 Target Groups
- Listener Rules

**API Gateway:**
- 1 HTTP API Gateway
- Integrations con ALB
- Stage: `prd`

**Frontend:**
- 1 Amplify App (conectada al repo de frontend)

**Otros:**
- CloudWatch Log Groups
- IAM Roles y Policies
- Secrets Manager (para credenciales de RDS)

---

## Paso 3: Obtener Outputs de Infraestructura

### 3.1 Ver Outputs en GitHub Actions

1. Ve al workflow que acaba de completar
2. Click en el job **terraform**
3. Expande el paso **Terraform Apply**
4. Scroll hasta el final, verás la sección **Outputs:**

```
Outputs:

alb_dns_name = "emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com"
amplify_app_id = "d2pzb9m4eoaiu0"
amplify_app_url = "https://main.d2pzb9m4eoaiu0.amplifyapp.com"
api_gateway_endpoint = "https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd"
api_gateway_url = "https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/"
ecs_cluster_name = "emplea-humboldt-cluster"
rds_endpoint = "emplea-humboldt-postgres.c6x4yugk4mnb.us-east-1.rds.amazonaws.com"
rds_secret_arn = "arn:aws:secretsmanager:us-east-1:750611778012:secret:rds!db-..."
vpc_id = "vpc-0c5e3b685b57f2945"
```

### 3.2 Copiar y Guardar estos Valores

**IMPORTANTE:** Necesitarás estos valores en los siguientes pasos. Cópialos en un documento temporal:

- **`api_gateway_url`**: Para configurar el frontend
- **`rds_endpoint`**: Para construir las URLs de base de datos
- **`rds_secret_arn`**: Para obtener las credenciales de RDS
- **`ecs_cluster_name`**: Para verificar servicios

### 3.3 Obtener Credenciales de RDS

Las credenciales de RDS se almacenan en **AWS Secrets Manager**.

**Opción A: Desde AWS Console (Recomendado)**

1. Ve a **AWS Console** → **Secrets Manager**
2. Busca el secret que contiene `rds!db-` en el nombre
3. Click en el secret
4. Scroll down → **Secret value** → Click **Retrieve secret value**
5. Verás un JSON:
   ```json
   {
     "username": "postgres",
     "password": "XyZ123abc...",
     "engine": "postgres",
     "host": "emplea-humboldt-postgres.c6x4yugk4mnb.us-east-1.rds.amazonaws.com",
     "port": 5432,
     "dbname": "postgres"
   }
   ```
6. Copia el **username** y **password**

**Opción B: Usando AWS CLI (si tienes CLI configurado)**

```bash
aws secretsmanager get-secret-value \
  --secret-id <rds_secret_arn> \
  --region us-east-1 \
  --query SecretString \
  --output text
```

---

## Paso 4: Configurar Secrets de Microservicios

Ahora necesitas configurar los secrets para cada microservicio. Cada microservicio tiene su propio repositorio y requiere su configuración.

### 4.1 Valores Comunes

Estos valores serán iguales para todos los microservicios:

- **AWS_ACCESS_KEY_ID**: El mismo del paso 1.2
- **AWS_SECRET_ACCESS_KEY**: El mismo del paso 1.2
- **AWS_REGION**: `us-east-1`
- **ECS_CLUSTER**: `emplea-humboldt-cluster`
- **RDS Username**: Del paso 3.3
- **RDS Password**: Del paso 3.3
- **RDS Host**: Del paso 3.2 (`rds_endpoint`)

### 4.2 Microservicio: Autenticación

**Repositorio:** https://github.com/123samuel10/microservicio-autenticacion-usuarios/settings/secrets/actions

Click **New repository secret** para cada uno:

| Secret Name | Value | Ejemplo |
|-------------|-------|---------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key | `wJalrXUtn...` |
| `AWS_REGION` | Región AWS | `us-east-1` |
| `ECR_REPOSITORY` | Nombre del repo ECR | `emplea-humboldt-autenticacion` |
| `ECS_SERVICE` | Nombre del servicio ECS | `autenticacion-service` |
| `ECS_CLUSTER` | Nombre del cluster | `emplea-humboldt-cluster` |
| `DATABASE_URL` | URL de conexión a DB | `postgresql+asyncpg://postgres:PASSWORD@HOST:5432/auth_db` |
| `SECRET_KEY` | Clave para JWT | Generar: `openssl rand -hex 32` o cualquier string random de 64 caracteres |
| `ALGORITHM` | Algoritmo JWT | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Expiración token | `60` |

**Construcción del DATABASE_URL:**
```
postgresql+asyncpg://[username]:[password]@[rds_endpoint]:5432/auth_db
                     ^           ^          ^                        ^
                     |           |          |                        |
                De Secrets Manager      Del output            Nombre de DB
```

**Ejemplo real:**
```
postgresql+asyncpg://postgres:MyP@ssw0rd123@emplea-humboldt-postgres.c6x4yugk4mnb.us-east-1.rds.amazonaws.com:5432/auth_db
```

### 4.3 Microservicio: Empleos

**Repositorio:** https://github.com/123samuel10/microservicio-empleos/settings/secrets/actions

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `emplea-humboldt-empleos` |
| `ECS_SERVICE` | `empleos-service` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://postgres:PASSWORD@HOST:5432/emp_db` |
| `AUTENTICACION_SERVICE_URL` | `http://autenticacion-service.emplea-humboldt-internal:8000` |

### 4.4 Microservicio: Postulaciones

**Repositorio:** https://github.com/123samuel10/microservicio-postulaciones/settings/secrets/actions

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `emplea-humboldt-postulaciones` |
| `ECS_SERVICE` | `postulaciones-service` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://postgres:PASSWORD@HOST:5432/post_db` |
| `AUTENTICACION_SERVICE_URL` | `http://autenticacion-service.emplea-humboldt-internal:8000` |
| `EMPLEOS_SERVICE_URL` | `http://empleos-service.emplea-humboldt-internal:8000` |
| `NOTIFICACIONES_SERVICE_URL` | `http://notificaciones-service.emplea-humboldt-internal:8000` |

### 4.5 Microservicio: Seguimiento

**Repositorio:** https://github.com/123samuel10/microservicio-seguimiento/settings/secrets/actions

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `emplea-humboldt-seguimiento_practicas` |
| `ECS_SERVICE` | `seguimiento_practicas-service` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://postgres:PASSWORD@HOST:5432/pra_db` |
| `AUTENTICACION_SERVICE_URL` | `http://autenticacion-service.emplea-humboldt-internal:8000` |
| `POSTULACIONES_SERVICE_URL` | `http://postulaciones-service.emplea-humboldt-internal:8000` |

### 4.6 Microservicio: Notificaciones

**Repositorio:** https://github.com/123samuel10/microservicio-notificaciones/settings/secrets/actions

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `emplea-humboldt-notificaciones` |
| `ECS_SERVICE` | `notificaciones-service` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://postgres:PASSWORD@HOST:5432/noti_db` |

---

## Paso 5: Desplegar Microservicios

Los microservicios deben desplegarse en un orden específico debido a sus dependencias.

### 5.1 Orden de Despliegue

```
1. Autenticación     (no tiene dependencias)
         ↓
2. Notificaciones    (no tiene dependencias)
         ↓
3. Empleos           (depende de Autenticación)
         ↓
4. Postulaciones     (depende de Autenticación, Empleos, Notificaciones)
         ↓
5. Seguimiento       (depende de Autenticación, Postulaciones)
```

### 5.2 Desplegar Microservicio de Autenticación

1. Ve a: **https://github.com/123samuel10/microservicio-autenticacion-usuarios/actions**
2. Click en **Autenticacion CI/CD Pipeline**
3. Click en **Run workflow** → Branch: **main** → **Run workflow**
4. Espera ~5-7 minutos

**Verificación:**
- ✅ Workflow completó con éxito (verde)
- ✅ Paso "Deploy to ECS" completó sin errores

### 5.3 Desplegar Microservicio de Notificaciones

1. Ve a: **https://github.com/123samuel10/microservicio-notificaciones/actions**
2. Click en **Notificaciones CI/CD Pipeline**
3. Click en **Run workflow** → Branch: **main** → **Run workflow**
4. Espera ~5-7 minutos

### 5.4 Desplegar Microservicio de Empleos

1. Ve a: **https://github.com/123samuel10/microservicio-empleos/actions**
2. Click en **Empleos CI/CD Pipeline**
3. Click en **Run workflow** → Branch: **main** → **Run workflow**
4. Espera ~5-7 minutos

### 5.5 Desplegar Microservicio de Postulaciones

1. Ve a: **https://github.com/123samuel10/microservicio-postulaciones/actions**
2. Click en **Postulaciones CI/CD Pipeline**
3. Click en **Run workflow** → Branch: **main** → **Run workflow**
4. Espera ~5-7 minutos

### 5.6 Desplegar Microservicio de Seguimiento

1. Ve a: **https://github.com/123samuel10/microservicio-seguimiento/actions**
2. Click en **Seguimiento CI/CD Pipeline**
3. Click en **Run workflow** → Branch: **main** → **Run workflow**
4. Espera ~5-7 minutos

### 5.7 Etapas de cada Pipeline de Microservicio

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Setup Python                  (~20 segundos)             │
│ 2. Install Dependencies          (~1 minuto)                │
│ 3. Run Tests                      (~10 segundos, skipped)   │
│ 4. Configure AWS Credentials      (~5 segundos)             │
│ 5. Login to ECR                   (~5 segundos)             │
│ 6. Build Docker Image             (~2-3 minutos)            │
│ 7. Push to ECR                    (~1-2 minutos)            │
│ 8. Deploy to ECS                  (~1-2 minutos)            │
│                                                              │
│ ECS realiza rolling update        (~2-3 minutos adicionales)│
└─────────────────────────────────────────────────────────────┘
Total por microservicio: ~5-7 minutos
Total para 5 microservicios: ~25-35 minutos (si se hacen en paralelo)
```

---

## Paso 6: Configurar y Desplegar Frontend

### 6.1 Configurar Variable de Entorno en Amplify

El frontend necesita saber la URL del API Gateway.

1. Ve a **AWS Console** → **AWS Amplify**
2. Click en la app: **emplea-humboldt-frontend**
3. En el panel izquierdo, click en **Environment variables**
4. Click en **Add environment variable**
5. Configura:
   - **Variable**: `NEXT_PUBLIC_API_URL`
   - **Value**: El `api_gateway_url` del paso 3.2 (ejemplo: `https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd`)
6. Click **Save**

### 6.2 Conectar Repositorio a Amplify

Si el repositorio no está conectado:

1. En Amplify app → Click **Set up build**
2. Selecciona **GitHub**
3. Click **Authorize AWS Amplify**
4. Selecciona el repositorio: **emplea-humboldt-frontend**
5. Branch: **main**
6. Build settings (usar los defaults):
   ```yaml
   version: 1
   frontend:
     phases:
       preBuild:
         commands:
           - npm ci
       build:
         commands:
           - npm run build
     artifacts:
       baseDirectory: .next/standalone
       files:
         - '**/*'
     cache:
       paths:
         - node_modules/**/*
   ```
7. Click **Save and deploy**

### 6.3 Trigger Deploy del Frontend

Si ya está conectado, puedes hacer un nuevo deploy:

**Opción A: Push a GitHub**
```bash
# Hacer cualquier cambio y push al repo
git commit --allow-empty -m "Trigger Amplify build"
git push
```

**Opción B: Desde Amplify Console**
1. Ve a Amplify → Tu app
2. Click en el branch **main**
3. Click **Redeploy this version**

### 6.4 Monitorear Build del Frontend

1. En Amplify, verás el build en progreso
2. Etapas:
   ```
   Provision      (~30 segundos)
   Build          (~3-5 minutos)
   Deploy         (~1 minuto)
   Verify         (~10 segundos)
   ```
3. Total: ~5-8 minutos

### 6.5 Obtener URL del Frontend

Una vez completado el build:

1. En Amplify, verás el dominio en la parte superior
2. Ejemplo: `https://main.d2pzb9m4eoaiu0.amplifyapp.com`
3. **O** desde los outputs de Terraform (paso 3.2): `amplify_app_url`

---

## Verificación Manual en AWS

Ahora que todo está desplegado, verifica manualmente que todo funciona.

### 1. Verificar VPC y Networking

**AWS Console → VPC**

✅ **Checklist:**
- [ ] VPC existe: `emplea-humboldt-vpc`
- [ ] CIDR: `10.0.0.0/16`
- [ ] 2 Subnets públicas creadas
- [ ] 2 Subnets privadas creadas
- [ ] Internet Gateway conectado
- [ ] 2 NAT Gateways (uno en cada subnet pública)

### 2. Verificar RDS (Base de Datos)

**AWS Console → RDS → Databases**

✅ **Checklist:**
- [ ] DB Instance: `emplea-humboldt-postgres`
- [ ] Status: **Available** (verde)
- [ ] Engine: PostgreSQL 15.x
- [ ] Instance class: db.t3.micro
- [ ] Storage: 20 GB
- [ ] Multi-AZ: No
- [ ] VPC: emplea-humboldt-vpc
- [ ] Publicly accessible: No

**Verificar bases de datos creadas:**

Las 5 bases de datos se crean automáticamente con las migraciones de Alembic cuando cada microservicio se despliega por primera vez.

Para verificar (requiere acceso a la VPC):
```sql
-- Conectarse desde un recurso dentro de la VPC
psql -h [rds_endpoint] -U postgres -d postgres -c "\l"

-- Deberías ver:
-- auth_db
-- emp_db
-- post_db
-- pra_db
-- noti_db
```

### 3. Verificar ECR (Container Registry)

**AWS Console → ECR → Repositories**

✅ **Checklist:**
- [ ] 5 repositorios creados:
  - [ ] `emplea-humboldt-autenticacion`
  - [ ] `emplea-humboldt-empleos`
  - [ ] `emplea-humboldt-postulaciones`
  - [ ] `emplea-humboldt-seguimiento_practicas`
  - [ ] `emplea-humboldt-notificaciones`

**Para cada repositorio:**
- [ ] Tiene al menos 1 imagen
- [ ] La imagen más reciente tiene tag: `latest`
- [ ] Image scan on push: Habilitado

### 4. Verificar ECS (Servicios de Contenedores)

**AWS Console → ECS → Clusters**

✅ **Verificar Cluster:**
- [ ] Cluster: `emplea-humboldt-cluster`
- [ ] Status: **ACTIVE**
- [ ] Services: **5**
- [ ] Tasks running: **5**

**Click en el cluster → Tab "Services"**

✅ **Verificar cada servicio:**

| Service Name | Desired | Running | Status | Health |
|--------------|---------|---------|--------|--------|
| autenticacion-service | 1 | 1 | ACTIVE | ✅ |
| empleos-service | 1 | 1 | ACTIVE | ✅ |
| postulaciones-service | 1 | 1 | ACTIVE | ✅ |
| seguimiento_practicas-service | 1 | 1 | ACTIVE | ✅ |
| notificaciones-service | 1 | 1 | ACTIVE | ✅ |

**Para cada servicio, click en el nombre:**

Tab **Tasks**:
- [ ] 1 task en estado **RUNNING**
- [ ] Last status: RUNNING
- [ ] Health status: HEALTHY (puede tardar ~30-60 segundos)

Tab **Logs**:
- [ ] Verás logs como:
  ```
  INFO:     Started server process
  INFO:     Waiting for application startup.
  INFO:     Application startup complete.
  INFO:     Uvicorn running on http://0.0.0.0:8000
  ```

Tab **Events**:
- [ ] Último evento debe ser: `service [service-name] has reached a steady state`
- [ ] No debe haber errores recientes

**Si un servicio no está HEALTHY:**
1. Ve al Tab **Tasks** → Click en el Task ID
2. Ve al Tab **Logs** para ver errores
3. Común: Error de conexión a base de datos → Verifica DATABASE_URL en secrets

### 5. Verificar Application Load Balancer (ALB)

**AWS Console → EC2 → Load Balancers**

✅ **Verificar ALB:**
- [ ] Name: `emplea-humboldt-alb`
- [ ] State: **active** (verde)
- [ ] Type: application
- [ ] Scheme: internet-facing
- [ ] VPC: emplea-humboldt-vpc
- [ ] Availability Zones: 2 zonas

**Tab "Listeners and rules":**
- [ ] 1 listener en puerto **80** (HTTP)
- [ ] Default action: Forward to target group

Click en **View rules** para el listener HTTP:80:
- [ ] 5 rules (una por microservicio)
- [ ] Paths: `/autenticacion/*`, `/empleos/*`, `/postulaciones/*`, `/seguimiento_practicas/*`, `/notificaciones/*`

**Verificar Target Groups:**

**AWS Console → EC2 → Target Groups**

✅ **Para cada Target Group:**

| Target Group Name | Protocol | Port | Health check path | Targets |
|-------------------|----------|------|-------------------|---------|
| autenticacion-tg-* | HTTP | 8000 | /autenticacion/health | 1 healthy |
| empleos-tg-* | HTTP | 8000 | /empleos/health | 1 healthy |
| postulaciones-tg-* | HTTP | 8000 | /postulaciones/health | 1 healthy |
| seguimiento-tg-* | HTTP | 8000 | /seguimiento_practicas/health | 1 healthy |
| notificaciones-tg-* | HTTP | 8000 | /notificaciones/health | 1 healthy |

**Para cada Target Group:**
1. Click en el nombre
2. Tab **Targets**
3. Verifica:
   - [ ] 1 target registrado
   - [ ] Health status: **healthy** (verde)
   - [ ] Si aparece "initial" o "unhealthy", espera 30-60 segundos

**Health status "unhealthy":**
- Click en el target → Ver "Status details"
- Común: "Health checks failed with these codes: [502]"
- Solución: Verifica que el ECS task está RUNNING y los logs no muestran errores

**Probar ALB manualmente:**

Puedes usar un navegador o herramienta como Postman:

1. Obtén el DNS del ALB (del output de Terraform o de la consola AWS)
2. Prueba los health checks:
   ```
   http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/autenticacion/health
   http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/empleos/health
   http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/postulaciones/health
   http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/seguimiento_practicas/health
   http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/notificaciones/health
   ```
3. Cada uno debe retornar:
   ```json
   {"status":"healthy","service":"nombre-del-servicio"}
   ```

### 6. Verificar API Gateway

**AWS Console → API Gateway**

✅ **Verificar API:**
- [ ] API Name: `emplea-humboldt-api`
- [ ] Protocol: HTTP
- [ ] Stage: `prd`
- [ ] Invoke URL: Coincide con el output de Terraform

**Click en el API → Panel izquierdo → "Routes":**

Deberías ver rutas como:
- [ ] `ANY /autenticacion/{proxy+}`
- [ ] `ANY /empleos/{proxy+}`
- [ ] `ANY /postulaciones/{proxy+}`
- [ ] `ANY /seguimiento_practicas/{proxy+}`
- [ ] `ANY /notificaciones/{proxy+}`

**Click en "Integrations":**

Para cada ruta:
- [ ] Integration type: **HTTP_PROXY**
- [ ] Integration URI: Apunta al ALB

**Probar API Gateway:**

Usa el API Gateway URL (del output de Terraform):

```
https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/autenticacion/health
https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/empleos/health
https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/postulaciones/health
https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/seguimiento_practicas/health
https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd/notificaciones/health
```

Cada uno debe retornar `200 OK` con:
```json
{"status":"healthy","service":"..."}
```

### 7. Verificar AWS Amplify (Frontend)

**AWS Console → AWS Amplify**

✅ **Verificar App:**
- [ ] App name: `emplea-humboldt-frontend`
- [ ] Repository: Conectado a GitHub
- [ ] Branch: `main`
- [ ] Domain: `https://main.[app-id].amplifyapp.com`

**Click en el branch "main":**
- [ ] Status: ✅ **Deployed** (verde)
- [ ] Last deploy: Exitoso

**Tab "Build settings":**
- [ ] Build specification está configurado

**Tab "Environment variables":**
- [ ] `NEXT_PUBLIC_API_URL` está configurado
- [ ] Value: URL del API Gateway

**Probar el Frontend:**

1. Click en el dominio (o abre la URL del output de Terraform)
2. El sitio debe cargar correctamente
3. Verifica:
   - [ ] Página principal carga
   - [ ] No hay errores en la consola del navegador
   - [ ] Intenta registrarte como estudiante
   - [ ] Intenta hacer login
   - [ ] Navega a las secciones (Empleos, Postulaciones)

### 8. Verificar CloudWatch Logs

**AWS Console → CloudWatch → Log groups**

✅ **Verificar Log Groups:**

Deberías ver 5 log groups:
- [ ] `/ecs/autenticacion-service`
- [ ] `/ecs/empleos-service`
- [ ] `/ecs/postulaciones-service`
- [ ] `/ecs/seguimiento_practicas-service`
- [ ] `/ecs/notificaciones-service`

**Para cada log group:**
1. Click en el nombre
2. Verás streams (uno por cada task/container)
3. Click en el stream más reciente
4. Verás logs como:
   ```
   INFO:     Started server process [1]
   INFO:     Waiting for application startup.
   ✓ Base de datos 'auth_db' ya existe
   INFO:     Application startup complete.
   INFO:     Uvicorn running on http://0.0.0.0:8000
   ```

**Buscar errores:**
1. En el log group, click **Search all**
2. En el filtro, escribe: `ERROR`
3. Si hay errores, investiga

### 9. Pruebas End-to-End Funcionales

#### Prueba 1: Health Checks (desde navegador o Postman)

URL base: `https://qjvf7f8jgd.execute-api.us-east-1.amazonaws.com/prd`

```
GET /autenticacion/health      → {"status":"healthy",...}
GET /empleos/health            → {"status":"healthy",...}
GET /postulaciones/health      → {"status":"healthy",...}
GET /seguimiento_practicas/health → {"status":"healthy",...}
GET /notificaciones/health     → {"status":"healthy",...}
```

#### Prueba 2: Registro de Usuario

```
POST /autenticacion/api/v1/usuarios/registro/estudiante
Content-Type: application/json

{
  "email": "test@ejemplo.com",
  "password": "Test1234!",
  "nombre_completo": "Usuario Test",
  "programa_academico": "Ingeniería de Sistemas",
  "semestre_actual": 5
}
```

Debe retornar `201 Created`.

#### Prueba 3: Login

```
POST /autenticacion/api/v1/usuarios/login
Content-Type: application/json

{
  "email": "test@ejemplo.com",
  "password": "Test1234!"
}
```

Debe retornar `200 OK` con un `access_token`.

#### Prueba 4: Listar Vacantes

```
GET /empleos/api/v1/vacantes
```

Debe retornar `200 OK` con un array (vacío si no hay vacantes).

#### Prueba 5: Listar Notificaciones (requiere autenticación)

```
GET /notificaciones/api/v1/notificaciones
Authorization: Bearer [token_del_login]
```

Debe retornar `200 OK` con un array.

---

## Troubleshooting

### Problema 1: ECS Tasks no inician (STOPPED)

**Síntomas:**
- En ECS → Cluster → Services, "Running tasks" = 0
- Tasks aparecen como STOPPED

**Diagnóstico:**
1. Ve a ECS → Cluster → Service → Tab **Events**
2. Lee el último evento de error

**Errores comunes:**

**Error: "CannotPullContainerError"**
- **Causa:** No puede descargar la imagen de ECR
- **Solución:**
  1. Verifica que la imagen existe en ECR
  2. Verifica que el Task Execution Role tiene permisos para ECR
  3. Re-ejecuta el pipeline del microservicio

**Error: "Essential container in task exited"**
- **Causa:** El contenedor se inició pero se detuvo inmediatamente
- **Solución:**
  1. Ve a CloudWatch Logs: `/ecs/[service-name]`
  2. Busca errores en los logs
  3. Común: Error de conexión a base de datos
     - Verifica DATABASE_URL en secrets
     - Verifica que RDS está "Available"
     - Verifica Security Groups permiten conexión

**Error: "ResourceInitializationError: unable to pull secrets"**
- **Causa:** No puede obtener secrets de Secrets Manager
- **Solución:**
  1. Verifica que el Task Execution Role tiene permisos para Secrets Manager
  2. Verifica que los secrets existen

### Problema 2: Target Groups "unhealthy"

**Síntomas:**
- En EC2 → Target Groups, targets aparecen "unhealthy" (rojo)
- Health checks fallan

**Diagnóstico:**
1. Ve a Target Group → Tab **Targets**
2. Click en el target → Ver "Status details"

**Errores comunes:**

**Status: "Health checks failed with these codes: [502]"**
- **Causa:** El backend no responde o retorna error
- **Solución:**
  1. Verifica que el ECS task está RUNNING
  2. Revisa logs en CloudWatch
  3. Verifica que la app escucha en puerto 8000
  4. Verifica la ruta del health check (ej: `/autenticacion/health`)

**Status: "Health checks failed: Connection refused"**
- **Causa:** No puede conectarse al contenedor
- **Solución:**
  1. Verifica Security Groups permiten tráfico del ALB a ECS
  2. Verifica que el contenedor está escuchando en 0.0.0.0:8000 (no 127.0.0.1)

**Status: "Initial" (por más de 2 minutos)**
- **Causa:** Health check toma mucho tiempo
- **Solución:**
  1. Espera 2-3 minutos más
  2. Si persiste, revisa logs del ECS task

### Problema 3: Base de datos no existe

**Síntomas:**
- Error en CloudWatch Logs: `database "auth_db" does not exist`
- ECS task se detiene con código de error

**Solución:**

Las bases de datos se crean automáticamente con Alembic. Si no se crearon:

1. **Verificar que las migraciones corrieron:**
   - Busca en CloudWatch Logs el mensaje: `✓ Base de datos 'auth_db' creada exitosamente`
   - O: `○ Base de datos 'auth_db' ya existe`

2. **Si no ves esos mensajes:**
   - El código de Alembic falló
   - Verifica el error en los logs
   - Común: credenciales incorrectas → Verifica DATABASE_URL

3. **Crear bases de datos manualmente (último recurso):**
   - Necesitas conectarte a RDS desde dentro de la VPC
   - Opción: Crear un EC2 en subnet pública como bastion
   - Conectar y ejecutar:
     ```sql
     CREATE DATABASE auth_db;
     CREATE DATABASE emp_db;
     CREATE DATABASE post_db;
     CREATE DATABASE pra_db;
     CREATE DATABASE noti_db;
     ```

### Problema 4: Frontend no puede conectarse al backend

**Síntomas:**
- En el navegador: "No se pudo conectar con el servidor"
- Errores de CORS en la consola del navegador
- Network errors

**Diagnóstico:**
1. Abre la consola del navegador (F12) → Tab **Network**
2. Intenta la acción que falla
3. Mira qué request falla y el código de error

**Errores comunes:**

**Error 404:**
- **Causa:** URL incorrecta o endpoint no existe
- **Solución:**
  1. Verifica `NEXT_PUBLIC_API_URL` en Amplify
  2. Debe terminar en `/prd` (sin trailing slash adicional)
  3. Ejemplo correcto: `https://xxx.execute-api.us-east-1.amazonaws.com/prd`

**Error de CORS:**
- **Causa:** Backend no permite requests desde el dominio del frontend
- **Solución:**
  1. Verifica configuración de CORS en cada microservicio
  2. Debe permitir el origin de Amplify

**Error 307 (Redirect):**
- **Causa:** Trailing slash en rutas de FastAPI
- **Solución:**
  1. Verifica que rutas usan `@router.get("")` no `@router.get("/")`
  2. Este problema ya fue solucionado en el último deploy

### Problema 5: Terraform Apply falla

**Error: "Error acquiring the state lock"**
```
Error: Error acquiring the state lock
Lock Info:
  ID: xxx
  ...
```

**Causa:** Otro proceso tiene el state file bloqueado

**Solución:**
1. Espera a que el otro proceso termine
2. Si estás seguro que no hay otro proceso:
   - Ve a Actions → Cancela el workflow que está corriendo
   - O espera timeout (15 minutos)
3. Si persiste: contacta al administrador de AWS para forzar desbloqueo

**Error: "Resource already exists"**
```
Error: creating EC2 VPC: VpcLimitExceeded: The maximum number of VPCs has been reached
```

**Causa:** Ya existe un recurso con ese nombre/ID

**Solución:**
1. Ve a la consola de AWS y elimina el recurso manualmente
2. O ejecuta `terraform destroy` desde el workflow (agregando el step manualmente)

### Problema 6: Pipeline de GitHub Actions falla

**Error: "AWS credentials not configured"**
```
Error: Credentials could not be loaded
```

**Solución:**
1. Verifica que configuraste los secrets en el repositorio:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
2. Verifica que el IAM user existe y tiene permisos
3. Verifica que las keys no expiraron

**Error: "Permission denied (ECR)"**
```
Error: denied: User is not authorized to perform: ecr:GetAuthorizationToken
```

**Solución:**
1. El IAM user necesita permisos para ECR
2. Adjunta la política: `AmazonEC2ContainerRegistryFullAccess`
3. O usa `AdministratorAccess` (desarrollo)

**Error: "No tests ran (exit code 5)"**
- **Solución:** Ya está resuelto con `continue-on-error: true`

### Problema 7: Amplify Build falla

**Error: "Module not found: Can't resolve '@/components/...'"**

**Solución:**
1. Verifica que los archivos existen en el repo
2. Verifica paths en `tsconfig.json`
3. Si persiste: trigger un nuevo build

**Error: "Build timeout"**
```
Error: Build timed out after 30 minutes
```

**Solución:**
1. Optimiza dependencias (elimina packages no usados)
2. Contacta AWS Support para aumentar timeout

---

## Resumen de Recursos Desplegados

Después de completar todos los pasos, tendrás:

### URLs Públicas

| Recurso | URL | Uso |
|---------|-----|-----|
| **Frontend** | `https://main.[app-id].amplifyapp.com` | Aplicación web pública |
| **API Gateway** | `https://[id].execute-api.us-east-1.amazonaws.com/prd` | API REST pública |

### Recursos Internos

| Recurso | Identificador | Acceso |
|---------|---------------|--------|
| **ALB** | `emplea-humboldt-alb-[id].us-east-1.elb.amazonaws.com` | Interno (detrás de API Gateway) |
| **RDS** | `emplea-humboldt-postgres.[id].us-east-1.rds.amazonaws.com` | Solo desde VPC privada |
| **ECS Cluster** | `emplea-humboldt-cluster` | AWS Console |
| **VPC** | `vpc-[id]` | AWS Console |

### Endpoints de API

Todos los endpoints están bajo: `https://[api-gateway-url]/[servicio]/api/v1/...`

| Servicio | Health Check | Documentación API |
|----------|--------------|-------------------|
| Autenticación | `/autenticacion/health` | `/autenticacion/docs` |
| Empleos | `/empleos/health` | `/empleos/docs` |
| Postulaciones | `/postulaciones/health` | `/postulaciones/docs` |
| Seguimiento | `/seguimiento_practicas/health` | `/seguimiento_practicas/docs` |
| Notificaciones | `/notificaciones/health` | `/notificaciones/docs` |

---

## Mantenimiento y Actualizaciones

### Actualizar un Microservicio

1. Haz cambios en el código del microservicio
2. Commit y push a `main` branch
3. El pipeline de GitHub Actions se ejecuta automáticamente
4. Espera ~5-7 minutos
5. ECS hace rolling update (zero downtime)

### Actualizar el Frontend

1. Haz cambios en el código del frontend
2. Commit y push a `main` branch
3. Amplify detecta el push y hace build automático
4. Espera ~5-8 minutos
5. El nuevo frontend se despliega

### Actualizar la Infraestructura

1. Haz cambios en los archivos `.tf`
2. Commit y push a `main` branch
3. El pipeline ejecuta `terraform plan` automáticamente
4. Para aplicar: Ejecuta el workflow manualmente (como en Paso 2)
5. Terraform hace los cambios (puede afectar servicios corriendo)

### Ver Logs en Tiempo Real

1. Ve a CloudWatch → Log groups
2. Selecciona el log group del servicio
3. Click en **Search all log streams**
4. Usa el filtro para buscar errores: `ERROR` o `Exception`

### Escalar Servicios

Para aumentar el número de contenedores:

1. Ve a ECS → Cluster → Service
2. Click **Update service**
3. Cambia **Desired tasks** a 2 (o más)
4. Click **Update**

O edita Terraform (recomendado para producción):
```hcl
# modules/ecs/main.tf
resource "aws_ecs_service" "autenticacion" {
  desired_count = 2  # Cambiar de 1 a 2
  ...
}
```

---

## Contacto y Soporte

Si tienes problemas:

1. ✅ Revisa la sección [Troubleshooting](#troubleshooting)
2. ✅ Revisa logs en CloudWatch
3. ✅ Revisa eventos en ECS Services
4. ✅ Revisa outputs de GitHub Actions workflows

---

**Última actualización:** Junio 2026
**Versión:** 1.0.0
**Región AWS:** us-east-1
