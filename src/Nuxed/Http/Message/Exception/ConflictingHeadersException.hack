namespace Nuxed\Http\Message\Exception;

use namespace Nuxed\Contract\Http\Message\Exception;

/**
 * The HTTP request contains headers with conflicting information.
 */
final class ConflictingHeadersException
  extends Exception\ConflictingHeadersException
  implements IException {
}
