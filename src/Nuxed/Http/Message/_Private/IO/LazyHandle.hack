namespace Nuxed\Http\Message\_Private\IO;

use namespace HH\Lib\Experimental\IO;

/**
 * Makes a seekable read write handle lazy-loaded.
 */
final class LazyHandle
  implements
    IO\SeekableReadWriteHandle,
    IO\CloseableSeekableReadWriteHandle,
    IO\CloseableReadWriteHandle {

  private ?IO\SeekableReadWriteHandle $handle = null;
  private (function(): IO\SeekableReadWriteHandle) $factory;

  public function __construct(
    (function(): IO\SeekableReadWriteHandle) $factory,
  ) {
    $this->factory = $factory;
  }

  protected function getHandle(): IO\SeekableReadWriteHandle {
    if ($this->handle is nonnull) {
      return $this->handle;
    }

    $this->handle = ($this->factory)();
    return $this->handle;
  }

  public async function seekAsync(int $offset): Awaitable<void> {
    await $this->getHandle()->seekAsync($offset);
  }

  public function tell(): int {
    return $this->getHandle()->tell();
  }

  public function rawWriteBlocking(string $bytes): int {
    return $this->getHandle()->rawWriteBlocking($bytes);
  }

  public async function writeAsync(
    string $bytes,
    ?float $timeout = null,
  ): Awaitable<void> {
    await $this->getHandle()->writeAsync($bytes, $timeout);
  }

  public function rawReadBlocking(?int $max_bytes = null): string {
    return $this->getHandle()->rawReadBlocking($max_bytes);
  }

  public async function readAsync(
    ?int $max_bytes = null,
    ?float $timeout = null,
  ): Awaitable<string> {
    return await $this->getHandle()->readAsync($max_bytes, $timeout);
  }

  public async function readLineAsync(
    ?int $max_bytes = null,
    ?float $timeout = null,
  ): Awaitable<string> {
    return await $this->getHandle()->readLineAsync($max_bytes, $timeout);
  }

  public function isEndOfFile(): bool {
    return $this->getHandle()->isEndOfFile();
  }

  public async function closeAsync(): Awaitable<void> {
    if ($this->handle is nonnull && $this->handle is IO\CloseableHandle) {
      await $this->handle->closeAsync();
    }
  }

  public async function flushAsync(): Awaitable<void> {
    await $this->getHandle()->flushAsync();
  }
}
