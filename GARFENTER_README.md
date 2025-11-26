# 🛍️ Garfenter Tienda - Tienda Guatemalteca en Línea

Una plataforma de comercio electrónico completa basada en Saleor, configurada específicamente para Guatemala.

## 🚀 Inicio Rápido

### Requisitos
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM mínimo
- 10GB espacio libre en disco

### Instalación en Un Solo Paso

```bash
./garfenter-start.sh
```

¡Eso es todo! En 2-3 minutos tendrás tu tienda funcionando.

## 🌐 Acceso

Después del despliegue:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| 🎨 Dashboard | http://localhost:9000/ | Panel de administración |
| 🔌 API GraphQL | http://localhost:8000/graphql/ | API para desarrolladores |
| 👨‍💼 Admin Django | http://localhost:8000/admin/ | Panel Django |
| 📧 Email Testing | http://localhost:8025/ | Visor de correos (Mailpit) |

## 🇬🇹 Configuración Guatemala

Preconfigurado para Guatemala:

- **💰 Moneda**: GTQ (Quetzal Guatemalteco)
- **🗺️ País**: Guatemala (GT)
- **🗣️ Idioma**: Español (es)
- **🕐 Zona Horaria**: America/Guatemala

## 📋 Primeros Pasos

### 1. Crear Usuario Administrador

```bash
docker exec -it garfenter-tienda python manage.py createsuperuser
```

### 2. Acceder al Dashboard

1. Abre http://localhost:9000/
2. Inicia sesión con tu usuario administrador
3. Completa el asistente de configuración inicial

### 3. Configurar Tu Tienda

- ✅ Información de la tienda
- ✅ Métodos de envío
- ✅ Categorías de productos
- ✅ Pasarelas de pago
- ✅ Plantillas de correo

## 🛠️ Comandos Útiles

```bash
# Ver logs en tiempo real
docker logs -f garfenter-tienda

# Detener servicios
./garfenter-stop.sh
# O manualmente:
docker-compose -f docker-compose.garfenter.yml down

# Reiniciar servicios
docker-compose -f docker-compose.garfenter.yml restart

# Acceder a la consola
docker exec -it garfenter-tienda bash

# Respaldar base de datos
docker exec garfenter-postgres pg_dump -U garfenter garfenter_tienda > respaldo.sql
```

## 📦 Servicios Incluidos

| Servicio | Contenedor | Puerto | Estado |
|----------|------------|--------|--------|
| API | garfenter-tienda | 8000 | ✅ Con healthcheck |
| Dashboard | garfenter-dashboard | 9000 | ✅ Con healthcheck |
| PostgreSQL | garfenter-postgres | 5432 | ✅ Con healthcheck |
| Redis | garfenter-redis | 6379 | ✅ Con healthcheck |
| Worker | garfenter-worker | - | ✅ Con healthcheck |
| Mailpit | garfenter-mailpit | 8025 | ✅ Con healthcheck |

## 📚 Documentación

- **[GARFENTER_DEPLOYMENT.md](GARFENTER_DEPLOYMENT.md)**: Guía completa de despliegue
- **[GARFENTER_COMMANDS.md](GARFENTER_COMMANDS.md)**: Referencia rápida de comandos
- **[Saleor Docs](https://docs.saleor.io/)**: Documentación oficial de Saleor

## 🔐 Seguridad

Para producción, asegúrate de:

- ✅ Cambiar `POSTGRES_PASSWORD` en `.env`
- ✅ Verificar que `SECRET_KEY` es único
- ✅ Configurar `DEBUG=False`
- ✅ Actualizar `ALLOWED_HOSTS` con tu dominio
- ✅ Configurar SSL/TLS
- ✅ Usar un servicio SMTP real
- ✅ Configurar respaldos automáticos

## 🆘 Soporte

### Problemas Comunes

**Los servicios no inician:**
```bash
docker-compose -f docker-compose.garfenter.yml logs
```

**Error de conexión a base de datos:**
```bash
docker exec garfenter-postgres pg_isready -U garfenter
```

**Puertos en uso:**
- Detén otros servicios en los puertos 8000, 9000, 5432, 6379
- O modifica los puertos en `docker-compose.garfenter.yml`

### Restablecer Todo

```bash
# ⚠️ ADVERTENCIA: Esto eliminará todos los datos
docker-compose -f docker-compose.garfenter.yml down -v
rm .env
./garfenter-start.sh
```

## 🏗️ Arquitectura

```
                    ┌─────────────────┐
                    │   Dashboard     │
                    │  (React SPA)    │
                    │   Port: 9000    │
                    └────────┬────────┘
                             │
                             │ GraphQL
                             ▼
┌─────────────────┐   ┌─────────────────┐   ┌──────────────┐
│   Mailpit       │◀──│   Saleor API    │──▶│  PostgreSQL  │
│ (Email Test)    │   │   (Django)      │   │  (Database)  │
│   Port: 8025    │   │   Port: 8000    │   │  Port: 5432  │
└─────────────────┘   └────────┬────────┘   └──────────────┘
                               │
                               │ Celery
                               ▼
                    ┌─────────────────┐   ┌──────────────┐
                    │  Celery Worker  │──▶│    Redis     │
                    │  (Background)   │   │   (Cache)    │
                    └─────────────────┘   │  Port: 6379  │
                                          └──────────────┘
```

## 🎯 Características

- ✅ **Multi-canal**: Vende en múltiples canales
- ✅ **Multi-moneda**: Soporte para GTQ y más
- ✅ **Multilenguaje**: Español e idiomas adicionales
- ✅ **GraphQL API**: API moderna y flexible
- ✅ **Dashboard Moderno**: Interfaz intuitiva
- ✅ **Escalable**: Arquitectura preparada para crecer
- ✅ **Extensible**: Sistema de plugins
- ✅ **Open Source**: Totalmente personalizable

## 📈 Próximos Pasos

1. **Personalizar Diseño**: Crea tu propio storefront
2. **Configurar Pagos**: Integra pasarelas de pago guatemaltecas
3. **Agregar Productos**: Comienza a cargar tu catálogo
4. **Configurar Envíos**: Establece zonas y tarifas de envío
5. **Marketing**: Configura descuentos y promociones

## 🤝 Contribuir

Este proyecto utiliza Saleor como base. Para contribuir:

- **Saleor**: https://github.com/saleor/saleor
- **Reportar Issues**: Usa el repositorio de Saleor para problemas del core

## 📄 Licencia

- Saleor: BSD-3-Clause
- Configuración Garfenter: Uso libre

## 🙏 Agradecimientos

Construido con:
- [Saleor](https://saleor.io/) - La plataforma de e-commerce
- [Django](https://www.djangoproject.com/) - Framework web
- [GraphQL](https://graphql.org/) - API query language
- [React](https://react.dev/) - Dashboard UI
- [PostgreSQL](https://www.postgresql.org/) - Base de datos
- [Redis](https://redis.io/) - Cache y message broker
- [Docker](https://www.docker.com/) - Containerización

---

**Hecho con ❤️ para Guatemala 🇬🇹**
