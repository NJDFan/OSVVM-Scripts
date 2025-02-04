#  File Name:         OsvvmProjectScripts.tcl
#  Purpose:           Scripts for running simulations
#  Revision:          OSVVM MODELS STANDARD VERSION
# 
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com 
#  Contributor(s):            
#     Jim Lewis      email:  jim@synthworks.com   
# 
#  Description
#    Tcl procedures with the intent of making running 
#    compiling and simulations tool independent
#    
#  Developed by: 
#        SynthWorks Design Inc. 
#        VHDL Training Classes
#        OSVVM Methodology and Model Library
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
# 
#  Revision History:
#    Date      Version    Description
#     3/2021   2021.03    Updated printing of start/finish times
#     2/2021   2021.02    Updated initialization of libraries                 
#                         Analyze allows ".vhdl" extensions as well as ".vhd" 
#                         Include/Build signal error if nothing to run                         
#                         Added SetVHDLVersion / GetVHDLVersion to support 2019 work           
#                         Added SetSimulatorResolution / GetSimulatorResolution to support GHDL
#                         Added beta of LinkLibrary to support linking in project libraries    
#                         Added beta of SetLibraryDirectory / GetLibraryDirectory              
#                         Added beta of ResetRunLibrary                                        
#     7/2020   2020.07    Refactored tool execution for simpler vendor customization
#     1/2020   2020.01    Updated Licenses to Apache
#     2/2019   Beta       Project descriptors in .pro which execute 
#                         as TCL scripts in conjunction with the library 
#                         procedures
#    11/2018   Alpha      Project descriptors in .files and .dirs files
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2018 - 2020 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# -------------------------------------------------
# StartUp
#   re-run the startup scripts, this program included
#
proc StartUp {} { 
  puts "source $::SCRIPT_DIR/StartUp.tcl"
  eval source $::SCRIPT_DIR/StartUp.tcl
}


# -------------------------------------------------
# Do_List
#   do an operation on a list of items
#
proc Do_List {FileWithNames ActionForName} {
#  puts "$FileWithNames"
  set FileHandle [open $FileWithNames]
  set ListOfNames [split [read $FileHandle] \n]
  close $FileHandle

  foreach OneName $ListOfNames {
    # skip blank lines
    if {[string length $OneName] > 0} {
      # use # as comment character
      if {[string index $OneName 0] ne "#"} {
        puts "$ActionForName ${OneName}"
        # will break $OneName into individual pieces for handling
        eval $ActionForName ${OneName}  
        # leaves $OneName as a single string
#        $ActionForName ${OneName}
      } else {
        # handle other file formats
        if {[lindex $OneName 1] eq "library"} {
          eval library [lindex $OneName 2]
        }
      }
    }
  }
}

proc StartTranscript {FileBaseName} {
  global OsvvmCurrentTranscript

  if {![info exists OsvvmCurrentTranscript]} {
    set OsvvmCurrentTranscript ""
  }
  if {($FileBaseName ne "NONE.log") && ($OsvvmCurrentTranscript eq "")} {
    # Create directories if they do not exist
    set OsvvmCurrentTranscript $FileBaseName
    set FileName [file join $::DIR_LOGS $FileBaseName]
    set RootDir [file dirname $FileName]
    if {![file exists $RootDir]} {
      puts "creating directory $RootDir"
      file mkdir $RootDir
    }
    
    vendor_StartTranscript $FileName
  }
}

proc StopTranscript {{FileBaseName ""}} {
  global OsvvmCurrentTranscript
  
  # Stop only if it is the transcript that is open
  if {($OsvvmCurrentTranscript eq $FileBaseName)} {
    # FileName used within the STOP_TRANSCRIPT variable if required
    set FileName [file join $::DIR_LOGS $FileBaseName]
    vendor_StopTranscript $FileName
    set OsvvmCurrentTranscript ""
  }
}

proc TerminateTranscript {} {
  global OsvvmCurrentTranscript

  if {[info exists OsvvmCurrentTranscript]} {
    set OsvvmCurrentTranscript ""
  }
}

#
#  Problematic since output of tests has the word log
#
# proc log {Message} {
#   puts $Message   
# }

