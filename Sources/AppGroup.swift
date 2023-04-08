// AppGroup.swift
import Foundation

public enum AppGroup: String {
    case facts = "group.com.useyourloaf.worldfacts"

    public var containerURL: URL {
        switch self {
        case .facts:
            return FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: rawValue)!
        }
    }
}
