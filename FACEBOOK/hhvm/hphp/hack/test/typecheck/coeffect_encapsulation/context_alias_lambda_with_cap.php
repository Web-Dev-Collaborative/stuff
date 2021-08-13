//// f.php
<?hh
<<file:__EnableUnstableFeatures('context_alias_declaration')>>

// Codegen framework
newtype Codegen as [] = [defaults];

function enter_codegen(
  (function ()[Codegen]: void) $f
): void {
  echo "Hello I can secretly do IO";
  $f();
}

//// g.php
<?hh
<<file:__EnableUnstableFeatures('context_alias_declaration')>>

// client code
<<__EntryPoint>>
function main(): void {
  enter_codegen(
    ()[Codegen] ==> {
      echo "break purity"; // illegal!
    }
  );
}
