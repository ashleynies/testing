#Author: Ashley Nies, Nya Oster & Anastasia Barnett 
#References: 
# ============================================================================
#
#   DESCRIPTION: Script for using PayloadUSAFAST.rb
#
#   Modes:
#       0 - Aliveness Check
#       1 - Functional
#       2 - Take photos 
# ============================================================================


def PayloadUSAFAST(start_time, mode, duration)
  
    begin

        # Turn up APID rates
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Turning up relative APID rates.'")
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_med_rate_active.set_apid_freq(7302, 0.025);'") # DICE
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_med_rate_active.set_apid_freq(7303, 1.0);'") # DICE_CAL
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_payload_active.set_apid_freq(322, 1.0);'") # USAFAST
        wait(1)

       # turning up 
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Turning up attitude and ephemeris APID rates to 0.2Hz.'")
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(600, 0.2);'") 
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(610, 0.2);'") 
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(611, 0.2);'") 
      
        # Power on DIAMOND MCU
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Powering on USAFA ST.'")
        cmd("MAX_FSX DICE_SET_PIN with INDEX 'USAFA_STAR_TRACKER_EN', VALUE 1")
        wait_check("MAX_FSX DICE DICE_USAFA_STAR_TRACKER_EN == 1", 60)
        #wait_check_tolerance("MAX_FSX DICE_CAL DICE_ADC_I_SNS_MCU_USAFA_STAR_TRACKER_CAL", TOLERANCE, EXPECT, 60)
        wait(1)
      
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Waiting for start time'")
        wait_expression("Time.now.to_i >= #{start_time}",3154e5) # timeout set to wait 10 year.
          
        case mode
        when 0 || 1 # Aliveness Check
            cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Beginning Mode #{mode}: Aliveness'")
            wait(30)
            cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Completed Mode #{mode}: Aliveness'")
            wait(1)
    
        when 2 #taking 5 photos and sending to GS
          cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Beginning Mode #{mode}: Take Photos'") 
          wait(1)
          
          # Take pictures
          cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Running shell script to take pictures'")
          cmd("MAX_FSX MISC_SYSTEM with STRING 'source /home/root/max/seq/sh/USAFA_ST_take_pictures.sh'")
          wait(30) #Star Tracker team says pictures are taken rapidly so 30 sec should be plenty for 10 pics
          
          not_sent_count = tlm("MAX_FSX RF_USAFA_ST_REC_FL_TLM RF_USAFA_ST_NOT_SENT_COUNT")
          if not_sent_count > 0
            cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, There are #{not_sent_count} pictures in the not_sent folder'")
          else
            cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, No pictures were taken'")
          end
          
          wait(1)
          cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Completed Mode #{mode}: Take Photo'") 
          wait(1)
        end

    rescue Exception => e
        # MUSAFAST raise an exception here to cause a non-zero exit code to move logs to anomaly
        raise "Exception during mode #{mode}: #{e.message} at #{e.backtrace}"
    
    ensure
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Beginning cleanup procedures'")
        wait(1)
  
        # Power off USAFAST
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Powering off USAFAST'")
        cmd("MAX_FSX DICE_SET_PIN with INDEX 'USAFA_STAR_TRACKER_EN', VALUE 0")
        wait_expression("tlm('MAX_FSX DICE DICE_USAFA_STAR_TRACKER_EN') == 0", 60)
        wait(1)

        # Turn down APID rates
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Turning down relative APID rates'")
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_med_rate_active.set_apid_freq(322, 0.0);'") # USAFAST
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_med_rate_active.set_apid_freq(7302, 0.0015);'") # DICE
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_med_rate_active.set_apid_freq(7303, 0.025);'") # DICE_CAL
        wait(1)  

        #add attitude and ephemeris rates set to 0.025
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Turning down attitude and ephemeris APID rates to 0.025Hz.'")
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(600, 0.025);'") 
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(610, 0.025);'") 
        cmd("MAX_FSX MISC_CONFIG_PARSE with STRING 'rec_packet_high_rate_active.set_apid_freq(611, 0.025);'") 
  
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, Completed cleanup procedures'")
        wait(1)
        cmd("MAX_FSX MISC_EVR with STRING 'E_INFO: Seq: PayloadUSAFAST, SEQUENCE COMPLETE'")
    end
  end

# If start is started as an SM_START_REL, this section gets executed
if __FILE__==$0
    start_time = $args[0].to_i
    mode = $args[1].to_i
    duration = $args[2].to_i
    PayloadUSAFAST(start_time, mode, duration)
end
