namespace Nuxed\Http\Message\_Private\IO;

use namespace HH\Lib\Experimental\{File, IO};

/**
 * Allows using files as seekable read write handles.
 *
 * @see https://github.com/hhvm/hsl-experimental/pull/88
 */
final class FileWrapper
  implements
    IO\NonDisposableSeekableReadWriteHandle,
    IO\SeekableReadWriteHandle {
  public function __construct(private File\ReadWriteHandle $file) {}

  public async function seekAsync(int $offset): Awaitable<void> {
    return await $this->file->seekAsync($offset);
  }

  public function tell(): int {
    return $this->file->tell();
  }

  public function rawWriteBlocking(string $bytes): int {
    return $this->file->rawWriteBlocking($bytes);
  }

  public async function writeAsync(
    string $bytes,
    ?float $timeout = null,
  ): Awaitable<void> {
    return await $this->file->writeAsync($bytes, $timeout);
  }

  public async function flushAsync(): Awaitable<void> {
    return await $this->file->flushAsync();
  }

  public function rawReadBlocking(?int $bytes = null): string {
    return $this->file->rawReadBlocking($bytes);
  }

  public async function readAsync(
    ?int $bytes = null,
    ?float $timeout = null,
  ): Awaitable<string> {
    return await $this->file->readAsync($bytes, $timeout);
  }

  public async function readLineAsync(
    ?int $bytes = null,
    ?float $timeout = null,
  ): Awaitable<string> {
    return await $this->file->readLineAsync($bytes, $timeout);
  }

  public function isEndOfFile(): bool {
    return $this->file->isEndOfFile();
  }

  public async function closeAsync(): Awaitable<void> {
    if ($this->file is IO\NonDisposableHandle) {
      return await $this->file->closeAsync();
    }
  }
}
