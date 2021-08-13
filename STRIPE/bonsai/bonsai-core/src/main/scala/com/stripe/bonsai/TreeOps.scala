package com.stripe.bonsai

/**
 * TreeOps is a type class for abstracting over arbitrary trees, allowing
 * traversal and data access. In general, it assumes that we can quickly access
 * the children and label of any given node.
 *
 * There are some convenience implicit methods added onto trees and nodes that
 * can be accessed by importing tree ops. For instance, say we wanted to add an
 * implicit method to any type of tree that let's us find some node in a tree.
 *
 * {{{
 * implicit class NodeFinder[T](tree: T)(implicit treeOps: TreeOps[T]) {
 * 
 *   // Brings in Node/Label types, and implicit classes.
 *   import treeOps._
 * 
 *   // Returns the first node (DFS) where the predicate is true.
 *   def find(f: Label => Boolean): Option[Node] = {
 *     def recur(node: Node): Option[Node] = {
 *       // treeOps.TreeNodeOps brings in the Node#label implicit method.
 *       if (f(node.label)) {
 *         node
 *       } else {
 *         // treeOps.TreeNodeOps also brings in Node#children implicit method.
 *         node.children.iterator.map(recur).find(_.isDefined).flatten
 *       }
 *     }
 * 
 *     // treeOps.TreeTreeOps brings in T#root.
 *     recur(tree.root)
 *   }
 * }
 * }}}
 */
trait TreeOps[Tree, Label] { ops =>

  /** The type of the nodes in the tree. */
  type Node

  /**
   * Returns the root node of the tree.
   */
  def root(t: Tree): Option[Node]

  /**
   * Returns all the direct children of the given node. The order may or may
   * not matter. TreeOps does not provide any guarantees here.
   */
  def children(node: Node): Iterable[Node]

  /**
   * Returns the label attached to the given node.
   */
  def label(node: Node): Label

  def fold[A](node: Node)(f: (Label, Iterable[Node]) => A): A =
    f(label(node), children(node))

  def fold[A](tree: Tree)(f: (Label, Iterable[Node]) => A): Option[A] =
    root(tree).map(n => fold(n)(f))

  def reduce[A](node: Node)(f: (Label, Iterable[A]) => A): A =
    f(label(node), children(node).map(reduce(_)(f)))

  def reduce[A](tree: Tree)(f: (Label, Iterable[A]) => A): Option[A] =
    root(tree).map(n => reduce(n)(f))

  def collectLabelsF[A](node: Node)(f: Label => A): Set[A] =
    reduce[Set[A]](node)((lbl, cs) => cs.foldLeft(Set(f(lbl)))(_ ++ _))

  def collectLabels(node: Node): Set[Label] = collectLabelsF(node)(identity)

  implicit class OpsForTree(tree: Tree) {
    def root: Option[Node] = ops.root(tree)
    def reduce[A](f: (Label, Iterable[A]) => A): Option[A] = root.map(ops.reduce(_)(f))
  }

  implicit class OpsForNode(node: Node) {
    def children: Iterable[Node] = ops.children(node)
    def label: Label = ops.label(node)
    def reduce[A](f: (Label, Iterable[A]) => A): A = ops.reduce(node)(f)
  }
}

object TreeOps {
  final def apply[Tree, Label](implicit ops: TreeOps[Tree, Label]) = ops
}
