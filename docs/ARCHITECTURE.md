# 🏗️ Arquitectura del Sistema

Documentación técnica de la arquitectura de NestJS Stripe Notion Automation.

## 📊 Diagrama de Arquitectura General

```mermaid
graph TB
    subgraph "🌐 Cliente"
        A[Cliente Web/Mobile]
    end
    
    subgraph "💳 Stripe Platform"
        B[Stripe Checkout]
        C[Stripe Dashboard]
        D[Stripe Webhooks]
    end
    
    subgraph "☁️ Fly.io Cloud"
        subgraph "🐳 Docker Container"
            E[NestJS Application]
            subgraph "📱 Controllers"
                F[StripeController]
                G[AppController]
            end
            subgraph "⚙️ Services"
                H[StripeService]
                I[PaymentsService] 
                J[NotionService]
            end
        end
    end
    
    subgraph "📚 Notion Workspace"
        K[Clients Database]
        L[Payments Database]
    end
    
    subgraph "🔐 1Password"
        M[Test Credentials]
        N[Production Credentials]
        O[Notion Secrets]
    end
    
    %% Flujo de pago
    A -->|1. Inicia Pago| B
    B -->|2. Procesa Pago| D
    D -->|3. Webhook Event| F
    F -->|4. Valida Firma| H
    H -->|5. Procesa Evento| I
    I -->|6. Obtiene Customer| H
    I -->|7. Crea/Actualiza| J
    J -->|8. Guarda Cliente| K
    J -->|9. Registra Pago| L
    
    %% Configuración
    M -.->|Dev Environment| E
    N -.->|Prod Environment| E
    O -.->|Notion Integration| E
    C -.->|Webhook Config| D
```

## 🔄 Flujo de Datos Detallado

```mermaid
sequenceDiagram
    participant C as Cliente
    participant SC as Stripe Checkout
    participant SW as Stripe Webhooks
    participant App as NestJS App
    participant Stripe as Stripe API
    participant Notion as Notion API
    
    Note over C,Notion: 💳 Proceso de Pago Completo
    
    C->>SC: 1. Inicia proceso de pago
    SC->>SW: 2. Payment successful
    SW->>App: 3. POST /webhook/stripe
    
    Note over App: 🔐 Validación de Seguridad
    App->>App: 4. Verifica firma webhook
    App->>App: 5. Valida evento tipo
    
    Note over App,Stripe: 📋 Obtención de Datos
    App->>Stripe: 6. GET payment details
    Stripe-->>App: 7. Payment + Customer data
    
    Note over App,Notion: 💾 Guardado en Notion
    App->>Notion: 8. Create/Update Client
    Notion-->>App: 9. Client page ID
    App->>Notion: 10. Create Payment record
    Notion-->>App: 11. Payment page ID
    App->>Notion: 12. Update client total
    
    App-->>SW: 13. 200 OK (processed)
    
    Note over C,Notion: ✅ Proceso Completado
```

## 🏛️ Arquitectura de Módulos NestJS

```mermaid
graph TD
    subgraph "🎯 Application Layer"
        A[AppModule]
        B[AppController]
        C[Health Check]
    end
    
    subgraph "💳 Stripe Module"
        D[StripeModule]
        E[StripeController]
        F[StripeService]
    end
    
    subgraph "💰 Payments Module"
        G[PaymentsModule]
        H[PaymentsService]
    end
    
    subgraph "📚 Notion Module"
        I[NotionModule]
        J[NotionService]
    end
    
    subgraph "⚙️ Config Module"
        K[ConfigModule]
        L[Environment Variables]
    end
    
    A --> D
    A --> G
    A --> I
    A --> K
    
    E --> F
    E --> H
    H --> F
    H --> J
    
    D --> K
    G --> K
    I --> K
```

## 🗃️ Estructura de Bases de Datos (Notion)

```mermaid
erDiagram
    CLIENTS {
        string id PK
        string name
        string email UK
        string phone
        date lastPaymentDate
        number totalPaid
        date createdAt
        date updatedAt
    }
    
    PAYMENTS {
        string id PK
        string paymentName
        number amount
        string currency
        string transactionId UK
        string paymentMethod
        string status
        string customerEmail
        string clientPageId FK
        date date
        date createdAt
    }
    
    CLIENTS ||--o{ PAYMENTS : "has many"
```

## 🔐 Gestión de Credenciales

```mermaid
graph LR
    subgraph "🧪 Development"
        A[NestJS Stripe API]
        B[NestJS Stripe Webhook]
    end
    
    subgraph "🏭 Production"
        C[NestJS Stripe API PROD]
        D[NestJS Stripe Webhook PROD]
    end
    
    subgraph "📚 Shared"
        E[NestJS Notion Integration]
        F[NestJS Notion Databases]
    end
    
    subgraph "🌍 Environments"
        G[NODE_ENV=development]
        H[NODE_ENV=production]
    end
    
    G --> A
    G --> B
    G --> E
    G --> F
    
    H --> C
    H --> D
    H --> E
    H --> F
```

