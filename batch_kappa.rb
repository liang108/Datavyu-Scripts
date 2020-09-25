# Updated 4.24.20

# Kappa function
# Collect data over batch of files, then compute kappa for all those data points

require 'Datavyu_API.rb'

begin 

    # Begin Function Definitions ------------------------------------------------------------------------------------------------------------------------

    def createConditionalArray(column, argindex, arg) # Argindex is the position of arguments in question, arg is the desired arg, eg. "OT" or "R"
        list = Array.new
        for cell in column.cells
            if (cell.argvals[argindex] == arg)
                list << cell.onset
            end
        end
        return list
    end

    def countMatchingArgsArray(array1, array2)
        count = 0
        for value in array1
            for value2 in array2
                if (value == value2)
                    count = count + 1
                end
            end
        end
        return count
    end

    def countMatchingArgsHash(hash1, hash2) # Count matching args in hash of arrays, using countMatchingArgsArray
        new_count = 0

        hash1.each do |key1, value1|
            hash2.each do |key2, value2|
                if (key1 == key2)
                    new_count = new_count + countMatchingArgsArray(value1, value2)
                end
            end
        end
        
        return new_count
    end

    def createArgHash(column, argindex, codes) # ArgHash is used to hold the arrays of onsets, eg. an array of onsets for cells coded "Q"
        argHash = Hash.new
        argTypeArray = Array.new

        codes.each do |arg|
            argTypeArray << arg
        end

        j = codes.length
        k = 0
        for argType in codes
            testArr = createConditionalArray(column, argindex, argType)
            if (testArr.nil?)
                k = k+1
            end
        end

        if (j == k)
            argTypeArray = []
            codes.each do |arg|
                argTypeArray << arg.capitalize()
            end
        end

        i = 0
        for argType in argTypeArray
            newArr = createConditionalArray(column, argindex, argType)
            h = {codes[i] => newArr} 
            argHash = argHash.merge(h)
            i = i+1
        end

        return argHash
    end

    def countArgsHash(hash1) # To use for calculating expected chance agreement, outputs array of counts for each arg
        countArr = Array.new(hash1.length)
        i = 0
        for arr in hash1.values
            countArr[i] = arr.count
            i = i+1
        end
        return countArr
    end  

    def compute_p_exp(array1, array2, totargcount) # Given two arrays of counts of arguments, calculated expected agreement, input scellsavg as totargcount
        if (array1.length != array2.length)
            puts "Error in computing expected agreement"
        end
        
        i = 0

        exp_prob_arr = Array.new(array1.length, 0)

        for argcount in array1
            exp_prob_arr[i] = (array1[i].to_f/totargcount.to_f) * (array2[i].to_f/totargcount.to_f)
            i = i+1
        end

        p_exp = 0.0

        for prob in exp_prob_arr
            p_exp = p_exp + prob
        end

        return p_exp

    end
        

    def compute_kappa_sl(argindex, codes, directory) # Parameters: codes should be a list of argvals, and file directory

        # USE "codes" as an array parameter to determine arg list !!

        scells = 0
        s2cells = 0
        matchArgs = 0  

        filenames = Dir.new(directory).entries
        $db,pj = load_db(directory + "/" + filenames.last)

        slcol = getColumn("speaker_listener")

        #unless slcol.arglist[argindex].include? '/'
        #    puts slcol.arglist[argindex]
        #    raise "Fix " + filenames.last.to_s + " argument list in code editor"
        #end

        #typeStr = slcol.arglist[argindex].split('/')
        #typeStr.each do |type|
        #    typeArr << type
        #end
        
        totCountArr1 = Array.new(codes.length, 0)     
        totCountArr2 = Array.new(codes.length, 0)

        for file in filenames
            if (file.include?(".opf")) and file[0].chr != '.'

                $db,$pj = load_db(directory + "/" + file)
                puts file.to_s
                #puts "\nLoading " + file.to_s + "...\n"

                # Use correct number of speaker cells depending on argument of interest

                slcol = getColumn("speaker_listener")
                slcol2 = getColumn("speaker_listener_2")

                for cell in slcol.cells
                    if (argindex != 0)
                        if (cell.argvals[0] == "S")
                            if (argindex == 1)
                                if (cell.argvals[1] != ".") and (cell.argvals[2] != ".")
                                    scells = scells + 1
                                end
                            end
                            if (argindex == 2)
                                if (cell.argvals[2] != ".")
                                    scells = scells + 1
                                end
                            end
                        end
                    else
                        scells += 1
                    end
                end
            
                for cell in slcol2.cells
                    if (argindex != 0)
                        if (cell.argvals[0] == "S")
                            if (argindex == 0)
                                s2cells += 1
                            end
                            if (argindex == 1)
                                if (cell.argvals[1] != ".") and (cell.argvals[2] != ".")
                                    s2cells = scells + 1
                                end
                            end
                            if (argindex == 2)
                                if (cell.argvals[2] != ".")
                                    s2cells = scells + 1
                                end
                            end
                        end
                    else
                        s2cells += 1
                    end
                end

                newHash1 = createArgHash(slcol, argindex, codes)   # Hash of arrays for arguments of primary column
                newHash2 = createArgHash(slcol2, argindex, codes)  # Hash of arrays for arguments of reliability column

                matchArgs = matchArgs + countMatchingArgsHash(newHash1, newHash2)

                countArr1 = countArgsHash(newHash1)
                countArr2 = countArgsHash(newHash2)

                # Tally each argument by adding elements of countArrays

                totCountArr1 = [totCountArr1, countArr1].transpose.map {|x| x.reduce(:+)}
                totCountArr2 = [totCountArr2, countArr2].transpose.map {|x| x.reduce(:+)}
            end
        end
    
        scellsavg = (scells + s2cells)/2    # correct for inconsistent arg count

        p_obs = (matchArgs/scellsavg.to_f) 
        p_exp = compute_p_exp(totCountArr1 , totCountArr2, scellsavg)

        kappa = (p_obs - p_exp)/(1 - p_exp)

        puts "\n"
        puts argindex.to_s
        puts "Observed agreement: " + p_obs.to_s 
        puts "Expected agreement: " + p_exp.to_s
        puts "Kappa: " + kappa.to_s

    end


    # Function call

    filedir = File.expand_path("~/Desktop/BatchFolder/") # Locate files and put in folder on desktop
    compute_kappa_sl(0, ["S", "L"], filedir) # IN ORDER TO DO THIS, NEED TO CHANGE SCELLSAVG TO COUNT LISTENING CELLS TOO
    #compute_kappa_sl(1, ["OT", "OFFT"], filedir)   #1 refers to otofft codes
    #compute_kappa_sl(2, ["Q","R","F"], filedir)    #2 refers to qrf codes

end