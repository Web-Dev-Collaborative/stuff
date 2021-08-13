/*
 * Copyright (c) 2015 Spotify AB
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */
package com.spotify.folsom;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

public class ConnectFuture extends CompletableFuture<Void> implements ConnectionChangeListener {

  private final boolean awaitConnected;
  private final boolean requireAll;

  /**
   * Create a future that completes once the client reaches the awaited state
   *
   * @param client
   * @param awaitConnected
   * @param requireAll
   */
  private ConnectFuture(ObservableClient client, boolean awaitConnected, final boolean requireAll) {
    this.awaitConnected = awaitConnected;
    this.requireAll = requireAll;
    client.registerForConnectionChanges(this);
    check(client);
  }

  public static CompletionStage<Void> disconnectFuture(ObservableClient client) {
    return new ConnectFuture(client, false, false);
  }

  public static CompletionStage<Void> fullyDisconnectedFuture(ObservableClient client) {
    return new ConnectFuture(client, false, true);
  }

  public static CompletionStage<Void> connectFuture(ObservableClient client) {
    return new ConnectFuture(client, true, false);
  }

  public static CompletionStage<Void> fullyConnectedFuture(ObservableClient client) {
    return new ConnectFuture(client, true, true);
  }

  @Override
  public void connectionChanged(ObservableClient client) {
    check(client);
  }

  private void check(ObservableClient client) {
    final Throwable failure = client.getConnectionFailure();
    if (failure != null) {
      completeExceptionally(failure);
    }
    if (requireAll) {
      final int expectedConnections = awaitConnected ? client.numTotalConnections() : 0;
      if (client.numActiveConnections() == expectedConnections) {
        if (complete(null)) {
          client.unregisterForConnectionChanges(this);
        }
      }
    } else {
      if (awaitConnected == client.isConnected()) {
        if (complete(null)) {
          client.unregisterForConnectionChanges(this);
        }
      }
    }
  }
}
