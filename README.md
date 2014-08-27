### qsp [![Build Status](https://secure.travis-ci.org/artemeff/qsp.png)](http://travis-ci.org/artemeff/qsp)

---

QSP is enhanced Erlang query string parser, that supports nested arrays, hashes and returns maps. Requires Erlang 17.0 and better. Extracted from [Plug](https://github.com/elixir-lang/plug/blob/master/lib/plug/conn/query.ex).

---

```erlang
> qsp:decode(<<"foo=bar">>).
#{<<"foo">> => <<"bar">>}
> qsp:decode(<<"foo[]=bar&foo[]=baz">>).
#{<<"foo">> => [<<"bar">>,<<"baz">>]}
> qsp:decode(<<"foo[bar]=baz&foo[rab]=zab">>).
#{<<"foo">> => #{<<"bar">> => <<"baz">>,<<"rab">> => <<"zab">>}}
> qsp:decode(<<"foo[][bar][][baz][]=1">>).
#{<<"foo">> => [#{<<"bar">> => [#{<<"baz">> => [<<"1">>]}]}]}
> qsp:decode(<<"foo=1&foo=2">>).
#{<<"foo">> => <<"2">>}
```

---

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
