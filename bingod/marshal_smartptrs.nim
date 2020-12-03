import ../bingod, fusion/smartptrs, std/streams

proc storeBin*[T](s: Stream; o: UniquePtr[T]) =
  if o.isNil:
    storeNil(s)
  else:
    storeBin(s, o[])

proc initFromBin*[T](dst: var UniquePtr[T]; s: Stream) =
  let isNil = readBool(s)
  if isNil:
    reset(dst)
  else:
    var tmp: T
    initFromBin(tmp, s)
    dst = newUniquePtr(tmp)

proc storeBin*[T](s: Stream; o: SharedPtr[T]) =
  if o.isNil:
    storeNil(s)
  else:
    storeBin(s, o[])

proc initFromBin*[T](dst: var SharedPtr[T]; s: Stream) =
  let isNil = readBool(s)
  if isNil:
    reset(dst)
  else:
    var tmp: T
    initFromBin(tmp, s)
    dst = newSharedPtr(tmp)

proc storeBin*[T](s: Stream; o: ConstPtr[T]) = storeBin(s, SharedPtr[T](o))
proc initFromBin*[T](dst: var ConstPtr[T]; s: Stream) = initFromBin(SharedPtr[T](dst), s)
