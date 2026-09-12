# Payment Control - Control de Pagos

Aplicación Flutter para gestionar el control de pagos en grupos de estudiantes de música, utilizando Firebase como backend.

## Configuración de Firebase

Este proyecto requiere configuración manual de Firebase. Sigue estos pasos:

### 1. Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Create a project"
3. Asigna un nombre al proyecto (ej: "payment-control")
4. Opcionalmente habilita Google Analytics (puedes deshabilitarlo para este proyecto)
5. Crea el proyecto

### 2. Configurar Firestore Database

1. En Firebase Console, ve a **Firestore Database**
2. Haz clic en "Create database"
3. Selecciona la ubicación (recomendado: una cerca de tu ubicación)
4. Elige **Start in production mode** o **Start in test mode** (test mode permite acceso público inicial)
5. Crea la base de datos

**Reglas de Firestore:**

Este proyecto ya usa reglas de producción (ver `firestore.rules` en la raíz),
que exigen sesión iniciada (`request.auth != null`) para leer o escribir en
las colecciones `grupos`, `ninos` y `abonos`. Despliega ese archivo con:

```bash
firebase deploy --only firestore:rules
```

### 3. Configurar Authentication

1. En Firebase Console, ve a **Authentication**
2. Haz clic en "Get Started"
3. En la pestaña **Sign-in method**, selecciona **Email/Password**
4. Habilita el proveedor y haz clic en "Save"

### 3.1 Crear los usuarios manualmente (Carito y "El Otro")

La app **no tiene pantalla de registro pública**: por seguridad, los únicos
usuarios que pueden ingresar son los que se crean manualmente desde la
consola de Firebase. Ambos usuarios tienen acceso completo a la app (no hay
roles diferenciados). Para crear cada usuario:

1. En Firebase Console, ve a **Authentication > Users**
2. Haz clic en **"Add user"**
3. Ingresa el correo electrónico del usuario (ej. `carito@ejemplo.com`)
4. Ingresa una contraseña segura (mínimo 6 caracteres, recomendado usar un
   gestor de contraseñas para generarla)
5. Haz clic en **"Add user"** para confirmar
6. Repite los pasos 2-5 para el segundo usuario ("El Otro")
7. Comparte las credenciales con cada persona por un canal seguro (no por
   correo ni chat sin cifrar)

**Notas:**
- Si un usuario olvida su contraseña, por ahora debe pedirte que se la
  cambies manualmente desde **Authentication > Users** (clic en el usuario
  → "Reset password" o edítala directamente). La recuperación de contraseña
  self-service dentro de la app no está implementada todavía.
- Para revocar el acceso de alguien, simplemente elimina o deshabilita su
  usuario desde esa misma pantalla.

### 4. Configurar Hosting (Opcional, para web deployment)

1. En Firebase Console, ve a **Hosting**
2. Haz clic en "Get Started"
3. Sigue las instrucciones para inicializar hosting (opcional para este proyecto)

### 5. Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

### 6. Autenticarse en Firebase

```bash
firebase login
```

### 7. Configurar el proyecto Flutter con Firebase

**IMPORTANTE:** Este paso generará el archivo `lib/firebase_options.dart` con las credenciales reales:

```bash
flutterfire configure
```

Este comando:
- Te pedirá seleccionar el proyecto Firebase que creaste
- Detectará las plataformas configuradas en tu proyecto (Android, iOS, Web, etc.)
- Generará automáticamente el archivo `lib/firebase_options.dart` con las credenciales correctas

### 8. Actualizar el código

El archivo `lib/firebase_options.dart` será reemplazado automáticamente por `flutterfire configure`. 
El placeholder actual en ese archivo será eliminado y reemplazado por las credenciales reales.

Verifica que `main.dart` importe el archivo generado:

```dart
import 'firebase_options.dart';
```

### 9. Inicializar Firebase en la aplicación

