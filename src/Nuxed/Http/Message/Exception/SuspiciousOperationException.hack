namespace Nuxed\Http\Message\Exception;

use namespace Nuxed\Contract\Http\Message\Exception;

/**
 * Raised when a user has performed an operation that should be considered
 * suspicious from a security perspective.
 */
final class SuspiciousOperationException
  extends Exception\SuspiciousOperationException
  implements IException {
}
