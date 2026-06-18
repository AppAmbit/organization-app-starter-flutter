# Flutter Code Review — claudereview1

> Revisión al estilo SonarQube · Senior Flutter Engineer · Junio 2026

---

## Resumen Ejecutivo

| Métrica | Valor |
|---|---|
| Archivos revisados | 29 |
| 🔴 Critical | 5 |
| 🟡 Major | 18 |
| 🟢 Minor | 12 |
| Score estimado | **C+** (código funcional, arquitectura necesita refactor) |

El código corre correctamente y la estructura de features es buena. Los problemas más graves son: lógica de negocio mezclada con UI en `main.dart`, duplicación severa de `_buildImage` en 4 archivos, acoplamiento directo entre la capa de estado (Riverpod) y la capa de UI (SnackBar), y strings de navegación hardcodeados en múltiples lugares sin constante compartida.

---

## Issues por Categoría

---

### 1. Bugs / Correctness

#### 🔴 BUG-01 — `Uri.parse` puede lanzar excepción en bloque `button`
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — línea 168

`Uri.parse(buttonUrl)` lanza `FormatException` si `buttonUrl` está malformado. El bloque no tiene `try-catch` para este caso.

```dart
// ❌ Ahora
final uri = Uri.parse(buttonUrl);
if (await canLaunchUrl(uri)) { ... }

// ✅ Fix
final uri = Uri.tryParse(buttonUrl);
if (uri != null && await canLaunchUrl(uri)) { ... }
```

---

#### 🔴 BUG-02 — Color parsing de 8 dígitos produce color incorrecto
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 156-159

Si `buttonColor` viene como `#FF6C63FF` (8 chars con alpha), el código suma `0xFF000000` sobre un valor que ya incluye alpha, resultando en un color erróneo. No valida la longitud del string.

```dart
// ❌ Ahora
buttonColor = Color(int.parse(block.buttonColor!.substring(1), radix: 16) + 0xFF000000);

// ✅ Fix
final hex = block.buttonColor!.substring(1);
if (hex.length == 6) {
  buttonColor = Color(int.parse(hex, radix: 16) + 0xFF000000);
} else if (hex.length == 8) {
  buttonColor = Color(int.parse(hex, radix: 16));
}
```

---

#### 🟡 BUG-03 — ID vacío en `FeedCollection` y `CollectionItem` produce colisiones de hash
**Archivos:**
- `lib/features/home/models/feed_collection.dart` — línea 77
- `lib/features/home/models/collection_item.dart` — línea 35

Si el CMS retorna un registro sin `id` ni `lookup_key`, el id queda `''`. Dos registros sin id tendrán el mismo `hashCode`, y el `sectionItemsProvider.family` los tratará como la misma clave.

```dart
// ❌ Ahora
id: map['id']?.toString() ?? map['lookup_key']?.toString() ?? '',

// ✅ Fix — generar id único como fallback
id: map['id']?.toString() ?? map['lookup_key']?.toString() 
    ?? 'fallback_${DateTime.now().microsecondsSinceEpoch}',
```

---

#### 🟡 BUG-04 — `_VideoBlockPlayer._initializePlayer` descarta el error silenciosamente
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 227-229

```dart
// ❌ Ahora
} catch (e) {
  if (mounted) setState(() { _isError = true; });
}

// ✅ Fix — loguear para debugging
} catch (e, st) {
  debugPrint('[VideoPlayer] init failed: $e\n$st');
  if (mounted) setState(() { _isError = true; });
}
```

---

#### 🟡 BUG-05 — `upsert` en `NotificationsRepository` no llama `prefs.reload()`
**Archivo:** `lib/features/notifications/data/notifications_repository.dart` — líneas 31-41

`load()` llama `prefs.reload()` para ver escrituras del isolate Android. `upsert()` no lo hace, entonces si el background isolate escribió algo y a continuación llega un foreground push que llama `upsert`, se perderán las entradas del background.

```dart
Future<List<NotificationModel>> upsert(NotificationModel item) async {
  final prefs = await _prefs;
  await prefs.reload(); // ← agregar
  final items = _read(prefs);
  ...
}
```

---

### 2. SOLID

#### 🔴 SRP-01 — `main.dart` tiene demasiadas responsabilidades (God File)
**Archivo:** `lib/main.dart` — todo el archivo (~410 líneas)

Un solo archivo contiene: configuración de la app, tematización, gestión de ciclo de vida, lógica de push notifications, navegación post-tap, gestión del estado `bottomBarVisible`, y 4 clases de UI (`AppShell`, `_AnimatedBottomTabBar`, `_TabItemData`, `_AnimatedTabItem`).