# -------------------------------------------------
# include 
#   finds and sources a project file
#
proc include {Path_Or_File} {
  global CURRENT_WORKING_DIRECTORY
  global VHDL_WORKING_LIBRARY
  
#  puts "set StartingPath ${CURRENT_WORKING_DIRECTORY} Starting Include"
  # If a library does not exist, then create the default
  if {![info exists VHDL_WORKING_LIBRARY]} {
    library default
  }
  set StartingPath ${CURRENT_WORKING_DIRECTORY}
  
  set NormName [file normalize ${StartingPath}/${Path_Or_File}]
  set RootDir [file dirname $NormName]
  set NameToHandle [file tail $NormName]
  set FileExtension [file extension $NameToHandle]
  
  # Path_Or_File is a File with extension .pro, .tcl, .do, .files, .dirs
  if {[file exists $NormName] && ![file isdirectory $NormName]} {
    puts "set CURRENT_WORKING_DIRECTORY ${RootDir}"
    set CURRENT_WORKING_DIRECTORY ${RootDir}
    if {$FileExtension eq ".pro" || $FileExtension eq ".tcl" || $FileExtension eq ".do"} {
      puts "source ${NormName}"
      source ${NormName} 
    } elseif {$FileExtension eq ".dirs"} {
      puts "Do_List ${NormName} include"
      Do_List ${NormName} "include"
    } else { 
    #  was elseif {$FileExtension eq ".files"} 
      puts "Do_List ${NormName} analyze"
      Do_List ${NormName} "analyze"
    }
  } else {
    # Path_Or_File is directory name
    if {[file isdirectory $NormName]} {
      puts "set CURRENT_WORKING_DIRECTORY ${NormName}"
      set CURRENT_WORKING_DIRECTORY ${NormName}
      set FileBaseName ${NormName}/[file rootname ${NameToHandle}] 
    } else {
    # Path_Or_File is name that specifies the rootname of the file(s)
      puts "set CURRENT_WORKING_DIRECTORY ${RootDir}"
      set CURRENT_WORKING_DIRECTORY ${RootDir}
      set FileBaseName ${NormName}
    } 
    # Determine which if any project files exist
    set FileProName    ${FileBaseName}.pro
    set FileDirsName   ${FileBaseName}.dirs
    set FileFilesName  ${FileBaseName}.files
    set FileTclName    ${FileBaseName}.tcl
    set FileDoName     ${FileBaseName}.do

    set FoundActivity 0
    if {[file exists ${FileProName}]} {
      puts "source ${FileProName}"
      source ${FileProName} 
      set FoundActivity 1
    } 
    # .dirs is intended to be deprecated in favor of .pro
    if {[file exists ${FileDirsName}]} {
      Do_List ${FileDirsName} "include"
      set FoundActivity 1
    }
    # .files is intended to be deprecated in favor of .pro
    if {[file exists ${FileFilesName}]} {
      Do_List ${FileFilesName} "analyze"
      set FoundActivity 1
    }
    # .tcl intended for extended capability
    if {[file exists ${FileTclName}]} {
      puts "do ${FileTclName} ${CURRENT_WORKING_DIRECTORY}"
      eval do ${FileTclName} ${CURRENT_WORKING_DIRECTORY}
      set FoundActivity 1
    }
    # .do intended for extended capability
    if {[file exists ${FileDoName}]} {
      puts "do ${FileDoName} ${CURRENT_WORKING_DIRECTORY}"
      eval do ${FileDoName} ${CURRENT_WORKING_DIRECTORY}
      set FoundActivity 1
    }
    if {$FoundActivity == 0} {
      error "Build / Include did not find anything to execute"
    }
  } 
#  puts "set CURRENT_WORKING_DIRECTORY ${StartingPath} Ending Include"
  set CURRENT_WORKING_DIRECTORY ${StartingPath}
}

