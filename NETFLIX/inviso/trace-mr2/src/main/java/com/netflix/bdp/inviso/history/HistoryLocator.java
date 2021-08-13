/*
 *
 *  Copyright 2014 Netflix, Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */


package com.netflix.bdp.inviso.history;

import org.apache.commons.lang3.tuple.Pair;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;


/**
 * Interface to abstract where job history files are located.
 *
 * @author dweeks
 */
public interface HistoryLocator {
    
    void initialize(Configuration config) throws Exception;
    
    Pair<Path, Path> locate(String jobId) throws Exception;
    
    void close() throws Exception;
}
