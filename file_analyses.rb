# Updated 4.24.20

require "Datavyu_API.rb"
require "csv"

# Batch operation: Analyses on multiple files, outputs to csv file called "Batch Analyses"

begin
    # Begin Function Definitions ------------------------------------------------------------------------------------------------------------------------

    def createCellArray(column, list)
        for cell in column.cells
            list << [cell.onset, cell.offset]
        end
    end
    
    def sumCellsColumn(column)
        sum = 0.0
        for cell in column.cells
            sum = sum + (cell.offset - cell.onset)
        end
        return sum
    end

    def sumCellsArray(list)
        sum = 0.0
        for cell in list
            sum = sum + (cell[1] - cell[0])
        end
        return sum
    end

    # End Function Definitions --------------------------------------------------------------------------------------------------------------------------

    # File Loading --------------------------------------------------------------------------------------------------------------------------------------

    #out_file = File.expand_path("~/Desktop/AnalysesOutput.txt/") # C:\Users\jhlia\Desktop\AnalysesOutput
    #out = File.new(out_file, 'w') 
            
        # Begin Column Collection ---------------------------------------------------------------------------------------------------------------------------

            slCol = getColumn("speaker_listener")
            peerCol = getColumn("peer")
            partCol = getColumn("participant")
            ecCol = getColumn("eye_contact")
            greetingColumn = getColumn("greeting")

            if (greetingColumn == nil)
                greetingColumn = getColumn("greeting_goodbye")
            end

        # End Column Collection -----------------------------------------------------------------------------------------------------------------------------

        # Begin Conversation Duration -----------------------------------------------------------------------------------------------------------------------

            offsets = Array.new
            cols = get_column_list()
            
            for col in cols
                curr = getColumn(col)
                if curr.cells.last == nil
                    next
                end
                offsets << curr.cells.last.offset
            end

            convoDur = offsets.max

        # End Conversation Duration ------------------------------------------------------------------------------------------------------------------------

        # Begin Sum of Participant and Peer Durations ------------------------------------------------------------------------------------------------------

            peerTimes = Array.new
            partTimes = Array.new
            peerDur = 0.0
            partDur = 0.0
        
            createCellArray(peerCol, peerTimes)
            createCellArray(partCol, partTimes)

            peerDur = sumCellsArray(peerTimes)
            partDur = sumCellsArray(partTimes)

            totalSpeakingDur = peerDur + partDur

        # End Sum of Peer and Participant Speaking Durations ------------------------------------------------------------------------------------------------

        # Begin Amount of time participant is on-topic relative to their own speaking duration --------------------------------------------------------------

            slOTtimes = Array.new
            slOFFTtimes = Array.new

            for cell in slCol.cells
                if (cell.argvals[1] == "OT")
                    slOTtimes << [cell.onset, cell.offset]
                end
            
                if (cell.argvals[1] == "OFFT")
                    slOFFTtimes << [cell.onset, cell.offset]
                end
            end

            participantOT = 0.0
            participantOFFT = 0.0

            for times in partTimes
                for range in slOTtimes
                    if (times[0] >= range[0]) and (times[1] <= range[1])
                        participantOT = participantOT + (times[1] - times[0])
                    end
                end

                for range in slOFFTtimes
                    if (times[0] >= range[0]) and (times[1] <= range[1])
                        participantOFFT = participantOFFT + (times[1] - times[0])
                    end
                end
            end
            

        # End Amount of time participant is on-topic relative to their own speaking duration ----------------------------------------------------------------

        # Begin Questions and Responses ---------------------------------------------------------------------------------------------------------------------

            total_qs = 0
            ot_qs = 0
            offt_qs = 0
            total_rs = 0
            ot_rs = 0
            offt_rs = 0

            for cell in slCol.cells
                if (cell.argvals[1] == "OT" and cell.argvals[2] == "Q")
                    ot_qs = ot_qs + 1
                    total_qs = total_qs + 1
                end
                if (cell.argvals[1] == "OFFT" and cell.argvals[2] == "Q")
                    offt_qs = offt_qs + 1
                    total_qs = total_qs + 1
                end
                if (cell.argvals[1] == "OT" and cell.argvals[2] == "R") 
                    ot_rs = ot_rs + 1
                    total_rs = total_rs + 1
                end
                if (cell.argvals[1] == "OFFT" and cell.argvals[2] == "R") 
                    offt_rs = offt_rs + 1
                    total_rs = total_rs + 1
                end
            end

        # End Questions and Responses -----------------------------------------------------------------------------------------------------------------------

        # Begin eye_contact durations -----------------------------------------------------------------------------------------------------------------------

            ecDur = sumCellsColumn(ecCol)

        # End eye_contact durations -------------------------------------------------------------------------------------------------------------------------

        # Begin Participant Listening -----------------------------------------------------------------------------------------------------------------------

            part_listening = 0.0
            count_listen = 0

            for cell in slCol.cells
                if (cell.argvals[0] == "L" or cell.argvals[0] == "l")
                    part_listening = part_listening + (cell.offset - cell.onset)
                    count_listen = count_listen + 1
                end
            end

        # End Participant Listening -------------------------------------------------------------------------------------------------------------------------

        # Begin Fillers Count -------------------------------------------------------------------------------------------------------------------------------

            countFiller = 0

            for cell in slCol.cells
                if (cell.argvals[2] == "F")
                    countFiller = countFiller + 1
                end
            end

        # End Fillers Count ---------------------------------------------------------------------------------------------------------------------------------

        # Begin Greeting Boolean ----------------------------------------------------------------------------------------------------------------------------

            # Exclude goodbyes

            greetingBoolean = 0

            for cell in greetingColumn.cells
                if (cell.argvals[0] == "G") and (cell.onset < 60000)
                    greetingBoolean = 1
                end
            end

        # End Greeting Boolean ------------------------------------------------------------------------------------------------------------------------------

        # Console Output

        puts "\nConversation duration: " + (convoDur/1000.0).to_s + " seconds\n"
        puts "Total speaking duration: " + (totalSpeakingDur/1000.0).to_s + " seconds\n"
        puts "Total peer speaking duration: " + (peerDur/1000.0).to_s + " seconds\n"
        puts "Total participant speaking duration: " + (partDur/1000.0).to_s + " seconds\n"
        puts "Percentage of time participant speaks during whole conversation: " + ((partDur/totalSpeakingDur)*100).to_s + "% \n"
        puts "Percentage of time peer speaks during whole conversation: " + ((peerDur/totalSpeakingDur)*100).to_s + "% \n\n"
        puts "Amount of time participant is on-topic: " + (participantOT/1000.0).to_s + " seconds \n"
        puts "Amount of time participant is on-topic relative to own speaking duration: " + ((participantOT/(participantOT + participantOFFT)) * 100).to_s + "% \n"
        puts "Amount of time participant is off-topic relative to own speaking duration: " + ((participantOFFT/(participantOT + participantOFFT))*100).to_s + "% \n"
        puts "\nNumber of on-topic questions: " + ot_qs.to_s + " out of " + total_qs.to_s + " total questions \n"
        puts "Number of off-topic questions: " + offt_qs.to_s + " out of " + total_qs.to_s + " total questions \n"
        puts "Percentage of on-topic questions: " + ((ot_qs.to_f/total_qs)*100).to_s + "% \n"
        puts "Percentage of off-topic questions: " + ((offt_qs.to_f/total_qs)*100).to_s + "% \n"
        puts "Number of on-topic responses: " + ot_rs.to_s + " out of " + total_rs.to_s + " total responses \n"
        puts "Number of off-topic responses: " + offt_rs.to_s + " out of " + total_rs.to_s + " total responses \n"
        puts "Percentage of on-topic responses: " + ((ot_rs.to_f/total_rs)*100).to_s + "% \n"
        puts "Percentage of off-topic responses: " +  ((offt_rs.to_f/total_rs)*100).to_s + "% \n\n"
        puts "Eye contact duration: " + (ecDur/1000).to_s + " seconds \n"
        puts "Percentage of eye contact over conversation duration: " + ((ecDur/convoDur)*100).to_s + "%\n"
        puts "Number of Listening Behaviors: " + count_listen.to_s + "\n"
        puts "Amount of time participant displays listening behaviors: " + (part_listening/1000).to_s + " seconds \n"
        puts "Percentage of time participant is listening while peer speaking: " + ((part_listening/peerDur)*100).to_s + " % \n\n"
        puts "Number of Fillers: " + countFiller.to_s + "\n\n"
        puts "Greeting? " + greetingBoolean.to_s + "\n\n"


        # Excel File Output ---------------------------------------------------------------------------------------------------------------------------------

        puts ("Excel Output: \n")
        puts (convoDur/1000.0).to_s + ", " + (totalSpeakingDur/1000.0).to_s + ", " + (peerDur/1000.0).to_s + ", " + (partDur/1000.0).to_s + ", " + (partDur/totalSpeakingDur).to_s + ", " + (peerDur/totalSpeakingDur).to_s + ", " + (participantOT/partDur).to_s + ", "  + (participantOT/participantOT + participantOFFT).to_s + ", " + (participantOFFT/partDur).to_s + ", " + ot_qs.to_s + ", " + offt_qs.to_s + ", " + (ot_qs/total_qs.to_f).to_s + ", " + (offt_qs/total_qs.to_f).to_s + ", " + ot_rs.to_s + ", " + offt_rs.to_s + ", " + (ot_rs/total_rs.to_f).to_s + ", " + (offt_rs.to_f/total_rs.to_f).to_s + ", " + (part_listening/1000).to_s + ", "  + (ecDur/1000).to_s + ", " + (ecDur/convoDur).to_s + ", " + count_listen.to_s + ", " + (part_listening/peerDur).to_s + ", " + countFiller.to_s + ", " + greetingBoolean.to_s + "\n\n"
        
        # CSV Output ----------------------------------------------------------------------------------------------------------------------------------------
end