defmodule Otis.Broadcaster do
  use Supervisor

  @supervisor_name Otis.Broadcaster

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @supervisor_name)
  end

  def start_broadcaster(opts) do
    start_broadcaster(@supervisor_name, opts)
  end

  def start_broadcaster(supervisor, opts) do
    name = {:via, :gproc, {:n, :l, {Otis.Channel.Broadcaster, opts.id}}}
    Supervisor.start_child(supervisor, [opts, name])
    {:ok, name}
  end

  def stop_broadcaster(broadcaster) do
    stop_broadcaster!(broadcaster, :stop)
  end

  def skip_broadcaster(broadcaster) do
    stop_broadcaster!(broadcaster, :skip)
  end

  def stop_broadcaster!(broadcaster, reason) do
    GenServer.cast(broadcaster, {:stop, reason})
  end

  def init(:ok) do
    children = [
      worker(Otis.Channel.Broadcaster, [], [restart: :transient])
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end