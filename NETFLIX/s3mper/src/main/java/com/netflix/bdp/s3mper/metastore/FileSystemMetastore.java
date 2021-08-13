/*
 *
 *  Copyright 2013 Netflix, Inc.
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


package com.netflix.bdp.s3mper.metastore;

import java.net.URI;
import java.util.List;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;

/**
 * Describes the basic operations used for FileSystem metastore consistency.
 * 
 * @author dweeks
 */
public interface FileSystemMetastore {
    
    public void initalize(URI uri, Configuration conf) throws Exception;
    
    public List<FileInfo> list(List<Path> path) throws Exception;
    
    public void add(Path path, boolean directory) throws Exception;
    
    public void delete(Path path) throws Exception;
    
    public void close();
    
}
