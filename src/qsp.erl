-module(qsp).
-export([decode/1]).

%%
%% Decode
%%

decode(QS) ->
    PL = cow_qs:parse_qs(QS),
    lists:foldl(fun decode_pair/2, #{}, lists:reverse(PL)).

decode_pair({Key, Value}, Acc) ->
    BL = binary:last(Key),
    Parts = if
        Key /= <<"">> andalso BL == $] ->
            Subkey = binary:part(Key, 0, byte_size(Key) - 1),
            case binary:split(Subkey, <<"[">>) of
                [Key2, Subpart] ->
                    [Key2 | binary:split(Subpart, <<"][">>, [global])];
                _ ->
                    [Key]
            end;
        true ->
            [Key]
    end, assign_parts(Parts, Value, Acc).

assign_parts([Key], Value, Acc) ->
    case maps:find(Key, Acc) of
        {ok, _Value} -> Acc;
        _ -> maps:put(Key, Value, Acc)
    end;
assign_parts([Key, <<"">> | T], Value, Acc) ->
    case maps:find(Key, Acc) of
        {ok, Current} when is_list(Current) ->
            maps:put(Key, assign_list(T, Current, Value), Acc);
        error ->
            maps:put(Key, assign_list(T, [], Value), Acc);
        _ ->
            Acc
    end;
assign_parts([Key | T], Value, Acc) ->
    case maps:find(Key, Acc) of
        {ok, Current} ->
            maps:put(Key, assign_parts(T, Value, Current), Acc);
        error ->
            maps:put(Key, assign_parts(T, Value, #{}), Acc);
        _ ->
            Acc
    end.

assign_list(T, Current, Value) -> [assign_list(T, Value) | Current].
assign_list([], Value) -> Value;
assign_list(T, Value) -> assign_parts(T, Value, #{}).

%%
%% Test
%%

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-define(asrt(A, B), ?assertEqual(B, A)).

get(K, M) ->
    case maps:find(K, M) of
        {ok, V} -> V;
        U -> U
    end.

decode_simple_test() ->
    P = decode(<<"foo=bar&baz=bat">>),
    ?asrt(get(<<"foo">>, P),
        <<"bar">>),
    ?asrt(get(<<"baz">>, P),
        <<"bat">>).

decode_hash_test() ->
    P = decode(<<"users[name]=hello&users[age]=17">>),
    ?asrt(get(<<"users">>, P),
        #{<<"name">> => <<"hello">>, <<"age">> => <<"17">>}).

decode_simple_list_test() ->
    ?asrt(decode(<<"foo[]">>),
        #{<<"foo">> => [true]}),
    ?asrt(decode(<<"foo[]=">>),
        #{<<"foo">> => [<<>>]}),
    ?asrt(decode(<<"foo[]=bar&foo[]=baz">>),
        #{<<"foo">> => [<<"bar">>, <<"baz">>]}).

decode_list_test() ->
    P = decode(<<"foo[]=bar&foo[]=baz&bat[]=1&bat[]=2">>),
    ?asrt(get(<<"foo">>, P),
        [<<"bar">>, <<"baz">>]),
    ?asrt(get(<<"bat">>, P),
        [<<"1">>, <<"2">>]).

decode_nested_test() ->
    ?asrt(decode(<<"x[y][z]=1">>),
        #{<<"x">> => #{<<"y">> => #{<<"z">> => <<"1">>}}}),
    ?asrt(decode(<<"x[y][z][]=1">>),
        #{<<"x">> => #{<<"y">> => #{<<"z">> => [<<"1">>]}}}),
    ?asrt(decode(<<"x[y][z][]=1&x[y][z][]=2">>),
        #{<<"x">> => #{<<"y">> => #{<<"z">> => [<<"1">>, <<"2">>]}}}),
    ?asrt(decode(<<"x[y][][z]=1">>),
        #{<<"x">> => #{<<"y">> => [#{<<"z">> => <<"1">>}]}}),
    ?asrt(decode(<<"x[y][][z][]=1">>),
        #{<<"x">> => #{<<"y">> => [#{<<"z">> => [<<"1">>]}]}}).

decode_weird_query_test() ->
    P = decode(<<"my+weird+field=q1%212%22%27w%245%267%2Fz8%29%3F">>),
    ?asrt(get(<<"my weird field">>, P),
        <<"q1!2\"'w$5&7/z8)?">>).

decode_weird_kv_test() ->
    ?asrt(decode(<<"key=">>),
        #{<<"key">> => <<>>}).

decode_accept_last_test() ->
    ?asrt(decode(<<"x[]=1&x[y]=1">>),
        #{<<"x">> => #{<<"y">> => <<"1">>}}),
    ?asrt(decode(<<"x[y][][w]=2&x[y]=1">>),
        #{<<"x">> => #{<<"y">> => <<"1">>}}),
    ?asrt(decode(<<"x=1&x[y]=1">>),
        #{<<"x">> => #{<<"y">> => <<"1">>}}).

-endif.
