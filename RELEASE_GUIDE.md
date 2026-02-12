# GitHub Actions Release - Guía de Uso

## 🚀 Cómo Crear un Release

### Método 1: Desde la Terminal

```bash
# 1. Asegúrate de que todo esté committeado
git add .
git commit -m "Release v1.0.0"

# 2. Crea el tag (versión semántica: v1.0.0, v1.0.1, etc.)
git tag v1.0.0

# 3. Push del código Y el tag
git push origin main
git push origin v1.0.0
```

### Método 2: Desde GitHub

1. Ve a tu repositorio en GitHub
2. Click en "Releases" (sidebar derecho)
3. Click "Create a new release"
4. En "Choose a tag", escribe: `v1.0.0` (o la versión que quieras)
5. Click "Create new tag: v1.0.0 on publish"
6. Agrega título y descripción
7. Click "Publish release"

## 📋 El Workflow Automáticamente:

✅ Compila la app en Xcode 15.2  
✅ Ejecuta tests (opcional)  
✅ Genera el archive (.xcarchive)  
✅ Crea el GitHub Release  
✅ Sube build info con detalles  
✅ Adjunta el .xcarchive como asset

## 🔍 Ver el Progreso

1. Ve a tu repo → Tab "Actions"
2. Verás el workflow "iOS Release Build" ejecutándose
3. Click para ver logs en tiempo real
4. Cuando termine (✅ verde), el release estará listo

## 📱 Descargar el Release

1. Ve a "Releases" en GitHub
2. Click en la versión (ej: v1.0.0)
3. Descarga los archivos:
   - `build-info.txt` - Información del build
   - `JailbreakDetector-v1.0.0.xcarchive.zip` - Archive de Xcode

## ⚙️ Configuración del Workflow

El archivo está en: `.github/workflows/release.yml`

**Triggers:**
- Se activa automáticamente cuando haces push de tags que empiecen con `v`
- Ejemplos: `v1.0.0`, `v2.1.3`, `v1.0.0-beta`

**macOS Runner:**
- Usa `macos-latest` (gratis en repos públicos)
- Si tu repo es privado, tiene costo (~$0.08/minuto)

## 🔧 Personalización

Para cambiar la versión de Xcode (línea 14):
```yaml
- name: Select Xcode version
  run: sudo xcode-select -s /Applications/Xcode_VERSION.app/Contents/Developer
```

Versiones disponibles: https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md

## ⚠️ Limitaciones

**Sin firma digital:**
- El build NO está firmado (no tiene certificados)
- No se puede instalar directamente en dispositivos físicos
- Solo para demostración y distribución del código fuente

**Para firma automática:**
Necesitas agregar a GitHub Secrets:
- `IOS_CERTIFICATE_P12` - Tu certificado .p12 (base64)
- `P12_PASSWORD` - Password del certificado
- `PROVISIONING_PROFILE` - Provisioning profile (base64)

## 📊 Ejemplo de Versionado

```bash
# Primera release
git tag v1.0.0
git push origin v1.0.0

# Bug fix
git tag v1.0.1
git push origin v1.0.1

# Nueva feature
git tag v1.1.0
git push origin v1.1.0

# Breaking change
git tag v2.0.0
git push origin v2.0.0
```

## 🐛 Troubleshooting

**Error: "Xcode not found"**
- El runner usa Xcode 15.2 por defecto
- Actualiza la línea 14 si necesitas otra versión

**Error: "Scheme not found"**
- Asegúrate de que el scheme esté compartido
- Debe estar en `xcshareddata/xcschemes/`

**Error: "No releases created"**
- Verifica que pusheaste el tag: `git push origin v1.0.0`
- El tag debe empezar con `v`

**Build tarda mucho:**
- Normal: 5-10 minutos
- Si tarda más, revisa los logs en Actions

## ✅ Checklist Pre-Release

Antes de crear un tag/release:

- [ ] Código compila sin errores
- [ ] Tests pasan localmente
- [ ] Version bump en Info.plist (opcional)
- [ ] Changelog actualizado (opcional)
- [ ] Commits pusheados a `main`
- [ ] Tag sigue formato `vX.Y.Z`

## 🎯 Flujo Completo

```
Developer crea tag v1.0.0
         ↓
GitHub detecta push del tag
         ↓
Actions ejecuta workflow
         ↓
Compila app en macOS runner
         ↓
Ejecuta tests
         ↓
Genera .xcarchive
         ↓
Crea GitHub Release
         ↓
Sube archivos al release
         ↓
✅ Release disponible!
```

---

**Creado:** 2026-02-11  
**Workflow:** `.github/workflows/release.yml`
