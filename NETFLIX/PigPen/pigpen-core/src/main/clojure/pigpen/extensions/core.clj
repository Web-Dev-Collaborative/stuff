;;
;;
;;  Copyright 2013-2015 Netflix, Inc.
;;
;;     Licensed under the Apache License, Version 2.0 (the "License");
;;     you may not use this file except in compliance with the License.
;;     You may obtain a copy of the License at
;;
;;         http://www.apache.org/licenses/LICENSE-2.0
;;
;;     Unless required by applicable law or agreed to in writing, software
;;     distributed under the License is distributed on an "AS IS" BASIS,
;;     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;     See the License for the specific language governing permissions and
;;     limitations under the License.
;;
;;

(ns pigpen.extensions.core
  (:require [clojure.pprint])
  (:import [java.io StringWriter]))

(set! *warn-on-reflection* true)

(defn pp-str
 "Pretty prints to a string"
 [object]
 (let [writer (StringWriter.)]
   (clojure.pprint/pprint object writer)
   (.toString writer)))

(defmacro zip
  "Syntax of for, semantics of map.

  Example:
		=> (zip [x [1 2 3]
		         y [:a :b :c]
		         z [\"foo\" \"bar\" \"baz\"]]
		     [x y z])
		([1 :a \"foo\"] [2 :b \"bar\"] [3 :c \"baz\"])
"
  [bindings & body]
  (let [bindings# (partition 2 bindings)
        vars# (mapv first bindings#)
        vals# (mapv second bindings#)]
    `(map (fn ~vars# ~@body) ~@vals#)))

(defmacro zipv
  "Syntax of for, semantics of mapv.

  Example:
		=> (zipv [x [1 2 3]
		          y [:a :b :c]
		          z [\"foo\" \"bar\" \"baz\"]]
		     [x y z])
		[[1 :a \"foo\"] [2 :b \"bar\"] [3 :c \"baz\"]]
"
  [bindings & body]
  (let [bindings# (partition 2 bindings)
        vars# (mapv first bindings#)
        vals# (mapv second bindings#)]
    `(mapv (fn ~vars# ~@body) ~@vals#)))

(defmacro forcat
  "Returns the result of applying concat to a for expression."
  [seq-exprs body-expr]
  `(apply concat
     (for ~seq-exprs ~body-expr)))

(defn lazy-split
  "Returns a lazy sequence of the string split on the delimiter."
  [^String s delimiter]
  (if (instance? java.util.regex.Pattern delimiter)
    (let [^java.util.regex.Pattern delimiter delimiter
          step (fn step [index]
                 (when (<= index (.length s))
                   (let [matcher (.matcher delimiter s)
                         is-found (.find matcher index)
                         end (if is-found (.start matcher) (.length s))
                         next-step (if is-found (.end matcher) (inc (.length s)))]
                     (cons (subs s index end) (lazy-seq (step next-step))))))]
      (step 0))
    (let [^String delimiter (if (clojure.string/blank? delimiter) "\t" delimiter)
          step (fn step [index]
                 (when (<= index (.length s))
                   (let [index-of-delimiter (.indexOf s delimiter (int index))
                         end (if (<= 0 index-of-delimiter) index-of-delimiter (.length s))
                         next-step (+ end (.length delimiter))]
                     (cons (subs s index end) (lazy-seq (step next-step))))))]
      (step 0))))

(defn structured-split
  "Returns a vector of the string split on the delimiter."
  [^String s delimiter]
  (if (instance? java.util.regex.Pattern delimiter)
    (clojure.string/split s delimiter -1)
    (let [^String delimiter (if (clojure.string/blank? delimiter) "\t" delimiter)
          step (fn step [v index]
                 (if (> index (.length s))
                   v
                   (let [index-of-delimiter (.indexOf s delimiter (int index))
                         end (if (<= 0 index-of-delimiter) index-of-delimiter (.length s))
                         next-step (+ end (.length delimiter))
                         next-vec (conj v (subs s index end))]
                     (recur next-vec next-step))))]
      (step [] 0))))

(defmacro keys-fn
  "Creates a named anonymous function. Useful as a terse substitute for keys
destructuring.

Similar to an anonymous function, which uses positional names for arg:

  #(assoc %1 :foo %2 :bar %3)

`keys-fn` uses named variables that are keys in the input map:

  (keys-fn
    (assoc %
      :foo-copy %foo
      :bar-x-2  (* %bar 2)))

To compare, this is the same function using keys destructuring:

  (fn [{:keys [foo bar], :as value}]
    (assoc value
      :foo-copy foo
      :bar-x-2  (* bar 2)))

When using a large number of destructured variables, this can make a noticeable
difference in code size and readability. This macro simply re-writes the first
form into the second.
"
  {:added "0.3.0"}
  [& body]
  (let [syms# (atom #{})
        body# (clojure.walk/postwalk
                (fn [s]
                  (if (and (symbol? s)
                           (not= s '%)
                           (.startsWith (name s) "%"))
                    (let [s' (symbol (subs (name s) 1))]
                      (swap! syms# conj s')
                      s')
                    s))
                body)]
    `(fn [{:as ~'%, :keys ~(vec @syms#)}]
       ~@body#)))