**Fix:** Separar en archivos:
- `lib/app/app_shell.dart` — `AppShell` + `_AppShellState`
- `lib/app/bottom_tab_bar.dart` — `_AnimatedBottomTabBar`, `_AnimatedTabItem`, `_TabItemData`
- `lib/app/app_providers.dart` — `BottomBarVisibleNotifier` + `bottomBarVisibleProvider`
- `lib/app/main_app.dart` — `MainApp` + `MaterialApp`

---

#### 🔴 SRP-02 — `PushEnabledNotifier` llama a UI directamente (SnackBar desde un Notifier)
**Archivo:** `lib/features/notifications/providers/notifications_providers.dart` — líneas 80-122

Un `AsyncNotifier` no debería saber que existe `SnackBarAppWidget`. Esto acopla la capa de estado con la capa de presentación, imposibilitando testear el notifier de forma aislada.

```dart
// ❌ Ahora — mezcla lógica de estado con UI
SnackBarAppWidget.show('Notificaciones deshabilitadas.', type: SnackBarType.info);

// ✅ Fix — emitir eventos desde el notifier, consumirlos en el widget
// En el notifier: exponer un Stream<PushEvent> o usar ref.listen en el screen
```

Patrón sugerido: `ref.listen(pushEnabledProvider, (prev, next) { /* mostrar snackbar aquí */ })` en `NotificationsScreen`.

---

#### 🟡 SRP-03 — `_AppShellState` maneja push, navegación y UI al mismo tiempo
**Archivo:** `lib/main.dart` — líneas 112-202

`_AppShellState` implementa `WidgetsBindingObserver`, registra listeners de push notifications, ejecuta lógica de navegación (`_handleOpened`) y renderiza el scaffold. Extraer `_handleOpened` a un servicio de navegación o un provider de eventos.

---

#### 🟡 OCP-01 — Agregar un `CardType` requiere modificar `_buildCarousel`
**Archivo:** `lib/features/home/widgets/home_feed_module_section.dart` — líneas 84-162

El `switch (section.cardType)` viola OCP. Si se agrega un nuevo tipo de card, hay que modificar este método.

**Fix:** Usar un mapa de builders o una factory:
```dart
typedef CarouselBuilder = Widget Function(BuildContext, List<CollectionItem>, void Function(CollectionItem));

final _carouselBuilders = <CardType, CarouselBuilder>{
  CardType.featured: (ctx, items, onTap) => _FeaturedCarousel(...),
  CardType.large: (ctx, items, onTap) => _LargeCarousel(...),
  CardType.small: (ctx, items, onTap) => _SmallCarousel(...),
};
```

---

#### 🟡 OCP-02 — Agregar un `ContentBlockType` requiere modificar `_buildBlock`
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 117-187

Mismo patrón que OCP-01. Nuevo tipo de bloque → modificar el switch. Extraer cada bloque a su propio widget.

---

#### 🟢 DIP-01 — `_AppShellState` depende directamente de `PushNotificationsSdk` (static)
**Archivo:** `lib/main.dart` — líneas 124-160

Las llamadas `PushNotificationsSdk.hasNotificationPermission()`, `PushNotificationsSdk.requestNotificationPermission()`, etc. son llamadas estáticas difíciles de mockear en tests.

**Fix:** Abstraer en un `PushPermissionService` inyectable vía Riverpod.

---

### 3. KISS / Complejidad

#### 🟡 KISS-01 — IIFE dentro de widget tree
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 116-187

```dart
// ❌ Ahora — IIFE confuso
child: () {
  switch (block.type) { ... }
}(),

// ✅ Fix — método nombrado
child: _buildBlockContent(context, block),
```

---

#### 🟡 KISS-02 — AnimatedSize complejo para show/hide del bottom bar
**Archivo:** `lib/main.dart` — líneas 233-254

Combinación de `AnimatedSize` + `Align` + `heightFactor: 1.0` + `SizedBox(width: double.infinity, height: 0)` es difícil de entender. 

```dart
// ✅ Fix — más legible
bottomNavigationBar: AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  height: isVisible ? _barHeight : 0.0,
  child: isVisible ? _AnimatedBottomTabBar(...) : const SizedBox.shrink(),
),
```

---

#### 🟡 KISS-03 — `Matrix4.diagonal3Values` para simple escala de tab
**Archivo:** `lib/main.dart` — líneas 349

