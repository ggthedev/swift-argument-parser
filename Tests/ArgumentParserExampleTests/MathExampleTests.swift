//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParser
import ArgumentParserTestHelpers

final class MathExampleTests: XCTestCase {
  func testMath_Simple() throws {
    AssertExecuteCommand(command: "math 1 2 3 4 5", expected: "15")
    AssertExecuteCommand(command: "math multiply 1 2 3 4 5", expected: "120")
  }
  
  func testMath_Help() throws {
    let helpText = """
        OVERVIEW: A utility for performing maths.

        USAGE: math <subcommand>

        OPTIONS:
          --version               Show the version.
          -h, --help              Show help information.

        SUBCOMMANDS:
          add                     Print the sum of the values.
          multiply                Print the product of the values.
          stats                   Calculate descriptive statistics.
        """
    
    AssertExecuteCommand(command: "math -h", expected: helpText)
    AssertExecuteCommand(command: "math --help", expected: helpText)
    AssertExecuteCommand(command: "math help", expected: helpText)
  }
  
  func testMath_AddHelp() throws {
    let helpText = """
        OVERVIEW: Print the sum of the values.

        USAGE: math add [--hex-output] [<values> ...]

        ARGUMENTS:
          <values>                A group of integers to operate on.

        OPTIONS:
          -x, --hex-output        Use hexadecimal notation for the result.
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    AssertExecuteCommand(command: "math add -h", expected: helpText)
    AssertExecuteCommand(command: "math add --help", expected: helpText)
    AssertExecuteCommand(command: "math help add", expected: helpText)
  }
  
  func testMath_StatsMeanHelp() throws {
    let helpText = """
        OVERVIEW: Print the average of the values.

        USAGE: math stats average [--kind <kind>] [<values> ...]

        ARGUMENTS:
          <values>                A group of floating-point values to operate on.

        OPTIONS:
          --kind <kind>           The kind of average to provide. (default: mean)
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    AssertExecuteCommand(command: "math stats average -h", expected: helpText)
    AssertExecuteCommand(command: "math stats average --help", expected: helpText)
    AssertExecuteCommand(command: "math help stats average", expected: helpText)
  }
  
  func testMath_StatsQuantilesHelp() throws {
    let helpText = """
        OVERVIEW: Print the quantiles of the values (TBD).

        USAGE: math stats quantiles [<values> ...]

        ARGUMENTS:
          <values>                A group of floating-point values to operate on.

        OPTIONS:
          --version               Show the version.
          -h, --help              Show help information.
        """
    
    // The "quantiles" subcommand's run() method is unimplemented, so it
    // just generates the help text.
    AssertExecuteCommand(command: "math stats quantiles", expected: helpText)
    
    AssertExecuteCommand(command: "math stats quantiles -h", expected: helpText)
    AssertExecuteCommand(command: "math stats quantiles --help", expected: helpText)
    AssertExecuteCommand(command: "math help stats quantiles", expected: helpText)
  }
  
  func testMath_CustomValidation() throws {
    AssertExecuteCommand(
      command: "math stats average --kind mode",
      expected: """
            Error: Please provide at least one value to calculate the mode.
            Usage: math stats average [--kind <kind>] [<values> ...]
            """,
      exitCode: .validationFailure)
  }
  
  func testMath_Versions() throws {
    AssertExecuteCommand(
      command: "math --version",
      expected: "1.0.0")
    AssertExecuteCommand(
      command: "math stats --version",
      expected: "1.0.0")
    AssertExecuteCommand(
      command: "math stats average --version",
      expected: "1.5.0-alpha")
  }

  func testMath_ExitCodes() throws {
    AssertExecuteCommand(
      command: "math stats quantiles --test-success-exit-code",
      expected: "",
      exitCode: .success)
    AssertExecuteCommand(
      command: "math stats quantiles --test-failure-exit-code",
      expected: "",
      exitCode: .failure)
    AssertExecuteCommand(
      command: "math stats quantiles --test-validation-exit-code",
      expected: "",
      exitCode: .validationFailure)
    AssertExecuteCommand(
      command: "math stats quantiles --test-custom-exit-code 42",
      expected: "",
      exitCode: ExitCode(42))
  }
  
  func testMath_Fail() throws {
    AssertExecuteCommand(
      command: "math --foo",
      expected: """
            Error: Unknown option '--foo'
            Usage: math add [--hex-output] [<values> ...]
            """,
      exitCode: .validationFailure)
    
    AssertExecuteCommand(
      command: "math ZZZ",
      expected: """
            Error: The value 'ZZZ' is invalid for '<values>'
            Usage: math add [--hex-output] [<values> ...]
            """,
      exitCode: .validationFailure)
  }
}

// MARK: - Completion Script

extension MathExampleTests {
  func testMath_CompletionScript() {
    AssertExecuteCommand(
      command: "math --generate-completion",
      expected: completionScriptText)
  }
}

private let completionScriptText = """
#compdef math
local context state state_descr line
typeset -A opt_args

_math() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
        case $state in
            (command)
                local modes
                modes=(
                    'add:Print the sum of the values.'
                    'multiply:Print the product of the values.'
                    'stats:Calculate descriptive statistics.'
                    'help:Show subcommand help information.'
                )
                _describe "mode" modes
                ;;
            (arg)
                case ${words[1]} in
                    (add)
                        _math_add
                        ;;
                    (multiply)
                        _math_multiply
                        ;;
                    (stats)
                        _math_stats
                        ;;
                    (help)
                        _math_help
                        ;;
                esac
                ;;
        esac    return ret
}

_math_add() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}

_math_multiply() {
    integer ret=1
    local -a args
    args+=(
        '(--hex-output -x)'{--hex-output,-x}'[Use hexadecimal notation for the result.]'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}

_math_stats() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
        case $state in
            (command)
                local modes
                modes=(
                    'average:Print the average of the values.'
                    'stdev:Print the standard deviation of the values.'
                    'quantiles:Print the quantiles of the values (TBD).'
                )
                _describe "mode" modes
                ;;
            (arg)
                case ${words[1]} in
                    (average)
                        _math_stats_average
                        ;;
                    (stdev)
                        _math_stats_stdev
                        ;;
                    (quantiles)
                        _math_stats_quantiles
                        ;;
                esac
                ;;
        esac    return ret
}

_math_stats_average() {
    integer ret=1
    local -a args
    args+=(
        '--kind[The kind of average to provide.]:kind:(mean median mode)'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}

_math_stats_stdev() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}

_math_stats_quantiles() {
    integer ret=1
    local -a args
    args+=(
        '--test-success-exit-code[]'
        '--test-failure-exit-code[]'
        '--test-validation-exit-code[]'
        '--test-custom-exit-code[]:test-custom-exit-code:'
        '--file[]:file:_files'
        '--directory[]:directory:_files -/'
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}

_math_help() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Print help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0
    return ret
}


_math
"""
