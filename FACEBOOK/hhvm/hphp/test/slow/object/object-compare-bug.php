<?hh
trait T { public $z; }
class A { use T; }
class B { use T; }
function main() {
  foreach (varray[varray[1,1], varray[1,2], varray[2,1]] as list($x, $y)) {
    $a = new A;
    $a->z = $x;
    $b = new B;
    $b->z = $y;
    var_dump($a == $b);
    var_dump($b == $a);
    var_dump($a != $b);
    var_dump($b != $a);
    var_dump(HH\Lib\Legacy_FIXME\lt($a, $b));
    var_dump(HH\Lib\Legacy_FIXME\lt($b, $a));
    var_dump(HH\Lib\Legacy_FIXME\lte($a, $b));
    var_dump(HH\Lib\Legacy_FIXME\lte($b, $a));
    var_dump(HH\Lib\Legacy_FIXME\gt($a, $b));
    var_dump(HH\Lib\Legacy_FIXME\gt($b, $a));
    var_dump(HH\Lib\Legacy_FIXME\gte($a, $b));
    var_dump(HH\Lib\Legacy_FIXME\gte($b, $a));
    echo "--------\n";
  }
}

<<__EntryPoint>>
function main_object_compare_bug() {
main();
}
