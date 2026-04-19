# TDSE Microservices Architecture

This project has been refactored from a monolith into three independent, scalable microservices ready for AWS Lambda deployment.

## Architecture Overview

### Services

1. **User Service** (Port 8081 locally)
   - Authentication and user profile management
   - Auth0 JWT validation
   - User CRUD operations
   - Database: PostgreSQL (tdse_users)
   - Endpoints: `/api/users/*`

2. **Posts Service** (Port 8082 locally)
   - Post management (CRUD)
   - Post queries and filtering
   - Database: PostgreSQL (tdse_posts)
   - Endpoints: `/api/posts/*`

3. **Stream Service** (Port 8083 locally)
   - Global feed aggregation
   - Calls Posts Service to get global timeline
   - No database (stateless)
   - Endpoints: `/api/stream/*`

### Database Isolation

Each service has its own PostgreSQL database:
- **User Service**: `tdse_users` (default port 5432)
- **Posts Service**: `tdse_posts` (default port 5433)
- **Stream Service**: Stateless (no database)

### Inter-Service Communication

Services communicate via REST HTTP calls:
- Posts Service calls User Service for user validation (future enhancement)
- Stream Service calls Posts Service to aggregate feed
- Uses `RestTemplate` with configurable base URLs

## Project Structure

```
services/
├── pom.xml                 # Parent POM (multi-module)
├── docker-compose.yml      # Local development environment
├── common-lib/             # Shared utilities
│   ├── pom.xml
│   └── src/main/java/org/eci/TdseApp/common/
│       └── security/       # Shared security config
├── user-service/           # User & Auth Service
│   ├── pom.xml
│   ├── Dockerfile          # Lambda container
│   ├── Dockerfile.dev      # Local dev container
│   ├── serverless.yml      # AWS Lambda deployment config
│   └── src/
├── posts-service/          # Post Management Service
│   ├── pom.xml
│   ├── Dockerfile
│   ├── Dockerfile.dev
│   ├── serverless.yml
│   └── src/
└── stream-service/         # Feed Aggregation Service
    ├── pom.xml
    ├── Dockerfile
    ├── Dockerfile.dev
    ├── serverless.yml
    └── src/
```

## Local Development

### Prerequisites

- Java 21+
- Maven 3.8+
- Docker & Docker Compose
- Auth0 tenant configured with OIDC credentials

### Setup

1. **Configure environment variables** (create `.env` file in services directory):

```bash
AUTH0_DOMAIN=your-auth0-domain.auth0.com
AUTH0_AUDIENCE=https://your-api.example.com
AUTH0_CLIENT_ID=your-client-id
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
SPRING_DATASOURCE_USERNAME=admin
SPRING_DATASOURCE_PASSWORD=rootpassword
```

2. **Build all services**:

```bash
cd services
mvn clean install -DskipTests
```

3. **Start services with Docker Compose**:

```bash
docker-compose up -d
```

This starts:
- PostgreSQL instances for users and posts databases
- All three microservices
- Flyway migrations run automatically on startup

4. **Access Swagger UIs**:

- User Service: http://localhost:8081/swagger-ui.html
- Posts Service: http://localhost:8082/swagger-ui.html
- Stream Service: http://localhost:8083/swagger-ui.html

### Stopping Services

```bash
docker-compose down
```

## Building for Deployment

### Build Lambda Packages

Each service builds an optimized JAR for Lambda with shade plugin:

```bash
cd services/user-service
mvn clean package
# Output: target/user-service.jar

cd ../posts-service
mvn clean package
# Output: target/posts-service.jar

cd ../stream-service
mvn clean package
# Output: target/stream-service.jar
```

### Docker Images for Lambda

Lambda container images use `public.ecr.aws/lambda/java:21` and are deployed via:

```bash
# Build and push to ECR
docker build -f Dockerfile -t <aws-account-id>.dkr.ecr.<region>.amazonaws.com/user-service:latest ./user-service
docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/user-service:latest
```

## AWS Lambda Deployment

### Prerequisites

- AWS CLI configured with credentials
- Serverless Framework installed: `npm install -g serverless`
- ECR repositories created in AWS

### Deployment with Serverless Framework

1. **Set environment variables**:

```bash
export AWS_REGION=us-east-1
export AUTH0_DOMAIN=your-domain.auth0.com
export AUTH0_AUDIENCE=https://your-api.example.com
export SPRING_DATASOURCE_URL=jdbc:postgresql://rds-endpoint:5432/tdse_users
export SPRING_DATASOURCE_USERNAME=admin
export SPRING_DATASOURCE_PASSWORD=<secure-password>
```

2. **Deploy each service**:

```bash
# User Service
cd services/user-service
mvn clean package
serverless deploy

# Posts Service
cd ../posts-service
mvn clean package
export USER_SERVICE_URL=<user-service-lambda-url>
serverless deploy

# Stream Service
cd ../stream-service
mvn clean package
export POSTS_SERVICE_URL=<posts-service-lambda-url>
serverless deploy
```

### Infrastructure Requirements

1. **RDS PostgreSQL** (or Aurora):
   - Create separate databases: `tdse_users`, `tdse_posts`
   - Network: Must be accessible from Lambda (VPC)
   - Flyway migrations run on service startup

2. **API Gateway**:
   - Automatically created by Serverless Framework
   - Routes `/api/*` to appropriate service

3. **IAM Roles**:
   - Lambda execution roles (defined in serverless.yml)
   - RDS access permissions

4. **CloudWatch Logs**:
   - Automatically created per Lambda function

## Configuration

### Environment Variables