## 🚀 Infraestructura de Deployment

```mermaid
graph TB
    subgraph "💻 Desarrollo Local"
        A[Docker Compose]
        B[Stripe CLI]
        C[1Password CLI]
    end
    
    subgraph "🔄 GitHub Repository"
        D[develop branch]
        E[main branch]
        F[GitHub Actions]
    end
    
    subgraph "🧪 Staging Environment"
        G[nestjs-stripe-notion-dev]
        H[Auto-scaling]
        I[Health Checks]
    end
    
    subgraph "🏭 Production Environment"
        J[nestjs-stripe-notion]
        K[Auto-scaling]
        L[Health Checks]
    end
    
    subgraph "🌐 External Services"
        M[Stripe API Test]
        N[Stripe API Live]
        O[Notion API]
        P[1Password Vault]
    end
    
    subgraph "📚 Notion Databases"
        Q[Clients DEV]
        R[Payments DEV]
        S[Clients PROD]
        T[Payments PROD]
    end
    
    A --> D
    D --> F
    E --> F
    F -->|Auto Deploy| G
    F -->|Auto Deploy| J
    
    G --> H
    G --> I
    J --> K
    J --> L
    
    G --> M
    G --> Q
    G --> R
    J --> N
    J --> S
    J --> T
    
    G --> O
    J --> O
    C --> P
    G --> P
    J --> P
```

## 📊 Métricas y Monitoreo

```mermaid
graph LR
    subgraph "📈 Application Metrics"
        A[Health Checks]
        B[Response Times]
        C[Error Rates]
    end
    
    subgraph "💳 Business Metrics"
        D[Payments Processed]
        E[Webhook Success Rate]
        F[Client Registration]
    end
    
    subgraph "🖥️ Infrastructure Metrics"
        G[CPU Usage]
        H[Memory Usage]
        I[Network Traffic]
    end
    
    subgraph "🔍 Monitoring Tools"
        J[Fly.io Dashboard]
        K[Application Logs]
        L[Stripe Dashboard]
    end
    
    A --> J
    B --> J
    C --> K
    D --> L
    E --> L
    F --> K
    G --> J
    H --> J
    I --> J
```

## 🔧 Tecnologías Utilizadas

| Categoría | Tecnología | Propósito |
|-----------|------------|-----------|
| **Backend** | NestJS | Framework principal |
| **Runtime** | Node.js 20 | Entorno de ejecución |
| **Package Manager** | pnpm | Gestión de dependencias |
| **Container** | Docker | Containerización |
| **Hosting** | Fly.io | Cloud hosting |
| **Payment** | Stripe | Procesamiento de pagos |
| **Database** | Notion | Base de datos y CRM |
| **Secrets** | 1Password | Gestión de credenciales |
| **Linting** | Biome | Code quality |
| **Version Control** | Git + GitHub | Control de versiones |

## 📝 Patrones de Diseño Implementados

### 🏗️ Architectural Patterns
- **Modular Architecture**: Separación en módulos funcionales
- **Dependency Injection**: IoC container de NestJS
- **Repository Pattern**: Abstracción de acceso a datos

### 🔄 Integration Patterns  
- **Webhook Pattern**: Comunicación asíncrona con Stripe
- **API Gateway Pattern**: NestJS como punto de entrada
- **Circuit Breaker**: Manejo de errores en APIs externas

### 🛡️ Security Patterns
- **Webhook Signature Validation**: Verificación de integridad
- **Environment-based Config**: Separación de credenciales
- **Secrets Management**: 1Password como vault centralizado

## 🚨 Consideraciones de Seguridad

1. **✅ Webhook Verification**: Todas las firmas son validadas
2. **✅ HTTPS Only**: Forzado en producción 
3. **✅ Environment Separation**: Credenciales separadas test/prod
4. **✅ Secrets Management**: 1Password para credenciales
5. **✅ Security Headers**: Headers de seguridad configurados
6. **✅ Non-root User**: Container ejecuta como usuario no privilegiado

## 📈 Escalabilidad

### Horizontal Scaling
- **Auto-scaling**: Fly.io maneja escalado automático
- **Load Balancing**: Distribuido por Fly.io
- **Multi-region**: Posible despliegue global

### Vertical Scaling  
- **CPU**: Escalable desde shared a dedicated
- **Memory**: Configurable desde 256MB
- **Storage**: Ephemeral, datos en Notion

### Performance Optimizations
- **Docker Multi-stage**: Imagen optimizada
- **Auto-stop/start**: Ahorro de recursos
- **Health Checks**: Detección proactiva de problemas 