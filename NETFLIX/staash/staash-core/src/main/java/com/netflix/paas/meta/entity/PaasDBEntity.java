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
package com.netflix.paas.meta.entity;

import com.netflix.paas.json.JsonObject;
import com.netflix.paas.meta.impl.MetaConstants;
import com.netflix.paas.util.Pair;

public class PaasDBEntity extends Entity{
    public static class Builder {
        private PaasDBEntity entity = new PaasDBEntity();
        
        public Builder withJsonPayLoad(JsonObject payLoad) {
            entity.setRowKey(MetaConstants.PAAS_DB_ENTITY_TYPE);
            String payLoadName = payLoad.getString("name");
            String load = payLoad.toString();
            entity.setName(payLoadName);
            entity.setPayLoad(load);
//            Pair<String, String> p = new Pair<String, String>(payLoadName, load);
//            entity.addColumn(p);
            return this;
        }                
        public PaasDBEntity build() {
            return entity;
        }        
    }    
    public static Builder builder() {
        return new Builder();
    }
}