**Common to all services:**
- `AUTH0_DOMAIN` - Auth0 domain (e.g., dev-abc.us.auth0.com)
- `AUTH0_AUDIENCE` - API identifier for JWT validation
- `AUTH0_CLIENT_ID` - For Swagger UI OAuth
- `CORS_ALLOWED_ORIGINS` - Comma-separated list of allowed origins

**User Service:**
- `SPRING_DATASOURCE_URL` - JDBC URL for users DB
- `SPRING_DATASOURCE_USERNAME` - Database user
- `SPRING_DATASOURCE_PASSWORD` - Database password

**Posts Service:**
- `SPRING_DATASOURCE_URL` - JDBC URL for posts DB (separate from users)
- `SPRING_DATASOURCE_USERNAME` - Database user
- `SPRING_DATASOURCE_PASSWORD` - Database password
- `USER_SERVICE_URL` - Internal URL to User Service

**Stream Service:**
- `POSTS_SERVICE_URL` - Internal URL to Posts Service

### Application Properties

Each service has `application.properties` with:
- Spring Boot config
- Database connection pool settings
- Flyway migration settings
- OpenAPI/Swagger config
- Security settings

## API Endpoints

### User Service
```
GET  /api/users/me          - Get current authenticated user profile
```

### Posts Service
```
GET  /api/posts             - List all posts (public)
GET  /api/posts/{id}        - Get single post (public)
POST /api/posts             - Create post (authenticated, requires write:posts scope)
PUT  /api/posts/{id}        - Update post (authenticated, owner only)
DELETE /api/posts/{id}      - Delete post (authenticated, owner only)
```

### Stream Service
```
GET  /api/stream            - Get global feed (public)
```

## Database Migrations

Flyway automatically runs migrations on service startup.

**User Service**: `services/user-service/src/main/resources/db/migration/`
- V1__init_users_table.sql - Creates users table with indexes

**Posts Service**: `services/posts-service/src/main/resources/db/migration/`
- V1__init_posts_table.sql - Creates posts table with indexes

To add migrations:
1. Create new file: `VX__description.sql` (sequential numbering)
2. Place in service's `db/migration/` folder
3. Service will automatically apply on next startup

## Security

- **JWT Validation**: Auth0 JWTs validated against JWKS endpoint
- **OAuth2 Resource Server**: Spring Security configured for bearer token validation
- **Scopes**: 
  - `read:profile` - Read user profile
  - `write:posts` - Create/update/delete posts
- **CORS**: Configurable origins, credentials allowed
- **Database**: Separate databases prevent lateral movement

## Performance Considerations

### Lambda Optimization

- **Memory**: Configured per service
  - User Service: 1024 MB
  - Posts Service: 1024 MB
  - Stream Service: 512 MB (stateless)
- **Timeout**: 30 seconds per service
- **Initialization**: Spring Cloud Function handler pre-warms on first invocation

### Database

- Connection pooling via HikariCP
- Indexes on frequently queried columns (auth0_sub, user_id, created_at)
- Separate databases prevent contention

### Caching (Future)

Consider adding:
- Redis for user lookup caching
- CloudFront for static API responses
- ElastiCache for feed caching

## Testing

Run tests locally:

```bash
cd services
mvn test

# Run specific service tests
cd user-service
mvn test

cd ../posts-service
mvn test

cd ../stream-service
mvn test
```

## Monitoring & Logging

- **CloudWatch Logs**: All Lambda services log to CloudWatch
- **Structured Logging**: JSON formatted logs via Spring Boot
- **Metrics**: Can be enabled via CloudWatch Insights
- **Tracing**: Can be enabled via X-Ray

## Troubleshooting

### Service Won't Start

Check logs in docker-compose:
```bash
docker-compose logs user-service
docker-compose logs posts-service
docker-compose logs stream-service
```

### Database Connection Errors

Verify:
- PostgreSQL containers are running: `docker-compose ps`
- Correct database names and credentials
- Network connectivity between services

### JWT Validation Failures

Verify:
- Auth0 domain is correct
- Audience matches your API identifier
- Token issued by Auth0 tenant

### Inter-Service Communication Issues

Check:
- Service URLs are correct (use service names in docker-compose, URLs in Lambda)
- Network connectivity
- No firewall blocking ports

## Scaling Considerations

1. **Horizontal Scaling**:
   - Lambda automatically scales based on requests
   - RDS: Use Aurora for auto-scaling or provisioned capacity

2. **Database Bottleneck**:
   - Consider read replicas for posts
   - Implement caching layer

3. **API Gateway**:
   - Default 10,000 requests/second limit
   - Can be increased via support ticket

## Future Enhancements

1. **Messaging Queue**: Add SQS/SNS for async operations
2. **Service Mesh**: Implement Istio for advanced traffic management
3. **Event Sourcing**: Log all domain events for audit trail
4. **CQRS**: Separate read/write models for optimization
5. **Multi-region**: Deploy to multiple regions with DynamoDB global tables
6. **WebSockets**: Real-time feed updates via API Gateway WebSocket API
7. **Caching Layer**: Redis for frequently accessed data

## Migration from Monolith

The original monolithic `backend/` has been successfully decomposed:

**User Module** → User Service
- UserEntity, UserService, UserController
- Auth0 JWT validation
- User profile endpoints

**Post Module** → Posts Service  
- PostEntity, PostService, PostController, PostMapper
- Post CRUD operations
- Separate database

**Stream Module** → Stream Service
- StreamController moved to Stream Service
- Now aggregates data from Posts Service
- Stateless, scalable design

**Shared Code** → Common Library
- SecurityConfig, AudienceValidator
- Available to all services