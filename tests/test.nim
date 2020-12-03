import ../bingod, std/[streams, math]

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
    three: float
    four: string
  BazFoo = ref object of BarFoo
    two: char
  FooBar = ref object of BazFoo
    one: int
  FooBaz = object
    t: float
    x: (int,)
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
  s.setPosition(0)
  let a = s.binTo(BarBaz)
  assert a == data
block:
  let data = NotApple
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(Stuff)
  assert a == data
block:
  let data: array[Fruit, int] = [0, 1, 2]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(array[Fruit, int])
  assert a == data
block:
  let data = Empty()
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(Empty)
  assert a == data
block:
  let data = (x: 42)
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(tuple[x:int])
  assert(a[0] == 42)
block:
  var data: set[Fruit]
  data.incl Apple
  data.incl Orange
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(set[Fruit])
  assert(a == data)
block:
  let data = "hello world"
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(string)
  assert a == data
block:
  let data = @[1, 2, 3, 4, 5, 6]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(seq[int])
  assert a == data
block:
  let data = @["one", "two", "three"]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(seq[string])
  assert a == data
block:
  let data = @[("3",), ("4",), ("5",)]
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(seq[(string,)])
  assert a == data
block:
  let data = FooBaz(v: "hello", t: 5.0, x: (3,))
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(FooBaz)
  assert a == data
block:
  let data = Foo(value: 1, next: Foo(value: 2, next: nil))
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(Foo)
  assert a.value == 1
  let b = a.next
  assert b.value == 2
block:
  let data = FooBar(four: "hello", three: 1.0)
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(FooBar)
  doAssert a.four == "hello"
  assert a.three == 1.0
  assert a.one == 0
block:
  let data = Bar(kind: Apple, apple: "world")
  let s = newStringStream()
  s.storeBin(data)
  s.setPosition(0)
  let a = s.binTo(Bar)
  assert a.kind == Apple
  assert a.apple == "world"
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
