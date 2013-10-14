The logger module provides an interface to manage message logging for
rotated logfiles. Messages can be outputed at different levels. Aspects
of logs such as location, name and when to rotate logfiles are possible
to customise.

​(c) Copyright 2013 Jonas Odencrants, Licensed under the MIT license
Source available at:
[https://github.com/krusipo/nimrod-logger](https://github.com/krusipo/nimrod-logger)

[Imports](#56)
==============

[os](os.html), [times](times.html), [posix](posix.html)

[Types](#57)
============

    TLogSizeUnit* = enum 
      MegaByte, GigaByte, KiloByte, Byte

    TLevel* = enum 
      INFO = 10, FATAL = 20, ERROR = 30, DEBUG = 40

[Procs](#62)
============

    proc inDeveloperMode*(): bool

internal: Get mode of logging operation

    proc getLogMessageString*(message: TLogMessage): string

Formats log message text from TLogMessage

    proc setLogDirectory*(directoryPath): string {.discardable.}

Set directory for where of logfiles.

    proc setLogFileExtension*(fileExtension): string {.discardable.}

Set extension for created logfiles.

    proc setFileName*(fileName): string {.discardable.}

Set name of created logfiles

    proc setDeveloperMode*(mode = False): bool {.discardable.}

Set mode of logging operation

    proc setLogSize*(lsize: int64; logsizeunit: TLogSizeUnit = TLogSizeUnit.MegaByte): bool {.
        discardable.}

Set maximum allowed size of logfile before attemting to rotate.

    proc setMaxLogFiles*(maxfiles: int): int {.discardable.}

Set maximum allowed logfiles to rotate between

    proc log*(level: TLevel; message: string): bool {.discardable.}

Write message of appropriate level to file. When fatal raise E\_Base.
When mode of logging operation are developer output message to terminal.

Generated: 2013-10-14 18:56:03 UTC
