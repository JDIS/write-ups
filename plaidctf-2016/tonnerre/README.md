# tonnerre

We are given an URL to a service and
[its source code](public_server_ea2e768e20e89fb1aafbbc547cdb4636.py) (Python).

We are given an URL to a website.

## User Extraction
Through SQL Injection on the website, we are able to extract the following
information about a user in the DB:

- user: `get_flag`
- salt: `d14058efb3f49bd1f1c68de447393855e004103d432fa61849f0e5262d0d9e8663c0dfcb877d40ea6de6b78efd064bdd02f6555a90d92a8a5c76b28b9a785fd861348af8a7014f4497a5de5d0d703a24ff9ec9b5c1ff8051e3825a0fc8a433296d31cf0bd5d21b09c8cd7e658f2272744b4d2fb63d4bccff8f921932a2e81813`
- verifier: `ebedd14b5bf7d5fd88eebb057af43803b6f88e42f7ce2a4445fdbbe69a9ad7e7a76b7df4a4e79cefd61ea0c4f426c0261acf5becb5f79cdf916d684667b6b0940b4ac2f885590648fbf2d107707acb38382a95bea9a89fb943a5c1ef6e6d064084f8225eb323f668e2c3174ab7b1dbfce831507b33e413b56a41528b1c850e59`

## Service Analysis
Taking a look at [the service's source code](public_server_ea2e768e20e89fb1aafbbc547cdb4636.py),
we see that it does the following, in details (which is basically [SRP](https://en.wikipedia.org/wiki/Secure_Remote_Password_protocol)): (feel free to skip the specifics, this is
mainly a reference for later steps)

*Note: `^` represents `pow` and all calculations are implicitly mod N*

- Declares `N` and `g` as big constants.
- Import a list of permitted users (our extracted `get_flag` user is one of those).

- Receives a `username` from us.
- Receives a `public_client` int from us.

- Calculates `c = public_client * user_verifier`.
- Aborts if `c` is in `[N-g, N-1, 0, 1, g]` (some of these are trivially
craftable, as we will see later). Remember that the calculations are done modulo
`N`, so that's why we see small values such as `0` and `1`.


- Generates a `random_server` value.
- Calculates `public_server = g ^ random_server`.
- Calculates `residue = public_server + user_verifier`.

- Gives us the `salt` and the `residue`.

- Calculates `session_secret = c ^ random_server`.
- Calculates `session_key = Hash(as_a_string(session_secret))`.

- Receives a `proof` from us.
- Sends us the flag if `proof == Hash(as_a_string(residue) + session_key)`.

## The Big Picture
Basically, we want to do the following:

- Provide a `public_client` that will produce a `c` that is not forbidden.
- That `c` must be chosen wisely (we must be able to guess the `session_secret`
  from it).
- Redo the calculations done by the server to calculate the `session_key`.
- Provide a `proof` out of that.

## Predicting `session_secret`
Predicting `session_secret` without worrying about forbidden values of `c` yet
is relatively easy.

We are given the `residue` and know that it is calculated as
`public_server + verifier`. We know the `verifier`. Thus, we can calculate
`public_server` as `residue - verifier` (since we are in `mod N`, we must do
`+ N` if the result is negative to keep positive numbers).

We know that the server will calculate `session_secret` as `c ^ random_server`.
If we could somehow produce a `c` value of the form `g ^ (something)`, then the
server would be calculating: `(g ^ something) ^ random_server`, or noted
differently: `g ^ (something * random_server)`.

By knowing `public_server`, we know the result of `g ^ random_server` (this is
how `public_server` is calculated). If we take this value to the power of
`something`, we get `(g ^ random_server) ^ something`, which is:
`g ^ (random_server * something)`.

Because multiplication is commutative,
`g ^ (something * random_server) == g ^ (random_server * something)`.

Therefore, we just need to pick a valid `something` value and we can predict
`session_secret`!

## Choosing a `public_client`
However, we can't just set that `something` value. The only leverage that we
have to influence the value of `c` is `public_client`.

We want to choose a `public_client` value such that:
`public_client * verifier = g ^ something`.

If we pick `public_client` to be the [modular inverse](https://en.wikipedia.org/wiki/Modular_multiplicative_inverse)
of `verifier`, we get:

```
   (modinv(verifier)) * verifier = g ^ something
=>                             1 = g ^ something
```

By [Fermat's Little Theorem](https://en.wikipedia.org/wiki/Fermat%27s_little_theorem),
we know that `a ^ (n-1) = 1 (mod n)`, if `n` is prime (which [factordb](http://factordb.com/index.php?query=168875487862812718103814022843977235420637243601057780595044400667893046269140421123766817420546087076238158376401194506102667350322281734359552897112157094231977097740554793824701009850244904160300597684567190792283984299743604213533036681794114720417437224509607536413793425411636411563321303444740798477587) confirms for our `N`).
This means that by picking `public_client = modinv(verifier)`, we fit the
theorem and get `g ^ (N - 1) = 1`, but we give `N - 1` the name `something`, and
`1` happens to be calculated through `public_client * verifier`.

However, `c = public_client * verifier = 1` is forbidden by the server.

`c = g ^ 2` is not.

Let's play with our current equation to produce a valid `c`:
```
           g ^ (N - 1) = 1
=> g ^ (N - 1) * g ^ 2 = 1 * g ^ 2     (* g^2 on each side)
=>     g ^ (N - 1 + 2) = g ^ 2         (group exponents)
=>         g ^ (N + 1) = g ^ 2
```

Now, `c = g ^ 2` and is valid! We can produce `c` with:
`c = public_client * verifier = (g ^ 2 * modinv(verifier)) * verifier) = g ^ 2 * 1 = g ^ 2`.

Thus, we choose `public_client = g ^ 2 * modinv(verifier)` to get a `c` of the
form `g ^ (N + 1)`.

Note: this section was a bit of an overkill in retrospect. The normal SRP
protocol could have been used with just an additional multiplication with the
`modinv` of `verifier`, according to [this write-up](http://duksctf.github.io/PCTF2016-tonnerre/).
Still, using *Fermat's Little Theorem* is worth some swag points.

## Putting it All Together
- S: User?
- C: `get_flag`.
- S: `public_client`?
- C: `g ^ 2 * modinv(verifier)`.
- S: `salt`. `residue`.

[extract `public_server` from `residue`]

[predict `session_secret` as `public_server ^ (N + 1)`]

[calculate `proof` from `session_secret`]

- C: `proof`.
- ...
- :tada:

\#TheForceHasBeenHacked
