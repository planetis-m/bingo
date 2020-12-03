import macros, streams, options, tables, sets
from typetraits import supportsCopyMem

# serialization
proc storeBin*(s: Stream; x: bool) =
  write(s, x)
proc storeBin*(s: Stream; x: char) =
  write(s, x)
proc storeBin*[T: SomeNumber](s: Stream; x: T) =
  write(s, x)
proc storeBin*[T: enum](s: Stream; x: T) =
  write(s, x)
proc storeBin*[T](s: Stream; x: set[T]) =
  write(s, x)
proc storeBin*(s: Stream; x: string) =
  write(s, int64(x.len))
  writeData(s, cstring(x), x.len)

proc storeBin*[S, T](s: Stream; x: array[S, T]) =
  when not supportsCopyMem(T):
    for elem in x.items:
      storeBin(s, elem)
  else:
    writeData(s, x.unsafeAddr, sizeof(x))

proc storeBin*[T](s: Stream; x: seq[T]) =
  write(s, int64(x.len))
  when not supportsCopyMem(T):
    for elem in x.items:
      storeBin(s, elem)
  else:
    writeData(s, x[0].unsafeAddr, x.len * sizeof(T))

proc storeBin*[T](s: Stream; o: SomeSet[T]) =
  write(s, int64(o.len))
  for elem in o.items:
    storeBin(s, elem)

proc storeBin*[K, V](s: Stream; o: (Table[K, V]|OrderedTable[K, V])) =
  write(s, int64(o.len))
  for k, v in o.pairs:
    storeBin(s, k)
    storeBin(s, v)

proc storeBin*(s: Stream; o: ref object) =
  let isSome = o != nil
  storeBin(s, isSome)
  if isSome:
    storeBin(s, o[])

proc storeBin*[T](s: Stream; o: Option[T]) =
  let isSome = isSome(o)
  storeBin(s, isSome)
  if isSome:
    storeBin(s, get(o))

proc storeBin*[T: object|tuple](s: Stream; o: T) =
  when not supportsCopyMem(T):
    for v in o.fields:
      storeBin(s, v)
  else: write(s, o)

# deserialization
proc initFromBin*(dst: var bool; s: Stream) =
  read(s, dst)
proc initFromBin*(dst: var char; s: Stream) =
  read(s, dst)
proc initFromBin*[T: SomeNumber](dst: var T; s: Stream) =
  read(s, dst)
proc initFromBin*[T: enum](dst: var T; s: Stream) =
  read(s, dst)
proc initFromBin*[T](dst: var set[T]; s: Stream) =
  read(s, dst)

proc initFromBin*(dst: var string; s: Stream) =
  let len = s.readInt64()
  dst.setLen(int(len))
  if readData(s, cstring(dst), int(len)) != len:
    raise newException(IOError, "cannot read from stream")

proc initFromBin*[T](dst: var seq[T]; s: Stream) =
  let len = s.readInt64()
  dst.setLen(len)
  when not supportsCopyMem(T):
    for i in 0 ..< len(dst):
      initFromBin(dst[i], s)
  else:
    let bLen = int(len) * sizeof(T)
    if readData(s, dst[0].addr, bLen) != bLen:
      raise newException(IOError, "cannot read from stream")

proc initFromBin*[S, T](dst: var array[S, T]; s: Stream) =
  when not supportsCopyMem(T):
    for i in low(dst) .. high(dst):
      initFromBin(dst[i], s)
  else:
    if readData(s, dst.addr, sizeof(dst)) != sizeof(dst):
      raise newException(IOError, "cannot read from stream")

proc initFromBin*[T](dst: var SomeSet[T]; s: Stream) =
  let len = s.readInt64()
  for i in 0 ..< len:
    var tmp: T
    initFromBin(tmp, s)
    dst.incl(tmp)

proc initFromBin*[K, V](dst: var (Table[K, V]|OrderedTable[K, V]); s: Stream) =
  let len = s.readInt64()
  for i in 0 ..< len:
    var key: K
    initFromBin(key, s)
    initFromBin(mgetOrPut(dst, key, default(V)), s)

