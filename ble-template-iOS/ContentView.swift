//
//  ContentView.swift
//  ble-template-iOS
//
//  Created by 周子傑 on 2023/7/4.
//

import SwiftUI
import CoreBluetooth

class StringListState: ObservableObject {
    @Published var strings: [String] = []
}


struct ContentView: View {
    @EnvironmentObject var cbManager: CBManager
    @StateObject var test: StringListState = StringListState()
    @State private var n = 0
    @State private var showDetail: Bool = false
    var body: some View {
        NavigationView {
            VStack {
                //                Button {
                //                    test.strings.append("\(n)")
                //                    n += 1
                //                } label: {
                //                    Text("\(n)")
                //                }
                List(cbManager.discoverPeripherals, id: \.self) { peripheral in
                    NavigationLink(
                        destination: DetailView(peripheral),
                        label: {
                            Text(peripheral.name!)
                        }
                    )
                }
            }
            .navigationTitle("掃描頁面")
        }
    }
}

struct DetailView:View{
    @EnvironmentObject var cbManager: CBManager
    @State private var peripheral: CBPeripheral
    @State private var state = true
    @State private var brightness = 0.0
    @State private var mode = "Normal"
    private let modes = ["Normal", "Breathing"]
    
    init(_ peripheral:CBPeripheral){
        self.peripheral = peripheral
    }
    
    var body: some View {
        ZStack(alignment: .topLeading){
            VStack(alignment: .leading,spacing: 10.0) {
                Text("Led State:")
                Button{
                    state = !state
                    cbManager.writeState(state)
                } label: {
                    Text(state ? "off" : "on")
                }.onReceive(cbManager.$state){ value in
//                    print(value)
                    state = value ?? false
                }
                Text("Led Brightness")
                Slider(value: $brightness, in: 0...255, step: 1)
                    .onChange(of: brightness){ value in
                        cbManager.writeBrightness(UInt8(value))
                    }
                    .padding()
                    .onReceive(cbManager.$brightness){ value in
    //                    print(value)
                        brightness = Double(value ?? 0)
                    }
                Text("Led Mode")
                Picker(selection: $mode, label: Text("Options")) {
                    ForEach(modes,id: \.self) { option in
                        Text(option)
                    }
                }
                .onChange(of: mode){ value in
                    cbManager.writeMode(UInt8(modes.firstIndex(of: value)!+1))
                }
                .onReceive(cbManager.$mode){ value in
//                    print(value)
                    mode = modes[Int(value ?? 1)-1]
                }
                .pickerStyle(MenuPickerStyle())
                Spacer()
            }
            .padding()
    //        .padding(.all,16)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        cbManager.isConnected ? cbManager.disconnectPeripheral() : cbManager.connectPeripheral(peripheral)
                    } label: {
                        Text(cbManager.isConnected ? "Disconnect" : "Connect")
                    }
                }
            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.onDisappear{
            print("detail page onDisappear")
            cbManager.disconnectPeripheral()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
