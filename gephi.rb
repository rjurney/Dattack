#!/usr/bin/env ruby

include Java
require "/lib/java/gephi-toolkit.jar"

java_import org.openide.util.Lookup
java_import org.gephi.project.api.ProjectController
java_import org.gephi.data.attributes.api.AttributeController
java_import org.gephi.graph.api.GraphController
java_import org.gephi.io.importer.api.ImportController
java_import org.gephi.io.importer.api.EdgeDefault

java_import org.gephi.io.processor.plugin.DefaultProcessor
java_import org.gephi.statistics.plugin.PageRank

java_import java.util.Arrays
java_import java.util.Comparator
java_import java.lang.Float

def getProjectController
  return Lookup.getDefault().lookup(ProjectController.java_class)
end

def getAttributeController
  return Lookup.getDefault().lookup(AttributeController.java_class)
end

def getImportController
  return Lookup.getDefault().lookup(ImportController.java_class)
end

def getGraphController
  return Lookup.getDefault().lookup(GraphController.java_class)
end

#New Project
projectController = getProjectController
puts "Create new project"
projectController.newProject
workspace = projectController.currentWorkspace

#Import file
inputFile = java.io.File.new(ARGV[0])
puts "Import file '#{ARGV[0]}'"
importController = getImportController
container = importController.importFile(inputFile)
container.getLoader().setEdgeDefault(EdgeDefault.DIRECTED);
importController.process(container, DefaultProcessor.new, workspace)

#Get models
attributeController = getAttributeController
attributeModel = attributeController.model
graphController = getGraphController
graphModel = graphController.model

#Execute pagerank
pagerank = PageRank.new
pagerank.setDirected(true)
pagerank.setUseEdgeWeight(true)
puts "Execute Pagerank p=#{pagerank.getProbability}"
pagerank.execute(graphModel, attributeModel);

#Get nodes and sort by pagerank
nodes = graphModel.graph.nodes.toArray
class PRComparator
  include Comparator
  
  def compare(n1, n2)
    p1 = Float.new(n1.nodeData.attributes.value("pagerank"))
    p2 = n2.nodeData.attributes.value("pagerank")
    return -p1.compareTo(p2)
  end
end
Arrays.sort(nodes, PRComparator.new)

#Display top 10
for i in 0..10
   node = nodes[i]
   pr = node.nodeData.attributes.value("pagerank")
   recruiter = node.nodeData.attributes.value("address")
   id = node.nodeData.attributes.value("_id")
   label = node.nodeData.label
   puts "#{id} #{pr} #{recruiter}"
end