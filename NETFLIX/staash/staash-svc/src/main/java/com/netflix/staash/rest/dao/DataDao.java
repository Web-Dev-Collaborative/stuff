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

import com.netflix.staash.json.JsonObject;

public interface DataDao {
    public String writeRow(String db, String table, JsonObject rowObj);
    public String listRow(String db, String table, String keycol, String key);
    public String writeEvent(String db, String table, JsonObject rowObj);
    public String readEvent(String db, String table, String eventTime);
    public String doJoin(String db, String table1, String table2,
            String joincol, String value);
}
