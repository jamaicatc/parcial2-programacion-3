# Integrantes: Juan David Cardona, Santiago Trujillo y Sharon Ospina.

Code.require_file("Util.ex", __DIR__)
Code.require_file("Util2.ex", __DIR__)
Code.require_file("modelos.exs", __DIR__)
Code.require_file("rutas.exs", __DIR__)
Code.require_file("validacion_red.exs", __DIR__)
Code.require_file("svg_coloracion.exs", __DIR__)
Code.require_file("coloreado.exs", __DIR__)

["itinerarios.txt", "errores_tramos.txt", "depuracion_tramos.txt",
 "alcance_centros.txt", "validacion_red.txt", "verificacion_colores.txt",
 "secuencia_colores.csv", "primera_coloracion_k10.svg"]
|> Enum.each(fn archivo -> File.open!(archivo, [:write, :utf8], fn _ -> :ok end) end)
Path.wildcard("coloraciones_k*.txt")
|> Enum.each(fn archivo ->
  if Regex.match?(~r/\Acoloraciones_k\d+\.txt\z/, archivo), do: File.rm(archivo)
end)
Rutas.run()
Coloreado.run()
Util.mostrar_mensaje("Procesamiento finalizado. Revise los archivos de salida.")
