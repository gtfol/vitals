import SwiftData
import SwiftUI

@main struct VitalsApp: App {
    // Created in the app's initializer, not in a view task, so a background relaunch by Bluetooth state
    // restoration recreates the central manager with its restore identifier before any UI exists.
    @State private var launch = AppLaunch()

    var body: some Scene {
        WindowGroup {
            Group {
                if let services = launch.services {
                    RootView()
                        .environment(services.coordinator)
                        .environment(services.monitor)
                        .modelContainer(services.container)
                } else {
                    VStack(spacing: 16) {
                        Text("vitals").font(VitalsStyle.heading)
                        Text("couldn’t open your training log on this iPhone.").font(VitalsStyle.caption)
                            .foregroundStyle(VitalsStyle.secondary)
                        TextAction("try again") { launch.start() }
                    }
                    .padding(VitalsStyle.gutter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(VitalsStyle.canvas)
                }
            }
            .font(VitalsStyle.body)
            .foregroundStyle(VitalsStyle.text)
            .tint(VitalsStyle.text)
            .preferredColorScheme(.dark)
        }
    }
}

@MainActor @Observable final class AppLaunch {
    private(set) var services: AppServices?

    init() { start() }

    func start() {
        services = try? AppServices(directory: URL.applicationSupportDirectory)
    }
}

/// The one local store, the strap monitor, Apple Health, and the coordinator that ties them together.
@MainActor final class AppServices {
    let container: ModelContainer
    let store: WorkoutStore
    let monitor: HeartRateMonitor
    let coordinator: SessionCoordinator

    init(directory: URL, exporter: any WorkoutExporting = HealthKitExporter(), activateBluetooth: Bool = true) throws {
        let container = try VitalsContainer.make(directory: directory)
        let store = WorkoutStore(context: container.mainContext)
        let preferences = try store.preferences()
        let monitor = HeartRateMonitor(restoreIdentifier: "\(Bundle.main.bundleIdentifier ?? "vitals").heart-rate",
                                       strapID: preferences.strapID, strapName: preferences.strapName)
        let coordinator = SessionCoordinator(store: store, exporter: exporter)
        monitor.onReading = { [weak coordinator, weak monitor] reading in
            coordinator?.receive(reading, strapName: monitor?.strapName)
        }
        monitor.onSelectionChange = { [weak coordinator] id, name in
            coordinator?.updateSettings { $0.strapID = id; $0.strapName = name }
        }
        coordinator.launch()
        // Only touch Bluetooth at launch if a strap was chosen before; otherwise wait until the user chooses one.
        if activateBluetooth, preferences.strapID != nil { monitor.activate() }
        self.container = container; self.store = store; self.monitor = monitor; self.coordinator = coordinator
    }
}
