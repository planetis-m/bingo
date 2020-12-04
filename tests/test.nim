import bingod, std/[streams, math, options, sets, tables]

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
    birth_year: int
    relation: Relation
    alive: bool

block:
  let data = [0, 1, 2, 3, 4, 5, 6]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(BarBaz)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = NotApple
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(Stuff)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data: array[Fruit, int] = [0, 1, 2]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(array[Fruit, int])
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = Empty()
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(Empty)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = (x: 42)
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(tuple[x:int])
  assert(a[0] == 42)
  assert s.getPosition == s.data.len
block:
  var data: set[Fruit]
  data.incl Apple
  data.incl Orange
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(data)
  s.setPosition(0)
  let a = s.binTo(set[Fruit])
  assert(a == data)
  assert s.getPosition == s.data.len
block:
  let data = "hello world"
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(int)+len(data)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(string)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = @[1, 2, 3, 4, 5, 6]
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(int)+data.len*sizeof(int)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(seq[int])
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
  let a = s.binTo(seq[string])
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = @[("3",), ("4",), ("5",)]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(seq[(string,)])
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = FooBaz(v: "hello", t: 5.0, x: (3'i32,))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(float)+sizeof(int)+len(data.v)+sizeof((int32,))
  s.setPosition(0)
  let a = s.binTo(FooBaz)
  assert a == data
  assert s.getPosition == s.data.len
block:
  let data = Foo(value: 1, next: Foo(value: 2, next: nil))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == 3*sizeof(bool)+2*sizeof(int)
  s.setPosition(0)
  let a = s.binTo(Foo)
  assert a.value == 1
  let b = a.next
  assert b.value == 2
  assert s.getPosition == s.data.len
block:
  let data = FooBar(four: "hello", three: 1'f32)
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(bool)+sizeof(float32)+sizeof(char)+2*sizeof(int)+len(data.four)
  s.setPosition(0)
  let a = s.binTo(FooBar)
  doAssert a.four == "hello"
  assert a.three == 1'f32
  assert a.one == 0
  assert s.getPosition == s.data.len
block:
  let data = some(Foo(value: 5, next: nil))
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == 3*sizeof(bool)+sizeof(int)
  s.setPosition(0)
  let a = s.binTo(Option[Foo])
  assert a.get.value == 5
  assert s.getPosition == s.data.len
block:
  let data = some(Empty())
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(bool)+sizeof(Empty)
  s.setPosition(0)
  let a = s.binTo(Option[Empty])
  assert s.getPosition == s.data.len
block:
  let data = toHashSet([5'f32, 3, 2])
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(int)+3*sizeof(float32)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(HashSet[float32])
  assert a == data
block:
  let data = {'a': 5'i32, 'b': 9'i32}.toTable
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(int)+2+2*sizeof(int32)
  s.setPosition(0)
  assert data.len == s.readInt64
  s.setPosition(0)
  let a = s.binTo(Table[char, int32])
  assert a == data
block:
  let data = Bar(kind: Apple, apple: "world")
  let s = newStringStream()
  s.storeBin(data)
  assert s.data.len == sizeof(bool)+sizeof(Fruit)+sizeof(int)+len(data.apple)
  s.setPosition(0)
  let a = s.binTo(Bar)
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
  let a = s.binTo(ContentNode)
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
  let a = s.binTo(seq[IrisPlant])
  assert a[0].species == "setosa"
  assert almostEqual(a[0].sepalWidth, 3.5'f32)
  assert almostEqual(a[1].sepalWidth, 3'f32)
  assert s.getPosition == s.data.len
block:
  let data = [
    Responder(name: "John Smith", gender: male, occupation: "student", age: 18,
      siblings: @[Sibling(sex: female, birth_year: 1991, relation: biological, alive: true),
                  Sibling(sex: male, birth_year: 1989, relation: step, alive: true)])]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  var a: array[1, Responder]
  s.loadBin(a)
  assert a[0].gender == male
  assert a[0].siblings.len == 2
  assert s.getPosition == s.data.len
