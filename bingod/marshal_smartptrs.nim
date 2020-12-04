import ../bingod, fusion/smartptrs, std/streams

proc storeToBin*[T](s: Stream; o: UniquePtr[T]) =
  let isSome = not o.isNil
  storeToBin(s, isSome)
  if isSome:
    storeToBin(s, o[])

proc initFromBin*[T](dst: var UniquePtr[T]; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    var tmp: T
    initFromBin(tmp, s)
    dst = newUniquePtr(tmp)
  else:
    reset(dst)

proc storeToBin*[T](s: Stream; o: SharedPtr[T]) =
  let isSome = not o.isNil
  storeToBin(s, isSome)
  if isSome:
    storeToBin(s, o[])

proc initFromBin*[T](dst: var SharedPtr[T]; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    var tmp: T
    initFromBin(tmp, s)
    dst = newSharedPtr(tmp)
  else:
    reset(dst)

proc storeToBin*[T](s: Stream; o: ConstPtr[T]) = storeToBin(s, SharedPtr[T](o))
proc initFromBin*[T](dst: var ConstPtr[T]; s: Stream) = initFromBin(SharedPtr[T](dst), s)
