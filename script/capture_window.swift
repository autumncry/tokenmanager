#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

struct CaptureWindow {
    let id: CGWindowID
    let title: String
    let owner: String
    let bounds: CGRect

    var area: CGFloat {
        self.bounds.width * self.bounds.height
    }
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: capture_window.swift <main|quick|settings> <output.png>\n", stderr)
    exit(64)
}

let target = CommandLine.arguments[1]
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let deadline = Date().addingTimeInterval(18)

func currentWindows() -> [CaptureWindow] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return []
    }

    return rawWindows.compactMap { raw -> CaptureWindow? in
        let owner = raw[kCGWindowOwnerName as String] as? String ?? ""
        guard owner.lowercased().contains("tokenmanager") else { return nil }
        let layer = raw[kCGWindowLayer as String] as? Int ?? 0
        guard layer == 0 else { return nil }
        guard let number = raw[kCGWindowNumber as String] as? UInt32 else { return nil }
        let title = raw[kCGWindowName as String] as? String ?? ""
        guard let boundsDictionary = raw[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary)
        else {
            return nil
        }
        guard bounds.width >= 260, bounds.height >= 240 else { return nil }
        return CaptureWindow(id: CGWindowID(number), title: title, owner: owner, bounds: bounds)
    }
}

func bestWindow(from windows: [CaptureWindow]) -> CaptureWindow? {
    switch target {
    case "main":
        return windows
            .filter { !$0.title.localizedCaseInsensitiveContains("settings") && !$0.title.localizedCaseInsensitiveContains("quick") }
            .sorted { $0.area > $1.area }
            .first
    case "quick":
        return windows
            .filter {
                $0.title.localizedCaseInsensitiveContains("quick")
                    || ($0.bounds.width >= 320 && $0.bounds.width <= 460 && $0.bounds.height >= 420 && $0.bounds.height <= 620)
            }
            .sorted { $0.area < $1.area }
            .first
    case "settings":
        return windows
            .filter {
                $0.title.localizedCaseInsensitiveContains("settings")
                    || ($0.bounds.width >= 650 && $0.bounds.width <= 820 && $0.bounds.height >= 460 && $0.bounds.height <= 640)
            }
            .sorted { $0.area > $1.area }
            .first
    default:
        return nil
    }
}

var selected: CaptureWindow?
while Date() < deadline {
    let windows = currentWindows()
    if let match = bestWindow(from: windows) {
        selected = match
        break
    }
    Thread.sleep(forTimeInterval: 0.35)
}

guard let window = selected else {
    let windows = currentWindows()
    let summary = windows
        .map { "\($0.owner) | \($0.title) | \(Int($0.bounds.width))x\(Int($0.bounds.height))" }
        .joined(separator: "\n")
    fputs("No tokenmanager window matched target \(target).\n\(summary)\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
process.arguments = ["-x", "-l", String(window.id), outputURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("screencapture failed for window \(window.id).\n", stderr)
    exit(Int32(process.terminationStatus))
}

print(outputURL.path)
