<?hh

<<__EntryPoint>>
function main() {
  require "inner.inc";
  require "nested3/inner.inc";

  var_dump(main<>);
  C::inner();
  C3::inner();
}
