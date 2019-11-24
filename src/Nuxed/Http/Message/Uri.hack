namespace Nuxed\Http\Message;

use namespace HH\Lib\{C, Regex, Str};
use namespace Nuxed\Contract\Http\Message;

/**
 * Value object representing a URI.
 *
 * This class is meant to represent URIs according to RFC 3986 and to
 * provide methods for most common operations.
 *
 * Instances of this class are considered immutable; all methods that
 * might change state are implemented such that they retain the internal
 * state of the current instance and return an instance that contains the
 * changed state.
 *
 * Typically the Host header will be also be present in the request message.
 * For server-side requests, the scheme will typically be discoverable in the
 * server parameters.
 *
 * @link http://tools.ietf.org/html/rfc3986 (the URI specification)
 */
final class Uri implements Message\IUri {
  private static dict<string, int> $schemes = dict[
    'http' => 80,
    'https' => 443,
  ];

  private string $scheme = '';

  private (string, ?string) $userInfo = tuple('', null);

  private string $host = '';

  private ?int $port;

  private string $path = '';

  private string $query = '';

  private string $fragment = '';

  public function __construct(string $uri = '') {
    if ('' !== $uri) {
      $parts = \parse_url($uri);

      if (false === $parts) {
        throw new Exception\InvalidArgumentException(
          "Unable to parse URI: ".$uri,
        );
      }

      $this->applyParts(dict($parts));
    }
  }

  public function toString(): string {
    return self::createUriString(
      $this->scheme,
      $this->getAuthority(),
      $this->path,
      $this->query,
      $this->fragment,
    );
  }

  /**
   * Retrieve the scheme component of the URI.
   *
   * If no scheme is present, this method will return an empty string.
   *
   * The value returned will be normalized to lowercase, per RFC 3986
   * Section 3.1.
   *
   * @see https://tools.ietf.org/html/rfc3986#section-3.1
   */
  public function getScheme(): string {
    return $this->scheme;
  }

  /**
   * Retrieve the authority component of the URI.
   *
   * If no authority information is present, this method will return an empty
   * string.
   *
   * The authority syntax of the URI is:
   *
   * <pre>
   *  [user-info@]host[:port]
   * </pre>
   *
   * If the port component is not set or is the standard port for the current
   * scheme, it will not be included.
   *
   * @see https://tools.ietf.org/html/rfc3986#section-3.2
   */
  public function getAuthority(): string {
    if ('' === $this->host) {
      return '';
    }

    $authority = $this->host;

    list($user, $password) = $this->userInfo;

    if ('' !== $user) {
      if ($password is nonnull) {
        $authority = Str\format('%s:%s@%s', $user, $password, $authority);
      } else {
        $authority = Str\format('%s@%s', $user, $authority);
      }
    }

    if ($this->port is nonnull) {
      $authority .= ':'.((string)$this->port);
    }

    return $authority;
  }

  /**
   * Retrieve the user information component of the URI.
   *
   * If no user information is present, this method will return an empty
   * string for the user, and null for the password.
   */
  public function getUserInfo(): (string, ?string) {
    return $this->userInfo;
  }

  /**
   * Retrieve the host component of the URI.
   *
   * If no host is present, this method will return an empty string.
   *
   * The value returned will be normalized to lowercase, per RFC 3986
   * Section 3.2.2.
   *
   * @see http://tools.ietf.org/html/rfc3986#section-3.2.2
   */
  public function getHost(): string {
    return $this->host;
  }

  /**
   * Retrieve the port component of the URI.
   *
   * If a port is present, and it is non-standard for the current scheme,
   * this method will return it as an integer. If the port is the standard port
   * used with the current scheme, this method will return null.
   *
   * If no port is present, and no scheme is present, this method will return
   * a null value.
   */
  public function getPort(): ?int {
    return $this->port;
  }

