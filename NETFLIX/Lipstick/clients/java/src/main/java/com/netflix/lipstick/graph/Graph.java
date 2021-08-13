package com.netflix.lipstick.graph;

import java.io.IOException;
import java.io.InputStream;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.collect.Maps;

@JsonInclude(value=JsonInclude.Include.NON_EMPTY)
@JsonIgnoreProperties(ignoreUnknown=true)
public class Graph {
    
    private static final Log LOG = LogFactory.getLog(Graph.class);
    
    public String id;
    public String name;
    public String user;
    public Status status;
    public Map<String, Object> properties;    
    
    @JsonIgnore
    private Map<String, Node> nodeMap;
    
    @JsonIgnore
    private Map<String, Edge> edgeMap;
    
    @JsonIgnore
    private Map<String, NodeGroup> nodeGroupMap;
    
    public Graph() {
        this.status = new Status();
        this.nodeMap = Maps.newHashMap();
        this.edgeMap = Maps.newHashMap();
        this.nodeGroupMap = Maps.newHashMap();
        this.properties = Maps.newHashMap();
    }        
    
    public Graph(String id, String name) {
        this(id, name, System.getProperty("user.name"));
    }
    
    public Graph(String id, String name, String user) {
        this.id = id;
        this.name = name;
        this.user = user;
        this.status = new Status();
        this.nodeMap = Maps.newHashMap();
        this.edgeMap = Maps.newHashMap();
        this.nodeGroupMap = Maps.newHashMap();
        this.properties = Maps.newHashMap();
    }
    
    public int numNodes() {
        return this.nodeMap.size();
    }
    
    public int numNodeGroups() {
        return this.nodeGroupMap.size();        
    }
    
    public int numEdges() {
        return this.edgeMap.size();
    }
    
    public Graph(String id) {
        this(id, "workflow-"+id);
    }
    
    public Graph id(String id) {
        this.id = id;
        return this;
    }
   
    public Graph name(String name) {
        this.name = name;
        return this;
    }
    
    public Graph user(String user) {
        this.user = user;
        return this;
    }
    
    public Graph status(Status status) {
        this.status = status;
        return this;
    }
    
    public Object property(String key) {
        return this.properties.get(key);
    }
    
    public Graph property(String key, Object value) {
        this.properties.put(key, value);
        return this;
    }
    
    public Graph properties(Map<String, Object> properties) {
        this.properties = properties;
        return this;
    }
    
    public Graph node(Node node) {
        this.nodeMap.put(node.id, node);
        return this;
    }
    
    public Node node(String nodeId) {
        return this.nodeMap.get(nodeId);
    }
    
    public Graph edge(Edge edge) {
        String edgeId = edge.u + edge.v;
        this.edgeMap.put(edgeId, edge);
        return this;
    }
    
    public Edge edge(String u, String v) {
        String edgeId = u + v;
        return this.edgeMap.get(edgeId);
    }
    
    public Graph nodeGroup(NodeGroup nodeGroup) {
        this.nodeGroupMap.put(nodeGroup.id, nodeGroup);
        return this;
    }
    
    public NodeGroup nodeGroup(String nodeGroupId) {
        return this.nodeGroupMap.get(nodeGroupId);
    }
    
    public Collection<Node> getNodes() {
        return this.nodeMap.values();
    }
    
    public void setNodes(List<Node> nodes) {
        nodes(nodes);
    }
    
    public Graph nodes(List<Node> nodes) {
        for (Node node : nodes) {
            nodeMap.put(node.id, node);
        }
        return this;
    }
    
    public void setEdges(List<Edge> edges) {
        edges(edges);
    }

    public Collection<Edge> getEdges() {
        return this.edgeMap.values();
    }
    
    public Graph edges(List<Edge> edges) {
        for (Edge edge : edges) {
            String edgeId = edge.u + edge.v;
            this.edgeMap.put(edgeId, edge);
        }
        return this;
    }
    
    @JsonProperty("node_groups")
    public void setNodeGroups(List<NodeGroup> nodeGroups) {
        nodeGroups(nodeGroups);
    }
    
    @JsonProperty("node_groups")
    public Collection<NodeGroup> getNodeGroups() {
        return this.nodeGroupMap.values();
    }
    
    public Graph nodeGroups(List<NodeGroup> nodeGroups) {
        for (NodeGroup nodeGroup : nodeGroups) {
            this.nodeGroupMap.put(nodeGroup.id, nodeGroup);
        }
        return this;
    }
    
    public boolean equals(Object other) {        
        if (this == other) return true;
        if (!(other instanceof Graph)) return false;
        
        Graph g = (Graph)other;
        
        return
                this.id == null ? g.id == null : this.id.equals(g.id) &&
                this.name == null ? g.name == null : this.name.equals(g.name) &&
                this.status == null ? g.status == null : this.status.equals(g.status) &&
                this.getNodes().equals(g.getNodes()) &&
                this.getEdges().equals(g.getEdges()) &&
                this.getNodeGroups().equals(g.getNodeGroups()) &&
                this.properties.equals(g.properties);
    }
    
    public static Graph fromJson(InputStream is) {
        try {
            Graph g = (new ObjectMapper()).readValue(is, Graph.class);
            return g;
        } catch (IOException e) {
            LOG.error("Error deserializing Graph", e);
        }
        return null;
    }
    
    public static Graph fromJson(String json) {
        try {
            Graph g = (new ObjectMapper()).readValue(json, Graph.class);
            return g;
        } catch (IOException e) {
            LOG.error("Error deserializing Graph", e);
        }
        return null;
    }
    
    public String toString() {
        String result = null;
        try {
            result = (new ObjectMapper()).writeValueAsString(this);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        return result;
    }
}
