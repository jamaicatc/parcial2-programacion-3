# Parcial 2 — Problemas 1 y 4

Implementación en Elixir de rutas dirigidas y coloración de grafos con generación perezosa.
`main.exs` es el punto de entrada. La implementación está separada en `modelos.exs`,
`rutas.exs`, `validacion_red.exs`, `coloreado.exs` y `svg_coloracion.exs`. `Util.ex` y
`Util2.ex` son los módulos auxiliares entregados; el programa los carga para mostrar mensajes.

## Ejecución

Con Elixir instalado, desde esta carpeta:

```sh
elixir main.exs
```

El programa busca las entradas en el directorio actual. Los archivos de ejemplo incluidos
son `tramos.csv`, `consultas.txt`, `nodos.csv`, `aristas.csv`, `colores.txt` y
`propuestas.txt`. Las líneas vacías y las líneas cuyo primer carácter no blanco sea `#`
se ignoran. Los números de línea de los reportes corresponden a las líneas físicas.

## Problema 1

Produce `itinerarios.txt`, `errores_tramos.txt`, `depuracion_tramos.txt` y
`alcance_centros.txt`. Se eliminan bucles y parejas dirigidas repetidas conservando la
primera; los ciclos entre centros distintos son válidos. La búsqueda enumera caminos
simples, y el Stream de alcance se detiene al repetir dos conjuntos consecutivos.

## Problema 4

Produce `validacion_red.txt`, `verificacion_colores.txt`, `coloraciones_k<K>.txt`,
`primera_coloracion_k10.svg` y `secuencia_colores.csv`. El backtracking emite soluciones
como Stream, probando nodos y colores en el orden solicitado. La búsqueda del mínimo
consume k=1,2,... sólo hasta encontrar una coloración.

Las validaciones recursivas de la red y de propuestas se implementan con funciones
recursivas propias, sin `Enum` ni `Stream` dentro de esos recorridos. La búsqueda completa
de coloraciones puede crecer exponencialmente, según el tamaño de la red.

## Casos comprobados con los ejemplos

- **Rutas válido:** `A,D` produce 4 itinerarios y conserva los empates en los criterios.
- **Rutas límite/sin solución:** `B,A` no es alcanzable; se informa sin iniciar la búsqueda.
- **Depuración de rutas:** el ejemplo incluye un bucle `A,A` y una segunda arista `A,B`,
  que se descartan dejando registro de sus líneas físicas.
- **Propuestas válidas e inválidas:** la primera asignación de `propuestas.txt` es válida;
  la segunda produce un conflicto en `A-C`.
- **Coloraciones límite:** con `k=2` hay 0 soluciones; con `k=3` hay 6 y con `k=4` hay 48.
  El Stream del mínimo se detiene en `k=3`.
