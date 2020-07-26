import Cocoa
import Combine

let p1 = PassthroughSubject<Int, Never>()
let p2 = PassthroughSubject<Int, Never>()

let s1 = p1.sink { val in
    print("p1: \(val)")
    p2.send(val)
}



let s2 = p2.sink { val in
    print("p2: \(val)")
}

p1.send(2)
