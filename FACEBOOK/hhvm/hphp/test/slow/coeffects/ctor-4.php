<?hh

class C {
  function __construct()[] { echo "C\n"; $this->prop(); }
  function prop()[write_this_props] { echo "C::prop\n"; }
}
class D extends C {
  function __construct()[] { echo "D\n"; parent::__construct(); }
}
<<__EntryPoint>>
function main() {
  new D();
}
