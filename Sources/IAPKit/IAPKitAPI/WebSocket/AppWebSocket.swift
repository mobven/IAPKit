//
//  AppWebSocket.swift
//  API
//
//  Created by Eser Kucuker on 3.06.2025.
//

import Foundation

protocol AppWebSocket {
    var urlRequest: URLRequest { get }
    func start(_ completion: @escaping ((Data) -> Void))
    func send(_ data: Data)
    func cancel()
}

public class BaseWebSocket: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    var urlRequest: URLRequest
    var webSocket: URLSessionWebSocketTask!
    var completion: ((Data) -> Void)!
    public var onConnected: (() -> Void)?
    public var onConnectionError: ((Error?) -> Void)?
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    public var isRunning: Bool {
        guard let webSocket else { return false }
        return webSocket.state == .running
    }

    init(withPath path: String, headers: [String: String]) {
        urlRequest = URLRequest(url: API.getWSURL(withPath: path))
        urlRequest.setValue("Bearer \(User.current.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }
    }

    func start(_ completion: @escaping ((Data) -> Void)) {
        if let existingSocket = webSocket {
            onConnected = nil
            onConnectionError = nil
            existingSocket.cancel(with: .goingAway, reason: nil)
        }

        self.completion = completion
        urlRequest.allHTTPHeaderFields?.updateValue("NO", forKey: "RECONNECTING")
        webSocket = urlSession.webSocketTask(with: urlRequest)
        webSocket.receive(completionHandler: webSocketReceive(_:))
        webSocket.resume()
    }

    func restart() {
        if let existingSocket = webSocket {
            onConnected = nil
            onConnectionError = nil
            existingSocket.cancel(with: .goingAway, reason: nil)
        }

        urlRequest.allHTTPHeaderFields?.updateValue("YES", forKey: "RECONNECTING")
        webSocket = urlSession.webSocketTask(with: urlRequest)
        webSocket.receive(completionHandler: webSocketReceive(_:))
        webSocket.resume()
    }

    func webSocketReceive(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        guard let webSocket else {
            print("WebSocket is nil, cannot receive messages")
            return
        }

        switch result {
        case let .success(message):
            parseMessage(message, completion)
            webSocket.receive(completionHandler: webSocketReceive(_:))
            webSocket.resume()
        case let .failure(error):
            print(error)
            onConnectionError?(error)
        }
    }

    func parseMessage(_ message: URLSessionWebSocketTask.Message, _ completion: @escaping ((Data) -> Void)) {
        if case let .data(data) = message {
            log(data, "RECEIVED")
            completion(data)
        } else if case let .string(string) = message, let data = string.data(using: .utf8) {
            log(data, "RECEIVED")
            completion(data)
        }
    }

    func send(_ data: Data) {
        log(data, "SENT")
        guard let webSocket else {
            print("Cannot send: WebSocket is not connected")
            return
        }
        guard let string = String(data: data, encoding: .utf8) else { return }
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocket.send(message) { error in
            guard let error else { return }
            print(error.localizedDescription)
        }
    }

    func cancel() {
        onConnected = nil
        onConnectionError = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("open websocket")
        onConnected?()
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        print("close websocket")
        if closeCode != .goingAway {
            onConnectionError?(nil)
        }
    }

    func log(_ data: Data, _ key: String) {
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            print("\n\n\n---Networking \(key) Response---")
            print(String(decoding: jsonData, as: UTF8.self))
            print("---Networking \(key) Response---\n\n\n")
        } else {
            print("json data malformed")
        }
    }
}
