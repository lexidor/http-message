namespace Nuxed\Http\Message\_Private\IO;

use namespace HH\Lib\{Math, Str};
use namespace HH\Lib\Experimental\IO;

final class MemoryHandle
  implements IO\CloseableSeekableReadWriteHandle, IO\SeekableReadWriteHandle {

  private int $position = 0;
  private ?Awaitable<mixed> $lastOperation;

  public function __construct(private string $data = '') {
  }

  protected function queuedAsync<T>(
    (function(): Awaitable<T>) $next,
  ): Awaitable<T> {
    $last = $this->lastOperation;
    $queue = async {
      await $last;
      return await $next();
    };
    $this->lastOperation = $queue;
    return $queue;
  }

  public async function seekAsync(int $offset): Awaitable<void> {
    await $this->queuedAsync(async () ==> {
      $this->position = $offset;
    });
  }

  public function tell(): int {
    return $this->position;
  }

  public function rawWriteBlocking(string $bytes): int {
    $length = Str\length($bytes);
    $this->data = Str\splice($this->data, $bytes, $this->position);
    $this->position += $length;

    return $length;
  }

  public async function writeAsync(
    string $bytes,
    ?float $_timeout = null,
  ): Awaitable<void> {
    await $this->queuedAsync(async (): Awaitable<void> ==> {
      $this->rawWriteBlocking($bytes);
    });
  }

  public function rawReadBlocking(?int $max_bytes = null): string {
    if ($this->isEndOfFile()) {
      return '';
    }

    $length = Str\length($this->data);
    $bytes = Str\slice($this->data, $this->position, $max_bytes);
    $postion = $this->position + Str\length($bytes);
    $this->position = $postion > $length ? $length : $postion;

    return $bytes;
  }

  public async function readAsync(
    ?int $max_bytes = null,
    ?float $_timeout = null,
  ): Awaitable<string> {
    return await $this->queuedAsync(async (): Awaitable<string> ==> {
      return $this->rawReadBlocking($max_bytes);
    });
  }

  public async function readLineAsync(
    ?int $max_bytes = null,
    ?float $_timeout = null,
  ): Awaitable<string> {
    $eol = Str\search($this->data, "\n", $this->position);
    if ($max_bytes is null) {
      $read = $eol is null
        ? $this->readAsync()
        : $this->readAsync($this->position - $eol);
      return await $read;
    }

    if ($eol is null) {
      return await $this->readAsync($max_bytes);
    }

    $length = Str\length($this->data);
    $mb = $this->position + $max_bytes;
    if ($mb > $length) {
      $mb = $length;
    }

    $max_bytes = Math\minva($eol + 1, $mb);
    return await $this->readAsync($max_bytes);
  }

  public function isEndOfFile(): bool {
    $length = Str\length($this->data);
    return $this->position >= $length;
  }

  public async function closeAsync(): Awaitable<void> {
    // do nothing.
  }

  public async function flushAsync(): Awaitable<void> {
    // do nothing.
  }
}