```dart
// ❌ Ahora — innecesariamente críptico
transform: Matrix4.diagonal3Values(isSelected ? 1.05 : 1.0, isSelected ? 1.05 : 1.0, 1.0),

// ✅ Fix
child: AnimatedScale(
  scale: isSelected ? 1.05 : 1.0,
  duration: const Duration(milliseconds: 200),
  child: ...,
),
```

---

#### 🟢 KISS-04 — `debugPrint` extensivo en `FeedCollection.fromMap` (producción)
**Archivo:** `lib/features/home/models/feed_collection.dart` — líneas 47-58, 72-74, 116

7 llamadas `debugPrint` en el parser del modelo. En producción, `debugPrint` es no-op, pero ensucian el código y deben estar acotadas o removidas. Gátalas con una flag o usa un logger con niveles.

---

#### 🟢 KISS-05 — `sectionItemsProvider` como Provider.family es innecesario
**Archivo:** `lib/features/home/providers/home_feed_providers.dart` — líneas 51-58

Este provider es una función pura (sin async, sin efectos, sin cache cruzado). No necesita Riverpod:

```dart
// ❌ Ahora — overhead de provider para algo que es una propiedad del modelo
final sectionItemsProvider = Provider.family<List<CollectionItem>, FeedCollection>(...);

// ✅ Fix — getter en el modelo ya existe: section.items
// En el widget: final items = section.items;  // directo
```

---

### 4. Duplicación (DRY)

#### 🔴 DRY-01 — `_buildImage` duplicado en 4 archivos
**Archivos:**
- `lib/features/home/widgets/featured_card.dart` — líneas 26-48 (inline)
- `lib/features/home/widgets/large_card.dart` — líneas 128-155
- `lib/features/home/widgets/small_card.dart` — líneas 81-108
- `lib/features/home/widgets/single_large_card.dart` — líneas 122-150

La misma lógica: `imageUrl ?? image` → si empieza con 'http' → `CachedNetworkImage`, si no → `Image.asset('movies_example/$path')`, con placeholder inline. Ya existe `ImagePlaceholder` pero **ninguno de los 4 archivos la usa**.

```dart
// ✅ Fix — widget compartido
// lib/features/home/widgets/card_image.dart
class CardImage extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final BoxFit fit;
  
  const CardImage({super.key, this.imageUrl, this.imagePath, this.fit = BoxFit.cover});
  
  @override
  Widget build(BuildContext context) {
    final resolved = imageUrl ?? imagePath;
    if (resolved == null) return const ImagePlaceholder(size: 48);
    if (resolved.startsWith('http')) {
      return CachedNetworkImage(imageUrl: resolved, fit: fit,
        placeholder: (_, __) => Container(color: AppColors.gray100),
        errorWidget: (_, __, ___) => const ImagePlaceholder(size: 48));
    }
    return Image.asset('movies_example/$resolved', fit: fit,
      errorBuilder: (_, __, ___) => const ImagePlaceholder(size: 48));
  }
}
```

---

#### 🟡 DRY-02 — `_resolveContentId` y `_resolveImageUrl` duplicados en dos modelos
**Archivos:**
- `lib/features/home/models/feed_collection.dart` — líneas 112-140
- `lib/features/home/models/collection_item.dart` — líneas 47-72

Ambos métodos son idénticos. Extraer a un archivo `lib/features/home/models/_cms_map_utils.dart` con funciones estáticas compartidas:

```dart
// lib/features/home/models/_cms_map_utils.dart
String? resolveContentId(Map<String, dynamic> map) { ... }
String? resolveImageUrl(Map<String, dynamic> map) { ... }
bool parseBool(dynamic value) { ... }
```

---

#### 🟡 DRY-03 — Conteo de no-leídos calculado en dos lugares
**Archivos:**
- `lib/features/notifications/providers/notifications_providers.dart` — líneas 58-63 (`unreadCountProvider`)
- `lib/features/notifications/screens/notifications_screen.dart` — líneas 28-31 (recomputa manualmente)

El screen no usa `ref.watch(unreadCountProvider)` sino que recalcula `items.where((e) => !e.read).length`. Usar el provider existente:

```dart
// ❌ Ahora en notifications_screen.dart
final unreadCount = asyncItems.maybeWhen(
  data: (items) => items.where((e) => !e.read).length,
  orElse: () => 0,
);

// ✅ Fix
final unreadCount = ref.watch(unreadCountProvider);
```

---

#### 🟡 DRY-04 — Navegación a `ContentDetailScreen` duplicada en 3 lugares
**Archivos:**
- `lib/main.dart` — líneas 187-198 (`_handleOpened`)
- `lib/features/notifications/screens/notifications_screen.dart` — líneas 140-152 (`_onTap`)
- `lib/features/home/widgets/home_feed_module_section.dart` — líneas 71-79 (`_handleCardTap`)

