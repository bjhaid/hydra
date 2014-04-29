-module(hydra_server).
-export([start/0, echo/0, readlines/1, search_file/3, receiver/0, standalone/2, main/1]).

main([]) -> usage();
main([_]) -> usage();
main([_, _]) -> usage();
main([String, Filename, Pattern]) ->
  case list_to_atom(String) of
    start -> start();
    standalone -> standalone(Filename, Pattern);
    _ -> usage()
  end;
main([_, _, _, _]) -> usage();
main([_, _, _, _|_]) -> usage().

usage() ->
  io:fwrite("Usage:
            hydra standalone <perl_regex> <filename>").

start() ->
  spawn(?MODULE, echo, []).

standalone(Filename, Pattern) ->
  Pid = spawn(?MODULE, receiver, []),
  search_file(Pid, Filename, Pattern).

receiver() ->
  receive
    Line -> io:fwrite(Line), receiver()
  end.

echo() ->
  receive
    {Pid, Filename, Pattern} ->
      Pid ! search_file(Pid, Filename, Pattern),
      echo();
    {stop} -> ok
  end.

readline(Device) ->
  case file:read_line(Device) of
    eof -> file:close(Device), eof;
    {ok, Line} -> Line;
    {error, Unknown} -> file:close(Device),
      {error, Unknown}
  end.

search_file(Pid, Filename, Pattern) ->
  case file:open(Filename, [read]) of
    {ok, Device} -> search_file(Pid, Filename, Pattern, Device);
    {error, Unknown} -> {error, Unknown}
  end.

search_file(Pid, Filename, Pattern, Device) ->
  Line = readline(Device),
  case Line of
    eof -> eof;
    {error, Unknown} -> Pid ! {error, Unknown};
    X -> send_matched_line(Pid, Pattern, X),
      search_file(Pid, Filename, Pattern, Device)
  end. 

send_matched_line(Pid, Pattern, Line) ->
  case re:run(Line, Pattern) of
    {match, _} -> Pid ! Line;
    X -> X
  end.
