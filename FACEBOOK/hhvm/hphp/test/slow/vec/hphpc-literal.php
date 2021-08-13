<?hh
// Copyright 2004-present Facebook. All Rights Reserved.

function main() {
  var_dump(HH\Lib\Legacy_FIXME\eq(vec[123], vec['123']));
  var_dump(HH\Lib\Legacy_FIXME\neq(vec[123], vec['123']));
  var_dump(vec[123] === vec['123']);
  var_dump(vec[123] !== vec['123']);
  var_dump(HH\Lib\Legacy_FIXME\lt(vec[123], vec['123']));
  var_dump(HH\Lib\Legacy_FIXME\lte(vec[123], vec['123']));
  var_dump(HH\Lib\Legacy_FIXME\gt(vec[123], vec['123']));
  var_dump(HH\Lib\Legacy_FIXME\gte(vec[123], vec['123']));
  var_dump(HH\Lib\Legacy_FIXME\cmp(vec[123], vec['123']));

  var_dump(HH\Lib\Legacy_FIXME\eq(vec['123'], vec[123]));
  var_dump(HH\Lib\Legacy_FIXME\neq(vec['123'], vec[123]));
  var_dump(vec['123'] === vec[123]);
  var_dump(vec['123'] !== vec[123]);
  var_dump(HH\Lib\Legacy_FIXME\lt(vec['123'], vec[123]));
  var_dump(HH\Lib\Legacy_FIXME\lte(vec['123'], vec[123]));
  var_dump(HH\Lib\Legacy_FIXME\gt(vec['123'], vec[123]));
  var_dump(HH\Lib\Legacy_FIXME\gte(vec['123'], vec[123]));
  var_dump(HH\Lib\Legacy_FIXME\cmp(vec['123'], vec[123]));

  var_dump(vec[123] == vec[123]);
  var_dump(vec[123] != vec[123]);
  var_dump(vec[123] === vec[123]);
  var_dump(vec[123] !== vec[123]);
  var_dump(vec[123] < vec[123]);
  var_dump(vec[123] <= vec[123]);
  var_dump(vec[123] > vec[123]);
  var_dump(vec[123] >= vec[123]);
  var_dump(vec[123] <=> vec[123]);

  var_dump(vec[123] == 123);
  var_dump(vec[123] != 123);
  var_dump(vec[123] === 123);
  var_dump(vec[123] !== 123);
  try { var_dump(vec[123] < 123); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(vec[123] <= 123); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(vec[123] > 123); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(vec[123] >= 123); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(vec[123] <=> 123); } catch (Exception $e) { echo $e->getMessage() . "\n"; }

  var_dump(HH\Lib\Legacy_FIXME\eq(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(HH\Lib\Legacy_FIXME\neq(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(varray[vec[123], vec['123']] === varray[vec['123'], vec[123]]);
  var_dump(varray[vec[123], vec['123']] !== varray[vec['123'], vec[123]]);
  var_dump(HH\Lib\Legacy_FIXME\lt(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(HH\Lib\Legacy_FIXME\lte(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(HH\Lib\Legacy_FIXME\gt(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(HH\Lib\Legacy_FIXME\gte(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));
  var_dump(HH\Lib\Legacy_FIXME\cmp(varray[vec[123], vec['123']], varray[vec['123'], vec[123]]));

  var_dump(varray[vec[123], keyset['123']] == varray[keyset['123'], vec[123]]);
  var_dump(varray[vec[123], keyset['123']] != varray[keyset['123'], vec[123]]);
  var_dump(varray[vec[123], keyset['123']] === varray[keyset['123'], vec[123]]);
  var_dump(varray[vec[123], keyset['123']] !== varray[keyset['123'], vec[123]]);
  try { var_dump(varray[vec[123], keyset['123']] < varray[keyset['123'], vec[123]]); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(varray[vec[123], keyset['123']] <= varray[keyset['123'], vec[123]]); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(varray[vec[123], keyset['123']] > varray[keyset['123'], vec[123]]); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(varray[vec[123], keyset['123']] >= varray[keyset['123'], vec[123]]); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
  try { var_dump(varray[vec[123], keyset['123']] <=> varray[keyset['123'], vec[123]]); } catch (Exception $e) { echo $e->getMessage() . "\n"; }
}

<<__EntryPoint>>
function main_hphpc_literal() {
main();
}
