# Guía de Despliegue en Producción - Emplea Humboldt

Guía completa para desplegar Emplea Humboldt en AWS usando GitHub Actions.

---

## Tabla de Contenidos

1. [Prerequisitos](#prerequisitos)
2. [Paso 1: Configurar Credenciales AWS](#paso-1-configurar-credenciales-aws)
3. [Paso 2: Desplegar Infraestructura](#paso-2-desplegar-infraestructura)
4. [Paso 3: Configurar Microservicios](#paso-3-configurar-microservicios)
5. [Paso 4: Desplegar Microservicios](#paso-4-desplegar-microservicios)
6. [Paso 5: Configurar Frontend](#paso-5-configurar-frontend)
7. [Verificación en AWS Console](#verificación-en-aws-console)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisitos

### Accesos Necesarios

- Cuenta AWS con permisos de administrador
- Cuenta GitHub con acceso a los repositorios
- Permisos para configurar GitHub Secrets

### Repositorios (usuario: `123samuel10`)

- `emplea-humboldt-infraestructura`
- `microservicio-autenticacion-usuarios`
- `microservicio-empleos`
- `microservicio-postulaciones`
- `microservicio-seguimiento`
- `microservicio-notificaciones`
- `emplea-humboldt-frontend`

---

## Paso 1: Configurar Credenciales AWS

### 1.1 Crear Usuario IAM

1. **AWS Console** → **IAM** → **Users** → **Create user**
2. Nombre: `github-actions-deployer`
3. Permissions: **AdministratorAccess**
4. **Create user**

### 1.2 Generar Access Keys

1. Click en el usuario → **Security credentials**
2. **Access keys** → **Create access key**
3. Use case: **Application running outside AWS**
4. **Guardar** Access Key ID y Secret Access Key

### 1.3 Configurar Secret en Infraestructura

Ir a: `https://github.com/123samuel10/emplea-humboldt-infraestructura/settings/secrets/actions`

Crear estos secrets:

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Tu Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Tu Secret Access Key |
| `AWS_REGION` | `us-east-1` |

---

## Paso 2: Desplegar Infraestructura

### 2.1 Ejecutar Workflow

1. Ir a: `https://github.com/123samuel10/emplea-humboldt-infraestructura/actions`
2. Click **Terraform CI/CD**
3. Click **Run workflow** → Branch: **main** → **Run workflow**
4. Esperar ~15-20 minutos

### 2.2 Verificar Éxito

✅ Workflow muestra check verde
✅ Logs muestran: `Apply complete! Resources: XX added`

### 2.3 Obtener Outputs

En el workflow completado:
1. Click en job **terraform**
2. Expandir **Terraform Apply**
3. Scroll al final → sección **Outputs**

**Guardar estos valores** (los necesitarás después):
- `api_gateway_url` → Para el frontend
- `alb_dns_name` → Para URLs de servicio a servicio
- `rds_endpoint` → Para DATABASE_URL
- `rds_secret_arn` → Para obtener credenciales

### 2.4 Obtener Credenciales de RDS

**AWS Console** → **Secrets Manager** → Buscar secret con `rds!db-`

Click en el secret → **Retrieve secret value**

Copiar `username` y `password`

---

## Paso 3: Configurar Microservicios

### 3.1 Valores Comunes

Estos valores son **iguales para todos** los microservicios:

- `AWS_ACCESS_KEY_ID` → Del paso 1.2
- `AWS_SECRET_ACCESS_KEY` → Del paso 1.2
- `AWS_REGION` → `us-east-1`
- `ECS_CLUSTER` → `emplea-humboldt-cluster`

### 3.2 URLs de Comunicación entre Servicios

**IMPORTANTE:** Los microservicios deben comunicarse a través del ALB.

Usar el `alb_dns_name` del paso 2.3 para construir las URLs:

```
http://[alb_dns_name]/autenticacion
http://[alb_dns_name]/empleos
http://[alb_dns_name]/postulaciones
http://[alb_dns_name]/notificaciones
```

**Ejemplo real:**
```
http://emplea-humboldt-alb-584456090.us-east-1.elb.amazonaws.com/autenticacion
```

### 3.3 Construcción de DATABASE_URL

Formato:
```
postgresql+asyncpg://[username]:[password]@[rds_endpoint]:5432/[db_name]
```

Ejemplo:
```
postgresql+asyncpg://postgres:MyP@ss123@emplea-humboldt-postgres.xxx.us-east-1.rds.amazonaws.com:5432/auth_db
```

### 3.4 Secrets por Microservicio

#### Autenticación
URL: `https://github.com/123samuel10/microservicio-autenticacion-usuarios/settings/secrets/actions`

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | (Común) |
| `AWS_SECRET_ACCESS_KEY` | (Común) |
| `AWS_REGION` | `us-east-1` |
| `ECR_REPOSITORY` | `emplea-humboldt-autenticacion` |
| `ECS_SERVICE` | `emplea-humboldt-autenticacion` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://[user]:[pass]@[host]:5432/auth_db` |
| `SECRET_KEY` | Generar con `openssl rand -hex 32` |
| `ALGORITHM` | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `60` |

#### Empleos
URL: `https://github.com/123samuel10/microservicio-empleos/settings/secrets/actions`

| Secret | Valor |
|--------|-------|
| (AWS secrets comunes) | ... |
| `ECR_REPOSITORY` | `emplea-humboldt-empleos` |
| `ECS_SERVICE` | `emplea-humboldt-empleos` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://[user]:[pass]@[host]:5432/emp_db` |
| `AUTENTICACION_SERVICE_URL` | `http://[alb_dns_name]/autenticacion` |

#### Postulaciones
URL: `https://github.com/123samuel10/microservicio-postulaciones/settings/secrets/actions`

| Secret | Valor |
|--------|-------|
| (AWS secrets comunes) | ... |
| `ECR_REPOSITORY` | `emplea-humboldt-postulaciones` |
| `ECS_SERVICE` | `emplea-humboldt-postulaciones` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://[user]:[pass]@[host]:5432/post_db` |
| `AUTENTICACION_SERVICE_URL` | `http://[alb_dns_name]/autenticacion` |
| `EMPLEOS_SERVICE_URL` | `http://[alb_dns_name]/empleos` |
| `NOTIFICACIONES_SERVICE_URL` | `http://[alb_dns_name]/notificaciones` |

#### Seguimiento
URL: `https://github.com/123samuel10/microservicio-seguimiento/settings/secrets/actions`

| Secret | Valor |
|--------|-------|
| (AWS secrets comunes) | ... |
| `ECR_REPOSITORY` | `emplea-humboldt-seguimiento_practicas` |
| `ECS_SERVICE` | `emplea-humboldt-seguimiento_practicas` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://[user]:[pass]@[host]:5432/pra_db` |
| `AUTENTICACION_SERVICE_URL` | `http://[alb_dns_name]/autenticacion` |
| `POSTULACIONES_SERVICE_URL` | `http://[alb_dns_name]/postulaciones` |

#### Notificaciones
URL: `https://github.com/123samuel10/microservicio-notificaciones/settings/secrets/actions`

| Secret | Valor |
|--------|-------|
| (AWS secrets comunes) | ... |
| `ECR_REPOSITORY` | `emplea-humboldt-notificaciones` |
| `ECS_SERVICE` | `emplea-humboldt-notificaciones` |
| `ECS_CLUSTER` | `emplea-humboldt-cluster` |
| `DATABASE_URL` | `postgresql+asyncpg://[user]:[pass]@[host]:5432/noti_db` |

---

## Paso 4: Desplegar Microservicios

### 4.1 Orden de Despliegue

**Importante:** Desplegar en este orden por dependencias:

1. **Autenticación** (sin dependencias)
2. **Notificaciones** (sin dependencias)
3. **Empleos** (necesita Autenticación)
4. **Postulaciones** (necesita Autenticación, Empleos, Notificaciones)
5. **Seguimiento** (necesita Autenticación, Postulaciones)

### 4.2 Proceso de Despliegue

Para **cada microservicio** en orden:

1. Ir a su repositorio → **Actions**
2. Click en el workflow **CD Pipeline**
3. **Run workflow** → Branch: **main** → **Run workflow**
4. Esperar ~5-7 minutos
5. Verificar que completó con ✓ verde

**Tiempo total:** ~25-35 minutos (si se ejecutan en paralelo después de satisfacer dependencias)

### 4.3 Verificación Rápida

Después de cada despliegue, verificar en **AWS Console** → **ECS** → **Clusters** → `emplea-humboldt-cluster`:

- Service debe estar **ACTIVE**
- Running tasks: **1**
- Task status: **RUNNING**
- Health status: **HEALTHY** (esperar ~1 minuto)

---

## Paso 5: Configurar Frontend

### 5.1 Agregar Variable de Entorno

**AWS Console** → **Amplify** → `emplea-humboldt-frontend`

1. **Environment variables** (panel izquierdo)
2. **Add environment variable**
3. Variable: `NEXT_PUBLIC_API_URL`
4. Value: El `api_gateway_url` del paso 2.3 (sin trailing slash adicional)
   - Ejemplo: `https://xxx.execute-api.us-east-1.amazonaws.com/prd`
5. **Save**

### 5.2 Desplegar Frontend

El frontend se despliega automáticamente con cada push a `main`.

Para forzar un redespliegue:
- **Amplify Console** → Tu app → Branch `main` → **Redeploy this version**

Esperar ~5-8 minutos.

### 5.3 Obtener URL

La URL del frontend aparece en Amplify Console:
- Ejemplo: `https://main.d2pzb9m4eoaiu0.amplifyapp.com`

---

## Verificación en AWS Console

### 1. RDS (Base de Datos)

**AWS Console → RDS → Databases**

✅ Verificar:
- DB Instance: `emplea-humboldt-postgres`
- Status: **Available**
- Engine: PostgreSQL 15.x

Las 5 bases de datos (`auth_db`, `emp_db`, `post_db`, `pra_db`, `noti_db`) se crean automáticamente con las migraciones de Alembic.

### 2. ECS (Contenedores)

**AWS Console → ECS → Clusters → emplea-humboldt-cluster**

✅ Verificar 5 servicios:
- `emplea-humboldt-autenticacion`
- `emplea-humboldt-empleos`
- `emplea-humboldt-postulaciones`
- `emplea-humboldt-seguimiento_practicas`
- `emplea-humboldt-notificaciones`

Cada uno debe tener:
- Status: **ACTIVE**
- Running tasks: **1**
- Desired tasks: **1**

Para cada servicio → Tab **Tasks** → Click en task ID → Tab **Logs**:
```
INFO: Started server process
INFO: Application startup complete
INFO: Uvicorn running on http://0.0.0.0:8000
```

### 3. Application Load Balancer

**AWS Console → EC2 → Load Balancers**

✅ Verificar:
- Name: `emplea-humboldt-alb`
- State: **active**

**EC2 → Target Groups**

Para cada target group (5 total):
- Health status: **healthy**

**Probar manualmente:**

```bash
curl http://[alb_dns_name]/autenticacion/health
curl http://[alb_dns_name]/empleos/health
curl http://[alb_dns_name]/postulaciones/health
curl http://[alb_dns_name]/seguimiento_practicas/health
curl http://[alb_dns_name]/notificaciones/health
```

Cada uno debe retornar:
```json
{"status":"healthy","service":"..."}
```

### 4. API Gateway

**AWS Console → API Gateway → emplea-humboldt-api**

✅ Verificar:
- Protocol: **HTTP**
- Stage: **prd**
- Routes: 5 rutas (una por microservicio)

**Probar:**

```bash
curl https://[api_gateway_url]/autenticacion/health
curl https://[api_gateway_url]/empleos/health
curl https://[api_gateway_url]/postulaciones/health
curl https://[api_gateway_url]/seguimiento_practicas/health
curl https://[api_gateway_url]/notificaciones/health
```

### 5. Frontend

**AWS Console → Amplify → emplea-humboldt-frontend**

✅ Verificar:
- Branch `main`: **Deployed**
- Last deploy: Exitoso
- Environment variable `NEXT_PUBLIC_API_URL`: Configurada

**Probar en navegador:**
- Abrir la URL de Amplify
- Registrarse como estudiante
- Hacer login
- Navegar a secciones (Empleos, Postulaciones)

### 6. CloudWatch Logs

**AWS Console → CloudWatch → Log groups**

Verificar que existen logs para:
- `/ecs/emplea-humboldt`

**Buscar errores:**
1. Click en el log group
2. **Search all**
3. Filtro: `ERROR`

---

## Troubleshooting

### ECS Tasks no inician (STOPPED)

**Diagnóstico:**
1. ECS → Cluster → Service → Tab **Events**
2. Leer el error

**Errores comunes:**

**"CannotPullContainerError"**
- Imagen no existe en ECR
- Solución: Re-ejecutar pipeline del microservicio

**"Essential container exited"**
- Error en la aplicación
- Solución: Ver logs en CloudWatch
- Común: Error de conexión a BD → Verificar DATABASE_URL

### Target Groups "unhealthy"

**Diagnóstico:**
1. EC2 → Target Groups → Click en target group
2. Tab **Targets** → Ver "Status details"

**"Health checks failed [502]"**
- Backend no responde
- Solución: Ver logs en CloudWatch, verificar que task está RUNNING

**"Connection refused"**
- Security Groups incorrectos
- Solución: Verificar que SG permite tráfico ALB → ECS puerto 8000

### Error 503 "No se pudo conectar con el servicio"

**Causa:** Microservicio no puede conectarse a otro microservicio

**Solución:**
1. Verificar que las URLs de servicios usan el ALB (no nombres DNS internos)
2. Formato correcto: `http://[alb_dns_name]/[servicio]`
3. Actualizar secrets y redesplegar

### Frontend no conecta al backend

**Diagnóstico:**
1. Abrir consola del navegador (F12)
2. Tab **Network**
3. Ver qué request falla

**Error 404:**
- `NEXT_PUBLIC_API_URL` incorrecta en Amplify
- Debe ser: `https://[id].execute-api.us-east-1.amazonaws.com/prd`

**Error CORS:**
- Verificar configuración CORS en microservicios
- Debe permitir origin de Amplify

### Pipeline de GitHub falla

**"AWS credentials not configured"**
- Secrets no configurados
- Solución: Verificar que AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY existen en el repo

**"Permission denied (ECR)"**
- IAM user sin permisos
- Solución: Adjuntar política `AmazonEC2ContainerRegistryFullAccess`

---

## Recursos Desplegados

### URLs Públicas

| Recurso | URL |
|---------|-----|
| Frontend | `https://main.[app-id].amplifyapp.com` |
| API Gateway | `https://[id].execute-api.us-east-1.amazonaws.com/prd` |

### Endpoints de API

Base: `https://[api_gateway_url]`

| Servicio | Health Check | Docs API |
|----------|--------------|----------|
| Autenticación | `/autenticacion/health` | `/autenticacion/docs` |
| Empleos | `/empleos/health` | `/empleos/docs` |
| Postulaciones | `/postulaciones/health` | `/postulaciones/docs` |
| Seguimiento | `/seguimiento_practicas/health` | `/seguimiento_practicas/docs` |
| Notificaciones | `/notificaciones/health` | `/notificaciones/docs` |

---

## Mantenimiento

### Actualizar Microservicio

1. Hacer cambios en el código
2. Commit y push a `main`
3. Pipeline se ejecuta automáticamente
4. ECS hace rolling update (sin downtime)

### Actualizar Frontend

1. Hacer cambios en el código
2. Commit y push a `main`
3. Amplify hace build automático

### Ver Logs en Tiempo Real

**CloudWatch** → Log groups → `/ecs/emplea-humboldt`

Filtrar por errores: `ERROR`

### Escalar Servicios

**ECS** → Cluster → Service → **Update service** → Cambiar **Desired tasks**

---

**Última actualización:** Junio 2026
**Versión:** 1.0.0
**Región:** us-east-1