Los 3 construyen `MaterialPageRoute(builder: (_) => ContentDetailScreen(item: ...))`. Centralizar en un `NavigationService` o en un método de extensión del `Navigator`.

---

#### 🟢 DRY-05 — String `'content_detail'` hardcodeado en 2 archivos
**Archivos:**
- `lib/main.dart` — línea 186: `model.route == 'content_detail'`
- `lib/features/notifications/screens/notifications_screen.dart` — línea 138: `item.route == 'content_detail'`

```dart
// ✅ Fix — agregar a constants.dart
class NotificationRoute {
  static const String contentDetail = 'content_detail';
}
```

---

#### 🟢 DRY-06 — `_NoInternetView`, `_ErrorView`, `_EmptyFeedView` comparten estructura
**Archivo:** `lib/features/home/screens/home_screen.dart` — líneas 90-205

Las 3 vistas privadas son icon + title + text + button opcional. Extraer un `_FeedEmptyState` configurable:

```dart
class _FeedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;
  ...
}
```

---

### 5. Riverpod / Estado

#### 🟡 RV-01 — `ref.read(notificationsProvider.notifier)` dentro de `build()`
**Archivo:** `lib/features/notifications/screens/notifications_screen.dart` — línea 26

`ref.read` dentro de `build()` es un anti-pattern en Riverpod. El notifier obtenido así es válido, pero hace el código confuso. Si se quiere usar el notifier en callbacks, llamar `ref.read` dentro del callback es suficiente.

```dart
// ❌ Ahora
final notificationsNotifier = ref.read(notificationsProvider.notifier);
// ... usado en onTap: () => notificationsNotifier.markAllRead()

// ✅ Fix
onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
```

---

#### 🟡 RV-02 — `BottomBarVisibleNotifier` definido en `main.dart`
**Archivo:** `lib/main.dart` — líneas 96-103

Providers y Notifiers en `main.dart` no son descubribles, no son testeables aisladamente, y viola la separación de archivos esperada en Riverpod. Mover a `lib/app/app_providers.dart`.

---

#### 🟡 RV-03 — `connectivityProvider` es one-shot, no reactivo
**Archivo:** `lib/features/home/providers/connectivity_provider.dart`

Si el usuario pierde conexión en medio de la sesión, el provider no se actualiza. Si se invierte la conectividad (offline → online), el error de datos sí se recupera, pero el `_NoInternetView` solo aparece al inicio.

Esto está documentado como intencional en CLAUDE.md, pero dejar una nota en el código para que futuros devs no asuman que es un stream reactivo.

---

#### 🟢 RV-04 — `sectionItemsProvider` debería ser un getter, no un provider
Ver **KISS-05** — overhead de provider innecesario para una transformación pura sin efectos.

---

### 6. Performance

#### 🟡 PERF-01 — `_AnimatedBottomTabBar` reconstruye lista de `_TabItemData` en cada build
**Archivo:** `lib/main.dart` — líneas 276-282

Los 5 `_TabItemData` se crean en cada `build()`. Solo el `badgeCount` cambia. Usar `const` donde sea posible o memoizar la lista base.

```dart
// ✅ Separar items base (const) de badgeCount (dinámico)
static const _baseItems = [
  (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  ...
];
```

---

#### 🟡 PERF-02 — `MediaQuery.of(context)` llamado redundantemente en widget tree
**Archivos:**
- `lib/features/home/widgets/home_feed_module_section.dart` — línea 82
- `lib/features/home/widgets/large_card.dart` — línea 18
- `lib/features/home/widgets/small_card.dart` — línea 17

`HomeFeedModuleSection` lee `MediaQuery` y pasa el `screenWidth` a `_buildCarousel`, pero `LargeCard` y `SmallCard` vuelven a leer `MediaQuery` por su cuenta. Si los padres pasan `isTablet: bool` como parámetro, se elimina la dependencia redundante.

---

#### 🟡 PERF-03 — `_relativeTime()` recalculada en cada build de `NotificationTile`
**Archivo:** `lib/features/notifications/widgets/notification_tile.dart` — línea 70

Cada vez que la lista reconstruye (badge update, scroll, etc.) se recalcula para cada tile. Para listas largas, preferir calcularla en el modelo o en un `ValueNotifier` basado en timer.

---

#### 🟢 PERF-04 — `_FeaturedCarousel` height fija 450px
**Archivo:** `lib/features/home/widgets/home_feed_module_section.dart` — línea 192