En `main.dart`, inicializa Firebase antes de la app:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## Ejecutar el proyecto

### En Chrome (Web):
```bash
flutter run -d chrome
```

### En Android:
```bash
flutter run -d android
```

### En iOS:
```bash
flutter run -d ios
```

## Estructura del proyecto

```
lib/
├── models/          # Modelos de datos (User, Group, Payment, etc.)
├── screens/         # Pantallas de la aplicación
├── services/        # Servicios de Firebase y lógica de negocio
├── widgets/         # Componentes reutilizables
├── main.dart        # Punto de entrada de la aplicación
└── firebase_options.dart  # Configuración de Firebase (generado por flutterfire)
```

## Notas importantes

- **Nunca compartas las credenciales de Firebase** (`firebase_options.dart`)
- Este archivo ya está configurado en `.gitignore` para evitar commits accidentales
- Para producción, actualiza las reglas de Firestore y Authentication para mayor seguridad
- El archivo `.gitignore` está configurado para excluir credenciales y archivos sensibles

## Próximos pasos (implementación pendiente)

- [x] Modelo de datos para Grupos, Niños, Abonos
- [x] Pantalla de autenticación (Login; sin registro público, ver sección 3.1)
- [x] Pantalla principal de gestión de grupos
- [x] Pantalla de registro de pagos
- [ ] Recuperación de contraseña ("olvidé mi contraseña") dentro de la app
- [ ] Lógica de negocio adicional para notificaciones

## Despliegue a producción

La app web se despliega como PWA (Progressive Web App) en Firebase Hosting.
`firebase.json` ya está configurado para servir el contenido generado en
`build/web`. Para desplegar una nueva versión, ejecuta estos comandos en orden:

```bash
flutter build web --release
firebase deploy --only hosting
```

- **`flutter build web --release`**: compila la app Flutter para web en modo
  release (optimizada, minificada) y genera todos los archivos estáticos
  (HTML, JS, assets, `manifest.json`, íconos, etc.) en la carpeta `build/web`.
- **`firebase deploy --only hosting`**: sube el contenido de `build/web` (según
  la configuración `"public": "build/web"` en `firebase.json`) a Firebase
  Hosting, publicando la nueva versión en la URL del proyecto.

Requisitos previos: tener Firebase CLI instalado y haber iniciado sesión
(`firebase login`), y que el proyecto Flutter esté correctamente enlazado al
proyecto de Firebase (ver `.firebaserc` / `flutterfire configure`).

### Iconos de la PWA

Los íconos en `web/icons/` (`Icon-192.png`, `Icon-512.png`,
`Icon-maskable-192.png`, `Icon-maskable-512.png`) y `web/favicon.png` son
**placeholders generados automáticamente**: un cuadro azul con las iniciales
"CP". Puedes reemplazarlos en cualquier momento por un diseño real,
manteniendo los mismos nombres de archivo y tamaños (192x192 y 512x512, más
sus versiones maskable) para que `manifest.json` siga funcionando sin
cambios adicionales.

### Instalar la PWA en un iPhone

Una vez desplegada la app en Firebase Hosting, para instalarla en la pantalla
de inicio de un iPhone:

1. Abre la URL de la app **en Safari** (en iOS, "Agregar a pantalla de
   inicio" para PWAs solo está disponible en Safari; no funciona desde Chrome
   ni otros navegadores en iOS).
2. Toca el botón de **compartir** (el ícono del cuadrado con la flecha hacia
   arriba, en la barra inferior o superior de Safari).
3. Selecciona **"Agregar a pantalla de inicio"** ("Add to Home Screen").
4. Confirma el nombre y toca **"Agregar"**.

La app quedará instalada como un ícono más en la pantalla de inicio y se
abrirá en modo standalone (sin la barra de navegación de Safari), usando el
ícono y el nombre configurados en `web/manifest.json` y `web/index.html`.

## Soporte

Para problemas relacionados con Firebase:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)