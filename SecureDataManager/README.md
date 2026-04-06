# SecureDataManager

Aplicación iOS de cifrado de información personal con seguridad de grado militar.

## Características de Seguridad

### 🔐 Autenticación de Dos Factores
- **Factor 1**: Contraseña maestra segura (PBKDF2 con 600,000 iteraciones)
- **Factor 2**: Face ID / Touch ID según disponibilidad del dispositivo

### 🛡️ Protección contra Fuerza Bruta
- Contador de intentos fallidos con ofuscación
- Bloqueo temporal progresivo: 1min → 5min → 15min → 1hora
- Bloqueo permanente después de 10 intentos

### 🔑 Shamir Secret Sharing
- 5 fragmentos de recuperación generados
- 3 fragmentos necesarios para reconstruir el acceso
- Implementación basada en curvas polinómicas en campo finito GF(p)

### 🔒 Cifrado AES-256-GCM
- Cifrado autenticado (AEAD) con CryptoKit
- Cada campo sensible cifrado individualmente
- Nonces únicos para cada operación de cifrado
- Tags de autenticación para integridad de datos

### 📦 Almacenamiento Seguro
- **Keychain**: Clave maestra, salt y hash de contraseña
- **Accesibilidad**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Datos cifrados almacenados localmente en Document Directory

## Arquitectura

```
SecureDataManager/
├── Models/              # Modelos de datos cifrados
├── Crypto/              # Servicios de cifrado (AES-256-GCM, SSS)
├── Security/            # Keychain, protección fuerza bruta
├── ViewModels/          # Lógica de negocio
├── Views/               # Interfaces de usuario
│   ├── Auth/            # Login y autenticación
│   ├── Setup/           # Configuración inicial
│   ├── Recovery/        # Recuperación de contraseña
│   ├── Main/            # Navegación principal
│   ├── Accounts/        # Gestión de cuentas
│   ├── Documents/       # Gestión de documentos
│   └── Photos/          # Gestión de fotos
└── Utils/               # Utilidades y extensiones
```

## Categorías de Datos

### Cuentas
- Almacena credenciales de servicios
- Campos: servicio, usuario, email, contraseña, notas, TOTP
- Cifrado de campo individual

### Documentos
- Soporta PDF, TXT, MD y otros formatos
- Vista previa segura
- Importación desde Files

### Fotos
- Cifrado completo de imágenes
- Thumbnails cifrados para mejor UX
- Captura directa desde cámara
- Importación desde galería

## Requisitos

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Frameworks Utilizados

- **CryptoKit**: Cifrado AES-256-GCM
- **LocalAuthentication**: Face ID / Touch ID
- **Security**: Keychain
- **CommonCrypto**: PBKDF2

## Compilación

1. Abrir `SecureDataManager.xcodeproj`
2. Seleccionar un simulador o dispositivo
3. Compilar y ejecutar (⌘+R)

## Notas de Seguridad

- La aplicación **no** almacena la contraseña en texto plano
- La clave maestra solo existe en memoria durante la sesión
- Sin los códigos de recuperación, los datos no pueden recuperarse
- Todas las operaciones criptográficas son locales

## Licencia

Proyecto privado - Todos los derechos reservados.
