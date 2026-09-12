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

**Reglas de Firestore (para desarrollo inicial):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // Solo para desarrollo, cambiar para producción
    }
  }
}
```

### 3. Configurar Authentication

1. En Firebase Console, ve a **Authentication**
2. Haz clic en "Get Started"
3. En la pestaña **Sign-in method**, selecciona **Email/Password**
4. Habilita el proveedor y haz clic en "Save"

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

- [ ] Modelo de datos para Users, Groups, Children, Payments
- [ ] Pantalla de autenticación (Login/Registro)
- [ ] Pantalla principal de gestión de grupos
- [ ] Pantalla de registro de pagos
- [ ] Lógica de negocio para cálculos y notificaciones

## Soporte

Para problemas relacionados con Firebase:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)