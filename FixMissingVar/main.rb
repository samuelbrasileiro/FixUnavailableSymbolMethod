require_relative 'UnavailableSymbolExtractor.rb'
require_relative 'GitProject.rb'
require_relative 'BCUnavailableSymbol.rb'
require_relative 'FixUnavailableSymbol.rb'

if ARGV.length < 1
  puts "invalid args, valid args example: "
  puts "grumTreePath projectPath"
  puts "projectPath is an optional param"
  return
end

# test = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
# "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
# "attributeCharacteristics")
# test.fix("buildTree", "")

# test = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
#   "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
#   "attributeCharacteristics", 151)
# content = File.read("/home/arthurpires/Documents/faculdade/TAES/fixPatternRequestUpdate/baseCommitClone/src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java")
# test.getMethodName(content, 151)
# return

# Pre setup
puts "Entry your password"
password = STDIN.noecho(&:gets)

gumTree = ARGV[0]

if ARGV.length > 1
  Dir.chdir(ARGV[1])
end
projectPath = Dir.getwd

repLog = `#{"git config --get remote.origin.url"}`
if repLog == ""
  puts "invalid repository"
  return
end

projectName = repLog.split("//")[1]
projectName = projectName.split("github.com/").last.gsub("\n","").gsub(".git", "")
commitHash = `#{"git rev-parse --verify HEAD"}`
commitHash = commitHash.gsub("\n", "")
#print commitHash
print "\n"
# Init  Analysis
gitProject = GitProject.new(projectName, projectPath, "samuelbrasileiro", password)
#TIRAR ESSE#conflictResult = gitProject.conflictScenario(commitHash) #aqui vamos pegar o parentMerge
#ESTRUTURA CR: [bool, [commits]]
gitProject.deleteProject()

#TIRAR ESSE#if conflictResult[0] #se existir 2 parents
if 1
  #TIRAR ESSE#conflictParents = conflictResult[1] #conflictParents = parentMerge
  #ESTRUTURA [PAI1,PAI2,FILHO]
  #TIRAR ESSE #travisLog = gitProject.getTravisLog(commitHash)#pegar a log do nosso commit

  unavailableSymbolExtractor = UnavailableSymbolExtractor.new()
  #TIRAR ESSE #unavailableResult = unavailableSymbolExtractor.extractionFilesInfo(travisLog)
  unavailableResult = ["unavailableSymbolMethod", [["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"], ["PerHostPercentileTracker", "builderWithHighestTrackableLatencyMillis", "Activator", "/home/travis/build/datastax/java-driver/driver-tests/osgi/src/main/java/com/datastax/driver/osgi/impl/Activator.java:", "[77,89]"]], 9]

  #print "unavailable Result:\n\n\n"
  #print unavailableResult




  if unavailableResult[0] == "unavailableSymbolVariable"
    conflictCauses = unavailableResult[1]
    ocurrences = unavailableResult[2]

    bcUnavailableSymbol = BCUnavailableSymbol.new(gumTree, projectName, projectPath, commitHash,
      conflictParents, conflictCauses)
    bcUnSymbolResult = bcUnavailableSymbol.getGumTreeAnalysis()
    print("bcUNres = \n#{bcUnSymbolResult}\n")
    if bcUnSymbolResult[0] != ""

      baseCommit = bcUnSymbolResult[1]
      cause = bcUnSymbolResult[0]
      className = conflictCauses[0][0]
      callClassName = conflictCauses[0][2]
      methodNameByTravis = conflictCauses[0][1]
      conflictFile = conflictCauses[0][3].tr(":","")
      fileToChange = conflictFile.gsub(/\/home\/travis\/build\/[a-z|A-Z|0-9]+\/[a-z|A-Z|0-9]+\//,"")
      conflictLine = Integer(conflictCauses[0][4].gsub("[","").gsub("]","").split(",")[0])


      if className == callClassName
        puts "A build Conflict was detect, the conflict type is " + unavailableResult[0] + "."
        puts "Do you want fix it? Y or n"
        resp = STDIN.gets()
        # resp = "n"

        puts ">>>>>>>>>>>>>>>class"
        puts className
        puts ">>>>>>>>>>>>>>>method"
        puts methodNameByTravis

        if resp != "n" && resp != "N"
          fixer = FixUnavailableSymbol.new(projectName, projectPath, baseCommit, fileToChange, cause, conflictLine)
          fixer.fix(className)
        end
      end


      # TODO: get back deleted files
      puts ">>>>>>>>>>>>>>>missing symbol"
      puts cause
      puts ">>>>>>>>>>>>>>>file "
      puts conflictFile
      puts ">>>>>>>>>>>>>>>fileToChange "
      puts fileToChange
      puts ">>>>>>>>>>>>>>>class"
      puts className
      puts ">>>>>>>>>>>>>>>method"
      puts methodName
      puts ">>>>>>>>>>>>>>>line"
      puts conflictLine
      puts ">>>>>>>>>>>>>>>base"
      puts baseCommit
    end
  end

  #TODO: METODO
  if unavailableResult[0] == "unavailableSymbolMethod"
    conflictCauses = unavailableResult[1]
    ocurrences = unavailableResult[2]

    #TIRAR ESSE #bcUnavailableSymbol = BCUnavailableSymbol.new(gumTree, projectName, projectPath, commitHash, conflictParents, conflictCauses)
    #TIRAR ESSE#bcUnSymbolResult = bcUnavailableSymbol.getGumTreeAnalysis()
    bcUnSymbolResult = ["builderWithHighestTrackableLatencyMillis", "4cf58a80635f5799440da084adc5b41e2139b3ab\n"]
    #print("\nbcUnSymbolResult = \n#{bcUnSymbolResult}\n")
    
    if bcUnSymbolResult[0] != ""
      baseCommit = bcUnSymbolResult[1]
      cause = bcUnSymbolResult[0]#gumtree
      className = conflictCauses[0][0]
      callClassName = conflictCauses[0][2]
      methodNameByTravis = conflictCauses[0][1]#travis
      conflictFile = conflictCauses[0][3].tr(":","")
      fileToChange = conflictFile.gsub(/\/home\/travis\/build\/[^\/]+\/[^\/]+\//, "")
      conflictLine = Integer(conflictCauses[0][4].gsub("[","").gsub("]","").split(",")[0])

      print "class name / callclassname #{className}/ #{callClassName}\n\n\n"
      if cause == methodNameByTravis
        puts "A build Conflict was detect, the conflict type is " + unavailableResult[0] + "."
        puts "Do you want fix it? Y or n"
        resp = STDIN.gets()
        # resp = "n"

        puts ">>>>>>>>>>>>>>>class"
        puts className
        puts ">>>>>>>>>>>>>>>method"
        puts methodNameByTravis

        if resp != "n" && resp != "N"
          fixer = FixUnavailableSymbol.new(projectName, projectPath, baseCommit, fileToChange, cause, conflictLine)
          fixer.fix(className)
        end
      end


      # TODO: get back deleted files
      puts ">>>>>>>>>>>>>>>missing symbol"
      puts cause
      puts ">>>>>>>>>>>>>>>file "
      puts conflictFile
      puts ">>>>>>>>>>>>>>>fileToChange "
      puts fileToChange
      puts ">>>>>>>>>>>>>>>class"
      puts className
      puts ">>>>>>>>>>>>>>>method"
      puts methodNameByTravis
      puts ">>>>>>>>>>>>>>>line"
      puts conflictLine
      puts ">>>>>>>>>>>>>>>base"
      puts baseCommit
    end
  end
end

puts "FINISHED!"
