import bingo, std/[streams, math, options, sets, tables]

type
  Foo = ref object
    value: int
    next: Foo
  Fruit = enum
    Apple, Banana, Orange
  Stuff = enum
    NotApple = 1, NotBanana, NotOrange
  BarBaz = array[2..8, int]
  Bar = ref object
    case kind: Fruit
    of Banana:
      bad: float
      banana: int
    of Apple: apple: string
    else: discard
  ContentNodeKind = enum
    P, Br, Text
  ContentNode = object
    case kind: ContentNodeKind
    of P: pChildren: seq[ContentNode]
    of Br: discard
    of Text: textStr: string
  BazBat = ref object of RootObj
  BarFoo = ref object of BazBat
    three: float32
    four: string
  BazFoo = ref object of BarFoo
    two: char
  FooBar = ref object of BazFoo
    one: int
  FooBaz = object
    t: float
    x: (int32,)
    v: string
  Empty = object
  IrisPlant = object
    sepalLength: float32
    sepalWidth: float32
    petalLength: float32
    petalWidth: float32
    species: string
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

block:
  let data = [0, 1, 2, 3, 4, 5, 6]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = NotApple
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data: array[Fruit, int] = [0, 1, 2]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = Empty()
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = (x: 42)
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = {Apple, Orange}
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = "hello world"
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = @[1, 2, 3, 4, 5, 6]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = @["αβγ", "δεζη", "θικλμ"]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  assert data[0].len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = @[("3",), ("4",), ("5",)]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = FooBaz(v: "hello", t: 5.0, x: (3'i32,))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = Foo(value: 1, next: Foo(value: 2, next: nil))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a.value == 1
  let b = a.next
  assert b.value == 2
  assert s.getPosition == s.data.len
block:
  let data = FooBar(four: "hello", three: 1'f32)
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  doAssert a.four == "hello"
  assert a.three == 1'f32
  assert a.one == 0
  assert s.getPosition == s.data.len
block:
  let data = some(Foo(value: 5, next: nil))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a.get.value == 5
  assert s.getPosition == s.data.len
block:
  let data = some(Empty())
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert s.getPosition == s.data.len
block:
  let data = toHashSet([5'f32, 3, 2])
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = {'a': 5'i32, 'b': 9'i32}.toTable
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = Bar(kind: Apple, apple: "world")
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == byteSize(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a.kind == Apple
  assert a.apple == "world"
  assert s.getPosition == s.data.len
block:
  let data = ContentNode(kind: P, pChildren: @[
    ContentNode(kind: Text, textStr: "mychild"),
    ContentNode(kind: Br)
  ])
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert $a == $data
  assert s.getPosition == s.data.len
block:
  let data = @[
    IrisPlant(sepalLength: 5.1, sepalWidth: 3.5, petalLength: 1.4,
              petalWidth: 0.2, species: "setosa"),
    IrisPlant(sepalLength: 4.9, sepalWidth: 3.0, petalLength: 1.4,
              petalWidth: 0.2, species: "setosa")]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(typeof data)
  assert a[0].species == "setosa"
  assert almostEqual(a[0].sepalWidth, 3.5'f32)
  assert almostEqual(a[1].sepalWidth, 3'f32)
  assert s.getPosition == s.data.len
block:
  let data = [
    Responder(name: "John Smith", gender: male, occupation: "student", age: 18,
      siblings: @[Sibling(sex: female, birthYear: 1991, relation: biological, alive: true),
                  Sibling(sex: male, birthYear: 1989, relation: step, alive: true)])]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  var a: array[1, Responder] = data
  a[0].name = "Janne Smith"
  a[0].gender = female
  a[0].siblings[0].birthYear = 1997
  a[0].siblings.add Sibling()
  s.loadBin(a)
  assert a[0].name == "John Smith"
  assert a[0].gender == male
  assert a[0].siblings.len == 2
  assert a[0].siblings[0].birthYear == 1991
  assert s.getPosition == s.data.len
