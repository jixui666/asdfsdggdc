Local patches on top of upstream (kept minimal so the upstream sources stay recognisable)
=========================================================================================

1. sing-box-for-apple/sing-box.xcodeproj/project.pbxproj
   Target: SFI (Debug + Release)
   Change: IPHONEOS_DEPLOYMENT_TARGET 15.0 -> 16.0

   Why: SFI/MainView.swift puts a nested `if #available(iOS 26.0, *)` inside a
   `.toolbar { }` builder. `ToolbarContentBuilder.buildIf` is only available from
   iOS 16.0, so the project fails with

       SFI/MainView.swift:113:107: error: 'buildIf' is only available in iOS 16.0 or newer
       SFI/MainView.swift:119:25:  error: 'buildIf' is only available in iOS 16.0 or newer
       SFI/MainView.swift:120:21:  error: 'buildIf' is only available in iOS 16.0 or newer

   Raising the app's deployment target to 16.0 is the least invasive fix: the app
   bundle itself keeps the code untouched, and the resulting ipa installs on
   iOS 16 and newer.

   Note: the other targets in the project keep their own deployment targets
   (ApplicationLibrary 15.0, extensions 16.0, WidgetExtension 18.0). If a future
   build reports the embedded WidgetExtension as incompatible, raise SFI to 18.0
   as well.

2. sing-box-for-apple/Library/Shared/FilePath.swift
   Change: `defaultSharedDirectory` no longer force-unwraps the App Group container.

   Why: upstream is

       private static let defaultSharedDirectory: URL! =
           FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)
       #if os(iOS)
           public static let sharedDirectory = defaultSharedDirectory!
       #endif

   An ipa re-signed with a free Apple ID has a profile without
   `com.apple.security.application-groups`, so the container lookup returns nil and
   the force unwrap traps inside the lazy initialiser of `sharedDirectory`
   (`Library.framework` +0x96fb0) — measured on the failing build as
   EXC_BREAKPOINT / SIGTRAP ~80 ms after launch:

       sing-box-2026-11-12-145425.ips
       modelCode iPhone16,1, iPhone OS 27.0.1 (24A446), 1.14.8 (10)
       exception EXC_BREAKPOINT, code 0x1, 0x10380efb0  (Library base 0x103714000 + 0x96fb0)
       frames: __pthread_kill / pthread_kill / raise /
               runtime.raise_trampoline.abi0 / runtime.asmcgocall.abi0

   (the Go frames are the tail of the combined SIGTRAP handler chain that
   ApplicationDelegate installs via LibboxPrepareCrashSignalHandlers +
   NativeCrashReporter + LibboxReinstallCrashSignalHandlers — the trap itself is
   Swift's nil unwrap in FilePath.swift)

   The patch falls back to `Application Support` inside the app's own sandbox,
   which keeps the UI usable for sideloaded builds. It does not grant the
   NetworkExtension entitlement, so the tunnel still needs a paid team + a
   profile that carries `com.apple.developer.networking.networkextension` and the
   App Group — with those, the upstream code path is used unchanged.