`height: 450` no se adapta al tamaño de pantalla. En dispositivos pequeños se ve excesivo, en tablet se ve pequeño. Usar proporción de pantalla: `MediaQuery.of(context).size.height * 0.5`.

---

### 7. Separación de Capas

#### 🔴 LAYER-01 — `PushEnabledNotifier` llama a UI (`SnackBarAppWidget`) desde la capa de estado
**Archivo:** `lib/features/notifications/providers/notifications_providers.dart` — líneas 82-122

Detallado en **SRP-02**. La capa de estado no debe tener referencia directa a widgets de presentación.

---

#### 🟡 LAYER-02 — `ContentDetailScreen._buildBlock` lanza URLs directamente
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 166-170

Lanzar una URL (`launchUrl`) es un efecto secundario que debería delegarse a un servicio:

```dart
// ❌ Ahora — side effect directo en widget build
onPressed: () async {
  if (await canLaunchUrl(uri)) await launchUrl(uri);
},

// ✅ Fix — usar un UrlLauncherService o similar
onPressed: () => ref.read(urlLauncherProvider).launch(buttonUrl),
```

---

#### 🟡 LAYER-03 — Lógica de navegación dentro de widgets (`_onTap`, `_handleCardTap`)
**Archivos:** `notifications_screen.dart` línea 136, `home_feed_module_section.dart` línea 71

Ver **DRY-04**. La decisión de "qué pantalla mostrar dado un route" es lógica de negocio, no responsabilidad del widget. Centralizar en un `AppRouter` o `NavigationService`.

---

#### 🟢 LAYER-04 — `HomeScreen` escribe en `bottomBarVisibleProvider` directamente
**Archivo:** `lib/features/home/screens/home_screen.dart` — líneas 53-57

`HomeScreen` es una feature de contenido que manipula el estado del shell de navegación. Debería notificar un evento que el shell consuma, no escribir directamente al provider del shell.

---

### 8. Manejo de Errores

#### 🟡 ERR-01 — `IosNotificationBridge.drainPending` silencia excepciones sin log
**Archivo:** `lib/features/notifications/data/ios_notification_bridge.dart` — líneas 31-34

```dart
// ❌ Ahora
} on PlatformException {
  return const [];
} on MissingPluginException {
  return const [];
}

// ✅ Fix
} on PlatformException catch (e) {
  debugPrint('[IosNotificationBridge] PlatformException: $e');
  return const [];
}
```

---

#### 🟡 ERR-02 — `_read` en `NotificationsRepository` silencia errores de parsing
**Archivo:** `lib/features/notifications/data/notifications_repository.dart` — líneas 77-84

```dart
try {
  items.add(NotificationModel.fromJson(s));
} catch (_) {
  // Skip corrupt entries — OK, but should log
}
```

Agregar `debugPrint('[NotificationsRepo] corrupt entry skipped: $e')` para poder detectar regresiones de serialización.

---

#### 🟡 ERR-03 — Error state en `ContentDetailScreen` usa ícono de WiFi para error genérico
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — línea 85

```dart
error: (error, stack) {
  debugPrint('Error: $error'); // no loguea stack
  return _buildCenteredMessage(context, Icons.wifi_off_rounded, ...);
},
```

`debugPrint('Error: $error')` sin el stack trace es inútil. Cambiar a `debugPrint('Error: $error\n$stack')`. El ícono `wifi_off` es misleading para un error que puede no ser de red.

---

#### 🟢 ERR-04 — Código comentado `AppAmbitSdk.enableConfig()` en `main.dart`
**Archivo:** `lib/main.dart` — línea 42

```dart
//AppAmbitSdk.enableConfig();
```

Dead code comentado. Si no se usa, eliminarlo. Si es una feature flag, documentarla con una constante.

---

### 9. Hardcoding / Magic Values

#### 🟡 HARD-01 — Breakpoints de tablet duplicados en 5 archivos sin constante
**Archivos:** `main.dart` (línea 210), `home_feed_module_section.dart` (línea 91, 130), `large_card.dart` (línea 19), `small_card.dart` (línea 18)

El valor `600` (tablet breakpoint) y los anchos `1100.0`, `820.0` aparecen sin definición centralizada.

```dart
// ✅ Fix — en lib/core/constants.dart
class AppLayout {
  static const double tabletBreakpoint = 600.0;
  static const double maxWidthTabletLandscape = 1100.0;
  static const double maxWidthTabletPortrait = 820.0;
  static const double contentMaxWidth = 700.0;
}
```

---

