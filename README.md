# Yuke Cat

Yuke debe recuperar los fragmentos del Código Espectral en la costa, la sierra y la selva del Perú. La aventura combina sigilo, un desafío de puntería y un rompecabezas musical.

## Jugar en Godot

1. Instala [Godot 4.5 Standard](https://godotengine.org/download/archive/4.5-stable/).
2. Clona este repositorio e importa `project.godot` desde el gestor de proyectos de Godot.
3. Presiona **F5** para empezar desde la introducción.

El repositorio incluye las cinco escenas de la historia y todos los recursos necesarios para ejecutarlas. Los recursos se descargan con un clon normal de Git.

## Controles

| Acción | Teclas |
| --- | --- |
| Mover a Yuke | **W A S D** o flechas |
| Correr | **Mayús** mientras te mueves |
| Interactuar o usar la acción del nivel | **Espacio** |
| Avanzar el diálogo | **Enter**, **Espacio** o el botón del diálogo |
| Pausar y reiniciar | **Esc**, luego **Reiniciar** |

## Exportar para navegador

Instala las plantillas de exportación que correspondan a tu versión de Godot desde **Editor → Manage Export Templates**. Con el ejecutable `godot` en tu PATH, ejecuta estos comandos desde la raíz del repositorio.

```sh
mkdir -p build/web
touch build/.gdignore
godot --headless --path . --editor --import
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Abre [http://localhost:8000](http://localhost:8000) en un navegador con WebGL 2. Para publicar el juego, sube todos los archivos que se generaron en `build/web` a tu alojamiento estático.

## Créditos y licencias

Yuke Cat es una versión independiente de la historia Spectral Code, creada en el proyecto educativo [Threadbare](https://github.com/endlessm/threadbare). El [repositorio del equipo](https://github.com/Game-Lab-5-0-UTP-Group-4-Team-1/threadbare) conserva el historial de la historia original. Los créditos de Threadbare se conservan en [AUTHORS](AUTHORS).

El código de Threadbare se distribuye bajo [MPL 2.0](COPYING) y sus recursos originales bajo [CC BY-SA 4.0](LICENSES/CC-BY-SA-4.0.txt). Las licencias y atribuciones de terceros se detallan en [REUSE.toml](REUSE.toml), en los archivos `.license` y en las carpetas de los complementos.
