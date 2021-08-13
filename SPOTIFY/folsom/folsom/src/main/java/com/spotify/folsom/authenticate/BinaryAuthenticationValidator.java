/*
 * Copyright (c) 2018 Spotify AB
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

package com.spotify.folsom.authenticate;

import com.spotify.folsom.RawMemcacheClient;
import com.spotify.folsom.client.binary.NoopRequest;
import java.util.concurrent.CompletionStage;

public class BinaryAuthenticationValidator implements Authenticator {

  private static final BinaryAuthenticationValidator INSTANCE = new BinaryAuthenticationValidator();

  public static BinaryAuthenticationValidator getInstance() {
    return INSTANCE;
  }

  private BinaryAuthenticationValidator() {}

  @Override
  public CompletionStage<RawMemcacheClient> authenticate(RawMemcacheClient client) {

    final NoopRequest request = new NoopRequest();

    return client
        .connectFuture()
        .thenCompose(ignored -> client.send(request).thenApply(status -> client));
  }

  @Override
  public void validate(final boolean binary) {
    if (!binary) {
      throw new IllegalStateException("Programmer error: wrong validator used");
    }
  }
}