#### 🟡 HARD-02 — Color `0xFF4338CA` hardcodeado en `_FeaturedCarousel`
**Archivo:** `lib/features/home/widgets/home_feed_module_section.dart` — línea 217

```dart
color: _currentPage == index
    ? const Color(0xFF4338CA) // "Blue/Indigo" — no usa AppColors
    : AppColors.gray300,

// ✅ Fix — agregar a AppColors
static const Color carouselDot = Color(0xFF4338CA);
```

---

#### 🟡 HARD-03 — `'movies_example/$imagePath'` path de demo en código de producción
**Archivos:** `featured_card.dart` (línea 37), `large_card.dart` (línea 148), `small_card.dart` (línea 101), `single_large_card.dart` (línea 141)

El fallback a assets locales de demo no debería existir en producción. Todas las imágenes deben venir del backend. Si se necesita demo mode, usar una constante booleana:

```dart
// ✅ Solo retornar ImagePlaceholder si la URL es null o no-http
if (resolved == null || !resolved.startsWith('http')) {
  return const ImagePlaceholder(size: 48);
}
```

---

#### 🟢 HARD-04 — Título de la app hardcodeado como string
**Archivo:** `lib/main.dart` — línea 68

```dart
title: 'KavaUp CMS App', // debería estar en AppConstants o l10n
```

---

#### 🟢 HARD-05 — Altura fija `300` para loading/error states en `ContentDetailScreen`
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 76-79, 94

```dart
height: 300, // magic number repetido dos veces en el mismo archivo
```

Extraer como constante `static const double _emptyStateHeight = 300.0`.

---

#### 🟢 HARD-06 — Strings de UI en español e inglés mezclados
**Archivos:** `main.dart` (línea 146 — español), `home_screen.dart` (línea 109 — inglés), `notifications_screen.dart` (líneas 83, 101 — inglés), `notifications_providers.dart` (líneas 82-120 — español)

La app mezcla idiomas en la UI. Definir un idioma único o usar `flutter_localizations`.

---

## Resumen de Mejoras Prioritarias

Las 5 acciones con mayor retorno de inversión:

### 1. 🔴 Extraer `_buildImage` a widget compartido `CardImage` (DRY-01)
Elimina ~120 líneas de código duplicado en 4 archivos. También usa `ImagePlaceholder` que ya existe pero nunca se usa. **Esfuerzo: 1-2h | Impacto: Alto**.

### 2. 🔴 Romper `main.dart` en archivos separados (SRP-01)
`main.dart` con 410 líneas haciendo 6 cosas es el mayor problema de mantenibilidad. Separa en `app_shell.dart`, `bottom_tab_bar.dart`, `app_providers.dart`. **Esfuerzo: 2-3h | Impacto: Alto**.

### 3. 🔴 Desacoplar `PushEnabledNotifier` de `SnackBarAppWidget` (SRP-02 / LAYER-01)
Usar `ref.listen` en el screen para mostrar SnackBars en respuesta a cambios de estado, en lugar de que el notifier llame directamente a la UI. Hace el notifier testeable. **Esfuerzo: 1h | Impacto: Alto en testabilidad**.

### 4. 🟡 Centralizar constantes de layout y strings de ruta (HARD-01, DRY-05)
`600`, `1100`, `820`, `700`, `'content_detail'` dispersos en 6+ archivos. 30 minutos de refactor evitan bugs cuando el breakpoint cambia. **Esfuerzo: 30min | Impacto: Medio**.

### 5. 🔴 Fix `Uri.tryParse` y validación de color hex (BUG-01, BUG-02)
Son crashes potenciales en producción con datos reales del CMS. Fix de 5 líneas cada uno. **Esfuerzo: 15min | Impacto: Crítico en estabilidad**.

---

---

### 10. Centralización de Colores

#### 🟡 COLOR-01 — `AppColors` existe pero se bypasea con hex literales
**Archivos:** `home_feed_module_section.dart` línea 217, `content_detail_screen.dart` líneas 156-159, `main.dart` color scheme inline

`AppColors` ya es la clase correcta pero no cubre todos los colores usados. Cualquier color que no esté en `AppColors` termina hardcodeado donde se usa.

**Fix: completar `AppColors` y prohibir hex literales fuera de ella:**

