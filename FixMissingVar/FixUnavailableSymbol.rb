class FixUnavailableSymbol

  def initialize(projectName, projectPath, baseCommit, filePath, missingVar, line)
    @projectPath = projectPath
    @baseCommit = baseCommit
    @filePath = filePath
    @missingVar = missingVar
    @projectName = projectName
    @line = line
    @initialPath = ""
  end

  def deleteClone()
    Dir.chdir(@initialPath)
    %x(rm -rf baseCommitClone/)
  end

  def fix(className)
    
    # cloning baseCommit
    @initialPath = Dir.getwd
    %x(git clone https://github.com/#{@projectName} baseCommitClone)
    Dir.chdir("baseCommitClone/")
    %x(git checkout #{@baseCommit})

    # getting declaration
    baseFileContent = File.read(Dir.getwd + "/" + @filePath)

    # getting merge file
    mergeFileContent = File.read(@projectPath + "/" + @filePath)

    # declarationPoints = originalFileContent.scan(/[^return].* #{@missingVar}[;| ].*;*/)
    # declarationPoints.delete_if {|x| x.match("return " + @missingVar + ";") != nil }

    declaration = ""
    declarationLine = 0

    methodName = getMethodName(baseFileContent, @line)

    if methodName != "" 
      
      baseStartScope, baseEndScope = getMethodScope(baseFileContent, methodName)

      # get declaration on method scope
      declaration = baseFileContent[baseStartScope..baseEndScope].scan(/[^return].* #{@missingVar}[;| ].*;*/)[0]

      # search line in method where there is the declaration
      baseDeclarationIndex = baseFileContent[baseStartScope, baseEndScope].index(declaration)
      baseDeclarationLine = baseFileContent[baseStartScope, baseEndScope][0..baseDeclarationIndex].count("\n")
      

      # find line of method on merge commit
      mergeStartScope, mergeEndScope = getMethodScope(mergeFileContent, methodName)
      mergeFirstUsageIndex = baseFileContent[mergeStartScope, mergeEndScope].index(@missingVar)
      mergeFirstUsageLine = baseFileContent[mergeStartScope, mergeEndScope][0..mergeFirstUsageIndex].count("\n")

      # save the line in the method
      declarationLine = baseDeclarationLine
      if declarationLine > mergeFirstUsageLine
        declarationLine = mergeFirstUsageLine
      end

      # line on merge commit to insert declaration
      mergeStartScopeLine = mergeFileContent[0..mergeStartScope].count("\n")
      declarationLine = declarationLine + mergeStartScopeLine
    else
      # search for the class
      # get the begin and the end of the class
      baseStartScope, baseEndScope = getClassScope(baseFileContent, className)
      scope = baseFileContent[baseStartScope..baseEndScope]
      
      # search the declaration in class scope
      declarationScanned = baseFileContent[baseStartScope..baseEndScope].scan(/[^return].* #{@missingVar}[;| ].*;*/)
      
      if declarationScanned.length > 1
        
        declarationScannedIndexes = []

        lastIndex = 0
        declarationScanned do |oneDeclaration|
          lastIndex = scope[lastIndex, 0].index(oneDeclaration)
          declarationScannedIndexes.push(lastIndex)
        end
        
        while declarationScanned.length > 1
          
          indexFirst = declarationScannedIndexes[0]
          
          openScope = scopeClass[baseStartScope..indexFirst].count("{")
          closeScope = scopeClass[baseStartScope..indexFirst].count("}")

          if openScope > closeScope
            declarationScanned.delete_at(0)
            declarationScannedIndexes.delete_at(0)
          else
            declarationScanned = [declarationScanned[0]]
            declarationScannedIndexes = [declarationScannedIndexes[0]]
          end
        end      
      end

      declaration = declarationScanned[0]

      mergeStartScope, mergeEndScope = getClassScope(mergeFileContent, className)
      declarationLine = baseFileContent[0..mergeStartScope].count("\n") + 1
    end

    # declaration = declarationPoints[0]
    # indexOfDeclaration = originalFileContent.index(declaration)
    # declarationLine = originalFileContent[0..indexOfDeclaration].count "\n"  
    # 
    # if declarationPoints.length > 1 && false # TODO: remove this && false
    #   declarationPoints.each do |decls|
    #     puts decls
    #   end
    #   puts "error"
    #   puts "need verify the context to know what declaration is true"
    #   return
    # else
    #   indexOfDeclaration = originalFileContent.index(declarationPoints[0])
    #   declarationLine = originalFileContent[0..indexOfDeclaration].count "\n"  
    # end

    # set declaration again and delete baseCommit
    puts "try set "
    puts declaration
    puts "in line: "
    puts declarationLine
    puts "where the file has lines equals to: "
    puts mergeFileContent.count("\n")
    setDeclaration(declaration, declarationLine)
    deleteClone()
  end

  def getMethodName(content, line)
    linePoint = 0
    lineCount = 0
    while lineCount < line - 1
      linePoint = linePoint + content[linePoint..-1].index("\n") + 1
      lineCount = lineCount + 1
    end
    contentBeforeLine = content[0..linePoint]
    contentSearch = contentBeforeLine
   
    lastDeclaration = nil
    isMethod = false
    declarationisTheLast = false
    nextOpenScope = -1
      
    while lastDeclaration == nil || !declarationisTheLast
      # verify if is method or class and repeat for others
      
      nextOpenScope = contentSearch.rindex("{")

      while contentSearch[0..nextOpenScope].count("{") <= contentSearch[0..nextOpenScope].count("}")
        nextOpenScope = contentSearch[0..nextOpenScope-1].rindex("{")
      end

      contentSearch = contentSearch[0..nextOpenScope]

      matchMethod = contentSearch.scan(/[\p{L}]+[\p{Space}]*\([\p{L}|\p{Space}|,|\?|\<|\>|\[|\]]*\)[\p{Space}]*{/)
      if matchMethod.length == 0
        matchMethod = nil
      else
        matchMethod = matchMethod[matchMethod.length - 1] 
      end
      
      matchClass = contentSearch.scan(/class[\p{Space}]*[\p{L}]*[\p{Space}]*[\p{L}|\p{Space}|,|\?|\<|\>|\[|\]]*[\p{Space}]*\{/)
      if matchClass.length == 0
        matchClass = nil
      else
        matchClass = matchClass[matchClass.length - 1] 
      end
      isMethod = false  
      
      if matchClass != nil && matchMethod != nil
        classIndex = contentSearch.rindex(matchClass)
        methodIndex = contentSearch.rindex(matchMethod)
  
        if classIndex > methodIndex
          lastDeclaration = matchClass
        else
          lastDeclaration = matchMethod
          isMethod = true
        end
      elsif matchClass != nil
        lastDeclaration = matchClass
        isMethod = false
      elsif matchMethod != nil
        lastDeclaration = matchMethod
        isMethod = true
      else
        lastDeclaration = nil
        isMethod = false
      end

      if lastDeclaration != nil
        declarationisTheLast = contentSearch.rindex(lastDeclaration) + lastDeclaration.length - 1 == nextOpenScope
      end
      
      contentSearch = contentSearch[0..contentSearch.length-2]
    end

    return lastDeclaration.gsub(/[\p{Space}]*\([\p{Space}|\w|,|\<|\>|\[|\]|\?]*\)[\p{Space}]*\{/, "").strip
  end

  def getMethodScope(fileContent, methodName) 
    # search for method name
    # methodDeclaration = fileContent.scan(/[^return].* #{@missingVar}[;| ].*;*/)
    # methodDeclarations = fileContent.scan(/[private |public |protected ]*[\W|\w|\<|\>]*[ ]+#{methodName}[ ]*\([\w|\W|\<|\>|,| ]*\)[ ]*{/)
    methodDeclaration = fileContent.scan(/#{methodName}[\p{Space}]*\([\w|\p{Space}|,|\?|\<|\>|\[|\]]*\)[\p{Space}]*{/)[0]
    

    # search the declaration line
    methodIndex = fileContent.index(methodDeclaration)

    # search the begin and the end of the method
    startScope = methodIndex + methodDeclaration.length

    # possibleScope = originalFile[startLine, 0]
    endScope = fileContent[startScope..-1].index("}") + startScope

    numberOfOpenScope = fileContent[startScope..endScope].count("{")
    numberOfCloseScope = fileContent[startScope..endScope].count("}")

    while  numberOfOpenScope >= numberOfCloseScope do
      endScope = fileContent[endScope+1..-1].index("}") + endScope + 1

      numberOfOpenScope = fileContent[startScope..endScope].count("{")
      numberOfCloseScope = fileContent[startScope..endScope].count("}")
    end

    return startScope, endScope
  end

  def getClassScope(fileContent, className) 
    # classDeclaration = fileContent.scan(/[public |private |protected |^.]*[a-z]*[ ]+class .*[ ]*{/m)
    classDeclaration = fileContent.scan(/class[ ]*#{className}[\p{Space}]*\([\w|\p{Space}|,|\?|\<|\>|\[|\]]*\)[\p{Space}]*{/)[0]

    # search the declaration line
    classIndex = fileContent.index(classDeclaration)

    # search the begin and the end of the class
    startScope = classIndex + classDeclaration.length

    # possibleScope = originalFile[startLine, 0]
    endScope = fileContent[startScope..-1].index("}") + startScope

    numberOfOpenScope = fileContent[startScope..endScope].count("{")
    numberOfCloseScope = fileContent[startScope..endScope].count("}")

    while  numberOfOpenScope >= numberOfCloseScope do
      endScope = fileContent[endScope+1..-1].index("}") + endScope + 1

      numberOfOpenScope = fileContent[startScope..endScope].count("{")
      numberOfCloseScope = fileContent[startScope..endScope].count("}")
    end

    return startScope, endScope
  end

  def setDeclaration(declaration, lineToInsert)
    Dir.chdir(@projectPath)
    tempFileName = @projectPath + "/" + @filePath + '.tmp'
    tempFile = File.new(tempFileName, 'w+')
    originalFile = File.open(@projectPath + "/" + @filePath, "r")
    declaration = declaration + "\n"
    lineCount = 0

    File.open(originalFile, 'r+').each do |line|
      lineCount = lineCount + 1
      tempFile.write(line)

      if lineCount == lineToInsert  
        tempFile.write(declaration)
      end
    end
    
    originalFile.close()
    tempFile.close()

    FileUtils.mv(tempFileName, @filePath)
  end

  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, reinsert " << @missingVar << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end
end