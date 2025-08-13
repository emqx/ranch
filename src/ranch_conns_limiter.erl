%% Copyright (c) 2025 EMQ Technologies Co., Ltd.
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(ranch_conns_limiter).

-export([create/2]).
-export([allow/2]).
-export([accepted/2, retired/2]).

-export_type([limiter/0, penalty/0]).

-type limiter() :: {module(), _State}.

-type penalty() ::
    close_connection
    | {close_connections_for, _Milliseconds :: non_neg_integer()}.

%% Create new limiter.
-callback create(_Options) -> _State.

%% Ask the limiter if connection could be accepted.
-callback allow(_Socket, State) -> {ok | penalty(), State}.

%% Notify limited that a connection was accepted.
-callback accepted(pid(), State) -> State.

%% Notify limited that a previously accepted connection is gone.
-callback retired(pid(), State) -> State.

%%

-spec create(module(), _Options) -> limiter().
create(Module, Options) ->
    {Module, Module:create(Options)}.

%% Ask the limiter if connection could be accepted.
-spec allow(_Socket, limiter()) -> {ok | penalty(), limiter()}.
allow(Socket, {Module, State}) ->
    {Result, NState} = Module:allow(Socket, State),
    {Result, {Module, NState}}.

%% Notify limited that a connection was accepted.
-spec accepted(pid(), limiter()) -> limiter().
accepted(Pid, {Module, State}) ->
    NState = Module:accepted(Pid, State),
    {Module, NState}.

%% Notify limited that a previously accepted connection is gone.
-spec retired(pid(), limiter()) -> limiter().
retired(Pid, {Module, State}) ->
    NState = Module:retired(Pid, State),
    {Module, NState}.