  /**
   * Retrieve the path component of the URI.
   *
   * The path can either be empty or absolute (starting with a slash) or
   * rootless (not starting with a slash).
   *
   * Normally, the empty path "" and absolute path "/" are considered equal as
   * defined in RFC 7230 Section 2.7.3. But this method will not automatically
   * do this normalization because in contexts with a trimmed base path, e.g.
   * the front controller, this difference becomes significant. It's the task
   * of the user to handle both "" and "/".
   *
   * The value returned will be percent-encoded, but without double-encoding
   * any characters. To determine what characters to encode, please refer to
   * RFC 3986, Sections 2 and 3.3.
   *
   * As an example, if the value should include a slash ("/") not intended as
   * delimiter between path segments, that value MUST be passed in encoded
   * form (e.g., "%2F") to the instance.
   *
   * @see https://tools.ietf.org/html/rfc3986#section-2
   * @see https://tools.ietf.org/html/rfc3986#section-3.3
   */
  public function getPath(): string {
    return $this->path;
  }

  /**
   * Retrieve the query string of the URI.
   *
   * If no query string is present, this method will return an empty string.
   *
   * The leading "?" character is not part of the query and will not be
   * added.
   *
   * The value returned will be percent-encoded, but without double-encoding
   * any characters. To determine what characters to encode, please refer to
   * RFC 3986, Sections 2 and 3.4.
   *
   * As an example, if a value in a key/value pair of the query string should
   * include an ampersand ("&") not intended as a delimiter between values,
   * that value MUST be passed in encoded form (e.g., "%26") to the instance.
   *
   * @see https://tools.ietf.org/html/rfc3986#section-2
   * @see https://tools.ietf.org/html/rfc3986#section-3.4
   */
  public function getQuery(): string {
    return $this->query;
  }

  /**
   * Retrieve the fragment component of the URI.
   *
   * If no fragment is present, this method will return an empty string.
   *
   * The leading "#" character is not part of the fragment and will not be
   * added.
   *
   * The value returned will be percent-encoded, but without double-encoding
   * any characters. To determine what characters to encode, please refer to
   * RFC 3986, Sections 2 and 3.5.
   *
   * @see https://tools.ietf.org/html/rfc3986#section-2
   * @see https://tools.ietf.org/html/rfc3986#section-3.5
   */
  public function getFragment(): string {
    return $this->fragment;
  }


  /**
   * Return an instance with the specified scheme.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified scheme.
   *
   * An empty scheme is equivalent to removing the scheme.
   */
  public function withScheme(string $scheme): this {
    $scheme = Str\lowercase($scheme);

    if ($this->scheme === $scheme) {
      return $this;
    }

    $new = clone $this;
    $new->scheme = $scheme;
    $new->port = $new->filterPort($new->port);

    return $new;
  }

  /**
   * Return an instance with the specified user information.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified user information.
   *
   * Password is optional, but the user information must include the
   * user; an empty string for the user is equivalent to removing user
   * information.
   */
  public function withUserInfo(string $user, ?string $password = null): this {
    if ('' === $password) {
      $password = null;
    }
    $info = tuple($user, $password);

    if ($this->userInfo === $info) {
      return $this;
    }

    $new = clone $this;
    $new->userInfo = $info;

    return $new;
  }

  /**
   * Return an instance with the specified host.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified host.
   *
   * An empty host value is equivalent to removing the host.
   */
  public function withHost(string $host): this {
    $host = Str\lowercase($host);

    if ($this->host === $host) {
      return $this;
    }

    $new = clone $this;
    $new->host = $host;

    return $new;
  }

  /**
   * Return an instance with the specified port.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified port.
   *
   * A null value provided for the port is equivalent to removing the port
   * information.
   *
   * @throws Exception\InvalidArgumentException for ports outside the
   *  established TCP and UDP port ranges.
   */
  public function withPort(?int $port): this {
    $port = $this->filterPort($port);

    if ($this->port === $port) {
      return $this;
    }

    $new = clone $this;
    $new->port = $port;

    return $new;
  }

  /**
   * Return an instance with the specified path.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified path.
   *
   * The path can either be empty or absolute (starting with a slash) or
   * rootless (not starting with a slash).
   *
   * If the path is intended to be domain-relative rather than path relative then
   * it must begin with a slash ("/"). Paths not starting with a slash ("/")
   * are assumed to be relative to some base path known to the application or
   * consumer.
   */
  public function withPath(string $path): this {
    $path = $this->filterPath($path);

    if ($this->path === $path) {
      return $this;
    }

    $new = clone $this;
    $new->path = $path;

    return $new;
  }

