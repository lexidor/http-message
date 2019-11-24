<p align="center"><img src="https://avatars3.githubusercontent.com/u/45311177?s=200&v=4"></p>

<p align="center">
<a href="https://travis-ci.org/nuxed/http-message"><img src="https://travis-ci.org/nuxed/http-message.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/nuxed/http-message"><img src="https://poser.pugx.org/nuxed/http-message/d/total.svg" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/nuxed/http-message"><img src="https://poser.pugx.org/nuxed/http-message/v/stable.svg" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/nuxed/http-message"><img src="https://poser.pugx.org/nuxed/http-message/license.svg" alt="License"></a>
</p>

# Nuxed Http Message

The Nuxed Http Message component defines an object-oriented layer for the HTTP Messages specification.

### Installation

This package can be installed with [Composer](https://getcomposer.org).

```console
$ composer require nuxed/http-message
```

### Example

```hack
use namespace HH\Lib\Str;
use namespace Nuxed\Http\Message;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  $request = Message\ServerRequest::capture();

  $response = Message\Response\text(
    Str\format('%s %s', $request->getMethod(), $request->getRequestTarget())
  )
    |> $$->withCookie('name', new Message\Cookie('value'))
    |> $$->withStatus(200, 'OK');
}
```

---

### Security

For information on reporting security vulnerabilities in Nuxed, see [SECURITY.md](SECURITY.md).

---

### License

Nuxed is open-sourced software licensed under the MIT-licensed.
