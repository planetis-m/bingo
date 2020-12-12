import bingo, std/[sha1, streams]

const
  savefile = "save1.bin"

type
  Gender = enum
    male, female
  Relation = enum
    biological, step
  Responder = object
    name: string
    gender: Gender
    occupation: string
    age: int
    siblings: seq[Sibling]
  Sibling = object
    sex: Gender
    birthYear: int
    relation: Relation
    alive: bool

proc sha1Bin(s: Stream): Sha1Digest =
  const BufferLength = 8192
  var state = newSha1State()
  var buffer = newString(BufferLength)
  while true:
    let len = readData(s, cstring(buffer), BufferLength)
    if len == 0:
      break
    state.update(buffer)
    if len != BufferLength:
      break
  result = state.finalize()

proc save(x: Responder) =
  let fs = newFileStream(savefile, fmReadWrite)
  if fs != nil:
    try:
      # Write a placeholder value
      var hash: Sha1Digest
      write(fs, hash)
      # Serialize
      storeBin(fs, x)
      # Compute hash
      fs.setPosition(sizeof(Sha1Digest))
      hash = sha1Bin(fs)
      # Overwrite placeholder
      fs.setPosition(0)
      write(fs, hash)
    finally: fs.close()

proc load(x: var Responder) =
  let fs = newFileStream(savefile)
  if fs != nil:
    try:
      # Read expected hash
      var expected: Sha1Digest
      read(fs, expected)
      # Check with computed hash
      let hash = sha1Bin(fs)
      doAssert expected == hash
      # Deserialize
      fs.setPosition(sizeof(Sha1Digest))
      loadBin(fs, x)
    finally: fs.close()

proc main =
  let data =
    Responder(name: "John Smith", gender: male, occupation: "student", age: 18,
      siblings: @[Sibling(sex: female, birthYear: 1991, relation: biological, alive: true),
      Sibling(sex: male, birthYear: 1989, relation: step, alive: true)])
  save(data)
  var a: Responder
  load(a)
  assert a == data

main()
