<?hh


<<__EntryPoint>>
function main_1428() {
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123.456") / 123;
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123.456") / 456.123;
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123.456") / HH\Lib\Legacy_FIXME\cast_for_arithmetic("123");
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123.456") / HH\Lib\Legacy_FIXME\cast_for_arithmetic("456.123");
var_dump($a);
$a = "123.456";
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic($a);
$a /= 123;
var_dump($a);
$a = "123.456";
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic($a);
$a /= 456.123;
var_dump($a);
$a = "123.456";
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic($a);
$a /= HH\Lib\Legacy_FIXME\cast_for_arithmetic("123");
var_dump($a);
$a = "123.456";
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic($a);
$a /= HH\Lib\Legacy_FIXME\cast_for_arithmetic("456.123");
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123") / 123;
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("123") / HH\Lib\Legacy_FIXME\cast_for_arithmetic("123");
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("321") / 123;
var_dump($a);
$a = HH\Lib\Legacy_FIXME\cast_for_arithmetic("321") / 123.456;
var_dump($a);
}
