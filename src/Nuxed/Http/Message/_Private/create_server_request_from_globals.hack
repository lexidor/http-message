namespace Nuxed\Http\Message\_Private;

use namespace HH;
use namespace HH\Lib\{C, Dict, Str};
use namespace Nuxed\Contract\Http;
use namespace Nuxed\Http\Message;
use namespace AzJezz\HttpNormalizer;

function create_server_request_from_globals(): Message\ServerRequest {
  $server = HH\global_get('_SERVER') as KeyedContainer<_, _>;
  $uploads = HttpNormalizer\normalize_files(
    HH\global_get('_FILES') as KeyedContainer<_, _>,
  );
  $cookies = HttpNormalizer\normalize(
    HH\global_get('_COOKIE') as KeyedContainer<_, _>,
  );
  $protocol = (new ProtocolVersionMarshaler())->marshal($server);
  $headers = (new HeadersMarshaler())->marshal($server);
  $uri = (new UriMarshaler())->marshal($server, $headers);
  $query = HttpNormalizer\parse($uri->getQuery() ?? '');
  $server = HttpNormalizer\normalize($server);
  $method = Str\uppercase(($server['REQUEST_METHOD'] ?? 'GET') as string);
  $ct = (string $value): bool ==>
    C\contains<string, string>($headers['content-type'] ?? vec[], $value);

  if (
    'POST' === $method &&
    ($ct('application/x-www-form-urlencoded') || $ct('multipart/form-data'))
  ) {
    $post = HH\global_get('_POST') as KeyedContainer<_, _>;
    $body = HttpNormalizer\normalize($post);
  } else {
    $body = null;
  }

  $uploads = Dict\map(
    $uploads,
    ($value) ==> {
      $errno = $value['error'];
      if ($errno > 5) {
        $errno--;
      }

      $error = Http\Message\UploadedFileError::assert($errno);
      return new Message\UploadedFile(
        $value['tmp_name'],
        $value['size'],
        $error,
        $value['name'] ?? null,
        $value['type'] ?? null,
      );
    },
  );

  return new Message\ServerRequest(
    $method,
    $uri,
    $headers,
    IO\ResourceHandle::input(),
    $protocol,
    $server,
  )
    |> $$->withCookieParams($cookies)
    |> $$->withQueryParams($query)
    |> $body is nonnull ? $$->withParsedBody($body) : $$
    |> $$->withUploadedFiles($uploads);
}
