/*******************************************************************************
 * /*
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
 *  *
 ******************************************************************************/
package com.netflix.staash.rest.dao;

import com.datastax.driver.core.Cluster;
import com.netflix.staash.json.JsonObject;

public class CqlDataDaoImplNew extends  CqlDataDaoImpl{

    public CqlDataDaoImplNew(Cluster cluster, MetaDao meta) {
        super(cluster, meta);
        // TODO Auto-generated constructor stub
    }

    public String writeRow(String db, String table, JsonObject rowObj) {
        // TODO Auto-generated method stub
        return null;
    }

    public String listRow(String db, String table, String keycol, String key) {
        // TODO Auto-generated method stub
        return null;
    }

    public String writeEvent(String db, String table, JsonObject rowObj) {
        // TODO Auto-generated method stub
        return null;
    }

    public String readEvent(String db, String table, String eventTime) {
        // TODO Auto-generated method stub
        return null;
    }

    public String doJoin(String db, String table1, String table2,
            String joincol, String value) {
        // TODO Auto-generated method stub
        return null;
    }

}
