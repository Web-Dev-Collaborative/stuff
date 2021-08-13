package com.netflix.fabricator;

import java.util.Properties;

import org.junit.Assert;
import org.junit.Test;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.netflix.fabricator.jackson.JacksonComponentConfiguration;

public class JacksonConfigurationSourceTest {
    private static String json = 
            "{\"properties\":{"
           + "   \"a\":\"_a\"," 
           + "   \"b\":\"_b\"," 
           + "   \"c\":\"_c\"" 
           + "}"
           + "}";
    

    @Test
    public void test() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        JsonNode node = mapper.readTree(json);

        Properties prop1 = new Properties();
        prop1.setProperty("a", "_a");
        prop1.setProperty("b", "_b");
        prop1.setProperty("c", "_c");
        
        JacksonComponentConfiguration source = new JacksonComponentConfiguration("key1", "type1", node);
        Properties prop2 = source.getChild("properties").getValue(Properties.class);
        Assert.assertEquals(prop1, prop2);
    }
}