proc build {{Path_Or_File "."} {LogName "."}} {
  global CURRENT_WORKING_DIRECTORY
  global CURRENT_RUN_DIRECTORY
  global VHDL_WORKING_LIBRARY
  global vendor_simulate_started

  set CURRENT_WORKING_DIRECTORY [pwd]
  
  if {![info exists CURRENT_RUN_DIRECTORY]} {
    set CURRENT_RUN_DIRECTORY ""
  }

  # Initialize 
  if {![info exists VHDL_WORKING_LIBRARY] || $CURRENT_WORKING_DIRECTORY ne $CURRENT_RUN_DIRECTORY } {
    if {[info exists VHDL_WORKING_LIBRARY]} {
      unset VHDL_WORKING_LIBRARY
    }
    library default 
  } 
  
  # End simulations if started - only set by simulate
  if {[info exists vendor_simulate_started]} {
    puts "Ending Previous Simulation"
    vendor_end_previous_simulation
    unset vendor_simulate_started
  }  

  # If Transcript Open, then Close it
  TerminateTranscript
  
  # Create the Log File Name
  set NormPathOrFile [file normalize ${Path_Or_File}]
  set NormDir        [file dirname $NormPathOrFile]
  set NormDirName    [file tail $NormDir]
  set NormTail       [file tail $NormPathOrFile]
  set NormTailRoot   [file rootname $NormTail]
  
  if {$NormDirName eq $NormTailRoot} {
    # <Parent Dir>_<Script Name>.log
    set LogName [file tail [file dirname $NormDir]]_${NormTailRoot}.log
  } else {
    # <Dir Name>_<Script Name>.log
    set LogName ${NormDirName}_${NormTailRoot}.log
  }

  set BuildStartTime   [clock seconds] 
  puts "Build Start time [clock format $BuildStartTime -format %T]"
  StartTranscript ${LogName}
  
  include ${Path_Or_File}
  
  puts "Build Start time  [clock format $BuildStartTime -format {%T %Z %a %b %d %Y }]"
  set  BuildFinishTime  [clock seconds] 
  set  BuildElapsedTime  [expr ($BuildFinishTime - $BuildStartTime)]    
#  puts "Finish time [clock format $BuildFinishTime -format %T]"
  puts "Build Finish time [clock format $BuildFinishTime -format %T], Elasped time: [format %d:%02d:%02d [expr ($BuildElapsedTime/(60*60))] [expr (($BuildElapsedTime/60)%60)] [expr (${BuildElapsedTime}%60)]] "
#  puts "Elapsed time [expr ($BuildFinishTime - $BuildStartTime)/60] minutes"
  StopTranscript ${LogName}
}


# -------------------------------------------------
# RemoveAllLibraries
#
proc RemoveAllLibraries {} {
  file delete -force -- $::DIR_LIB
}


proc CreateDirectory {Directory} {
  if {![file exists $Directory]} {
    puts "creating directory $Directory"
    file mkdir $Directory
  }
}

# -------------------------------------------------
# OsvvmInitialize
#
proc OsvvmInitialize {} {
  global CURRENT_WORKING_DIRECTORY
  global CURRENT_RUN_DIRECTORY
  global LIB_BASE_DIR
  global DIR_LIB
  global DIR_LOGS
  global ToolNameVersion 

  if {![info exists CURRENT_WORKING_DIRECTORY]} {
    set CURRENT_WORKING_DIRECTORY [pwd]
  }
  set CURRENT_RUN_DIRECTORY [pwd]

  if {![info exists LIB_BASE_DIR]} {
    set LIB_BASE_DIR $CURRENT_RUN_DIRECTORY
  }
  
  # Set locations for libraries and logs
  set DIR_LIB    ${LIB_BASE_DIR}/VHDL_LIBS/${ToolNameVersion}
  set DIR_LOGS   ${CURRENT_RUN_DIRECTORY}/logs/${ToolNameVersion}

  # Create LIB and Results directories
  CreateDirectory $DIR_LIB
  CreateDirectory ${CURRENT_RUN_DIRECTORY}/results
}

# -------------------------------------------------
# Library
#
proc library {LibraryName} {
  global VHDL_WORKING_LIBRARY
  global DIR_LIB
  
  # If VHDL_WORKING_LIBRARY does not exist, then initialize
  if {![info exists VHDL_WORKING_LIBRARY]} {
    OsvvmInitialize
  }
  
  puts "library $LibraryName" 

# Does DIR_LIB need to be normalized?
    
  vendor_library $LibraryName $DIR_LIB

  set VHDL_WORKING_LIBRARY  $LibraryName
}

