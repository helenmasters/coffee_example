import Foundation
import Kitura
import LoggerAPI
import Configuration


import CouchDB

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080


// Set up the cloudant
internal var database: Database?

public func initialize() throws {

    func executableURL() -> URL? {
        var executableURL = Bundle.main.executableURL
        #if os(Linux)
            if (executableURL == nil) {
                executableURL = URL(fileURLWithPath: "/proc/self/exe").resolvingSymlinksInPath()
            }
        #endif
            return executableURL
    }

    func findProjectRoot(fromDir initialSearchDir: URL) -> URL? {
        let fileManager = FileManager()
        var searchDirectory = initialSearchDir
        while searchDirectory.path != "/" {
            let projectFilePath = searchDirectory.appendingPathComponent(".swiftservergenerator-project").path
            if fileManager.fileExists(atPath: projectFilePath) {
                return searchDirectory
            }
            searchDirectory.deleteLastPathComponent()
        }
        return nil
    }

    guard let searchDir = executableURL()?.deletingLastPathComponent(),
          let projectRoot = findProjectRoot(fromDir: searchDir) else {
        Log.error("Cannot find project root")
        exit(1)
    }

    manager.load(file: projectRoot.appendingPathComponent("config.json").path)
                .load(.environmentVariables)



    // Configuring cloudant
    let cloudantService = try manager.getCloudantService(name: "myCoffeeStoreCloudantService")
let dbClient = CouchDBClient(service: cloudantService)


    router.all("/", middleware: StaticFileServer())

port = manager["port"] as? Int ?? port

router.all("/*", middleware: BodyParser())

initializeIndex()

}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
