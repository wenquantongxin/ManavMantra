classdef DependencyFormatter
    
    methods(Static)
        %-----------------------------------
        %   matlab.depfun.internal.DependencyFormatter class public methods
        %-----------------------------------
        
        %discover all files within a toolbox root for a toolbox project
        function [toolboxDependencies] = toolboxPackagingDependencies(varargin)
            toolboxRoot = varargin{1};
            [path,~,~]=fileparts(toolboxRoot);
            if(isempty(path) && exist(fullfile(pwd,toolboxRoot),'dir'))
                toolboxRoot = fullfile(pwd,toolboxRoot);
            end
            demosHeader = '';%demos.xml will not checked for an empty string header
            if(nargin ==2)
                demosHeader = varargin{2};%demos.xml will be checked for any nonempty header
            end
            allSubdirectories = matlab.depfun.internal.DependencyFormatter.findSubdirectoriesByBFS(toolboxRoot);
            [demosFile]  = matlab.depfun.internal.DependencyFormatter.findDemosXML(allSubdirectories);
            [categorizedExamples, demosFileHadError, demosFileWasAutoGenerated] = matlab.depfun.internal.DependencyFormatter.findCategorizedExamples(allSubdirectories, demosFile, demosHeader);
            [apps] = matlab.depfun.internal.DependencyFormatter.findApps(allSubdirectories);
            [docFile] = matlab.depfun.internal.DependencyFormatter.findDocumentation(allSubdirectories);
            [demosFile]  = matlab.depfun.internal.DependencyFormatter.findDemosXML(allSubdirectories);
            toolboxDependencies=struct('CategorizedExamples',{categorizedExamples},'AppsList',{apps},'DocFile',docFile, 'DemosFile',demosFile, 'DemosFileHadError',demosFileHadError, 'DemosWasAutoGenerated', demosFileWasAutoGenerated);
        end
        
        %retrieve all dependencies for an apptool project
        function [depfileslist, products, platforms]= apptoolDependencies(entryPoint)
            [depfileslist, products, platforms] = matlab.depfun.internal.DependencyFormatter.findDependencies(entryPoint);
        end
        
        %find all dependencies and support packages for a deploytool project
        function [depfileslist, depsupportpackagelist]= deploytoolDependencies(varargin)
            [depfileslist, depsupportpackagelist]= matlab.depfun.internal.DependencyFormatter.findFilesAndSupportPackages(varargin);
        end
        
        %-----------------------------------
        %   Flattened methods for use in Java
        %-----------------------------------
        
        % return flattened lists of all dependencies for a toolbox project
        % formatError is true when there was an
        % invalid formatting somewhere within demos.xml. This may
        % cause some examples to have been read incorrectly or not at all.
        function [categorizedExamples,  apps, docFile, demosFile, demosFileHadError, demosFileWasAutoGenerated] = toolboxPackagingDependenciesFlattened(toolboxRoot, demosHeader)
            [toolboxDependencies] =  matlab.depfun.internal.DependencyFormatter.toolboxPackagingDependencies(toolboxRoot, demosHeader);
            categorizedExamples = toolboxDependencies.CategorizedExamples;
            demosFileHadError = toolboxDependencies.DemosFileHadError;
            demosFileWasAutoGenerated = toolboxDependencies.DemosWasAutoGenerated;
            apps = toolboxDependencies.AppsList;
            docFile =  toolboxDependencies.DocFile;
            demosFile = toolboxDependencies.DemosFile;
        end
        
        %return flattened lists of all dependencies for an apptool project
        function [depfileslist, productName, productVersion, productNumber, platforms]= apptoolDependenciesFlattened(varargin)
            [depfileslist, products, platforms] = matlab.depfun.internal.DependencyFormatter.apptoolDependencies(varargin);
            productName = cellfun(@(x) char(x), {products(:).Name}, 'UniformOutput',false);
            productVersion = cellfun(@(x) char(x), {products(:).Version}, 'UniformOutput',false);
            productNumber = cellfun(@(x) mat2str(x), {products(:).Number}, 'UniformOutput',false);
        end
        
    %returns all the dependencies that are not within the toolbox folder
        function [ externalDependencies, productName, productVersion, productNumber, supportPackages] = findExternalDependenciesTopOnly(toolboxRoot,UseTopOnly,varargin)
            if UseTopOnly
                [depfileslist, products] = matlab.depfun.internal.DependencyFormatter.getAllRequiredFilesAndProducts(varargin, 'toponly');
            else
                [depfileslist, products] = matlab.depfun.internal.DependencyFormatter.getAllRequiredFilesAndProducts(varargin);
            end
            [supportPackages] =  matlab.depfun.internal.DependencyFormatter.findSupportPackages(depfileslist, cellfun(@(x) char(x), {products(:).Name}, 'UniformOutput',false));
            isInToolbox = matlab.depfun.internal.DependencyFormatter.areFilesInToolbox(depfileslist, toolboxRoot);
            externalDependencies = depfileslist(~cell2mat(isInToolbox));
            productName = cellfun(@(x) char(x), {products(:).Name}, 'UniformOutput',false);
            productVersion = cellfun(@(x) char(x), {products(:).Version}, 'UniformOutput',false);
            productNumber = cellfun(@(x) mat2str(x), {products(:).ProductNumber}, 'UniformOutput',false);
        end

    end

    methods (Static, Access = 'private')
        %-----------------------------------
        %   matlab.depfun.internal.DependencyFormatter class private methods
        %-----------------------------------

        function  [depfileslist, products] = getAllRequiredFilesAndProducts(filesList, varargin)
            [depfileslist, products] = matlab.codetools.requiredFilesAndProducts(filesList, varargin{:});
        end

        %returns all the dependencies that are not within the toolbox folder
        function [allExternalDependencies] = findExternalDependencies(allFiles, toolboxRoot)
            isInToolbox = matlab.depfun.internal.DependencyFormatter.areFilesInToolbox(allFiles, toolboxRoot);
            allExternalDependencies=allFiles(~cell2mat(isInToolbox));
        end
        
        %returns logical cell array denoting whether or not the file in the
        %corresponding location in the input cell array is in the specified
        %toolbox folder
        function [isInToolbox] = areFilesInToolbox(files, toolboxRoot)
            %windows platforms are case insensitive for file/folder names
            comparisonFunction=@strncmp;
            if(ispc)
                comparisonFunction=@strncmpi;
            end
            %find all the files that do not have the toolbox folder root in
            %the beggining of their path
            isInToolbox=cellfun(@(x) comparisonFunction(x,toolboxRoot,numel(toolboxRoot)), files, 'UniformOutput',false);
        end
        
        %Find all files, products, and platforms on which the input is dependent
        function [depfileslist, products, platforms] = findDependencies(filesToAnalyze)
            [dependentfiles, depproducts, ~] = matlab.depfun.internal.requirements(filesToAnalyze, 'MATLAB');
            if(~isempty(dependentfiles))
                depfileslist = {dependentfiles(:).path};
            else
                depfileslist = {};
            end
            if(~isempty(depproducts.products))
                depproductname = cellfun(@(x) char(x), {depproducts.products(:).Name}, 'UniformOutput',false);
                depproductversion = cellfun(@(x) char(x), {depproducts.products(:).Version}, 'UniformOutput',false);
                depproductnumber = cellfun(@(x) mat2str(x), {depproducts.products(:).ProductNumber}, 'UniformOutput',false);
                platforms = depproducts.platforms;
            else
                depproductname = {};
                depproductversion = {};
                depproductnumber = {};
                platforms = {};
            end
            products = struct('Name', depproductname, 'Version', depproductversion, 'Number', depproductnumber);
        end

        %The function looks into all the input directories and
        %returns the examples in the form of structs:
        %example = (html file, m file, thumbnail image, other images
        function [categories, demosFileHadError, demosFileWasAutoGenerated] = findCategorizedExamples(allFolders, demosFile, demosHeader)
            %default value for error flags
            demosFileHadError = struct('FormatError', false, 'FileNotFoundError', false);
            demosFileWasAutoGenerated = false;
            if(~isempty(demosFile))
                %if there is a demos file, then read exampels and categorize them based on the data in the demos file
                [categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles, demosFileHadError, demosFileWasAutoGenerated] = ...
                    matlab.depfun.internal.DependencyFormatter.parseExamplesFromDemosFile(demosFile, demosFileHadError, demosHeader);
                %if the demos.xml contains the demos header string, then
                %skip over it and scan the file system instead
            end
            
            if(isempty(demosFile) || demosFileWasAutoGenerated || demosFileHadError.FormatError || demosFileHadError.FileNotFoundError)
                %if there is no demos file, or if the demos.xml was autogenerated, or if the demos.xml was invalid for some reason
                %search the toolbox on the file system for example files
                [categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles]=matlab.depfun.internal.DependencyFormatter.searchToolboxForExamples(allFolders);
            end
            categories=matlab.depfun.internal.DependencyFormatter.categorizeExamples(categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles);
        end
        
        %this function parses the input demos.xml file and returns lists of
        %examples info and the category to which each one belongs
        function [categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles, demosFileHadError, demosFileWasAutoGenerated] = ...
                parseExamplesFromDemosFile( demosFile, demosFileHadError, demosHeader)
            [relativeRoot,~,~] = fileparts(demosFile);
            %the output info will be appended to in the loops below
            categoriesPerExample = {};
            exampleNames = {};
            MATLABFiles = {};
            HTMLFiles = {};
            demosFileWasAutoGenerated = false;
            
            %a java fatal error cannot be caught. We will temporarily write
            %errors elswhere
            oldJavaError = java.lang.System.err;
            newJavaError = java.io.PrintStream(java.io.ByteArrayOutputStream());
            java.lang.System.setErr(newJavaError);
            %lastly, the system will return errors to the original location
            finishup = onCleanup(@() java.lang.System.setErr(oldJavaError));
            
            
            %read in the document and prepare to parse it
            try
                dom = xmlread(demosFile);
                demos = dom.getElementsByTagName('demos').item(0);
                demosFileWasAutoGenerated = matlab.depfun.internal.DependencyFormatter.isDemosFileAutogenerated(demos, demosHeader);
                
                %if the demos file can be skipped, don't bother to read it;
                if (demosFileWasAutoGenerated)
                   return; 
                end
                
                demoSections = demos.getElementsByTagName('demosection');
                numDemoSections=demoSections.getLength;
                for n=0:numDemoSections-1
                    category = demoSections.item(n);
                    categoryName = char(category.getElementsByTagName('label').item(0).getTextContent);
                    demoItems=category.getElementsByTagName('demoitem');
                    [categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, demosFileHadError] = ...
                        matlab.depfun.internal.DependencyFormatter.parseDemoItemsFromContainer ...
                        (demoItems, categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, categoryName, relativeRoot, demosFileHadError);
                end
                %get uncategorized examples
                demosChildren = demos.getChildNodes;%this is fine as long as the type is validated as 'demoitem' later
                %demoItems=demos.getElementsByTagName('demoitem');
                defaultCategoryTitle = message('MATLAB:depfun:req:DefaultCategoryTitle').getString();
                [categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, demosFileHadError] =  matlab.depfun.internal.DependencyFormatter.parseDemoItemsFromContainer...
                    (demosChildren, categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, defaultCategoryTitle, relativeRoot, demosFileHadError);
                
            catch e
                %silently catch any errors when reading the xml document
                disp('Caught error while parsing demo''s.xml');
                demosFileHadError.FormatError = true;
            end
        end
        
        function [isAutoGenerated] = isDemosFileAutogenerated(demos, demosHeader)
            try
                headerString = demos.getChildNodes.item(0).getNodeValue;
                isAutoGenerated = any(strcmp(headerString, demosHeader));
            catch e
                isAutoGenerated = false;
            end
        end
        
        %reads demoitems from demosections or uncategorized demoitems.
        %Returns a list of all the example HTML/MATLAB files that seem
        %valid.
        function [categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, demosFileHadError] = ...
                parseDemoItemsFromContainer(demoItems, categoriesPerExample, exampleNames, HTMLFiles, MATLABFiles, categoryName, relativeRoot, demosFileHadError)
            %get examples (demoitems) for this category and append it to
            %the rest of the data found for any previous categories
            [exNames, exHTMLFiles, exMATLABFiles, exCategoryNames, demosFileHadError] =  ...
                matlab.depfun.internal.DependencyFormatter.parseExamplesFromDemoItems(demoItems, categoryName, relativeRoot, demosFileHadError);
            categoriesPerExample = [categoriesPerExample exCategoryNames];
            exampleNames = [exampleNames   exNames];
            HTMLFiles = [HTMLFiles  exHTMLFiles];
            MATLABFiles = [MATLABFiles exMATLABFiles];
        end
        
        %looks at each demo item, the way the information is parsed depends
        %on the demoitem's type.
        function [exampleNames, HTMLFiles, MATLABFiles, categoryNames, demosFileHadError] = ...
                parseExamplesFromDemoItems(demoItems, categoryName, relativeRoot, demosFileHadError)
            numDemoItems = demoItems.getLength;
            categoryNames = {};
            exampleNames = {};
            MATLABFiles = {};
            HTMLFiles = {};
            if(numDemoItems>0)
                for m=0:numDemoItems-1%easier to read xml parsing in a loop and not a cellfun/arrayfun
                    try
                        demoItem = demoItems.item(m);
                        if(strcmp(demoItem.getNodeName,'demoitem'))%dbl check that the node is a demo item
                            nameOfExample = char(demoItem.getElementsByTagName('label').item(0).getTextContent);
                            %there may or may not be an M file <source>
                            MATLABFile = matlab.depfun.internal.DependencyFormatter.readTagsForMATLABFile( demoItem);
                            
                            try
                                demoItemType = char(demoItem.getElementsByTagName('type').item(0).getTextContent);
                            catch e
                                %if there is no type tag just make it an
                                %empty string
                                demoItemType = '';
                            end
                            try
                                HTMLFile = matlab.depfun.internal.DependencyFormatter.formatParsedHTMLFile(demoItem, relativeRoot);
                            catch e
                                %if there was no html file, just skip
                                %over it. It is not needed.
                                
                                HTMLFile = '';
                                %however, if is a published example
                                %look for the accompanying html file
                                if (~isempty(MATLABFile) && ~isempty(demoItemType) && any(regexp(demoItemType,'^M-file$')))
                                    [path,name,~] = fileparts(MATLABFile);
                                        potentialCorrespondingHTMLFile = fullfile(path,'html',[name '.html']);
                                        if(exist(potentialCorrespondingHTMLFile,'file'))
                                            HTMLFile = potentialCorrespondingHTMLFile;
                                        end
                                    end
                                end
                                [categoryNames, exampleNames, HTMLFiles, MATLABFiles, fileNotFoundError] =  matlab.depfun.internal.DependencyFormatter.addExampleToLists ...
                                    (categoryName, nameOfExample, HTMLFile, MATLABFile, categoryNames, exampleNames, HTMLFiles, MATLABFiles, demosFileHadError.FileNotFoundError);
                                demosFileHadError.FileNotFoundError = fileNotFoundError;
                            %end
                        end
                    catch e
                        %may have been missing label, type, source or file
                        disp('parse examples from demos.xml failed');
                        demosFileHadError.FormatError = true;
                    end
                end
            end
        end
        
        %parse out the MATLAB File Location from the demos.xml. Format it to
        %be an absolute path and give it an extension
        function [MATLABFile] = readTagsForMATLABFile( demoItem)
            try
                %if there is a source tag use the name o the file described
                %in the source tag
                name = char(demoItem.getElementsByTagName('source').item(0).getTextContent);
                MATLABFile = which([name '.m']);
            catch e
                %swallow error
                %if there is no tag, the matlab file will just be a blank
                %string
                %disp('Caught some error: line 288');
                MATLABFile = '';
            end
            %if the source file doesn't exist just return a blank string
            %             if(~exist(MATLABFile,'file'))
            %                 MATLABFile = '';
            %             end
        end
        
        %parse out the HTML File Location from the demos.xml. Format it to
        %be an absolute path and give it an extension
        function [HTMLFile] = formatParsedHTMLFile(demoItem, relativeRoot)
            HTMLFile = matlab.depfun.internal.DependencyFormatter.formatParsedFileLocation(demoItem, relativeRoot, '.html','file');
        end
        
        %parse out a File Location from the demos.xml.Format it to
        %be an absolute path and give it an extension
        function [ParsedFile] = formatParsedFileLocation(demoItem, relativeRoot, fileExt, tag)
                ParsedFile = char(demoItem.getElementsByTagName(tag).item(0).getTextContent);
                ParsedFile = fullfile(relativeRoot, ParsedFile);
                [path,name,~] = fileparts(ParsedFile);
                ParsedFile = fullfile(path,[name fileExt]);%ensure proper extension
        end 
        
        %check that the MATLAB and HTML File exist and add them to the
        %input structures if they do exist
        function [categoryNames, exampleNames, HTMLFiles, MATLABFiles, fileNotFoundError] = ...
                addExampleToLists(categoryName, nameOfExample, HTMLFile, MATLABFile, categoryNames, exampleNames, HTMLFiles, MATLABFiles, fileNotFoundError)
            %only use the example if its files exist
            %relative to the toolbox root
            %only add the example if either the the html or source are non
            %empty and exist -- otherwise nothing to display in the UI??
            %if ((~isempty(HTMLFile) && exist(HTMLFile,'file')) || (~isempty(MATLABFile) && exist(MATLABFile,'file'))) 
            categoryNames = [categoryNames categoryName];
            exampleNames = [exampleNames   {nameOfExample}];
            HTMLFiles = [HTMLFiles  {HTMLFile}];
            MATLABFiles = [MATLABFiles {MATLABFile}];
            %do not error out if the html file does not exist though
            %end
        end
        
        %The function looks into all the input directories and
        %returns the examples in the form of structs:
        %example = (name, html file, m file, thumbnail image, other images
        %this function (similar to DemosReader), finds the first three fields
        function [categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles] = searchToolboxForExamples(allFolders)
            %Do a BFS to collect all the m files
            AllMATLABFiles = matlab.depfun.internal.DependencyFormatter.findAllMATLABFiles(allFolders);
            %filter out dot files
            AllMATLABFiles = matlab.depfun.internal.DependencyFormatter.filterOutDotFiles(AllMATLABFiles,'(?:m|mlx)');
            [paths, names, ~] = cellfun(@(x) fileparts(x), AllMATLABFiles, 'UniformOutput', false);
            
            %check each executable file for an html directory at the same level
            AllHtmlFolders = cellfun(@(x) (fullfile(x,'html')),paths,'UniformOutput',false);
            HTMLFolderExistsIndices = cellfun(@(x) any(exist(fullfile(x,'html'),'dir')),paths);
            
            %separate m files to be checked for a matching html file
            AllHtmlFolders = AllHtmlFolders(HTMLFolderExistsIndices);
            MATLABFileNamesToAnalyze = names(HTMLFolderExistsIndices);
            MATLABFileToAnalyze = AllMATLABFiles(HTMLFolderExistsIndices);
            
            %create names of html files and check if they exist
            MatchingHTMLFileNames = arrayfun(@(x) fullfile(AllHtmlFolders{x},[MATLABFileNamesToAnalyze{x} '.html']), ...
                (1:size(AllHtmlFolders,2)),'UniformOutput', false);
            HTMLFileExistsIndices = cellfun(@(x) any(exist(fullfile(x),'file')),MatchingHTMLFileNames);
            
            %the returned html and m files
            MATLABFiles = MATLABFileToAnalyze(HTMLFileExistsIndices);
            HTMLFiles = MatchingHTMLFileNames(HTMLFileExistsIndices);
            
            %find the category names by looking at each example's parent
            %folder name
            [parentFolders, exampleNames,~]  = cellfun(@(x) fileparts(x),MATLABFiles,'UniformOutput',0);
            [~, categoriesPerExample,~]  = cellfun(@(x) fileparts(x),parentFolders,'UniformOutput',0);
        end
        
        %given information about each example
        %find any thumbnails or image arrays associated with those examples
        %assign found images to the image array and thumbnail field
        %then put the examples into structs, and create category structs
        function [categoriesAsLists] = categorizeExamples(categoriesPerExample, exampleNames, MATLABFiles, HTMLFiles)
            %create list for thumbnail images
            numberOfExamples=size(MATLABFiles,2);
            thumbnailsList = repmat(cellstr(''),1,numberOfExamples);
            
            %determine if thumbnail images exist
            [paths, name, ~] = cellfun(@(x) fileparts(x), HTMLFiles, 'UniformOutput', false);
            ThumbnailNames = arrayfun(@(x) fullfile(paths{x}, [name{x} '.png']), ...
                (1:numberOfExamples),'UniformOutput',false);
            ThumbnailExistsIndices = cellfun(@(x) any(exist(x,'file')),ThumbnailNames);
            thumbnailsList(ThumbnailExistsIndices) = ThumbnailNames(ThumbnailExistsIndices);
            
            
            %create list for all other images
            [AllUsedHTMLFolders,~,~] = cellfun(@(x) fileparts(x),HTMLFiles,'UniformOutput',0);
            allImages = arrayfun(@(x) dir(fullfile(AllUsedHTMLFolders{x},[name{x} '_*.png'])), ...
                (1:numberOfExamples),'UniformOutput',false);
            
            %returned images must end with: '_', a number, then extension
            matchExpressionFunction=@(index) (cellfun(@(x) any(regexp(x,'_[\d]+.png$')), {allImages{index}.name}));
            doesMatchExpression=arrayfun(@(x) matchExpressionFunction(x),(1:numberOfExamples),'UniformOutput',false);
            structToCellOfImageNames=cellfun(@(x) {x.name},allImages,'UniformOutput',false);
            imageArray = arrayfun(@(x) fullfile(AllUsedHTMLFolders{x},structToCellOfImageNames{x}(doesMatchExpression{x})), ...
                (1:numberOfExamples),'UniformOutput', false);
            
            %put the examples into structs, and lists of examples
            %into categories
            categoryNames = unique(categoriesPerExample);
            numCategories = numel(categoryNames);
            %logical arrays to denote which examples belong to a category
            Ex2Cat=(cellfun(@(x) strcmp(x,categoriesPerExample),categoryNames,'UniformOutput',0));
            
%             the following code returns the categories & examples in structs
%             right now it is clearest to use just cell arrays because they
%             do not contain the field names when returned to Java.
%                         %create a list of example structures per category
%                         exampleGroups = arrayfun(@(x) ...
%                             struct('Name', exampleNames(Ex2Cat{x}), 'HTMLFile', HTMLFiles(Ex2Cat{x}),'MATLABFile', MATLABFiles(Ex2Cat{x}), 'Thumbnail', thumbnailsList(Ex2Cat{x}), 'Images', imageArray(Ex2Cat{x})), ...
%                             (1:numCategories), 'UniformOutput',false);
%                         %create a struct per category and insert the examples list
%                         categoriesAsStructs = arrayfun(@(x) struct('Name', categoryNames{x}, 'ExamplesList', exampleGroups{x}),(1:numCategories),'UniformOutput',0);
            
            %put the examples and categories into a list structure suitable
            %for java
            individualExamples = arrayfun(@(x) {exampleNames(x)  HTMLFiles(x)  MATLABFiles(x)  thumbnailsList(x)  imageArray(x)}, ...
                (1:numberOfExamples), 'UniformOutput',false);
            exampleGroupsList =  arrayfun(@(x)  individualExamples(Ex2Cat{x}), (1:numCategories), 'UniformOutput',false);
            categoriesAsLists = arrayfun(@(x) {categoryNames{x}  exampleGroupsList{x}},(1:numCategories),'UniformOutput',0);
        end
        
        %The function looks into all the input directories and returns a
        %neatly formatted list of all the m file locations within them
        function [allMATLABFiles] = findAllMATLABFiles(allFolders)
            MATLABFiles = cellfun(@(x) [dir(fullfile(x,'*.m')); dir(fullfile(x,'*.mlx'))],allFolders,'UniformOutput',false);
            allMNames = cellfun(@(x) {x.name},MATLABFiles,'UniformOutput', false);
            indices=cell2mat(cellfun(@(x) ~isempty(x),allMNames,'UniformOutput',0));
            mPaths=cellfun(@(x,y) matlab.depfun.internal.DependencyFormatter.getFullPaths(x,y), allFolders(indices),allMNames(indices),'Uniform',0);
            allMATLABFiles=[mPaths{:}];
            if(isempty(allMATLABFiles))
                allMATLABFiles=cellfun(@num2str, num2cell(allMATLABFiles), 'UniformOutput', false);%empty cells must be converted to strings to be read by java
            end
        end
        
        %Returns a neatly formatted list of '*.mlapp' and *.mlappinstall' 
        %files contained within the input folders.
        function [appsList]= findApps(allFolders)
            %ext_filter='mlappinstall';
            %getAllApps=@(x) dir(fullfile(x, ['*.' ext_filter]));
            getAllApps=@(x) [dir(fullfile(x,'*.mlapp')); dir(fullfile(x,'*.mlappinstall'))];
            allApps = cellfun(@(x) getAllApps(x), allFolders,'UniformOutput',false);
            indices=cell2mat(cellfun(@(x) ~isempty(x),allApps,'UniformOutput',0));
            appPaths=cellfun(@(x,y) matlab.depfun.internal.DependencyFormatter.getFullPaths(x,{y(:).name}), allFolders(indices),allApps(indices),'Uniform',0);
            appsList=[appPaths{:}];
            if(isempty(appsList))
                appsList=cellfun(@num2str, num2cell(appsList), 'UniformOutput', false);%empty cells must be converted to strings to be read by java
            end
            %remove dot files from the list
            appsList = matlab.depfun.internal.DependencyFormatter.filterOutDotFiles(appsList,'(?:mlapp|mlappinstall)');
        end
        
        function [allFullPaths] = getFullPaths(path,names)
            allFullPaths = cellfun(@(x) fullfile(path,x),names,'UniformOutput',0);
        end
        
        %looks into all the input folders and returns the first 'info.xml'
        %that it finds. The input should be in BFS order if you would like
        %the algorithm to favor the topmost instance of the file.
        function [docFile]= findDocumentation(allFolders)
            docFile=matlab.depfun.internal.DependencyFormatter.findFile('info.xml',allFolders, true);
        end
        
        %looks into all the input folders and returns the first 'demos.xml'
        %that it finds.
        function [demosFile]= findDemosXML(allFolders)
            demosFile=matlab.depfun.internal.DependencyFormatter.findFile('demos.xml',allFolders, true);
        end
        
        %searches folders in BFS to find a file with the specified name
        function [file] = findFile(fileName, allFolders, useCaseSensitivity)
            possibleMatches = cellfun(@(x) matlab.depfun.internal.DependencyFormatter.searchForFileByNameAndExt(x, fileName, useCaseSensitivity), allFolders, ...
                'UniformOutput' , 0);
            indices=cell2mat(cellfun(@(x) ~isempty(x),possibleMatches,'UniformOutput',0));
            file = matlab.depfun.internal.DependencyFormatter.selectFirstMatch(possibleMatches, indices);
        end
 
        function [fileMatch] = searchForFileByNameAndExt(folderLocation, fileName, caseSensitiveOnName)
            [~, ~, ext] = fileparts(fileName);
            %possible to be case sensitive on the name (but not the
            %extension-- doc center ppl said to use lowercase for xml)
            %dir() returns the actual cases of the names if you do not
            %specify the name in the regex--it will return whatever you
            %specify for ext though--which is always lowercase in this
            %class
            comparisonFunction=@strcmp;
            if(~caseSensitiveOnName)
                comparisonFunction=@strcmpi;
            end
            contentsOfFolderByExt = dir(fullfile(folderLocation,strcat('*',ext)));
            matchesbyName = cellfun(@(x) comparisonFunction(x,fileName),{contentsOfFolderByExt(:).name},'UniformOutput',false);
            fileMatch = matlab.depfun.internal.DependencyFormatter.selectFirstMatch({contentsOfFolderByExt(:).name}, [matchesbyName{:}]);
            if(~isempty(fileMatch))
                fileMatch = fullfile(folderLocation, fileMatch);
            else
                fileMatch = '';
            end
        end
        
        %function that returns the first result of a cell array or returns
        %'' (blanks string. This is useful if you know the returned values
        %are either 0 or 1 in quantity or if you just want the first result
        %for BFS reasons.
        function [firstResult] = selectFirstMatch(allItems, matchedItemIndices)
            if (~isempty(allItems))
                pathIndex=find(matchedItemIndices,1,'first');
                if(~isempty(pathIndex))
                    firstResult = allItems{pathIndex};
                else
                    firstResult = '';
                end
            else
                firstResult = '';
            end
        end
        
        %returns a list of subdirectories found recursively from the root
        %input folder. The Subdirectories will be returned in BFS order.
        function BFSSubDirectories = findSubdirectoriesByBFS(rootFolder)
            subfoldersToSearch = {rootFolder};
            subfolderCollection = {rootFolder};
            while(numel(subfoldersToSearch)>0)
                %add all subfolders to the output list
                temp_subdirs=matlab.depfun.internal.DependencyFormatter.subdirectories(subfoldersToSearch{1});
                subfolderCollection = [subfolderCollection; temp_subdirs];
                %add all subfolders to be checked for further subfolders
                subfoldersToSearch(1)=[];
                subfoldersToSearch = [subfoldersToSearch; temp_subdirs];
            end
            BFSSubDirectories=subfolderCollection;
        end
        
        %Returns a list of all the directories within a folder. This
        %function is not recursive.
        function subDirectories = subdirectories(folderName)
            allDirectories = dir(folderName);
            isub = [allDirectories(:).isdir];
            subDirectories = {allDirectories(isub).name}';
            subDirectories(ismember(subDirectories,{'.','..'})) = [];
            subDirectories = cellfun(@(x) fullfile(folderName, x), subDirectories, 'UniformOutput',false);
        end
        
        % Returns the list of files and support packages on which the input
        % files are dependent.
        function [depfileslist, depsupportpackagelist]=findFilesAndSupportPackages (allInputs)
            warnstatus = warning('OFF','MATLAB:depfun:req:AllInputsExcluded');
            restoreWarnState = onCleanup(@()warning(warnstatus));
            
            % Convert JAVA String vector to MATLAB cell array
            mcc_settings.source_file = cell(allInputs{1});    % files to analyze (resources and entrypoints)
            mcc_settings.dash_p      = cell(allInputs{2});    % -p
            mcc_settings.dash_I      = cell(allInputs{3});    % -a
            mcc_settings.dash_a      = cell(allInputs{4});    % -I
            mcc_settings.dash_N      = logical(allInputs{5}); % -N

            [parts, resources] = matlab.depfun.internal.deploytool_call_requirements(mcc_settings);
            
            depfileslist = {};
            if ~isempty(parts)
                depfileslist = {parts.path};
            end
            
            % Check possibly required support packages.
            depproductlist = {};
            if ~isempty(resources) && ~isempty(resources.products)
                depproductlist = {resources.products.Name};
            end
            depsupportpackagelist = matlab.depfun.internal.DependencyFormatter.findSupportPackages(depfileslist, depproductlist);
        end
        
        %gets support packages without running required files and products
        function [supportpackagelist]=findSupportPackages(depfilelist, depproductlist)

            % for storing the topOnly results so we only call it once
            topOnlyResults = {};

            supportpackagelist = {};

            % Get the list of deployable support packages
            deployableSupportPkgs = matlab.depfun.internal.DeployableSupportPackages;
            pkgs = deployableSupportPkgs.getSupportPackageList();


            % For each support package see if it's used by the files or products
            pkgCnt = length(pkgs);
            includedPkg = 1;

            for pkgItr=1:pkgCnt
                if(isempty(topOnlyResults)) % only call toponly once
                    topOnlyResults = matlab.depfun.internal.DependencyFormatter.getTopOnlyResults(depfilelist);
                end
                dependentFlag = pkgs{pkgItr}.filesOrProductsUseSupportPackage(topOnlyResults, depproductlist);

                % additions to check for 3rd party dependencies
                tpInstalls = length(pkgs{pkgItr}.thirdPartyName);

                tpData = {};
                % if there are find the name, url and download url for each one
                for tpI = 1:tpInstalls
                  tpData(tpI, :) = {pkgs{pkgItr}.thirdPartyName{tpI} pkgs{pkgItr}.thirdPartyURL{tpI} ''};

                end

                % only return the support package if the flag is set to true
                if(dependentFlag)
                    supportpackagelist(includedPkg,:) = { pkgs{pkgItr}.name pkgs{pkgItr}.displayName pkgs{pkgItr}.baseProduct 'true' tpInstalls tpData};
                    includedPkg = includedPkg + 1;
                end
            end
        end
        
        function topOnlyResults = getTopOnlyResults(depfilelist)
    
            % turn off the "no mcode" warnings
             warnstatus = warning('OFF','MATLAB:depfun:req:NoCorrespondingMCode');
                    restoreWarnState = onCleanup(@()warning(warnstatus));

            p = matlab.depfun.internal.Completion(depfilelist, matlab.depfun.internal.Target.All, true);

            pParts = p.parts;

            fileCnt = length(pParts);
            topOnlyResults = cell(1, fileCnt);
            for fileItr = 1:fileCnt
                topOnlyResults{fileItr} = pParts(fileItr).path;
            end

        end

        
        %pass in an extension eg 'm' or 'mlappinstall' (WITHOUT the .) and 
        %receive the regex to determine if files of that extension do not 
        %have names preceded by a '.'  The input 'ext' should be the 
        %extension without the dot, can also be a regex group covering 
        %multiple extensions, e.g. (?:m|mlx).
        function [regexNonDot] = nonDotFileWithExtRegexp(ext)
            % This regex will observe file separators on Windows and
            % UNIX/Mac.
            regexNonDot = ['[/\\][^.][^/\\]*\.' ext '$'];
        end
        
        %Filters out files whose name begins with a '.' from the input cell
        %array 'fileCells'. This is useful from removing dot files that may
        %appear to be apps or published examples, but are invalid for those
        %purposes. The input 'ext' should be the extension without the dot,
        %can also be a regex group covering multiple extensions, e.g. 
        %(?:m|mlx).
        function [filteredCellArray] = filterOutDotFiles(fileCells, ext)
            regexpString = matlab.depfun.internal.DependencyFormatter.nonDotFileWithExtRegexp(ext);
           nonDotFileIndices = cellfun(@(x) any(regexp(x,regexpString)),fileCells,'UniformOutput',false);%dot files need to be filtered out
            filteredCellArray = fileCells(cell2mat(nonDotFileIndices)); 
        end
    end
end
