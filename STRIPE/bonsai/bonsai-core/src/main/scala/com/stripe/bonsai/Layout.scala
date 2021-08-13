package com.stripe.bonsai

import scala.language.implicitConversions

import scala.reflect.ClassTag

import java.io.{ DataOutput, DataInput }

import com.stripe.bonsai.layout._

trait Layout[A] {
  def newBuilder: VecBuilder[A]

  def write(vec: Vec[A], out: DataOutput): Unit

  def read(in: DataInput): Vec[A]

  def isSafeToCast(vec: Vec[_]): Boolean

  def empty: Vec[A] = newBuilder.result()

  def zip[B](that: Layout[B]): Layout[(A, B)] = Layout.join(this, that)

  def transform[B](f: A => B, g: B => A): Layout[B] = Layout.transform(this)(f, g)

  def optional: Layout[Option[A]] = Layout.optional(this)

  def inflateOnRead(implicit ct: ClassTag[A]): Layout[A] = Layout.inflateOnRead(this)
}

object Layout {
  def apply[A](implicit layout: Layout[A]): Layout[A] = layout

  implicit def unitLayout: Layout[Unit] = UnitLayout
  implicit def denseBooleanLayout: Layout[Boolean] = DenseBooleanLayout
  implicit def denseByteLayout: Layout[Byte] = DenseByteLayout
  implicit def denseShortLayout: Layout[Short] = DenseShortLayout
  implicit def denseIntLayout: Layout[Int] = DenseIntLayout
  implicit def denseLongLayout: Layout[Long] = DenseLongLayout
  implicit def denseFloatLayout: Layout[Float] = DenseFloatLayout
  implicit def denseDoubleLayout: Layout[Double] = DenseDoubleLayout
  implicit def denseCharLayout: Layout[Char] = DenseCharLayout
  implicit def denseStringLayout: Layout[String] = DenseStringLayout

  implicit def optional[A](implicit layout: Layout[A]): Layout[Option[A]] = new OptionalLayout(layout)
  implicit def setLayout[A](implicit layout: Layout[A], offsetsLayout: Layout[Int]): Layout[Set[A]] =
    new ColLayout[A, Set[A]](layout, offsetsLayout)
  implicit def mapLayout[K, V](implicit layout: Layout[(K, V)], offsetsLayout: Layout[Int]): Layout[Map[K, V]] =
    new ColLayout[(K, V), Map[K, V]](layout, offsetsLayout)
  implicit def vectorLayout[A](implicit layout: Layout[A], offsetsLayout: Layout[Int]): Layout[Vector[A]] =
    new ColLayout[A, Vector[A]](layout, offsetsLayout)

  /**
   * Returns a data store that can store either A or B and requires only
   * 1.37n bits additional data (+ O(1) pointers).
   */
  implicit def either[A, B](implicit lhs: Layout[A], rhs: Layout[B]): Layout[Either[A, B]] =
    new DisjunctionLayout[A, B, Either[A, B]](lhs, rhs, identity, Left(_), Right(_))

  implicit def join[A, B](implicit lhs: Layout[A], rhs: Layout[B]): Layout[(A, B)] =
    new ProductLayout[A, B, (A, B)](lhs, rhs, identity, _ -> _)

  implicit def join3[A, B, C](implicit as: Layout[A], bs: Layout[B], cs: Layout[C]): Layout[(A, B, C)] =
    new Product3Layout[A, B, C, (A, B, C)](as, bs, cs, identity, (_, _, _))

  def transform[A, B](layout: Layout[A])(f: A => B, g: B => A): Layout[B] =
    new TransformedLayout(layout, g, f)

  def inflateOnRead[A: ClassTag](layout: Layout[A]): Layout[A] =
    new Layout[A] {
      def newBuilder: VecBuilder[A] = layout.newBuilder
      def write(vec: Vec[A], out: DataOutput): Unit = layout.write(vec, out)
      def read(in: DataInput): Vec[A] = layout.read(in).inflate
      def isSafeToCast(vec: Vec[_]): Boolean = layout.isSafeToCast(vec)
    }
}
