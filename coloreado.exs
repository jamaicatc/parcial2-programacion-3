# Integrantes: Juan David Cardona, Santiago Trujillo y Sharon Ospina.

defmodule Coloreado do
  def run do
    resolver_coloreado()
  end

  # ---------------- Problema 4: coloreado ----------------

  defp resolver_coloreado do
    {nodos, aristas, errores_red} = ValidacionRed.cargar_red()
    ks = cargar_ks()

    File.open!("validacion_red.txt", [:write, :utf8], fn io ->
      escribir_lineas(io, errores_red)
      if errores_red == [], do: IO.write(io, "Red válida.\n")
    end)

    {propuestas_ok, errores_propuestas} = ValidacionRed.cargar_propuestas(nodos, aristas)
    File.open!("verificacion_colores.txt", [:write, :utf8], fn io ->
      escribir_lineas(io, errores_propuestas)
      if errores_propuestas == [], do: IO.write(io, "No hay propuestas inválidas.\n")
      escribir_lineas(io, propuestas_ok)
    end)

    if errores_red == [] do
      procesar_coloreados(nodos, aristas, ks)
    else
      Util2.mostrar("No se buscaron coloraciones: la red contiene errores.", :error)
      File.open!("primera_coloracion_k10.svg", [:write, :utf8], fn io -> SvgColoracion.escribir_svg(io, nodos, aristas, %{}) end)
    end
    Util.mostrar_mensaje("Archivo SVG generado: primera_coloracion_k10.svg")
  end

  defp procesar_coloreados(nodos, aristas, ks) do
    adyacencia = construir_adyacencia(aristas, %{})
    Enum.each(ks, fn k -> escribir_coloraciones(k, nodos, adyacencia) end)
    escribir_primera_k10(nodos, aristas, adyacencia)
    escribir_minimo_colores(nodos, adyacencia)
  end

  defp cargar_ks do
    if not File.exists?("colores.txt") do
      Util2.mostrar("Falta el archivo requerido: colores.txt", :error)
      []
    else
      "colores.txt"
      |> lineas_utiles()
      |> Enum.reduce([], fn {linea, texto}, acc ->
        case Integer.parse(texto) do
          {k, ""} when k > 0 -> [k | acc]
          _ -> Util2.mostrar("Línea #{linea} de colores.txt inválida: #{texto}", :error); acc
        end
      end)
      |> Enum.reverse()
    end
  end

  defp construir_adyacencia([], mapa), do: mapa
  defp construir_adyacencia([%Arista{a: a, b: b} | resto], mapa) do
    mapa = Map.update(mapa, a, MapSet.new([b]), &MapSet.put(&1, b))
    mapa = Map.update(mapa, b, MapSet.new([a]), &MapSet.put(&1, a))
    construir_adyacencia(resto, mapa)
  end

  # El Stream de soluciones genera cada coloración al solicitarla, sin almacenar todas.
  defp soluciones([], _adyacencia, _k, asignados), do: Stream.map([asignados], & &1)
  defp soluciones([nodo | resto], adyacencia, k, asignados) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.take_while(&(&1 <= k))
    |> Stream.flat_map(fn color ->
      if compatible?(nodo.id, color, adyacencia, asignados) do
        soluciones(resto, adyacencia, k, Map.put(asignados, nodo.id, color))
      else
        Stream.map([], & &1)
      end
    end)
  end

  defp compatible?(id, color, adyacencia, asignados) do
    vecinos = Map.get(adyacencia, id, MapSet.new())
    Enum.all?(vecinos, fn vecino -> Map.get(asignados, vecino) != color end)
  end

  defp escribir_coloraciones(k, nodos, adyacencia) do
    nombre = "coloraciones_k#{k}.txt"
    File.open!(nombre, [:write, :utf8], fn io ->
      IO.write(io, "Coloraciones válidas con k=#{k}\n")
      total =
        soluciones(nodos, adyacencia, k, %{})
        |> Enum.reduce(0, fn asignacion, indice ->
          IO.write(io, "#{indice + 1}. #{formatear_asignacion(nodos, asignacion)}\n")
          indice + 1
        end)
      IO.write(io, "Total: #{total}\n")
      Util.mostrar_mensaje("k=#{k}: #{total} coloraciones")
    end)
  end

  defp escribir_primera_k10(nodos, aristas, adyacencia) do
    primera = soluciones(nodos, adyacencia, 10, %{}) |> Enum.take(1)
    asignacion = case primera do [solucion | _] -> solucion; [] -> %{} end
    File.open!("primera_coloracion_k10.svg", [:write, :utf8], fn io -> SvgColoracion.escribir_svg(io, nodos, aristas, asignacion) end)
  end

  defp escribir_minimo_colores(nodos, adyacencia) do
    File.open!("secuencia_colores.csv", [:write, :utf8], fn io ->
      IO.write(io, "k;total_coloraciones\n")
      Stream.iterate(1, &(&1 + 1))
      |> Stream.map(fn k -> {k, contar_soluciones(soluciones(nodos, adyacencia, k, %{}), 0)} end)
      |> Enum.reduce_while(nil, fn {k, total}, _ ->
        IO.write(io, "#{k};#{total}\n")
        if total > 0, do: {:halt, {k, total}}, else: {:cont, nil}
      end)
      # Muestra sólo el primer k que tiene al menos una coloración.
      |> then(fn {k, total} -> Util.mostrar_mensaje("Mínimo de colores: k=#{k} (#{total} coloraciones)") end)
    end)
  end

  defp contar_soluciones(stream, cuenta), do: Enum.reduce(stream, cuenta, fn _solucion, n -> n + 1 end)

  defp formatear_asignacion(nodos, asignacion), do: formatear_asignacion_rec(nodos, asignacion, [])
  defp formatear_asignacion_rec([], _asignacion, acc), do: acc |> Enum.reverse() |> Enum.join(";")
  defp formatear_asignacion_rec([nodo | resto], asignacion, acc) do
    formatear_asignacion_rec(resto, asignacion, ["#{nodo.id}=#{Map.get(asignacion, nodo.id)}" | acc])
  end

  defp escribir_lineas(_io, []), do: :ok
  defp escribir_lineas(io, [linea | resto]), do: (IO.write(io, linea <> "\n"); escribir_lineas(io, resto))

  # Todas las entradas pasan por File.stream!/1; se conservan índices físicos.
  defp lineas_utiles(archivo) do
    File.stream!(archivo)
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, n} -> {n, String.trim(linea)} end)
    |> Stream.reject(fn {_n, texto} -> texto == "" or String.starts_with?(texto, "#") end)
  end
end
