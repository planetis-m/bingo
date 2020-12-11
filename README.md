# bingo — Binary serialization framework for Nim
## About
This package provides the ``binTo``, ``loadBin`` procs which deserialize the specified
type from a ``Stream``. The `storeBin` procs are used to write the binary
representation of a location into a `Stream`. Low level `initFromBin` and `storeBin`
procs can be overloaded, in order to support arbitary container types, i.e.
[marshal_smartptrs.nim](bingo/marshal_smartptrs.nim).

## Usage

```nim
import std/streams, bingo

type
  Foo = ref object
    value: int
    next: Foo

let d = Foo(value: 1, next: Foo(value: 2, next: nil))
let s = newStringStream()
# Make a roundtrip
s.storeBin(d) # writes binary from a location
s.setPosition(0)
let a = s.binTo(Foo) # reads binary and transform to a type
# Alternatively load directly into a location
s.setPosition(0)
var b: Foo
s.loadBin(b)
```

## Features
- Serializing and deserializing directly into `Streams`. For common usage it is done automatically.
  Generally speaking intervation is needed when working with `ptr` types.
- Supports `options`, `sets` and `tables` by default.
- Overloading serialization procs.

## Limitations
- Limited support of object variants. The discriminant field is expected first.
  Also there can be no fields before and after the case section.
- Borrowing proc `initFromBin[T](dst: var T; s: Stream)` for distinct types isn't
  currently working. Blocked by a Nim bug. Use overloads for now. Or you can easily
  override this behaviour by copying these lines in your project:

  ```nim
  from typetraits import distinctBase
  proc storeBin[T: distinct](s: Stream; x: T) = storeToBin(s, x.distinctBase)
  proc initFromBin[T: distinct](dst: var T; s: Stream) = initFromBin(dst.distinctBase, p)
  ```
- Custom pragmas are not supported. Unless `hasCustomPragma` improves, this feature won't be added.
  You can currently substitute skipped fields by creating empty overloads.
