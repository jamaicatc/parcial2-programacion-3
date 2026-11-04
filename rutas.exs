# Integrantes del grupo:
# Juan David Cardona
# Santiago Trujillo
# Sharon Ospina

# Declara el módulo que implementa el problema 1: rutas dirigidas.
defmodule Rutas do
  # Expone la ejecución del problema de rutas.
  def run do
    # Carga, depura y procesa las consultas de rutas.
    resolver_rutas()
  # Cierra la función pública run/0.
  end

  # ---------------- Problema 1: rutas ----------------

  # Define la función privada resolver_rutas, encargada de resolver rutas.
  defp resolver_rutas do
    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    {tramos, vertices} = cargar_tramos()

    # Accede al archivo indicado para leerlo o escribirlo.
    File.open!("itinerarios.txt", [:write, :utf8], fn itinerarios_io ->
      # Accede al archivo indicado para leerlo o escribirlo.
      File.open!("alcance_centros.txt", [:write, :utf8], fn alcance_io ->
        # Selecciona el tratamiento según el valor evaluado.
        case File.exists?("consultas.txt") do
          # Define el resultado para este patrón o caso de la función.
          false -> Util2.mostrar("Falta el archivo requerido: consultas.txt", :error)
          # Define el resultado para este patrón o caso de la función.
          true -> procesar_consultas(tramos, vertices, itinerarios_io, alcance_io)
        # Cierra el bloque o la definición iniciada anteriormente.
        end
      # Continúa la lógica del bloque y prepara el siguiente paso.
      end)
    # Continúa la lógica del bloque y prepara el siguiente paso.
    end)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada cargar_tramos, encargada de cargar tramos.
  defp cargar_tramos do
    # Ejecuta una rama condicional según el resultado de la expresión.
    if not File.exists?("tramos.csv") do
      # Regenera ambos reportes aun cuando falta el archivo de entrada.
      File.open!("errores_tramos.txt", [:write, :utf8], fn io ->
        IO.write(io, "Falta el archivo requerido: tramos.csv\n")
      end)
      File.open!("depuracion_tramos.txt", [:write, :utf8], fn _io -> :ok end)
      # Muestra un mensaje al usuario mediante el módulo auxiliar.
      Util2.mostrar("Falta el archivo requerido: tramos.csv", :error)
      # Consulta o actualiza el conjunto de elementos visitados.
      {[], MapSet.new()}
    # Inicia la alternativa cuando no se cumple la condición anterior.
    else
      # Accede al archivo indicado para leerlo o escribirlo.
      File.open!("errores_tramos.txt", [:write, :utf8], fn errores_io ->
        # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
        leidos =
          # Continúa la lógica del bloque y prepara el siguiente paso.
          "tramos.csv"
          # Encadena una transformación sobre el resultado anterior.
          |> lineas_utiles()
          # Encadena una transformación sobre el resultado anterior.
          |> Stream.map(fn {linea, texto} ->
            # Selecciona el tratamiento según el valor evaluado.
            case Tramo.parse(texto) do
              # Define el resultado para este patrón o caso de la función.
              {:ok, tramo} -> {:ok, %{tramo | linea: linea}, texto}
              # Define el resultado para este patrón o caso de la función.
              {:error, motivo} -> {:error, linea, texto, motivo}
            # Cierra el bloque o la definición iniciada anteriormente.
            end
          # Continúa la lógica del bloque y prepara el siguiente paso.
          end)
          # Encadena una transformación sobre el resultado anterior.
          |> Enum.reduce([], fn
            # Define el resultado para este patrón o caso de la función.
            {:ok, tramo, _texto}, acc -> [tramo | acc]
            # Define el resultado para este patrón o caso de la función.
            {:error, linea, texto, motivo}, acc ->
              # Escribe el fragmento de salida en el archivo o dispositivo.
              IO.write(errores_io, "Línea #{linea}: #{texto} | #{motivo}\n")
              # Continúa la lógica del bloque y prepara el siguiente paso.
              acc
          # Continúa la lógica del bloque y prepara el siguiente paso.
          end)

        # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
        leidos = Enum.reverse(leidos)
        # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
        tramos = depurar_tramos(leidos)
        # Consulta o actualiza el conjunto de elementos visitados.
        vertices = vertices_tramos(tramos, MapSet.new())
        # Construye el valor que se entrega como resultado de esta rama.
        {tramos, vertices}
      # Continúa la lógica del bloque y prepara el siguiente paso.
      end)
    # Cierra el bloque o la definición iniciada anteriormente.
    end
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Validación recursiva: conserva la primera aparición de cada dirección.
  # Define la función privada depurar_tramos, encargada de depurar tramos.
  defp depurar_tramos(tramos) do
    # Accede al archivo indicado para leerlo o escribirlo.
    File.open!("depuracion_tramos.txt", [:write, :utf8], fn io ->
      # Consulta o actualiza el conjunto de elementos visitados.
      depurar_tramos_rec(tramos, MapSet.new(), [], io)
    # Continúa la lógica del bloque y prepara el siguiente paso.
    end)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada depurar_tramos_rec, encargada de depurar tramos rec.
  defp depurar_tramos_rec([], _vistos, aceptados, _io), do: invertir(aceptados)
  # Define la función privada depurar_tramos_rec, encargada de depurar tramos rec.
  defp depurar_tramos_rec([tramo | resto], vistos, aceptados, io) do
    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    pareja = {tramo.origen, tramo.destino}

    # Evalúa las condiciones en orden hasta encontrar una verdadera.
    cond do
      # Define el resultado para este patrón o caso de la función.
      tramo.origen == tramo.destino ->
        # Escribe el fragmento de salida en el archivo o dispositivo.
        IO.write(io, "Línea #{tramo.linea}: #{tramo.origen},#{tramo.destino},#{tramo.minutos},#{tramo.costo} | bucle descartado\n")
        # Continúa la lógica del bloque y prepara el siguiente paso.
        depurar_tramos_rec(resto, vistos, aceptados, io)

      # Define el resultado para este patrón o caso de la función.
      MapSet.member?(vistos, pareja) ->
        # Escribe el fragmento de salida en el archivo o dispositivo.
        IO.write(io, "Línea #{tramo.linea}: #{tramo.origen},#{tramo.destino},#{tramo.minutos},#{tramo.costo} | pareja dirigida repetida; se conserva la primera\n")
        # Continúa la lógica del bloque y prepara el siguiente paso.
        depurar_tramos_rec(resto, vistos, aceptados, io)

      # Define el resultado para este patrón o caso de la función.
      true ->
        # Consulta o actualiza el conjunto de elementos visitados.
        depurar_tramos_rec(resto, MapSet.put(vistos, pareja), [tramo | aceptados], io)
    # Cierra el bloque o la definición iniciada anteriormente.
    end
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Invierte listas mediante recursión para conservar el orden original.
  defp invertir(lista), do: invertir(lista, [])
  # Devuelve el acumulador cuando ya no quedan elementos por recorrer.
  defp invertir([], acumulado), do: acumulado
  # Traslada la cabeza de la lista al acumulador y continúa recursivamente.
  defp invertir([cabeza | cola], acumulado), do: invertir(cola, [cabeza | acumulado])

  # Define la función privada vertices_tramos, encargada de vertices tramos.
  defp vertices_tramos([], vertices), do: vertices
  # Define la función privada vertices_tramos, encargada de vertices tramos.
  defp vertices_tramos([tramo | resto], vertices) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    vertices
    # Encadena una transformación sobre el resultado anterior.
    |> MapSet.put(tramo.origen)
    # Encadena una transformación sobre el resultado anterior.
    |> MapSet.put(tramo.destino)
    # Encadena una transformación sobre el resultado anterior.
    |> then(&vertices_tramos(resto, &1))
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada procesar_consultas, encargada de procesar consultas.
  defp procesar_consultas(tramos, vertices, itinerarios_io, alcance_io) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    "consultas.txt"
    # Encadena una transformación sobre el resultado anterior.
    |> lineas_utiles()
    # Encadena una transformación sobre el resultado anterior.
    |> Enum.each(fn {linea, texto} ->
      # Selecciona el tratamiento según el valor evaluado.
      case String.split(texto, ",", trim: false) |> Enum.map(&String.trim/1) do
        # Define el resultado para este patrón o caso de la función.
        [origen, destino] when origen != "" and destino != "" ->
          # Escribe el fragmento de salida en el archivo o dispositivo.
          IO.write(itinerarios_io, "=== #{origen} → #{destino} ===\n")

          # Ejecuta una rama condicional según el resultado de la expresión.
          if not MapSet.member?(vertices, origen) or not MapSet.member?(vertices, destino) do
            # Escribe el fragmento de salida en el archivo o dispositivo.
            IO.write(itinerarios_io, "Centro consultado inexistente (línea #{linea}); no se inició la búsqueda.\n\n")
            # Muestra un mensaje al usuario mediante el módulo auxiliar.
            Util.mostrar_mensaje("#{origen} → #{destino}: centro inexistente")
          # Inicia la alternativa cuando no se cumple la condición anterior.
          else
            # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
            alcanzados = escribir_alcance(origen, destino, tramos, alcance_io)

            # Ejecuta una rama condicional según el resultado de la expresión.
            if not MapSet.member?(alcanzados, destino) do
              # Escribe el fragmento de salida en el archivo o dispositivo.
              IO.write(itinerarios_io, "Sin itinerarios: el destino no es alcanzable.\n\n")
              # Muestra un mensaje al usuario mediante el módulo auxiliar.
              Util.mostrar_mensaje("#{origen} → #{destino}: 0 itinerarios")
            # Inicia la alternativa cuando no se cumple la condición anterior.
            else
              # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
              rutas = buscar_itinerarios(origen, destino, tramos)
              # Continúa la lógica del bloque y prepara el siguiente paso.
              escribir_itinerarios(itinerarios_io, rutas)
              # Muestra un mensaje al usuario mediante el módulo auxiliar.
              Util.mostrar_mensaje("#{origen} → #{destino}: #{length(rutas)} itinerarios")
            # Cierra el bloque o la definición iniciada anteriormente.
            end
          # Cierra el bloque o la definición iniciada anteriormente.
          end

        # Define el resultado para este patrón o caso de la función.
        _ ->
          # Escribe el fragmento de salida en el archivo o dispositivo.
          IO.write(itinerarios_io, "Línea #{linea}: consulta inválida: #{texto}\n\n")
      # Cierra el bloque o la definición iniciada anteriormente.
      end
    # Continúa la lógica del bloque y prepara el siguiente paso.
    end)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Consume el Stream sólo hasta que dos conjuntos consecutivos sean iguales.
  # Define la función privada escribir_alcance, encargada de escribir alcance.
  defp escribir_alcance(origen, destino, tramos, io) do
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Consulta #{origen} → #{destino}\n")
    # Consulta o actualiza el conjunto de elementos visitados.
    estados = Stream.iterate(MapSet.new([origen]), &siguiente_alcance(&1, tramos))

    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    {alcanzados, _} =
      # Procesa la colección disponible en este punto.
      Enum.reduce_while(estados, {nil, 0}, fn estado, {anterior, paso} ->
        # Ejecuta una rama condicional según el resultado de la expresión.
        if anterior == estado do
          # Escribe el fragmento de salida en el archivo o dispositivo.
          IO.write(io, "Estabiliza en paso #{paso - 1}.\n\n")
          # Construye el valor que se entrega como resultado de esta rama.
          {:halt, {anterior, paso}}
        # Inicia la alternativa cuando no se cumple la condición anterior.
        else
          # Consulta o actualiza el conjunto de elementos visitados.
          centros = estado |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")
          # Escribe el fragmento de salida en el archivo o dispositivo.
          IO.write(io, "Paso #{paso}: {#{centros}}\n")
          # Construye el valor que se entrega como resultado de esta rama.
          {:cont, {estado, paso + 1}}
        # Cierra el bloque o la definición iniciada anteriormente.
        end
      # Continúa la lógica del bloque y prepara el siguiente paso.
      end)

    # Continúa la lógica del bloque y prepara el siguiente paso.
    alcanzados
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada siguiente_alcance, encargada de siguiente alcance.
  defp siguiente_alcance(actual, tramos), do: agregar_destinos(tramos, actual, actual)
  # Define la función privada agregar_destinos, encargada de agregar destinos.
  defp agregar_destinos([], _actual, alcanzados), do: alcanzados
  # Define la función privada agregar_destinos, encargada de agregar destinos.
  defp agregar_destinos([tramo | resto], actual, alcanzados) do
    # Consulta o actualiza el conjunto de elementos visitados.
    nuevos = if MapSet.member?(actual, tramo.origen), do: MapSet.put(alcanzados, tramo.destino), else: alcanzados
    # Continúa la lógica del bloque y prepara el siguiente paso.
    agregar_destinos(resto, actual, nuevos)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada buscar_itinerarios, encargada de buscar itinerarios.
  defp buscar_itinerarios(origen, destino, tramos) do
    # Consulta o actualiza el conjunto de elementos visitados.
    explorar_rutas(origen, destino, tramos, MapSet.new(), [origen], [], 0, 0)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada explorar_rutas, encargada de explorar rutas.
  defp explorar_rutas(destino, destino, _tramos, _visitados, centros, usados, minutos, costo) do
    # Construye el valor que se entrega como resultado de esta rama.
    [%Itinerario{centros: Enum.reverse(centros), tramos: Enum.reverse(usados), minutos: minutos, costo: costo}]
  # Cierra el bloque o la definición iniciada anteriormente.
  end
  # Define la función privada explorar_rutas, encargada de explorar rutas.
  defp explorar_rutas(actual, destino, tramos, visitados, centros, usados, minutos, costo) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    visitar_salidas(salidas_desde(tramos, actual), destino, tramos,
      # Consulta o actualiza el conjunto de elementos visitados.
      MapSet.put(visitados, actual), centros, usados, minutos, costo, [])
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada salidas_desde, encargada de salidas desde.
  defp salidas_desde(tramos, centro), do: salidas_desde_rec(tramos, centro, [])
  # Define la función privada salidas_desde_rec, encargada de salidas desde rec.
  defp salidas_desde_rec([], _centro, acc), do: Enum.reverse(acc)
  # Define la función privada salidas_desde_rec, encargada de salidas desde rec.
  defp salidas_desde_rec([tramo | resto], centro, acc) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    salidas_desde_rec(resto, centro, if(tramo.origen == centro, do: [tramo | acc], else: acc))
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada visitar_salidas, encargada de visitar salidas.
  defp visitar_salidas([], _destino, _tramos, _visitados, _centros, _usados, _minutos, _costo, acc), do: Enum.reverse(acc)
  # Define la función privada visitar_salidas, encargada de visitar salidas.
  defp visitar_salidas([tramo | resto], destino, tramos, visitados, centros, usados, minutos, costo, acc) do
    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    nuevas =
      # Ejecuta una rama condicional según el resultado de la expresión.
      if MapSet.member?(visitados, tramo.destino) do
        # Construye el valor que se entrega como resultado de esta rama.
        []
      # Inicia la alternativa cuando no se cumple la condición anterior.
      else
        # Continúa la lógica del bloque y prepara el siguiente paso.
        explorar_rutas(tramo.destino, destino, tramos, visitados, [tramo.destino | centros],
          # Construye el valor que se entrega como resultado de esta rama.
          [tramo | usados], minutos + tramo.minutos, costo + tramo.costo)
      # Cierra el bloque o la definición iniciada anteriormente.
      end

    # Continúa la lógica del bloque y prepara el siguiente paso.
    visitar_salidas(resto, destino, tramos, visitados, centros, usados, minutos, costo, Enum.reverse(nuevas) ++ acc)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada escribir_itinerarios, encargada de escribir itinerarios.
  defp escribir_itinerarios(io, rutas) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    escribir_rutas(io, rutas, 1)
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Total: #{length(rutas)} itinerarios\n")
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Menos tramos: #{indices_optimos(rutas, &length(&1.tramos))}\n")
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Menor tiempo: #{indices_optimos(rutas, & &1.minutos)}\n")
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Menor costo: #{indices_optimos(rutas, & &1.costo)}\n\n")
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada escribir_rutas, encargada de escribir rutas.
  defp escribir_rutas(_io, [], _indice), do: :ok
  # Define la función privada escribir_rutas, encargada de escribir rutas.
  defp escribir_rutas(io, [ruta | resto], indice) do
    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    centros = Enum.join(ruta.centros, " → ")
    # Define el resultado para este patrón o caso de la función.
    tramos = ruta.tramos |> Enum.map(fn t -> "#{t.origen}->#{t.destino}(#{t.minutos} min, costo #{t.costo})" end) |> Enum.join(", ")
    # Escribe el fragmento de salida en el archivo o dispositivo.
    IO.write(io, "Itinerario #{indice}: #{centros} | tramos: #{length(ruta.tramos)} [#{tramos}] | #{ruta.minutos} min | costo: #{ruta.costo}\n")
    # Continúa la lógica del bloque y prepara el siguiente paso.
    escribir_rutas(io, resto, indice + 1)
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Define la función privada indices_optimos, encargada de indices optimos.
  defp indices_optimos([], _criterio), do: "ninguno"
  # Define la función privada indices_optimos, encargada de indices optimos.
  defp indices_optimos(rutas, criterio) do
    # Asigna o actualiza el valor utilizado por las instrucciones siguientes.
    mejor = minimo_rec(rutas, criterio, nil)
    # Continúa la lógica del bloque y prepara el siguiente paso.
    rutas
    # Encadena una transformación sobre el resultado anterior.
    |> indices_iguales(criterio, mejor, 1, [])
    # Encadena una transformación sobre el resultado anterior.
    |> Enum.reverse()
    # Encadena una transformación sobre el resultado anterior.
    |> Enum.join(", ")
  # Cierra el bloque o la definición iniciada anteriormente.
  end
  # Define la función privada minimo_rec, encargada de minimo rec.
  defp minimo_rec([], _criterio, mejor), do: mejor
  # Define la función privada minimo_rec, encargada de minimo rec.
  defp minimo_rec([ruta | resto], criterio, nil), do: minimo_rec(resto, criterio, criterio.(ruta))
  # Define la función privada minimo_rec, encargada de minimo rec.
  defp minimo_rec([ruta | resto], criterio, mejor), do: minimo_rec(resto, criterio, min(mejor, criterio.(ruta)))
  # Define la función privada indices_iguales, encargada de indices iguales.
  defp indices_iguales([], _criterio, _mejor, _indice, acc), do: acc
  # Define la función privada indices_iguales, encargada de indices iguales.
  defp indices_iguales([ruta | resto], criterio, mejor, indice, acc) do
    # Continúa la lógica del bloque y prepara el siguiente paso.
    indices_iguales(resto, criterio, mejor, indice + 1, if(criterio.(ruta) == mejor, do: [indice | acc], else: acc))
  # Cierra el bloque o la definición iniciada anteriormente.
  end

  # Función compartida por el módulo para leer entradas de forma perezosa.
  defp lineas_utiles(archivo) do
    # Abre el archivo línea por línea sin cargarlo completo.
    File.stream!(archivo)
    # Añade el número físico de línea a cada texto leído.
    |> Stream.with_index(1)
    # Recorta espacios conservando el índice original.
    |> Stream.map(fn {linea, n} -> {n, String.trim(linea)} end)
    # Omite las líneas vacías y los comentarios.
    |> Stream.reject(fn {_n, texto} -> texto == "" or String.starts_with?(texto, "#") end)
  # Cierra lineas_utiles/1.
  end
# Cierra el módulo Rutas.
end
