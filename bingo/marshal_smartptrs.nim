import ../bingo, fusion/smartptrs, std/streams

proc hasCustomSerializer*[T](t: typedesc[(UniquePtr[T]|SharedPtr[T]|ConstPtr[T])]): bool = true

proc byteSize*[T](o: (UniquePtr[T]|SharedPtr[T]|ConstPtr[T])): int =
  result = sizeof(bool)
  if not o.isNil:
    result.inc byteSize(o[])

proc storeBin*[T](s: Stream; o: UniquePtr[T]) =
  let isSome = not o.isNil
  storeBin(s, isSome)
  if isSome:
    storeBin(s, o[])

proc initFromBin*[T](dst: var UniquePtr[T]; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    var tmp: T
    initFromBin(tmp, s)
    dst = newUniquePtr(tmp)
  else:
    reset(dst)

proc storeBin*[T](s: Stream; o: SharedPtr[T]) =
  let isSome = not o.isNil
  storeBin(s, isSome)
  if isSome:
    storeBin(s, o[])

proc initFromBin*[T](dst: var SharedPtr[T]; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    var tmp: T
    initFromBin(tmp, s)
    dst = newSharedPtr(tmp)
  else:
    reset(dst)

proc storeBin*[T](s: Stream; o: ConstPtr[T]) {.inline.} = storeBin(s, SharedPtr[T](o))
proc initFromBin*[T](dst: var ConstPtr[T]; s: Stream) {.inline.} = initFromBin(SharedPtr[T](dst), s)
