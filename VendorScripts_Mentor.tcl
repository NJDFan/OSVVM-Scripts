#  File Name:         VendorScripts_Mentor.tcl
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
#     3/2021   2021.03    In Simulate, added optional scripts to run as part of simulate
#     2/2021   2021.02    Refactored variable settings to here from ToolConfiguration.tcl
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
#  Copyright (c) 2018 - 2021 by SynthWorks Design Inc.    
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
# Tool Settings
#
  quietly set ToolType    "simulator"
  quietly set ToolVendor  "Siemens"
  if {[lindex [split [vsim -version]] 0] eq "Questa"} {
    quietly set simulator   "QuestaSim"
  } else {
    quietly set simulator   "ModelSim"
  }
  quietly set ToolNameVersion ${simulator}-[vsimVersion]
  puts $ToolNameVersion


# -------------------------------------------------
# StartTranscript / StopTranscxript
#
proc vendor_StartTranscript {FileName} {
  transcript file ""
  echo transcript file $FileName
  transcript file $FileName
}

proc vendor_StopTranscript {FileName} {
  # FileName not used here
  transcript file ""
}


# -------------------------------------------------
# Library
#
proc vendor_library {LibraryName PathToLib} {
  set PathAndLib ${PathToLib}/${LibraryName}.lib

  if {![file exists ${PathAndLib}]} {
    echo vlib    ${PathAndLib}
    eval vlib    ${PathAndLib}
  }
  echo vmap    $LibraryName  ${PathAndLib}
  eval vmap    $LibraryName  ${PathAndLib}
}

proc vendor_map {LibraryName PathToLib} {
  set PathAndLib ${PathToLib}/${LibraryName}.lib

  if {![file exists ${PathAndLib}]} {
    error "Map:  Creating library ${PathAndLib} since it does not exist.  "
    echo vlib    ${PathAndLib}
    eval vlib    ${PathAndLib}
  }
  echo vmap    $LibraryName  ${PathAndLib}
  eval vmap    $LibraryName  ${PathAndLib}
}

# -------------------------------------------------
# analyze
#
proc vendor_analyze_vhdl {LibraryName FileName} {
  global OsvvmVhdlVersion
  echo vcom -${OsvvmVhdlVersion} -work ${LibraryName} ${FileName}
  eval vcom -${OsvvmVhdlVersion} -work ${LibraryName} ${FileName}
}

proc vendor_analyze_verilog {LibraryName FileName} {
#  Untested branch for Verilog - will need adjustment
  echo vlog -work ${LibraryName} ${FileName}
  eval vlog -work ${LibraryName} ${FileName}
}

# -------------------------------------------------
# End Previous Simulation
#
proc vendor_end_previous_simulation {} {
  global SourceMap

  # close junk in source window
  foreach index [array names SourceMap] { 
    noview source [file tail $index] 
  }
  
  quit -sim
}

# -------------------------------------------------
# Simulate
#
proc vendor_simulate {LibraryName LibraryUnit OptionalCommands} {
  global SCRIPT_DIR
  global ToolVendor
  global simulator

#  puts "Simulate Start time [clock format $::SimulateStartTime -format %T]"
  puts {vsim -voptargs="+acc" -t $::SIMULATE_TIME_UNITS -lib ${LibraryName} ${LibraryUnit} ${OptionalCommands} -suppress 8683 -suppress 8684 -suppress 8617}
  eval vsim -voptargs="+acc" -t $::SIMULATE_TIME_UNITS -lib ${LibraryName} ${LibraryUnit} ${OptionalCommands} -suppress 8683 -suppress 8684 -suppress 8617
  
  ### Project level settings - in OsvvmLibraries/Scripts
  # Historical name.  Must be run with "do" for actions to work
  if {[file exists ${SCRIPT_DIR}/Mentor.do]} {
    do ${SCRIPT_DIR}/Mentor.do
  }
  # Project Vendor script
  if {[file exists ${SCRIPT_DIR}/${ToolVendor}.tcl]} {
    source ${SCRIPT_DIR}/${ToolVendor}.tcl
  }
  # Project Simulator Script
  if {[file exists ${SCRIPT_DIR}/${simulator}.tcl]} {
    source ${SCRIPT_DIR}/${simulator}.tcl
  }

  ### User level settings for simulator in the simulation run directory
  # User Vendor script
  if {[file exists ${ToolVendor}.tcl]} {
    source ${ToolVendor}.tcl
  }
  # User Simulator Script
  if {[file exists ${simulator}.tcl]} {
    source ${simulator}.tcl
  }
  # User Testbench Script
  if {[file exists ${LibraryUnit}.tcl]} {
    source ${LibraryUnit}.tcl
  }
  # User Testbench + Simulator Script
  if {[file exists ${LibraryUnit}_${simulator}.tcl]} {
    source ${LibraryUnit}_${simulator}.tcl
  }
  # User wave.do
  if {[file exists wave.do]} {
    do wave.do
  }
  
  # Removed.  Desirable, but causes crashes if no signals in testbench.
#  add log -r [env]/*
  run -all 
}