# Integrantes: Juan David Cardona, Santiago Trujillo y Sharon Ospina.

defmodule Tramo do
  defstruct [:origen, :destino, :minutos, :costo, :linea]

  def parse(texto) do
    case String.split(texto, ",", trim: false) |> Enum.map(&String.trim/1) do
      [origen, destino, minutos, costo] when origen != "" and destino != "" ->
        with {minutos, ""} when minutos > 0 <- Integer.parse(minutos),
             {costo, ""} when costo > 0 <- Integer.parse(costo) do
          {:ok, %__MODULE__{origen: origen, destino: destino, minutos: minutos, costo: costo}}
        else
          _ -> {:error, "minutos y costo deben ser enteros positivos"}
        end

      _ ->
        {:error, "se esperaban origen,destino,minutos,costo"}
    end
  end
end

defmodule Itinerario do
  defstruct [:centros, :tramos, :minutos, :costo]
end

defmodule Nodo do
  defstruct [:id, :x, :y, :linea]
end

defmodule Arista do
  defstruct [:a, :b, :linea]
end
