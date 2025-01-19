//
//  FontEnumGenerator.swift
//  FontEnum
//
//  Created by Rohan Bimal Raj on 15/01/25.
//

import PackagePlugin
import Foundation

@main
struct FontEnumGenerator: BuildToolPlugin {
    
    // This method creates the build commands which will be run by the build system when necessary
    func createBuildCommands(context: PackagePlugin.PluginContext, target: any PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        
        // The executable responsible for generating the Swift enum file from font files
        let fontGenerator = try context.tool(named: "FontEnumGeneratorExc")
        let targetName = target.name
        
        // Ensure the target has a source module (to retrieve input files)
        guard let sourceModule = target.sourceModule else {
            throw PluginError.missingSourceModule
        }
        
        // Filter the source files in the target to include only font files with valid extensions
        let inputFiles = sourceModule.sourceFiles.filter { hasValidFontExtension($0.url) }.map{ $0.url }
        let inputFilesArguments = inputFiles.map{ $0.path() }
        
        // If no valid font files are found, throw an error and display a diagnostic message
        if inputFiles.isEmpty {
            Diagnostics.error("The target \(targetName) does not contain any custom fonts in a supported format. Supported formats are: .ttf, .otf.")
            throw PluginError.missingInputFiles
        }
        
        // Define the output directory where the generated enum file will be stored
        let outputDirectory = context.pluginWorkDirectoryURL
                                     .appending(path: target.name)
                                     .appending(path: "Generated")
        
        // Create the output directory if it doesn't already exist
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        
        // Define the path for the generated Swift file
        let outputFile = outputDirectory.appending(path: "\(targetName)GeneratedFonts.swift")
        
        // Return the build command to execute the font generator tool
        return [
            .buildCommand(
                displayName: "Generating Font Definitions For \(targetName)", // Display name for the build process
                executable: fontGenerator.url, // Path to the executable tool
                arguments: [
                    outputFile.path(), // Output file path as the first argument
                ] + inputFilesArguments , // Append input font file paths as arguments
                environment: [:], // Specify any custom environment variables if needed
                inputFiles: inputFiles, // Declare input files for tracking changes
                outputFiles: [outputFile] // Declare the output file for tracking changes. Files which are declared here will be included in the bundle when the app is archived
            )
        ]
    }
}

private extension FontEnumGenerator {
    
    // Helper method to check if a file has a valid font extension (.ttf or .otf)
    func hasValidFontExtension(_ fileUrl: URL) -> Bool {
        let fileName = fileUrl.lastPathComponent
        return fileName.hasSuffix(".ttf") || fileName.hasSuffix(".otf")
    }
}

// Enum to define possible plugin errors
enum PluginError: Error {
    case missingInputFiles // Error for missing font files
    case missingSourceModule // Error for missing source module
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

// Extend FontEnumGenerator to conform to XcodeBuildToolPlugin
// This enables the plugin to work with Xcode projects
extension FontEnumGenerator: XcodeBuildToolPlugin {
    
    func createBuildCommands(context: XcodeProjectPlugin.XcodePluginContext, target: XcodeProjectPlugin.XcodeTarget) throws -> [PackagePlugin.Command] {
        
        // Retrieve the tool (executable) defined in the package
        let fontGenerator = try context.tool(named: "FontEnumGeneratorExc")
        let targetName = target.displayName // Get the human-readable name of the target
        
        // Filter input files to include only supported font files
        let inputFiles = target.inputFiles.filter { hasValidFontExtension($0.url) }.map{ $0.url }
        let inputFilesArguments = inputFiles.map{ $0.path() }
        
        // If no valid font files are found, throw an error and show a diagnostic message
        if inputFiles.isEmpty {
            Diagnostics.error("The target \(targetName) does not contain any custom fonts in a supported format. Supported formats are: .ttf, .otf.")
            throw PluginError.missingInputFiles
        }
        
        // Define the output directory where the generated file will be stored
        let outputDirectory = context.pluginWorkDirectoryURL
                                     .appending(path: target.displayName)
                                     .appending(path: "Generated")
        
        // Create the output directory if it doesn't already exist
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        
        // Define the output file path for the generated Swift file
        let outputFile = outputDirectory.appending(path: "\(targetName)GeneratedFonts.swift")
                
        // Construct the build command to execute the tool
        return [
            .buildCommand(
                displayName: "Generating Font Definitions For \(targetName)", // Display message during the build process
                executable: fontGenerator.url, // Path to the executable tool
                arguments: [
                    outputFile.path(), // Specify the output file path as the first argument
                ] + inputFilesArguments , // Append the font file paths as additional arguments
                environment: [:], // Specify any environment variables if required
                inputFiles: inputFiles, // Declare input files for dependency tracking
                outputFiles: [outputFile] // Declare the generated file as an output in order to be included when app is archived
            )
        ]
    }
}

#endif
