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

Everything else (source trees, resources, entitlements, build settings) is
upstream as-is.
