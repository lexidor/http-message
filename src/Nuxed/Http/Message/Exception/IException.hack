namespace Nuxed\Http\Message\Exception;

use namespace Nuxed\Contract\Http\Message\Exception;

/**
 * Marker interface for component-specific exceptions.
 */
<<__Sealed(
  RuntimeException::class,
  InvalidArgumentException::class,
  UnrecognizedProtocolVersionException::class,
  ConflictingHeadersException::class,
  SuspiciousOperationException::class,
)>>
interface IException extends Exception\IException {
}