  /**
   * Return an instance with the specified query string.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified query string.
   *
   * An empty query string value is equivalent to removing the query string.
   */
  public function withQuery(string $query): this {
    $query = $this->filterQueryAndFragment($query);
    if ($this->query === $query) {
      return $this;
    }

    $new = clone $this;
    $new->query = $query;

    return $new;
  }

  /**
   * Return an instance with the specified URI fragment.
   *
   * This method will retain the state of the current instance, and return
   * an instance that contains the specified URI fragment.
   *
   * An empty fragment value is equivalent to removing the fragment.
   */
  public function withFragment(string $fragment): this {
    $fragment = $this->filterQueryAndFragment($fragment);

    if ($this->fragment === $fragment) {
      return $this;
    }

    $new = clone $this;
    $new->fragment = $fragment;

    return $new;
  }

  /**
   * Apply parse_url parts to a URI.
   */
  private function applyParts(KeyedContainer<string, arraykey> $parts): void {
    $this->scheme = C\contains_key($parts, 'scheme')
      ? Str\lowercase((string)$parts['scheme'])
      : '';

    $this->host = C\contains_key($parts, 'host')
      ? Str\lowercase((string)$parts['host'])
      : '';

    $this->port = C\contains_key($parts, 'port')
      ? $this->filterPort((int)$parts['port'])
      : null;

    $this->path = C\contains_key($parts, 'path')
      ? $this->filterPath((string)$parts['path'])
      : '';

    $this->query = C\contains_key($parts, 'query')
      ? $this->filterQueryAndFragment((string)$parts['query'])
      : '';

    $this->fragment = C\contains_key($parts, 'fragment')
      ? $this->filterQueryAndFragment((string)$parts['fragment'])
      : '';

    if (C\contains_key($parts, 'user')) {

      $this->userInfo = tuple((string)$parts['user'], null);

      if (C\contains_key($parts, 'pass')) {
        $this->userInfo = tuple((string)$parts['user'], (string)$parts['pass']);
      }

    } else {
      $this->userInfo = tuple('', null);
    }
  }

  /**
   * Create a URI string from its various parts.
   */
  private static function createUriString(
    string $scheme,
    string $authority,
    string $path,
    string $query,
    string $fragment,
  ): string {
    $uri = '';

    if ('' !== $scheme) {
      $uri .= $scheme.':';
    }

    if ('' !== $authority) {
      $uri .= '//'.$authority;
    }

    if (Str\length($path) > 0) {
      if ('/' !== $path[0]) {
        if ('' !== $authority) {
          // If the path is rootless and an authority is present, the path will be prefixed by "/"
          $path = '/'.$path;
        }
      } else if (Str\length($path) > 1 && '/' === $path[1]) {
        if ('' === $authority) {
          // If the path is starting with more than one "/" and no authority is present, the
          // starting slashes will be reduced to one.
          $path = '/'.Str\trim_left($path, '/');
        }
      }

      $uri .= $path;
    }

    if ('' !== $query) {
      $uri .= '?'.$query;
    }

    if ('' !== $fragment) {
      $uri .= '#'.$fragment;
    }

    return $uri;
  }

  /**
   * Is a given port standard for the current scheme?
   */
  public static function isStandardPort(string $scheme, int $port): bool {
    return $port === (self::$schemes[$scheme] ?? null);
  }

  private function filterPort(?int $port): ?int {
    if ($port is null) {
      return null;
    }

    if (static::isStandardPort($this->scheme, $port)) {
      return null;
    }

    if (1 > $port || 0xffff < $port) {
      throw new Exception\InvalidArgumentException(
        Str\format('Invalid port: %d. Must be between 1 and 65535', $port),
      );
    }

    return $port;
  }

  private function filterPath(string $path): string {
    return Regex\replace_with(
      $path,
      re"/(?:[^a-zA-Z0-9_\-\.~!\$&\'\(\)\*\+,;=%:@\/]++|%(?![A-Fa-f0-9]{2}))/",
      ($match) ==> \rawurlencode($match[0]),
    );
  }

  private function filterQueryAndFragment(string $str): string {
    return Regex\replace_with(
      $str,
      re"/(?:[^a-zA-Z0-9_\-\.~!\$&\'\(\)\*\+,;=%:@\/\?]++|%(?![A-Fa-f0-9]{2}))/",
      ($match) ==> \rawurlencode($match[0]),
    );
  }
}
