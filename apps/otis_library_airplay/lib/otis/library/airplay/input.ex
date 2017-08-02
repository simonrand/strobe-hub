defmodule Otis.Library.Airplay.Input do
  use GenStage

  alias Otis.Library.Airplay
  alias Porcelain.Result, as: Result
  require Logger

  defstruct [
    :id
  ]

  defmodule S do
    defstruct [
      :id,
      :process,
      :config,
      buffer: <<>>,
      queue: :queue.new(),
    ]
  end

  # TODO: get packet size from provided config
  @bpms round(44_100 * 2 * 2 * (1 / 1_000))
  @packet_size 100 * @bpms
  @silence_bytes @packet_size
  @silence :binary.copy(<<0>>, @silence_bytes)
  @buffer_len 40

  def title(%__MODULE__{id: id}) do
    "Airplay Input #{id}"
  end

  def start_link(n, config) do
    GenStage.start_link(__MODULE__, [n, config], name: Airplay.producer_id(n))
  end

  def init([n, _config]) do
    process = run_shairport(n)
    Process.flag(:trap_exit, true)
    {:producer, %S{id: n, process: process}, buffer_size: 100}
  end

  if Mix.env == :test do
    def run_shairport(_n) do
      nil
    end
  else
    def run_shairport(n) do
      Airplay.Shairport.run(n)
    end
  end

  def terminate(_reason, %S{process: nil}) do
    :ok
  end
  def terminate(_reason, %S{process: process}) do
    Airplay.Shairport.stop(process)
    :ok
  end

  def handle_demand(new_demand, state) when new_demand > 0 do
    {events, state} = supply_demand(state, new_demand, [])
    {:noreply, events, state}
  end

  defp supply_demand(state, 0, events) do
    {Enum.reverse(events), state}
  end
  defp supply_demand(%S{queue: queue} = state, demand, events) do
    case :queue.out(queue) do
      {{:value, data}, queue} ->
        supply_demand(%S{state | queue: queue}, demand - 1, [data | events])
      {:empty, queue} ->
        # We always want to send some audio data, even if there's none
        # available from the airplay process because otherwise our broadcaster
        # hangs
        supply_demand(%S{state | queue: queue}, demand - 1, [@silence | events])
    end
  end

  def handle_cast(:stream_start, state) do
    {:noreply, [], state}
  end
  def handle_cast(:stream_stop, state) do
    {:noreply, [], %S{state | buffer: <<>>, queue: :queue.new}}
  end

  def handle_info({_pid, :data, :out, data}, state) do
    {:noreply, [], append_data(data, state)}
  end
  def handle_info({_pid, :data, :err, _data}, state) do
    {:noreply, [], state}
  end
  # Generated by a conflict with an already running shairport instance
  def handle_info({_pid, :result, %Result{status: 1}}, state) do
    {:stop, {:error, :address_in_use}, state}
  end
  def handle_info({_pid, :result, %Result{} = _result}, state) do
    {:noreply, [], state}
  end
  def handle_info(msg, state) do
    Logger.warn "Unhandled message #{__MODULE__}.handle_info/2 #{inspect msg}"
    {:noreply, [], state}
  end

  defp append_data(data, %S{queue: queue, buffer: buffer} = state) do
    {buffer, queue} =
      << buffer <> data >>
      |> split_packets()
      |> queue_packets(queue)
    %S{state | buffer: buffer, queue: queue}
  end

  defp split_packets(buffer) do
    split_packets(buffer, [])
  end
  defp split_packets(buffer, packets) do
    case byte_size(buffer) do
      b when b >= @packet_size ->
        split_packets(:binary.part(buffer, @packet_size, b - @packet_size), [:binary.part(buffer, 0, @packet_size) | packets])
      _ ->
        {buffer, Enum.reverse(packets)}
    end
  end

  defp queue_packets({buffer, packets}, queue) do
    queue = packets |> Enum.reduce(queue, &queue_packet/2)
    {buffer, queue}
  end

  defp queue_packet(packet, queue) do
    :queue.in(packet, queue) |> limit_queue(@buffer_len)
  end

  defp limit_queue(queue, max_len) do
    case :queue.len(queue) do
      l when l > max_len ->
        :queue.drop(queue)
      _ ->
        queue
    end
  end
end


defimpl Otis.Library.Source, for: Otis.Library.Airplay.Input do
  alias Otis.Library.Airplay
  alias Airplay.Input

  def id(%Input{id: id}) do
    id
  end

  def type(_input) do
    Input
  end

  def open!(%Input{id: id}, _id, _packet_size_bytes) do
    Airplay.Stream.start!(Airplay.producer_id(id), nil)
  end

  def pause(_input, _id, _stream) do
    :stop
  end

  def close(%Input{}, _id, _stream) do
    :ok
  end

  def transcoder_args(_input) do
    # ["-f", "s16le", "-ar", "44100", "-ac", "2"]
    :passthrough
  end

  def metadata(input) do
    %{id: input.id,
      bit_rate: nil,
      channels: 2,
      duration_ms: nil,
      extension: nil,
      filename: nil,
      mime_type: nil,
      sample_rate: nil,
      stream_size: nil,
      album: nil,
      composer: nil,
      date: nil,
      disk_number: nil,
      genre: nil,
      performer: nil,
      title: Input.title(input),
      track_number: nil,
      track_total: nil,
      cover_image: nil,
    }
  end

  def duration(_input) do
    {:ok, :infinity}
  end
end

defimpl Otis.Library.Source.Origin, for: Otis.Library.Airplay.Input do
  alias Otis.Library.Airplay.Input

  def load!(%Input{} = input) do
    input
  end
end

defimpl Poison.Encoder, for: Otis.Library.Airplay.Input do
  def encode(input, opts) do
    %{id: input.id,
      bit_rate: nil,
      channels: 2,
      duration_ms: nil,
      extension: nil,
      filename: nil,
      mime_type: nil,
      sample_rate: nil,
      stream_size: nil,
      album: nil,
      composer: nil,
      date: nil,
      disk_number: nil,
      disk_total: nil,
      genre: nil,
      performer: nil,
      title: "Airplay Input #{input.id}",
      track_number: nil,
      track_total: nil,
      cover_image: Otis.Library.Airplay.Events.Library.airplay_logo(input.id),
    } |> Poison.Encoder.encode(opts)
  end
end
