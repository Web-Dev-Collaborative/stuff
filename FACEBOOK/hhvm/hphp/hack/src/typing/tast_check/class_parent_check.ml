(*
 * Copyright (c) 2018, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

open Aast
open Base
module Env = Tast_env
module Cls = Decl_provider.Class

let check_is_class env (p, h) =
  match h with
  | Aast.Happly ((_, name), _) ->
    begin
      match Env.get_class env name with
      | None -> ()
      | Some cls ->
        let kind = Cls.kind cls in
        let name = Cls.name cls in
        if Ast_defs.is_c_class kind then (
          if Cls.final cls then Errors.requires_final_class p name
        ) else
          Errors.requires_non_class
            p
            name
            (Ast_defs.string_of_classish_kind kind)
    end
  | Aast.Habstr (name, _) -> Errors.requires_non_class p name "a generic"
  | _ -> Errors.requires_non_class p "This" "an invalid type hint"

let check_is_interface (env, error_verb) (p, h) =
  match h with
  | Aast.Happly ((_, name), _) ->
    begin
      match Env.get_class env name with
      | None -> ()
      | Some cls when Ast_defs.is_c_interface (Cls.kind cls) -> ()
      | Some cls -> Errors.non_interface p (Cls.name cls) error_verb
    end
  | Aast.Habstr _ -> Errors.non_interface p "generic" error_verb
  | _ -> Errors.non_interface p "invalid type hint" error_verb

let check_is_trait env (p, h) =
  match h with
  | Aast.Happly ((_, name), _) ->
    let type_info = Env.get_class env name in
    begin
      match type_info with
      | None -> ()
      | Some cls when Ast_defs.is_c_trait (Cls.kind cls) -> ()
      | Some cls ->
        let name = Cls.name cls in
        let kind = Cls.kind cls in
        Errors.uses_non_trait p name (Ast_defs.string_of_classish_kind kind)
    end
  | _ -> failwith "assertion failure: trait isn't an Happly"

let hint_happly_to_string h =
  match h with
  | Aast.Happly ((_, name), _) -> Some name
  | _ -> None

let duplicated_used_traits c =
  let traits = Hashtbl.create (module String) in
  List.iter
    ~f:(fun (p, h) ->
      match hint_happly_to_string h with
      | Some s -> Hashtbl.add_multi traits ~key:s ~data:p
      | None -> ())
    c.c_uses;
  Hashtbl.iteri
    ~f:(fun ~key ~data ->
      if List.length data > 1 then
        Errors.trait_reuse_inside_class
          c.c_name
          key
          (List.rev_map data ~f:Pos_or_decl.of_raw_pos))
    traits

let handler =
  object
    inherit Tast_visitor.handler_base

    method! at_class_ env c =
      let (req_extends, req_implements) = split_reqs c.c_reqs in
      List.iter c.c_uses ~f:(check_is_trait env);
      duplicated_used_traits c;
      List.iter req_extends ~f:(check_is_class env);
      List.iter c.c_implements ~f:(check_is_interface (env, "implement"));
      List.iter
        req_implements
        ~f:(check_is_interface (env, "require implementation of"))
  end
