# Normas de Flujo de Trabajo y Versionado de MusicX

1. **Limpieza y sincronización**:
   - Después de cada cambio, limpiar y sincronizar el árbol de trabajo al 100% con el último commit (sin archivos temporales, sin modificaciones pendientes sin committear).

2. **Versión Patch (0.0.X)**:
   - Incrementar SIEMPRE la versión patch (ej. 0.2.23 -> 0.2.24) de forma automática y sin preguntar.
   - Sincronizar en los 3 archivos:
     - `package.json`
     - `src-tauri/tauri.conf.json`
     - `src-tauri/Cargo.toml`
   - El commit de la versión patch es **SOLO LOCAL** (no hacer push a GitHub automáticamente).

3. **Versión Minor (0.X.0) y Major (X.0.0)**:
   - Subir versión minor o major **ÚNICAMENTE cuando el usuario lo ordene explícitamente**.
   - Cuando el usuario ordene subir minor o major:
     - Actualizar la versión en los 3 archivos.
     - Hacer commit y **subir los cambios a GitHub** (`git push origin main`).
     - Crear el tag correspondiente (ej. `v0.3.0` o `v1.0.0`) y subirlo a GitHub (`git push origin v...`) para disparar el workflow de Release en GitHub Actions.

4. **Sin Caché y Sin Pestañas Obsoletas (Cambios siempre directos y efectuados)**:
   - Dejar pestañas abiertas en el editor con versiones antiguas no deja ver los cambios reales y puede sobreescribir el disco con buffers obsoletos.
   - Prohibido depender de cachés; los cambios deben efectuarse y sincronizarse siempre de manera directa, fresca y verificable en disco.