```dart
// lib/core/styles/app_colors.dart — añadir colores faltantes
class AppColors {
  // Existentes
  static const Color accent       = Color(0xFF4338CA);
  static const Color background   = Color(0xFFF5F5F5);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color black        = Color(0xFF000000);
  static const Color gray100      = Color(0xFFF3F4F6);
  static const Color gray300      = Color(0xFFD1D5DB);
  static const Color gray400      = Color(0xFF9CA3AF);
  static const Color gray500      = Color(0xFF6B7280);
  static const Color textPrimary  = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color badgeRed     = Color(0xFFEF4444);

  // ✅ Añadir — actualmente hardcodeados fuera de esta clase
  static const Color carouselDotActive = accent;          // era 0xFF4338CA en home_feed_module_section
  static const Color carouselDotInactive = gray300;
  static const Color buttonDefault = accent;               // botones sin color de CMS
}
```

**Regla:** Ningún `Color(0xFF...)` debe aparecer fuera de `app_colors.dart`. Si en code review aparece uno, es un smell automático.

---

#### 🟡 COLOR-02 — Colores de tema definidos inline en `main.dart`
**Archivo:** `lib/main.dart` — líneas 71-90

`ColorScheme.fromSeed(seedColor: AppColors.accent, surface: AppColors.white)` está hardcodeado en `MainApp.build()`. El tema completo debería estar en su propio archivo:

```dart
// ✅ lib/core/styles/app_theme.dart
class AppTheme {
  static ThemeData light(TextTheme textTheme) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    appBarTheme: _appBarTheme(textTheme),
    bottomNavigationBarTheme: _bottomNavTheme,
  );

  static AppBarTheme _appBarTheme(TextTheme t) => AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.white,
    titleTextStyle: t.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: AppColors.black,
      letterSpacing: -0.5,
    ),
  );

  static const _bottomNavTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: AppColors.gray500,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
  );
}
```

`main.dart` queda: `theme: AppTheme.light(textTheme)` — una línea.

---

### 11. Aislamiento de Paquetes (Facade Pattern)

**Principio:** Si el paquete cambia de API (versión major), solo cambia el wrapper. El resto del app no sabe que el paquete existe.

Actualmente los paquetes se usan directamente en 14 archivos. Estos son los wrappers necesarios:

---

#### 🟡 PKG-01 — `cached_network_image` usado directamente en 5 archivos
**Archivos:** `featured_card.dart`, `large_card.dart`, `small_card.dart`, `single_large_card.dart`, `content_detail_screen.dart`

```dart
// ✅ lib/shared/widgets/app_network_image.dart
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(   // ← único lugar donde aparece CachedNetworkImage
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => placeholder ?? Container(color: AppColors.gray100),
      errorWidget: (_, __, ___) => errorWidget ?? const ImagePlaceholder(size: 48),
    );
  }
}
```

Todos los archivos pasan de `import 'package:cached_network_image/...'` a `import '../shared/widgets/app_network_image.dart'`.

---

#### 🟡 PKG-02 — `url_launcher` usado directamente en 2 archivos
**Archivos:** `content_detail_screen.dart` línea 166, `about_screen.dart` línea 111

```dart
// ✅ lib/shared/services/url_launcher_service.dart
class UrlLauncherService {
  static Future<bool> launch(String url) async {
    final uri = Uri.tryParse(url);   // ← fix de BUG-01 incluido
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

Si `url_launcher` cambia su API (ya cambió de `launch()` a `launchUrl()` en v6), solo cambia aquí.

---

#### 🟡 PKG-03 — `shared_preferences` usado directamente en `NotificationsRepository`
**Archivo:** `lib/features/notifications/data/notifications_repository.dart`

```dart
// ✅ lib/shared/services/local_storage_service.dart
class LocalStorageService {
  static Future<SharedPreferences> _instance() =>
      SharedPreferences.getInstance();

  static Future<String?> getString(String key) async =>
      (await _instance()).getString(key);

  static Future<bool> setString(String key, String value) async =>
      (await _instance()).setString(key, value);

  static Future<void> reload() async =>
      (await _instance()).reload();
}
```

`NotificationsRepository` deja de depender de `SharedPreferences` directamente — facilita tests con mock.

---

#### 🟡 PKG-04 — `connectivity_plus` expuesto directamente al provider
**Archivo:** `lib/features/home/providers/connectivity_provider.dart`

```dart
// ✅ lib/shared/services/connectivity_service.dart
class ConnectivityService {
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }
}
```

`connectivityProvider` queda: `return ConnectivityService.isConnected()` — si `connectivity_plus` cambia su enum, solo cambia `ConnectivityService`.

---

#### 🟡 PKG-05 — `video_player` + `chewie` mezclados con lógica de UI en `ContentDetailScreen`
**Archivo:** `lib/features/home/screens/content_detail_screen.dart` — líneas 208-270

`_VideoBlockPlayer` ya es un widget separado (bien), pero contiene la inicialización de `VideoPlayerController`, `ChewieController`, y la lógica de dispose mezclada con build. El acoplamiento a ambos paquetes es fuerte.

```dart
// ✅ lib/shared/widgets/app_video_player.dart
// Encapsula VideoPlayerController + ChewieController
// Expone: AppVideoPlayer(url: String)
// Internamente maneja init, dispose, error state
// Si chewie se reemplaza por media_kit, solo cambia este archivo
```

---

#### 🟢 PKG-06 — `google_fonts` llamado directamente en `MainApp.build()`
**Archivo:** `lib/main.dart` — línea 63

```dart
// ❌ Ahora
final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

