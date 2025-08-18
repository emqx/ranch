-module(counting_limiter).
-behaviour(ranch_conns_limiter).

-export([create/1]).
-export([allow/2]).
-export([accepted/2, retired/2]).

create(Options) ->
	Options#{n => 0}.

allow(Socket, State0 = #{n := N0, penalize := Pred, penalty := Penalty}) ->
	N = N0 + 1,
	State = State0#{n := N},
	Ret = case Pred(N) of
		true -> Penalty;
		false -> ok
	end,
	report(?FUNCTION_NAME, [Socket], Ret, State),
	{Ret, State}.

accepted(Pid, State) ->
	report(?FUNCTION_NAME, [Pid], State),
	State.

retired(Pid, State) ->
	report(?FUNCTION_NAME, [Pid], State),
	State.

report(Function, Args, Ret, #{report_to := Pid}) ->
	Pid ! {Function, Args, Ret}.

report(Function, Args, #{report_to := Pid}) ->
	Pid ! {Function, Args}.
