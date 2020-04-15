# swift-opt-corruption

Reproducer for a Swift bug that corrupts data when built with `-O`.
This is a stripped down version of the swift-format code where this
bug was discovered.

The bug appears to have been introduced in the development snapshots
between 2020.03.26 and 2020.03.27.

## To reproduce

1. Build and run the executable in debug mode with either the 2020.03.26
   or the 2020.03.27 toolchain and observe the output; specifically, the
   first two tokens printed:

   ```
   TOOLCHAINS=org.swift.50202003261a swift build -c debug && .build/debug/swift-opt-corruption

   + Token.contextualBreakingStart
   + Token.contextualBreakingStart
   + Token.syntax("P")
   + Token.contextualBreakingEnd
   + Token.syntax("(")
   + Token.syntax(")")
   + Token.contextualBreakingEnd
   + Token.syntax("")
   ... more output
   ```

2. Build and run the executable in release mode with the 2020.03.26
   toolchain and observe that the output is the same (be patient,
   SwiftSyntax takes a while to compile when optimized):

   ```
   TOOLCHAINS=org.swift.50202003261a swift build -c release && .build/release/swift-opt-corruption

   + Token.contextualBreakingStart
   + Token.contextualBreakingStart
   + Token.syntax("P")
   + Token.contextualBreakingEnd
   + Token.syntax("(")
   + Token.syntax(")")
   + Token.contextualBreakingEnd
   + Token.syntax("")
   ... more output
   ```

3. Build and run the executable in release mode with the 2020.03.27
   toolchain and observe that the output is different and the program
   segfaults:

   ```
   TOOLCHAINS=org.swift.50202003261a swift build -c release && .build/release/swift-opt-corruption

   + Token.contextualBreakingStart
   + Token.contextualBreakingEnd
   + Token.syntax("P")
   + Token.contextualBreakingEnd
   + Token.syntax("(")
   + Token.syntax(")")
   + Token.syntax("")
   [1]    10986 segmentation fault  .build/release/swift-opt-corruption
   ```

4. Navigate to line 87 of main.swift and make one of the two modifications
   there, then build again with the 2020.03.27 toolchain and observe that
   the bug goes away.
