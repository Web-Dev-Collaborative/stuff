/*******************************************************************************
 * /***
 *  *
 *  *  Copyright 2013 Netflix, Inc.
 *  *
 *  *     Licensed under the Apache License, Version 2.0 (the "License");
 *  *     you may not use this file except in compliance with the License.
 *  *     You may obtain a copy of the License at
 *  *
 *  *         http://www.apache.org/licenses/LICENSE-2.0
 *  *
 *  *     Unless required by applicable law or agreed to in writing, software
 *  *     distributed under the License is distributed on an "AS IS" BASIS,
 *  *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  *     See the License for the specific language governing permissions and
 *  *     limitations under the License.
 *  *
 ******************************************************************************/
package com.netflix.staash.mesh.server.tasks;

import com.netflix.staash.mesh.InstanceRegistry;
import com.netflix.staash.mesh.server.Server;

public class RefreshRingRunnable implements Runnable {
    private final Server server;
    private final InstanceRegistry instanceRegistry;
    
    public RefreshRingRunnable(Server server, InstanceRegistry instanceRegistry) {
        this.server = server;
        this.instanceRegistry = instanceRegistry;
    }
    
    @Override
    public void run() {
        try {
//            server.(this.instanceRegistry.getMembers());
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
