//
//  FontEnumGeneratorExc.swift
//  FontEnum
//
//  Created by Rohan Bimal Raj on 16/01/25.
//

import Foundation

// Main structure representing the executable responsible for generating the font enum
@main
struct FontEnumGeneratorExc {

    // Entry point of the executable
    static func main() throws {
        
        // Ensure the command line arguments are valid
        // The minimum required arguments: executable name, output path, and at least one input file
        guard CommandLine.arguments.count > 3 else {
            throw Error.invalidArguments
        }

        let arguments = CommandLine.arguments
        let outputPath = arguments[1] // Second argument specifies the output file path
                
        let inputFiles = Array(arguments[2...]) // Remaining arguments are the input font files
        
        let enumName = "AppFont" // Name of the generated Swift enum
        
        // Generate enum cases for each input file
        let cases = try inputFiles.compactMap { path -> String? in
            let url: URL?
            
            // Use modern file path API if available, fallback to older API for compatibility
            if #available(iOS 16.0, macOS 13.0, *) {
                url = URL(filePath: path)
            } else {
                url = URL(fileURLWithPath: path)
            }

            // Extract the file name (without extension) from the URL
            guard let fileName = url?.deletingPathExtension().lastPathComponent else {
                throw Error.invalidArguments
            }

            // Generate a valid case name by removing invalid characters and formatting
            let caseName = fileName
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .lowercasingFirstLetter()

            // Create the enum case declaration
                return "    case \(caseName) = \"\(fileName)\""
            }.joined(separator: "\n")
        
        // Define the Swift content for the enum
        let swiftContent = """
            enum \(enumName): String {
            \(cases)
            }
            """
        
        // Write the generated enum to the specified output file
        try swiftContent.write(
            to: URL(fileURLWithPath: outputPath), // Output path for the file
            atomically: true, // Write atomically to avoid partial writes
            encoding: .utf8 // Use UTF-8 encoding for the Swift file
        )
        
    }
}

// Enum to define errors for invalid command line arguments
enum Error: Swift.Error {
    case invalidArguments // Raised when the arguments are insufficient or invalid
}

// String extension to lowercase the first letter of a string
extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst() // Lowercase the first character
    }
}
