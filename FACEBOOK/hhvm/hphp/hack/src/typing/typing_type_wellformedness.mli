(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

(** This module checks wellformedness of type hints in the decls and bodies.
    Wellformedness checks include:
    - constraints on type parameters (e.g. C<string> where C requires T as arraykey)
    - hint well-kinded-ness
    - trivial syntactic errors:
        - writing ?nonnull instead of mixed
        - ?void, ?noreturn, ?mixed
        - Tuple<X, Y> instead of (X, Y))
    - correct usage of __ViaLabel attribute

    NB: this is akin to well-formedness in e.g.
    "Featherweight Java: A Minimal Core Calculus for Java and GJ", 2002,
    Igarashi, Pierce, Wadler. *)

val fun_ : Typing_env_types.env -> Nast.fun_ -> unit

val class_ : Typing_env_types.env -> Nast.class_ -> unit

val typedef : Typing_env_types.env -> Nast.typedef -> unit

val global_constant : Typing_env_types.env -> Nast.gconst -> unit

val record_def : Typing_env_types.env -> Nast.record_def -> unit

(** Check type wellformedness of any hint appearing in this
    expression, e.g. parameter type hints of lambda expressions,
    hints in `is` and `as` expressions, etc. *)
val expr : Typing_env_types.env -> Nast.expr -> unit