// ✅ Fix — dentro de AppTheme
class AppTheme {
  static TextTheme textTheme(BuildContext context) =>
      GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);
}
// Si se cambia de Poppins a otra fuente o de google_fonts a otro paquete, solo cambia AppTheme
```

---

#### 🟢 PKG-07 — `flutter_dotenv` llamado directamente en `main()`
**Archivo:** `lib/main.dart` — líneas 35-45

```dart
// ✅ lib/core/config/app_config.dart
class AppConfig {
  static late final String appKeyIos;
  static late final String appKeyAndroid;

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    appKeyIos = dotenv.env['APPAMBIT_APPKEY_IOS'] ?? '';
    appKeyAndroid = dotenv.env['APPAMBIT_APPKEY_ANDROID'] ?? '';
  }

  static String get currentAppKey =>
      Platform.isIOS ? appKeyIos : appKeyAndroid;
}
```

`main()` queda: `await AppConfig.load()`. Si se cambia de `flutter_dotenv` a otra solución (const env, compile-time defines), solo cambia `AppConfig`.

---

#### 🟡 PKG-08 — `AppAmbitSdk.trackEvent` llamado directamente desde widgets
**Archivos:** `about_screen.dart` línea 117, `main.dart` línea 181

```dart
// ✅ lib/shared/services/analytics_service.dart
class AnalyticsService {
  static void trackEvent(String name, Map<String, dynamic> properties) {
    AppAmbitSdk.trackEvent(name, properties);
  }
  
  static void trackResourceOpened(String url, String label) =>
      trackEvent('Resource Opened', {'url': url, 'label': label});
  
  static void trackNotificationOpened(String title, String body) =>
      trackEvent('Notification Opened', {'title': title, 'body': body});
}
```

Si el SDK de analytics cambia (o se agrega un segundo analytics), solo cambia `AnalyticsService`.

---

## Resumen de Mejoras Prioritarias

Las 5 acciones con mayor retorno de inversión:

### 1. 🔴 Extraer `_buildImage` a widget compartido `CardImage` (DRY-01)
Elimina ~120 líneas de código duplicado en 4 archivos. También usa `ImagePlaceholder` que ya existe pero nunca se usa. **Esfuerzo: 1-2h | Impacto: Alto**.

### 2. 🔴 Romper `main.dart` en archivos separados (SRP-01)
`main.dart` con 410 líneas haciendo 6 cosas es el mayor problema de mantenibilidad. Separa en `app_shell.dart`, `bottom_tab_bar.dart`, `app_providers.dart`. **Esfuerzo: 2-3h | Impacto: Alto**.

### 3. 🔴 Desacoplar `PushEnabledNotifier` de `SnackBarAppWidget` (SRP-02 / LAYER-01)
Usar `ref.listen` en el screen para mostrar SnackBars en respuesta a cambios de estado, en lugar de que el notifier llame directamente a la UI. Hace el notifier testeable. **Esfuerzo: 1h | Impacto: Alto en testabilidad**.

### 4. 🟡 Crear wrappers de paquetes + completar `AppColors` (PKG-01..08 / COLOR-01..02)
`cached_network_image`, `url_launcher`, `shared_preferences`, `connectivity_plus`, `google_fonts`, `flutter_dotenv`, `AppAmbitSdk.trackEvent`. Cada wrapper es 10-20 líneas. Si un paquete hace breaking change, solo un archivo cambia. `AppTheme` centraliza todo el tema. **Esfuerzo: 3-4h total | Impacto: Alto en mantenibilidad a largo plazo**.

### 5. 🔴 Fix `Uri.tryParse` y validación de color hex (BUG-01, BUG-02)
Son crashes potenciales en producción con datos reales del CMS. Fix de 5 líneas cada uno. **Esfuerzo: 15min | Impacto: Crítico en estabilidad**.

---

*Generado el 2026-06-17 — Revisión manual, no automatizada.*
