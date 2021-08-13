/*
 * Copyright 2014 Spotify AB. All rights reserved.
 *
 * The contents of this file are licensed under the Apache License, Version
 * 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */
package com.spotify.crunch.lib;

import com.google.common.base.Function;
import com.google.common.collect.Iterables;
import org.apache.crunch.*;
import org.apache.crunch.types.PType;
import org.apache.hadoop.conf.Configuration;

import java.io.Serializable;

public class MapFns {

  private static abstract class CompoundMapFn<S, T> extends MapFn<S, T> {
    private MapFn<S, ?>[] mapFns;
    public CompoundMapFn(MapFn<S, ?>... mapFns) {
      this.mapFns = mapFns;
    }
    @Override
    public void initialize() {
      for (MapFn<S, ?> mapFn : mapFns) {
        mapFn.initialize();
      }
    }

    @Override
    public void configure(Configuration conf) {
      for (MapFn<S, ?> mapFn : mapFns) {
        mapFn.configure(conf);
      }
    }

  }

  /**
   * Combine two "extraction" MapFns into a single MapFn to Pair
   */
  public static <T, A, B> MapFn<T, Pair<A, B>> pairFn(final MapFn<T, A> aFn, final MapFn<T, B> bFn) {
    return new CompoundMapFn<T, Pair<A, B>>(aFn, bFn) {
      @Override
      public Pair<A, B> map(T input) {
        return Pair.of(aFn.map(input), bFn.map(input));
      }
    };
  }

  /**
   * Combine three "extraction" MapFns into a single MapFn to Tuple3
   */
  public static <T, A, B, C> MapFn<T, Tuple3<A, B, C>> tuple3Fn(final MapFn<T, A> aFn, final MapFn<T, B> bFn, final MapFn<T, C> cFn) {
    return new CompoundMapFn<T, Tuple3<A, B, C>>(aFn, bFn, cFn) {
      @Override
      public Tuple3<A, B, C> map(T input) {
        return Tuple3.of(aFn.map(input), bFn.map(input), cFn.map(input));
      }
    };
  }

  /**
   * Combine four "extraction" MapFns into a single MapFn to Tuple4
   */
  public static <T, A, B, C, D> MapFn<T, Tuple4<A, B, C, D>> tuple4Fn(final MapFn<T, A> aFn, final MapFn<T, B> bFn, final MapFn<T, C> cFn, final MapFn<T, D> dFn) {
    return new CompoundMapFn<T, Tuple4<A, B, C, D>>(aFn, bFn, cFn, dFn) {
      @Override
      public Tuple4<A, B, C, D> map(T input) {
        return Tuple4.of(aFn.map(input), bFn.map(input), cFn.map(input), dFn.map(input));
      }
    };
  }
}
