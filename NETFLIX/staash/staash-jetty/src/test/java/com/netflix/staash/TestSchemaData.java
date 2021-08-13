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
package com.netflix.staash;

import java.util.List;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.google.common.base.Supplier;
import com.google.common.collect.Lists;
import com.google.inject.AbstractModule;
import com.google.inject.Injector;
import com.google.inject.name.Names;
import com.netflix.astyanax.connectionpool.Host;
import com.netflix.governator.guice.LifecycleInjector;
import com.netflix.paas.cassandra.discovery.EurekaAstyanaxHostSupplier;
import com.netflix.paas.cassandra.discovery.EurekaModule;

public class TestSchemaData {
    private static final Logger LOG = LoggerFactory.getLogger(TestSchemaData.class);
    
    private static final String groupName = "UnitTest2";
    
    @BeforeClass
    public static void startup() {
        //SingletonEmbeddedCassandra.getInstance();
    }
    
    @AfterClass
    public static void shutdown() {
        
    }
    
    @Test
    @Ignore
    public void test() throws Exception {
        List<AbstractModule> modules = Lists.newArrayList(
            new AbstractModule() {
                @Override
                protected void configure() {
                    bind(String.class).annotatedWith(Names.named("groupName")).toInstance(groupName);
                }
            },
//            new CassandraPaasModule(),
            new EurekaModule()
//            new PaasModule(),
//            new JerseyServletModule() {
//                @Override
//                protected void configureServlets() {
//                    // Route all requests through GuiceContainer
//                    bind(GuiceContainer.class).asEagerSingleton();
//                    serve("/*").with(GuiceContainer.class);
//                }
//            },
//            new AbstractModule() {
//                @Override
//                protected void configure() {
//                    bind(PaasBootstrap.class).asEagerSingleton();
//                    bind(PaasCassandraBootstrap.class).asEagerSingleton();
//                }
//            }
        );
        
        // Create the injector
        Injector injector = LifecycleInjector.builder()
            .withModules(modules)
            .createInjector();

//        LifecycleManager    manager = injector.getInstance(LifecycleManager.class);
//        manager.start();
//
//        SchemaService schema = injector.getInstance(SchemaService.class);
//        Assert.assertNotNull(schema);

//        final String schemaName = "vschema1";
//        final String tableName  = "vt_CASS_SANDBOX_AstyanaxUnitTests_AstyanaxUnitTests|users";
//
//        
//        DataResource       dataResource   = injector      .getInstance          (DataResource.class);
//        Assert.assertNotNull(dataResource);
//        
//        SchemaDataResource schemaResource = dataResource  .getSchemaDataResource(schemaName);
//        Assert.assertNotNull(schemaResource);
//        
//        TableDataResource  tableResource  = schemaResource.getTableSubresource  (tableName);
//        tableResource.listRows(null, 10, 10);

//        ClusterDiscoveryService discoveryService = injector.getInstance(ClusterDiscoveryService.class);
//        LOG.info("Clusters: " + discoveryService.getClusterNames());
        EurekaAstyanaxHostSupplier supplier = injector.getInstance(EurekaAstyanaxHostSupplier.class);
        Supplier<List<Host>> list1 = supplier.getSupplier("cass_sandbox");
        List<Host> hosts = list1.get();
        LOG.info("cass_sandbox");
        for (Host host:hosts) {
            LOG.info(host.getHostName());
        }
        Supplier<List<Host>> list2 = supplier.getSupplier("ABCLOUD");
        hosts = list2.get();
        LOG.info("ABCLOUD");
        for (Host host:hosts) {
            LOG.info(host.getHostName());
        }
        
        Supplier<List<Host>> list3 = supplier.getSupplier("CASSS_PAAS");
        hosts = list3.get();
        LOG.info("casss_paas");
        for (Host host:hosts) {
            LOG.info(host.getHostName());
        }

        
//        CassandraSystemAdminResource admin = injector.getInstance(CassandraSystemAdminResource.class);
//        admin.discoverClusters();
        LOG.info("starting cluster discovery task");
//        TaskManager taskManager = injector.getInstance(TaskManager.class);
//        taskManager.submit(ClusterDiscoveryTask.class);
//
//        PassGroupConfigEntity.Builder groupBuilder = PassGroupConfigEntity.builder().withName(groupName);
//        

//        String keyspaceName = "AstyanaxUnitTests";
//        int i = 0;
//        String vschemaName = "vschema1";
//        DbEntity.Builder virtualSchemaBuilder = DbEntity.builder()
//            .withName(vschemaName);
//        
//          
//        
        LOG.info("running cluster dao");

//        DaoProvider daoManager = injector.getInstance(Key.get(DaoProvider.class));
//        DaoKeys key;
//        Dao<CassandraClusterEntity> cassClusterDAO = daoManager.getDao(DaoKeys.DAO_CASSANDRA_CLUSTER_ENTITY);
//        Collection<CassandraClusterEntity> cassClusterColl = cassClusterDAO.list();
//        for (CassandraClusterEntity cse: cassClusterColl) {
//            LOG.info(cse.getClusterName());
//        }
        
        
//        for (String cfName : cassCluster.getKeyspaceColumnFamilyNames(keyspaceName)) {
//            LOG.info(cfName);
//            TableEntity table = TableEntity.builder()
//                    .withTableName(StringUtils.join(Lists.newArrayList("vt", clusterName, keyspaceName, cfName), "_"))
//                    .withStorageType("cassandra")
//                    .withOption("cassandra.cluster",        clusterName)
//                    .withOption("cassandra.keyspace",       keyspaceName)
//                    .withOption("cassandra.columnfamily",   cfName)
//                    .build();
//                    
//            virtualSchemaBuilder.addTable(table);
//        }
//        
//        vschemaDao.write(virtualSchemaBuilder.build());
//        
//        groupDao.write(groupBuilder.build());
        
        
//        DaoManager daoManager = injector.getInstance(Key.get(DaoManager.class, Names.named("configuration")));
//        Dao<VirtualSchemaEntity> schemaDao = daoManager.getDao(VirtualSchemaEntity.class);
//        
//        List<Dao<?>> daos = daoManager.listDaos();
//        Assert.assertEquals(1, daos.size());
//        
//        for (Dao<?> dao : daos) {
//            LOG.info("Have DAO " + dao.getDaoType() + ":" + dao.getEntityType());
//            dao.createStorage();
//        }
//        
//        DaoSchemaRegistry schemaService = injector.getInstance(DaoSchemaRegistry.class);
//        schemaService.listSchema();
//        
//        DaoManager daoFactory = injector.getInstance(DaoManager.class);
//        
////        Dao<SchemaEntity> schemaEntityDao = daoFactory.getDao(SchemaEntity.class);
////        schemaEntityDao.createStorage();
////        schemaEntityDao.write(SchemaEntity.builder()
////                .withName("schema1")
////                .addTable(TableEntity.builder()
////                    .withStorageType("cassandra")
////                    .withTableName("table1")
////                    .withSchemaName("schema1")
////                    .withOption("clusterName",      "local")
////                    .withOption("keyspaceName",     "Keyspace1")
////                    .withOption("columnFamilyName", "ColumnFamily1")
////                    .build())
////                .build());
//        
////        Iterable<SchemaEntity> schemas = schemaEntityDao.list();
////        for (SchemaEntity entity : schemas) {
////            System.out.println(entity.toString());
////        }
        
//        manager.close();
    }
}
