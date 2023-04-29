/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

@MainActor
class QuoteViewModel: ObservableObject {
  @Published var quote = Quote.example
  var decoder = JSONDecoder()
  
  func getQuotes() async throws {
    
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 5
    let session = URLSession(configuration: configuration)
    
    guard let url = URL(string: Constants.URL.quote) else {
      print("Invalid quote URL")
      return
    }
    
    Task {
      do {
        let (data, response): (Data, URLResponse)  = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse
        else {
          throw HTTPError.networkError
        }
        
        switch httpResponse.statusCode {
          
        case 100..<200:
          print("quote httpResponse: \(httpResponse.statusCode) -> informational")
          
        case 200..<300:
          print("quote httpResponse: \(httpResponse.statusCode) -> success")
          
        case 300..<400:
          print("quote httpResponse: \(httpResponse.statusCode) -> redirection")
          
        case 400..<500:
          print("quote httpResponse: \(httpResponse.statusCode) -> client error")
          throw HTTPError.clientError
          
        case 500..<600:
          print("quote httpResponse: \(httpResponse.statusCode) -> server error")
          throw HTTPError.serverError
          
        default:
          print("quote httpResponse: \(httpResponse.statusCode) -> undefined status code")
          throw HTTPError.undefinedStatus
        }
        
        if data.isEmpty {
          print("No data in quote response from \(url).")
          return
        }
        
        guard let decodedData = try? decoder.decode(Quote.self, from: data) else {
          throw HTTPError.responseDecodingFailed
        }
        
        self.quote = decodedData
        
      } catch  {
        if error.isOtherConnectionError {
          print("The network seems to be offline. Please check your connection.")
          print(error.localizedDescription)
        } else {
          print(error.localizedDescription)
        }
      }
    }
  }
}
