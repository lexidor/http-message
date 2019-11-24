namespace Nuxed\Http\Message\_Private\IO;

use namespace HH\Lib\Experimental\{File, IO};

final class ResourceHandle
  extends File\_Private\NonDisposableFileHandle
  implements
    IO\SeekableReadWriteHandle,
    IO\NonDisposableSeekableReadWriteHandle,
    IO\NonDisposableReadWriteHandle {
  use IO\_Private\LegacyPHPResourceReadHandleTrait;
  use IO\_Private\LegacyPHPResourceWriteHandleTrait;
  use IO\_Private\LegacyPHPResourceSeekableHandleTrait;

  public static function input(): IO\SeekableReadWriteHandle {
    return new LazyHandle(
      (): ResourceHandle ==> new ResourceHandle('php://input', 'r+'),
    );
  }

  public static function output(): IO\SeekableReadWriteHandle {
    return new LazyHandle(
      (): ResourceHandle ==> new ResourceHandle('php://output', 'rw+'),
    );
  }
}
