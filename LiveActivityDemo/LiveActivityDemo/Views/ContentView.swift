import ActivityKit
import LiveActivityContent
import SwiftUI

struct ContentView: View {
    @State private var activity: Activity<ScoreActivityAttributes>?
    @State private var allActivities: [Activity<ScoreActivityAttributes>] = []

    @State private var demoContent = DemoContent()
    @State private var pushTokenString: String = ""
    @State private var pushTokenUpdateString: String = ""
    @State private var channelId: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity Operations").font(.headline)

                if let activity {
                    Text("Current Activity: \(activity.id)")
                    
                }
                
                HStack {
                    Button("Start", action: startActivity)

                    Menu("Update", content: {
                        Button("match start", action: { updateActivity(newState: demoContent.matchStart()) })
                        Button("first goal", action: { updateActivity(newState: demoContent.firstGoal()) })
                        Button("half time", action: { updateActivity(newState: demoContent.halfTime()) })
                        Button("second goal", action: { updateActivity(newState: demoContent.secondGoal()) })
                        Button("third goal", action: { updateActivity(newState: demoContent.thirdGoal()) })
                    })
                    .disabled(activity == nil)

                    Button("End", action: finishActivity)
                        .disabled(activity == nil)
                }
                .buttonStyle(.borderedProminent)
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Push Token").font(.headline)
                }
                Text(pushTokenString.isEmpty ? "Fetching push token..." : pushTokenString)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Copy Push Token") {
                    UIPasteboard.general.string = pushTokenString
                }
                .buttonStyle(.bordered)
            }
            .padding()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Push Update Token").font(.headline)
                }
                Text(pushTokenString.isEmpty ? "Fetching push update token..." : pushTokenUpdateString)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Copy Push Update Token") {
                    UIPasteboard.general.string = pushTokenUpdateString
                }
                .buttonStyle(.bordered)
            }
            .padding()
             VStack(alignment: .leading, spacing: 16) {
                Text("Start Activity with Channel ID").font(.headline)
                TextField("Enter Channel ID", text: $channelId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Start Activity with Channel ID") {
                    startLiveActivityWithChannel(channelId: channelId)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Activity List").font(.headline)

                    Spacer()
                    Button("Get Push Update Token", action: getPushUpdate)
                    Button("Refresh", action: refreshActivities)
                }

                if allActivities.isEmpty {
                    Text("No activities running at the moment")
                } else {
                    ForEach(allActivities) { activity in
                        Text(activity.id)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: refreshActivities)
        .padding()
        .navigationTitle("Live Activity Demo")
        .task { await requestPushPermissions() }
    }

    func refreshActivities() {
        allActivities = Activity<ScoreActivityAttributes>.activities
        activity = allActivities.first
        Task {
            for await pushToken in Activity<ScoreActivityAttributes>.pushToStartTokenUpdates {
                let pushTokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
                print("=== [START] ScoreActivityAttributes: \(pushTokenString)")
                DispatchQueue.main.async {
                                   self.pushTokenString = pushTokenString
                               }
            }
        }
    }
    
    func getPushUpdate() {
        print("start get")
        Task {
            for await activityData in Activity<ScoreActivityAttributes>.activityUpdates {
                for await tokenData in activityData.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    print("=== [UPDATE] 22 ScoreActivityAttributes [\(activityData.id)] : \(token)")
                    DispatchQueue.main.async {
                                       self.pushTokenUpdateString = token
                    }
                }

               
            }
        }
    }
    func requestPushPermissions() async {
        do {
            let _ = try await UNUserNotificationCenter
                .current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            print("got authorization")
        } catch {
            print("error requesting authorization: \(error)")
        }
    }

    static func listenForTokenToStartActivityViaPush() {
        Task {
            for await pushToken in Activity<ScoreActivityAttributes>.pushToStartTokenUpdates {
                let pushTokenString = pushToken.reduce("") { $0 + String(format: "%02x", $1) }
                print("=== [START] ScoreActivityAttributes: \(pushTokenString)")
            
            }
        }
    }

    static func listenForTokenToUpdateActivityViaPush() {
        Task {
            for await activityData in Activity<ScoreActivityAttributes>.activityUpdates {
                for await tokenData in activityData.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    print("=== [UPDATE] ScoreActivityAttributes [\(activityData.id)] : \(token)")
                }

                for await stateUpdate in activityData.activityStateUpdates {
                    print("=== [STATE] ScoreActivityAttributes [\(activityData.id)] : \(stateUpdate)")
                }

                for await newContent in activityData.contentUpdates {
                    print("=== [CONTENT] ScoreActivityAttributes [\(activityData.id)] : \(newContent)")
                }
                for await newContent in activityData.contentUpdates {
                    print("=== [CONTENT] ScoreActivityAttributes [\(activityData.id)] : \(newContent)")
                }
            }
        }
    }

    func startActivity() {
        let attrs = ScoreActivityAttributes.previewValue()

        let initialState = ScoreActivityAttributes.ContentState.previewValue(
            matchState: .notYetStarted,
            blueTeamScore: 0,
            redTeamScore: 0
        )
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: .token
            )

        } catch {
            print(error.localizedDescription)
        }
    }

    func updateActivity(newState: ScoreActivityAttributes.ContentState) {
        guard let activity else { return }

        Task { @MainActor in
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(
                content,
                alertConfiguration: .init(
                    title: "New content!",
                    body: "The match is getting interesting",
                    sound: .default
                )
            )
        }
    }
    
        func startLiveActivityWithChannel(channelId: String) {
            print(channelId)
            let attrs = ScoreActivityAttributes.previewValue()

            let initialState = ScoreActivityAttributes.ContentState.previewValue(
                matchState: .notYetStarted,
                blueTeamScore: 0,
                redTeamScore: 0
            )
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: .channel(channelId)
            )

        } catch {
            print(error.localizedDescription)
        }
    }
    func finishActivity() {
        guard let activity else { return }

        Task {
            let finalContent = demoContent.matchEnded()
            let dismissalPolicy: ActivityUIDismissalPolicy = .default

            await activity.end(
                ActivityContent(state: finalContent, staleDate: nil),
                dismissalPolicy: dismissalPolicy
            )

            self.activity = nil
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
