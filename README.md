# Mini-Twitter: Microservicios Serverless en AWS

**Integrantes:** Juan Pablo Contreras · Juan Carlos Leal · Tomas Ramirez

Aplicación estilo Twitter donde usuarios autenticados publican posts de máximo 140 caracteres en un feed global. Evolucionó de un Monolito Spring Boot a Microservicios 100% Serverless en AWS, asegurada con Auth0.

---

## Arquitectura

### Fase 1 — Monolito Spring Boot + Auth0
![Arquitectura Monolito](docs/monolith_architecture.png)

### Fase 2 — Microservicios AWS Lambda + DynamoDB
![Arquitectura Microservicios](docs/microservices_architecture.png)

**Stack:** React (Vite) · Auth0 · AWS Lambda · AWS API Gateway · Amazon DynamoDB · Serverless Framework

---

## Instalacion y Uso

### Requisitos previos
- Node.js v18+
- Java 21 + Maven
- Cuenta AWS con credenciales configuradas
- Cuenta Auth0

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/MicroserviciosLambda.git
cd MicroserviciosLambda
```

### 2. Configurar el Frontend
```bash
cd frontend
```
Crea el archivo `.env`:
```env
VITE_AUTH0_DOMAIN=dev-osmyby26lkp0anye.us.auth0.com
VITE_AUTH0_CLIENT_ID=4QPFkPQsXo9kKVGkuo0H1KbypiOASLjk
VITE_AUTH0_AUDIENCE=https://twitter
```
```bash
npm install
npm run dev        # Corre en http://localhost:5173
```

### 3. Desplegar Microservicios en AWS
```bash
cd services
```
Configura tus credenciales en `C:\Users\tu-usuario\.aws\credentials`:
```ini
[default]
aws_access_key_id=TU_KEY
aws_secret_access_key=TU_SECRET
aws_session_token=TU_TOKEN
```
```bash
npm install
npx serverless deploy
```
Al finalizar, la terminal imprime la URL del API Gateway. Cópiala y pégala en `frontend/src/App.jsx` en la variable `API_URL`.

### 4. Correr el Monolito (opcional)
```bash
cd backend
mvn spring-boot:run    # Swagger en http://localhost:8080/swagger-ui/index.html
```

---

## Proceso de Despliegue en AWS

El despliegue se realiza en un solo comando (`sls deploy`) desde la carpeta `services/`. El Serverless Framework se encarga automáticamente de:
1. Crear la tabla **DynamoDB** (`twitter-posts-table-dev`).
2. Empaquetar y subir las 3 funciones **Lambda** (`getStream`, `createPost`, `getUser`).
3. Crear el **HTTP API Gateway** con el autorizador JWT nativo de Auth0.

El frontend se despliega en **Amazon S3** como sitio web estático:
```bash
cd frontend
npm run build
aws s3 sync dist/ s3://NOMBRE-TU-BUCKET/ --delete
```

---

## Evidencias

### Configuracion de Auth0
![API Auth0](docs/ApiAuth0.png)

![Configuracion Seguridad Auth0](docs/ConfiguracionSeguridadAuth0.png)

### Aplicacion en funcionamiento
![Aplicacion Funcionando](docs/Aplicacion%20Funcionando.png)

![Ingreso con Seguridad](docs/Ingreso%20con%20seguridad.png)

![Aplicacion corriendo en AWS](docs/Aplicacion%20corriendo%20AWS.png)

### Swagger UI
![Swagger](docs/Swagger.png)

### Base de Datos DynamoDB
![DynamoDB](docs/BaseDatosDynamoDB.png)

---

## Pruebas Realizadas

| # | Prueba | Resultado |
|---|---|---|
| 1 | `GET /api/stream` sin token | `200 OK` — Feed público accesible |
| 2 | `POST /api/posts` sin token | `401 Unauthorized` — Endpoint protegido |
| 3 | `GET /api/me` sin token | `401 Unauthorized` — Endpoint protegido |
| 4 | Post > 140 caracteres | `400 Bad Request` — Validación activa |
| 5 | Login con Google via Auth0 | JWT válido, `authorId` guardado en DynamoDB |

---

## Conclusiones

- La arquitectura Serverless elimina la administración de servidores y escala automáticamente.
- Auth0 simplifica la autenticación, evitando implementar seguridad desde cero.
- DynamoDB ofrece alta disponibilidad sin configuración de base de datos.
- Un solo comando (`sls deploy`) aprovisiona toda la infraestructura en AWS.

---

## Links

- **App en AWS S3:** https://twitter-frontend-tomas-20260421.s3.amazonaws.com/index.html
- **Video:** `[PEGAR LINK DEL VIDEO AQUI]`

---
*Assignment - EXPERIMENTAL: Building a Secure Twitter-like Application with Microservices and Auth0*

