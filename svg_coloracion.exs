# Integrantes: Juan David Cardona, Santiago Trujillo y Sharon Ospina.

defmodule SvgColoracion do
  def escribir_svg(io, nodos, aristas, asignacion) do
    ancho = max(240, max_coord(nodos, :x, 0) + 80)
    alto = max(240, max_coord(nodos, :y, 0) + 80)
    IO.write(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{ancho}\" height=\"#{alto}\" viewBox=\"0 0 #{ancho} #{alto}\">\n")
    IO.write(io, "<rect width=\"100%\" height=\"100%\" fill=\"#f8fafc\"/>\n")
    escribir_aristas_svg(io, aristas, nodos)
    escribir_nodos_svg(io, nodos, asignacion)
    IO.write(io, "</svg>\n")
  end

  defp max_coord([], _campo, maximo), do: maximo
  defp max_coord([nodo | resto], :x, maximo), do: max_coord(resto, :x, max(maximo, nodo.x))
  defp max_coord([nodo | resto], :y, maximo), do: max_coord(resto, :y, max(maximo, nodo.y))
  defp escribir_aristas_svg(_io, [], _nodos), do: :ok
  defp escribir_aristas_svg(io, [arista | resto], nodos) do
    with %Nodo{} = a <- buscar_nodo_struct(nodos, arista.a), %Nodo{} = b <- buscar_nodo_struct(nodos, arista.b) do
      IO.write(io, "<line x1=\"#{a.x}\" y1=\"#{a.y}\" x2=\"#{b.x}\" y2=\"#{b.y}\" stroke=\"#64748b\" stroke-width=\"3\"/>\n")
    end
    escribir_aristas_svg(io, resto, nodos)
  end
  defp escribir_nodos_svg(_io, [], _asignacion), do: :ok
  defp escribir_nodos_svg(io, [nodo | resto], asignacion) do
    color = Map.get(asignacion, nodo.id, 1)
    relleno = Enum.at(["#2563eb", "#dc2626", "#16a34a", "#f59e0b", "#9333ea", "#0891b2", "#db2777", "#65a30d", "#ea580c", "#4f46e5"], rem(color - 1, 10))
    id = escapar_xml(nodo.id)
    IO.write(io, "<circle cx=\"#{nodo.x}\" cy=\"#{nodo.y}\" r=\"22\" fill=\"#{relleno}\" stroke=\"#0f172a\" stroke-width=\"2\"/>\n")
    IO.write(io, "<text x=\"#{nodo.x}\" y=\"#{nodo.y + 5}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\" fill=\"white\">#{id}</text>\n")
    escribir_nodos_svg(io, resto, asignacion)
  end

  defp buscar_nodo_struct([], _id), do: nil
  defp buscar_nodo_struct([%Nodo{id: id} = nodo | _], id), do: nodo
  defp buscar_nodo_struct([_ | resto], id), do: buscar_nodo_struct(resto, id)

  defp escapar_xml(texto) do
    texto |> String.replace("&", "&amp;") |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;") |> String.replace("\"", "&quot;") |> String.replace("'", "&apos;")
  end

end
