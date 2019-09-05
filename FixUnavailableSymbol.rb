class FixUnavailableSymbol

  def initialize(projectName, projectPath, baseCommit, filePath, missingMethod, line, declaredMethod)
    @projectPath = projectPath
    @baseCommit = baseCommit
    @filePath = filePath
    @missingMethod = missingMethod
    @projectName = projectName
    @declaredMethod = declaredMethod

    @line = line
    @initialPath = ""
  end

  def deleteClone()
    Dir.chdir(@initialPath)
    %x(rm -rf baseCommitClone/)
  end


  def fixMethod()


    fileDirectory = Dir.getwd + "/" + @filePath
    puts fileDirectory
    #armazenar o conteudo do arquivo que esta faltando o metodo
    baseFileContent = File.read(fileDirectory)
    puts baseFileContent
  puts "missing = " + @missingMethod
    puts "declared = "+ @declaredMethod
    #substituir o metodo que mudou o nome para o que foi declarado
    baseFileContent.gsub!(@missingMethod, @declaredMethod)

    #escrever no arquivo
    e = File.open(fileDirectory, 'w')
    e.write(baseFileContent)
    e.close

    makeCommit
  end



  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, reinsert " << @missingMethod << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end

end