proc map {LibraryName {PathToLib ""}} {
  global DIR_LIB
  global VHDL_WORKING_LIBRARY

  if {![info exists VHDL_WORKING_LIBRARY]} {
    OsvvmInitialize
  }

  if {![string match $PathToLib ""]} {
    # only for mapping to external existing library
    set ResolvedPathToLib $PathToLib
  } else {
    # naming pattern for project libraries
    set ResolvedPathToLib ${DIR_LIB}/${LibraryName}.lib
  }
  
  vendor_map $LibraryName $ResolvedPathToLib
  
  set VHDL_WORKING_LIBRARY  $LibraryName
}

# -------------------------------------------------
# analyze
#
proc analyze {FileName} {
  global CURRENT_WORKING_DIRECTORY
  global VHDL_WORKING_LIBRARY

  # If a library does not exist, then create the default
  if {![info exists VHDL_WORKING_LIBRARY]} {
    library default
  }
  
  puts "analyze $FileName"
  
  set NormFileName [file normalize ${CURRENT_WORKING_DIRECTORY}/${FileName}]
  set FileExtension [file extension $FileName]

  if {$FileExtension eq ".vhd" || $FileExtension eq ".vhdl"} {
    vendor_analyze_vhdl ${VHDL_WORKING_LIBRARY} ${NormFileName}
  } elseif {$FileExtension eq ".v"} {
    vendor_analyze_verilog ${VHDL_WORKING_LIBRARY} ${NormFileName}
  } elseif {$FileExtension eq ".lib"} {
    #  for handling older deprecated file format
    library [file rootname $FileName]
  }
}

# -------------------------------------------------
# Simulate
#
proc simulate {LibraryUnit {OptionalCommands ""}} {
  global vendor_simulate_started
  global VHDL_WORKING_LIBRARY
  global SimulateStartTime
  
  if {[info exists vendor_simulate_started]} {
    vendor_end_previous_simulation
  }  
  set vendor_simulate_started 1
  
#  StartTranscript ${LibraryUnit}.log
  
  # If a library does not exist, then create the default
  if {![info exists VHDL_WORKING_LIBRARY]} {
    library default
  }
  set SimulateStartTime   [clock seconds] 
  
  puts "simulate $LibraryUnit $OptionalCommands"
  puts "Simulate Start time [clock format $SimulateStartTime -format %T]"

  vendor_simulate ${VHDL_WORKING_LIBRARY} ${LibraryUnit} ${OptionalCommands}

  #puts "Start time  [clock format $SimulateStartTime -format %T]"
  set  SimulateFinishTime  [clock seconds] 
  set  SimulateElapsedTime  [expr ($SimulateFinishTime - $SimulateStartTime)]    
  puts "Simulate Finish time [clock format $SimulateFinishTime -format %T], Elasped time: [format %d:%02d:%02d [expr ($SimulateElapsedTime/(60*60))] [expr (($SimulateElapsedTime/60)%60)] [expr (${SimulateElapsedTime}%60)]] "
#  puts "Elasped time [expr ($FinishTime - $SimulateStartTime)/60] minutes"
#  StopTranscript ${LibraryUnit}.log
}



# -------------------------------------------------
# Settings
#
proc SetVHDLVersion {VhdlVersion} {
  global OsvvmVhdlVersion
  global OsvvmVhdlShortVersion
  
  if {$VhdlVersion eq "2008" || $VhdlVersion eq "08"} {
    set OsvvmVhdlVersion 2008
    set OsvvmVhdlShortVersion 08
  } elseif {$VhdlVersion eq "2019" || $VhdlVersion eq "19" } {
    set OsvvmVhdlVersion 2019
    set OsvvmVhdlShortVersion 19
  } elseif {$VhdlVersion eq "2002" || $VhdlVersion eq "02" } {
    set OsvvmVhdlVersion 2002
    set OsvvmVhdlShortVersion 02
    puts "\nWARNING:  VHDL Version set to 2002.  OSVVM Requires 2008 or newer\n"
  } elseif {$VhdlVersion eq "1993" || $VhdlVersion eq "93" } {
    set OsvvmVhdlVersion 93
    set OsvvmVhdlShortVersion 93
    puts "\nWARNING:  VHDL Version set to 1993.  OSVVM Requires 2008 or newer\n"
  } else {
    set OsvvmVhdlVersion 2008
    set OsvvmVhdlShortVersion 08
    puts "\nWARNING:  Input to SetVHDLVersion not recognized.   Using 2008.\n"
  }  
}

