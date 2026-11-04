# Integrantes: Juan David Cardona, Santiago Trujillo y Sharon Ospina.

defmodule ValidacionRed do
  def cargar_red do
    {nodos, errores_nodos} = cargar_nodos()
    {aristas, errores_aristas} = cargar_aristas()
    ids = ids_nodos(nodos, MapSet.new())
    errores_validacion = validar_nodos(nodos, MapSet.new(), []) ++ validar_aristas(aristas, ids, MapSet.new(), [])
    {nodos, aristas, errores_nodos ++ errores_aristas ++ errores_validacion}
  end
  defp cargar_nodos do
    if not File.exists?("nodos.csv") do
      Util2.mostrar("Falta el archivo requerido: nodos.csv", :error)
      {[], ["Falta el archivo requerido: nodos.csv"]}
    else
      File.stream!("nodos.csv")
      |> Stream.with_index(1)
      |> Stream.map(fn {linea, n} -> {n, String.trim(linea)} end)
      |> Stream.reject(fn {_n, s} -> s == "" or String.starts_with?(s, "#") end)
      |> Stream.map(fn {n, texto} -> parse_nodo(n, texto) end)
      |> Enum.reduce({[], []}, fn
        {:ok, nodo}, {ns, es} -> {[nodo | ns], es}
        {:error, error}, {ns, es} -> {ns, [error | es]}
      end)
      |> then(fn {ns, es} -> {Enum.reverse(ns), Enum.reverse(es)} end)
    end
  end
  defp parse_nodo(linea, texto) do
    case String.split(texto, ",", trim: false) |> Enum.map(&String.trim/1) do
      [id, x, y] when id != "" ->
        with {x, ""} when x >= 0 <- Integer.parse(x),
             {y, ""} when y >= 0 <- Integer.parse(y) do
          {:ok, %Nodo{id: id, x: x, y: y, linea: linea}}
        else
          _ -> {:error, "Línea #{linea}: coordenadas deben ser enteros no negativos: #{texto}"}
        end
      _ -> {:error, "Línea #{linea}: formato de nodo inválido: #{texto}"}
    end
  end
  defp cargar_aristas do
    if not File.exists?("aristas.csv") do
      Util2.mostrar("Falta el archivo requerido: aristas.csv", :error)
      {[], ["Falta el archivo requerido: aristas.csv"]}
    else
      File.stream!("aristas.csv")
      |> Stream.with_index(1)
      |> Stream.map(fn {texto, linea} -> {linea, String.trim(texto)} end)
      |> Stream.reject(fn {_n, s} -> s == "" or String.starts_with?(s, "#") end)
      |> Stream.map(fn {n, texto} ->
        case String.split(texto, ",", trim: false) |> Enum.map(&String.trim/1) do
          [a, b] when a != "" and b != "" -> {:ok, %Arista{a: a, b: b, linea: n}}
          _ -> {:error, "Línea #{n}: formato de arista inválido: #{texto}"}
        end
      end)
      |> Enum.reduce({[], []}, fn
        {:ok, arista}, {as, es} -> {[arista | as], es}
        {:error, error}, {as, es} -> {as, [error | es]}
      end)
      |> then(fn {as, es} -> {Enum.reverse(as), Enum.reverse(es)} end)
    end
  end

  # Validadores recursivos propios: no usan Enum ni Stream.
  defp validar_nodos([], _vistos, errores), do: invertir(errores)
  defp validar_nodos([nodo | resto], vistos, errores) do
    if MapSet.member?(vistos, nodo.id) do
      validar_nodos(resto, vistos, ["Línea #{nodo.linea}: ID de nodo duplicado #{nodo.id}" | errores])
    else
      validar_nodos(resto, MapSet.put(vistos, nodo.id), errores)
    end
  end
  defp ids_nodos([], ids), do: ids
  defp ids_nodos([nodo | resto], ids), do: ids_nodos(resto, MapSet.put(ids, nodo.id))
  defp validar_aristas([], _ids, _vistos, errores), do: invertir(errores)
  defp validar_aristas([arista | resto], ids, vistos, errores) do
    pareja = if arista.a <= arista.b, do: {arista.a, arista.b}, else: {arista.b, arista.a}
    problemas = problemas_arista(arista, pareja, ids, vistos, [])
    validar_aristas(resto, ids, MapSet.put(vistos, pareja), invertir(problemas) ++ errores)
  end
  defp problemas_arista(arista, pareja, ids, vistos, acc) do
    acc = if arista.a == arista.b,
      do: ["Línea #{arista.linea}: bucle no permitido #{arista.a},#{arista.b}" | acc], else: acc
    acc = if not MapSet.member?(ids, arista.a) or not MapSet.member?(ids, arista.b),
      do: ["Línea #{arista.linea}: arista con nodo desconocido #{arista.a},#{arista.b}" | acc], else: acc
    if MapSet.member?(vistos, pareja),
      do: ["Línea #{arista.linea}: arista repetida (incluida dirección inversa) #{arista.a},#{arista.b}" | acc],
      else: acc
  end
  def cargar_propuestas(nodos, aristas) do
    if not File.exists?("propuestas.txt") do
      Util2.mostrar("Falta el archivo requerido: propuestas.txt", :error)
      {[], ["Falta el archivo requerido: propuestas.txt"]}
    else
      File.stream!("propuestas.txt")
      |> Stream.with_index(1)
      |> Stream.map(fn {texto, n} -> {n, String.trim(texto)} end)
      |> Stream.reject(fn {_n, s} -> s == "" or String.starts_with?(s, "#") end)
      |> Enum.reduce({[], []}, fn {linea, texto}, {ok, errores} ->
        case parse_propuesta(linea, texto) do
          {:ok, k, asignaciones} ->
            problemas = validar_propuesta(k, asignaciones, nodos, aristas, linea)
            if problemas == [] do
              { ["Línea #{linea}: válida (k=#{k})" | ok], errores }
            else
              {ok, Enum.reverse(problemas) ++ errores}
            end
          {:error, motivo} -> {ok, ["Línea #{linea}: #{motivo}" | errores]}
        end
      end)
      |> then(fn {ok, errores} -> {Enum.reverse(ok), Enum.reverse(errores)} end)
    end
  end
  defp parse_propuesta(linea, texto) do
    case String.split(texto, ";", trim: false) do
      [k_texto | pares] ->
        case Integer.parse(String.trim(k_texto)) do
          {k, ""} when k > 0 -> parse_asignaciones(pares, k, %{}, linea)
          _ -> {:error, "k debe ser un entero positivo"}
        end
      _ -> {:error, "propuesta vacía"}
    end
  end
  defp parse_asignaciones([], k, asignaciones, _linea), do: {:ok, k, asignaciones}
  defp parse_asignaciones([par | resto], k, asignaciones, linea) do
    case String.split(String.trim(par), "=", trim: false) |> Enum.map(&String.trim/1) do
      [id, color_texto] when id != "" ->
        case Integer.parse(color_texto) do
          {color, ""} -> parse_asignaciones(resto, k, Map.update(asignaciones, id, [color], &[color | &1]), linea)
          _ -> {:error, "Línea #{linea}: color inválido en #{par}"}
        end
      _ -> {:error, "Línea #{linea}: asignación inválida #{par}"}
    end
  end
  defp validar_propuesta(k, asignaciones, nodos, aristas, linea) do
    faltantes = faltantes_nodos(nodos, asignaciones, linea, [])
    # Detecta asignaciones repetidas también para IDs que no pertenecen a la red.
    repetidos = asignaciones_repetidas(Map.to_list(asignaciones), linea, [])
    conflictos_color = validar_colores_nodo(Map.to_list(asignaciones), k, linea, [])
    desconocidos = desconocidos_asignados(Map.keys(asignaciones), nodos, linea, [])
    conflictos_arista = conflictos_propuesta(aristas, asignaciones, linea, [])
    faltantes ++ repetidos ++ conflictos_color ++ desconocidos ++ conflictos_arista
  end
  defp faltantes_nodos([], _asignaciones, _linea, acc), do: invertir(acc)
  defp faltantes_nodos([nodo | resto], asignaciones, linea, acc) do
    nuevos = case Map.get(asignaciones, nodo.id) do
      nil -> ["Línea #{linea}: falta asignar el nodo #{nodo.id}" | acc]
      _colores -> acc
    end
    faltantes_nodos(resto, asignaciones, linea, nuevos)
  end

  # Revisa recursivamente todos los IDs asignados, incluidos los desconocidos.
  defp asignaciones_repetidas([], _linea, acc), do: invertir(acc)
  defp asignaciones_repetidas([{id, colores} | resto], linea, acc) do
    nuevos =
      if lista_multiples?(colores),
        do: ["Línea #{linea}: nodo #{id} aparece más de una vez" | acc],
        else: acc

    asignaciones_repetidas(resto, linea, nuevos)
  end

  defp lista_multiples?([_primero, _segundo | _resto]), do: true
  defp lista_multiples?(_lista), do: false
  defp validar_colores_nodo([], _k, _linea, acc), do: invertir(acc)
  defp validar_colores_nodo([{id, colores} | resto], k, linea, acc) do
    nuevos = validar_lista_colores(colores, id, k, linea, acc)
    validar_colores_nodo(resto, k, linea, nuevos)
  end
  defp validar_lista_colores([], _id, _k, _linea, acc), do: acc
  defp validar_lista_colores([color | resto], id, k, linea, acc) do
    nuevos = if color < 1 or color > k, do: ["Línea #{linea}: color #{color} de #{id} fuera de 1..#{k}" | acc], else: acc
    validar_lista_colores(resto, id, k, linea, nuevos)
  end
  defp desconocidos_asignados([], _nodos, _linea, acc), do: invertir(acc)
  defp desconocidos_asignados([id | resto], nodos, linea, acc) do
    if buscar_nodo(nodos, id) do
      desconocidos_asignados(resto, nodos, linea, acc)
    else
      desconocidos_asignados(resto, nodos, linea, ["Línea #{linea}: nodo desconocido #{id}" | acc])
    end
  end
  defp conflictos_propuesta([], _asignaciones, _linea, acc), do: invertir(acc)
  defp conflictos_propuesta([arista | resto], asignaciones, linea, acc) do
    ca = Map.get(asignaciones, arista.a, [])
    cb = Map.get(asignaciones, arista.b, [])
    # Comprueba recursivamente todos los colores si hay asignaciones repetidas.
    case color_comun(ca, cb) do
      nil -> conflictos_propuesta(resto, asignaciones, linea, acc)
      color ->
        nuevos = ["Línea #{linea}: conflicto en arista #{arista.a}-#{arista.b} (color #{color})" | acc]
        conflictos_propuesta(resto, asignaciones, linea, nuevos)
    end
  end

  defp color_comun([], _colores), do: nil
  defp color_comun([color | resto], colores) do
    if contiene_color?(colores, color), do: color, else: color_comun(resto, colores)
  end

  defp contiene_color?([], _color), do: false
  defp contiene_color?([color | _resto], color), do: true
  defp contiene_color?([_ | resto], color), do: contiene_color?(resto, color)
  defp buscar_nodo([], _id), do: false
  defp buscar_nodo([%Nodo{id: id} | _], id), do: true
  defp buscar_nodo([_ | resto], id), do: buscar_nodo(resto, id)

  # Inversión recursiva para mantener libres de Enum/Stream los validadores.
  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([cabeza | cola], acumulado), do: invertir(cola, [cabeza | acumulado])
end