proc initFromBin*[T](dst: var ref T; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    new(dst)
    initFromBin(dst[], s)
  else:
    dst = nil

proc initFromBin*[T](dst: var Option[T]; s: Stream) =
  let isSome = readBool(s)
  if isSome:
    var tmp: T
    initFromBin(tmp, s)
    dst = some(tmp)
  else: none[T]()

proc initFromBin*[T: tuple](dst: var T; s: Stream) =
  when not supportsCopyMem(T):
    for v in dst.fields:
      initFromBin(v, s)
  else: read(s, dst)

template getFieldValue(stream, tmpSym, fieldSym) =
  initFromBin(tmpSym.fieldSym, stream)

template getKindValue(stream, tmpSym, kindSym, kindType) =
  var kindTmp: kindType
  initFromBin(kindTmp, stream)
  tmpSym = (typeof tmpSym)(kindSym: kindTmp)

proc foldObjectBody(typeNode, tmpSym, stream: NimNode): NimNode =
  case typeNode.kind
  of nnkEmpty:
    result = newNimNode(nnkNone)
  of nnkRecList:
    result = newStmtList()
    for it in typeNode:
      let x = foldObjectBody(it, tmpSym, stream)
      if x.kind != nnkNone: result.add x
  of nnkIdentDefs:
    expectLen(typeNode, 3)
    let fieldSym = typeNode[0]
    result = getAst(getFieldValue(stream, tmpSym, fieldSym))
  of nnkRecCase:
    let kindSym = typeNode[0][0]
    let kindType = typeNode[0][1]
    result = getAst(getKindValue(stream, tmpSym, kindSym, kindType))
    let inner = nnkCaseStmt.newTree(nnkDotExpr.newTree(tmpSym, kindSym))
    for i in 1..<typeNode.len:
      let x = foldObjectBody(typeNode[i], tmpSym, stream)
      if x.kind != nnkNone: inner.add x
    result.add inner
  of nnkOfBranch, nnkElse:
    result = copyNimNode(typeNode)
    for i in 0..typeNode.len-2:
      result.add copyNimTree(typeNode[i])
    let inner = newNimNode(nnkStmtListExpr)
    let x = foldObjectBody(typeNode[^1], tmpSym, stream)
    if x.kind != nnkNone: inner.add x
    result.add inner
  of nnkObjectTy:
    expectKind(typeNode[0], nnkEmpty)
    expectKind(typeNode[1], {nnkEmpty, nnkOfInherit})
    result = newNimNode(nnkNone)
    if typeNode[1].kind == nnkOfInherit:
      let base = typeNode[1][0]
      var impl = getTypeImpl(base)
      while impl.kind in {nnkRefTy, nnkPtrTy}:
        impl = getTypeImpl(impl[0])
      result = foldObjectBody(impl, tmpSym, stream)
    let body = typeNode[2]
    let x = foldObjectBody(body, tmpSym, stream)
    if result.kind != nnkNone:
      if x.kind != nnkNone:
        for i in 0..<result.len: x.add(result[i])
        result = x
    else: result = x
  else:
    error("unhandled kind: " & $typeNode.kind, typeNode)

macro assignObjectImpl(dst: typed; s: Stream): untyped =
  let typeSym = getTypeInst(dst)
  result = newStmtList()
  let x = foldObjectBody(typeSym.getTypeImpl, dst, s)
  if x.kind != nnkNone: result.add x

proc initFromBin*[T: object](dst: var T; s: Stream) =
  when not supportsCopyMem(T):
    assignObjectImpl(dst, s)
  else: read(s, dst)

proc binTo*[T](s: Stream, t: typedesc[T]): T =
  ## Unmarshals the specified Stream into the type specified.
  ##
  ## Known limitations:
  ##
  ##   * Sets in object variants are not supported.
  ##   * Not nil annotations are not supported.
  ##
  initFromBin(result, s)

proc loadBin*[T](s: Stream, dst: var T) =
  ## Unmarshals the specified Stream into the location specified.
  initFromBin(dst, s)