proc GetVHDLVersion {} {
  return $::OsvvmVhdlVersion
}

proc SetSimulatorResolution {SimulatorResolution} {
  global SIMULATE_TIME_UNITS

  set SIMULATE_TIME_UNITS        $SimulatorResolution
}

proc GetSimulatorResolution {} {
  return $::SIMULATE_TIME_UNITS
}

#
# Remaining proc are Experimental, Alpha code and are likely to change.
# Use at your own risk.
#

#
#  Currently only set in OsvvmScriptDefaults
#
proc SetLibraryDirectory {{LibraryDirectory ""}} {
  global CURRENT_RUN_DIRECTORY
  global LIB_BASE_DIR
  global VHDL_WORKING_LIBRARY
  global ToolNameVersion
  
  if {$LibraryDirectory eq ""} {
    if {[info exists CURRENT_RUN_DIRECTORY]} {
      set LIB_BASE_DIR $CURRENT_RUN_DIRECTORY
      set DIR_LIB    ${LIB_BASE_DIR}/VHDL_LIBS/${ToolNameVersion}
    } else {
      # Instead, will be set by first call to build, include, analyze, simulate, or library
      if {[info exists LIB_BASE_DIR]} {
        unset LIB_BASE_DIR
      }
      if {[info exists VHDL_WORKING_LIBRARY]} {
        unset VHDL_WORKING_LIBRARY
      }
    }
  } else {
    set LIB_BASE_DIR $LibraryDirectory
    set DIR_LIB    ${LIB_BASE_DIR}/VHDL_LIBS/${ToolNameVersion}
  }
}

proc GetLibraryDirectory {} {
  global LIB_BASE_DIR
  
  if {[info exists LIB_BASE_DIR]} {
    return "${LIB_BASE_DIR}"
  } else {
    puts "WARNING:  GetLibraryDirectory LIB_BASE_DIR not defined"
    return ""
  }
}
  
proc ResetRunDirectory {} {
  global CURRENT_RUN_DIRECTORY
  global LIB_BASE_DIR
  global VHDL_WORKING_LIBRARY
  
  if {[info exists CURRENT_RUN_DIRECTORY]} {
    unset CURRENT_RUN_DIRECTORY
  }
  if {[info exists LIB_BASE_DIR]} {
    unset LIB_BASE_DIR
  }
  if {[info exists VHDL_WORKING_LIBRARY]} {
    unset VHDL_WORKING_LIBRARY
  }
}

proc LinkLibrary {{LibraryDirectory ""}} {
  global CURRENT_RUN_DIRECTORY
  global ToolNameVersion
  
  if {$LibraryDirectory eq ""} {
    if {[info exists DIR_LIB]} {
      set CurrentLib $DIR_LIB
    } else {
      set CurrentLib ${CURRENT_RUN_DIRECTORY}/VHDL_LIBS/${ToolNameVersion}
    }
  } else {
      set CurrentLib ${LibraryDirectory}/VHDL_LIBS/${ToolNameVersion}
  }
  if {[file isdirectory $CurrentLib]} {
    foreach LibToLink [glob -directory $CurrentLib *] {
      set LibName [file rootname [file tail $LibToLink]]
      library $LibName
    }  
  } else {
    puts "$CurrentLib does not exist"
  }
}

# -------------------------------------------------
# MapLibraries
#   Likely this will be replaced by LinkLibrary.
#
#   Used to create a library mapping in a  
#   directory different from the initial/normal simulation 
#   directory.  
#
#   Most projects should not need this, however, 
#   it was used on a project to work around long name
#   issues in Windows 10 Home.
#
#   Accomplishes this by temporarily switching in a 
#   different version of library, analyze, and simulate
#
proc MapLibraries {{Path_Or_File "."}} {
  global SCRIPT_DIR
  source ${SCRIPT_DIR}/OsvvmCreateLibraryMapOverrideScripts.tcl
  include $Path_Or_File
#  build $Path_Or_File
  source ${SCRIPT_DIR}/OsvvmProjectScripts.tcl
}

# MapAllLibraries - deprecated, but for older script support
proc MapAllLibraries {{Path_Or_File "."}} {
  MapLibraries ${Path_Or_File}
}
