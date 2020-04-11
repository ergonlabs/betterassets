import Flutter
import UIKit




public class SwiftBetterassetsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "betterassets", binaryMessenger: registrar.messenger())
    let instance = SwiftBetterassetsPlugin(with: registrar, and: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    let registrar: FlutterPluginRegistrar
    let channel: FlutterMethodChannel
    public init(with registrar: FlutterPluginRegistrar, and channel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        super.init()
    }


    var streams : Dictionary<String, FileHandle> = [:]
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>

        let bundle: Bundle
        if let delegate = UIApplication.shared.delegate  {
          let c = type(of: delegate)
          bundle = Bundle(for: c)
        } else {
          bundle = Bundle.main
        }

        if call.method.starts(with: "stream.") {
            if let key = args?["key"] as? String,
               let fd = streams[key] {
                switch call.method {
                case "stream.close":
                    fd.closeFile()
                    streams.removeValue(forKey: key)
                    channel.invokeMethod("close", arguments: args)
                    result(nil)
                case "stream.length":
                    let pos = fd.offsetInFile
                    result(fd.seekToEndOfFile())
                    fd.seek(toFileOffset: pos)
                case "stream.position":
                    if let newPos = args?["position"] as? Int64 {
                        fd.seek(toFileOffset: UInt64(newPos))
                    }
                    result(fd.offsetInFile)
                case "stream.read":
                    let bytes = args?["bytes"] as? Int ?? Int(INT_MAX)
                    let data = fd.readData(ofLength: bytes)
                    result(data)
                case "stream.readByte":
                    result(fd.readData(ofLength: 1)[0])
                default:
                    result(nil)
                }
            }

        }

        var path = registrar.lookupKey(forAsset: "")
        if let subPath = args?["path"] as? String {
            path = path + subPath
        }

        switch call.method {
        case "list":
            if let realPath = bundle.path(forResource: path, ofType: nil),
                let contents = try? FileManager.default.contentsOfDirectory(atPath: realPath).map {path in path} {
              result(contents)
            } else {
                result([]);
            }
        case "open":
            if let realPath = bundle.path(forResource: path, ofType: nil),
                let fd = FileHandle(forReadingAtPath: realPath) {
                let key = UUID().uuidString
                streams[key] = fd
                result(key)
            }
        default:
            result(nil)
        }
    }
}
