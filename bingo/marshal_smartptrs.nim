import ../bingo, fusion/smartptrs, std/streams

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

proc storeBin*[T](s: Stream; o: ConstPtr[T]) = storeBin(s, SharedPtr[T](o))
proc initFromBin*[T](dst: var ConstPtr[T]; s: Stream) = initFromBin(SharedPtr[T](dst), s)
