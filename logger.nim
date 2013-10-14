## The logger module provides an interface to manage message
## logging for rotated logfiles. Messages can be outputed at
## different levels. Aspects of logs such as location, name
## and when to rotate logfiles are possible to customise.
##
## (c) Copyright 2013 Jonas Odencrants, Licensed under the MIT license
## Source available at: https://github.com/krusipo/nimrod-logger
import os
from times import `$`,getTime, TTime
from posix import getpid, TPid

type 
  ## Unit for size of logfile
  TLogSizeUnit* = enum
    MegaByte,
    GigaByte,
    KiloByte,
    Byte

type 
  ## Structure to describe size of logfile
  TLogSize = object
    size: int64
    unit: TLogSizeUnit 

type 
  ## Logging level
  TLevel* = enum
    INFO = 10,
    FATAL = 20,
    ERROR = 30,
    DEBUG = 40

type 
  ## Structure to describe rows in logfile.
  TLogMessage {.inheritable.} = object
    process_id*: TPid
    calendar_time*: TTime
    level*: string
    text*: string

var
  ## basename of logfile. Default: "application" 
  logfileName: string
var 
  ## extension of logfile. Default ".log"
  logFileExtension: string
var 
  ## directory of logfile. Default: ""
  logDirectory: string
  
var 
  ## When True, direct output to terminal. Default False
  developerMode: bool
var 
  ## Size of logfile. Default: 10, TLogSizeUnit.MegaByte
  logSize: TLogSize
var 
  ## Maximum number of logfiles to rotate. Default: 10
  maxLogFiles: int
  

proc getLogFilePath(): string = 
  ## internal: Get path of logfile
  var full_file_path = logDirectory&logFileName&logFileExtension
  return full_file_path

proc inDeveloperMode*(): bool =
  ## internal: Get mode of logging operation
  return developerMode

proc createFileIfNotExists(): bool = 
  ## internal: Tries to create file when not existing
  var F: TFile

  try: 
    F = Open(getLogFilePath(), fmRead)
    Close(F)
  except EIO:
    F = Open(getLogFilePath(), fmReadWrite)
    Close(F)
  
  return existsFile(getLogFilePath())

proc rotateLogFile(): bool =
  ## internal: Rotates logfiles when necesary based on maxium
  ## allowed size of logfiles and the maximum allowed number
  ## of logfiles. 
  var F: TFile
  var error_message: string
  var file_size, rotate_at_size: int64

  try:
    F = Open(getLogFilePath(), fmRead)
    file_size = getFileSize(F)
    Close(F)
  except EIO:
    error_message = "Could not retrieve file size of: "&getLogFilePath()
    if inDeveloperMode():
      raise newException(EIO, error_message)
    else:
      return False

  if(logSize.unit == TLogSizeUnit.Byte):
    rotate_at_size = logSize.size * 1
  elif(logSize.unit == TLogSizeUnit.KiloByte):
    rotate_at_size = logSize.size * 1024
  elif(logSize.unit == TLogSizeUnit.MegaByte):
    rotate_at_size = logSize.size * 1024 * 1024
  elif(logSize.unit == TlogSizeUnit.GigaByte):
    rotate_at_size = logSize.size * 1024 * 1024 * 1024

  if(file_size >= rotate_at_size):
    var i = maxLogFiles-2
    while i > 0:
      var new_number = 1 + i
      var current_log_file_path = logDirectory&logFileName&"_"&`$`($i)&logFileExtension
      var new_log_file_path = logDirectory&logFileName&"_"&`$`($new_number)&logFileExtension
      if existsFile(current_log_file_path):
        try:
          moveFile(current_log_file_path, new_log_file_path)
        except EOS:
          error_message = "Unable to move:  "&current_log_file_path&" to new location: "&new_log_file_path
          if inDeveloperMode():
            raise newException(EOS, error_message)
          else:
            return False
      dec(i)

    try:
      moveFile(getLogFilePath(), logDirectory&logFileName&"_1"&logFileExtension)
    except EOS:
      if inDeveloperMode():
        raise newException(EOS, error_message)
      else:
        return False
  
  return True

proc rotateAndCreateLogFiles(): bool =
  ## internal: True when file exists and are writable
  return createFileIfNotExists() and rotateLogFile()

proc getLogMessageString*(message: TLogMessage): string = 
  ## Formats log message text from TLogMessage
  var log_message_string = `$`(message.calendar_time)&" ["&`$`(message.process_id)&"]["&message.level&"] "&message.text&"\n"
  return log_message_string

proc setLogDirectory*(directoryPath): string {.discardable.} =
  ## Set directory for where of logfiles.
  logDirectory = directoryPath

proc setLogFileExtension*(fileExtension) : string {.discardable} =
  ## Set extension for created logfiles.
  logFileExtension = fileExtension

proc setFileName*(fileName): string {.discardable} =
  ## Set name of created logfiles
  logFileName = fileName

proc setDeveloperMode*(mode = False) : bool {.discardable} =
  ## Set mode of logging operation
  developerMode = mode

proc setLogSize*(lsize: int64, logsizeunit:TLogSizeUnit = TLogSizeUnit.MegaByte) : bool {.discardable} =
  ## Set maximum allowed size of logfile before attemting to rotate.
  logSize = TLogSize(size: lsize, unit: logsizeunit)
  return True

proc setMaxLogFiles*(maxfiles:int): int {.discardable} = 
  ## Set maximum allowed logfiles to rotate between
  maxLogFiles = maxFiles

proc log*(level: TLevel, message: string): bool {.discardable} =
  ## Write message of appropriate level to file.
  ## When fatal raise E_Base.
  ## When mode of logging operation are developer output
  ## message to terminal.
  var log_file_exists: bool
  var error_message: string
  var F: TFile
  var log_message: TLogMessage
  
  log_file_exists = rotateAndCreateLogFiles()

  if not log_file_exists:
    error_message = "The file: "&getLogFilePath()&" could not be found."
    if inDeveloperMode():
      raise newException(EIO, error_message)
    else:
      return False

  log_message = TLogMessage(process_id: getpid(), calendar_time: getTime(), text: message)

  if(TLevel.INFO == level):
    log_message.level = "INFO"
  elif(TLevel.ERROR == level):
    log_message.level = "ERROR"
  elif(TLevel.DEBUG == level):
    log_message.level = "DEBUG"
  elif(TLevel.FATAL == level):
    log_message.level = "FATAL"
    error_message = getLogMessageString(log_message)
    raise newException(E_Base, error_message)

  if(inDeveloperMode()):
    echo(getLogMessageString(log_message))

  try:
    F = Open(getLogFilePath(), fmAppend)
    F.write(getLogMessageString(log_message))
    Close(F)
  except E_Base:
    error_message = "Could not append message to logfile: "&getLogFilePath()
    if inDeveloperMode():
      raise newException(EIO, error_message)
    else:
      return False

  return True

proc main() =
  ## Register default values
  setLogFileExtension(".log")
  setFileName("application")
  setLogDirectory("")
  setDeveloperMode(False)
  setLogSize(10, TLogSizeUnit.MegaByte)
  setMaxLogFiles(10)

main()