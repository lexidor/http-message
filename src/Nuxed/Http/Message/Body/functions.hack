namespace Nuxed\Http\Message\Body;

use namespace Nuxed\Http\Message\_Private;
use namespace HH\Lib\Experimental\{File, IO};

function temporary(): IO\SeekableReadWriteHandle {
  return lazy((): IO\SeekableReadWriteHandle ==> {
    $path = \sys_get_temp_dir().'/'.\bin2hex(\random_bytes(8));
    $file = File\open_read_write_nd($path, File\WriteMode::MUST_CREATE);
    if ($file is IO\SeekableReadWriteHandle) {
      return $file;
    }

    return new _Private\IO\FileWrapper($file);
  });
}

function memory(string $data = ''): IO\SeekableReadWriteHandle {
  return new _Private\IO\MemoryHandle($data);
}

function file(
  string $path,
  File\WriteMode $mode = File\WriteMode::OPEN_OR_CREATE,
): IO\SeekableReadWriteHandle {
  return lazy((): IO\SeekableReadWriteHandle ==> {
    $file = File\open_read_write_nd($path, $mode);
    if ($file is IO\SeekableReadWriteHandle) {
      return $file;
    }

    return new _Private\IO\FileWrapper($file);
  });
}

function lazy(
  (function(): IO\SeekableReadWriteHandle) $factory,
): IO\SeekableReadWriteHandle {
  return new _Private\IO\LazyHandle($factory);
}
