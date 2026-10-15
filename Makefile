ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:17.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = JetsamChanger

JetsamChanger_FILES = \
    JetsamChanger/App/JetsamChangerApp.swift \
    JetsamChanger/Core/Kernel/KernelMemory.c \
    JetsamChanger/Core/Kernel/KernelExploit.m \
    JetsamChanger/Core/Kernel/JetsamModifier.m \
    JetsamChanger/Core/Kernel/DylibInjector.m \
    JetsamChanger/Core/Kernel/DaemonManager.m \
    JetsamChanger/Core/Process/ProcessManager.swift \
    JetsamChanger/UI/Theme.swift \
    JetsamChanger/UI/ContentView.swift \
    JetsamChanger/UI/DylibInjectorView.swift \
    JetsamChanger/UI/JITManagerView.swift \
    JetsamChanger/UI/LaunchDaemonsView.swift \
    JetsamChanger/UI/ExploitTweaksView.swift \
    JetsamChanger/UI/AppListView.swift \
    JetsamChanger/UI/ProcessDetailView.swift \
    JetsamChanger/UI/SettingsView.swift \
    JetsamChanger/UI/KernelConsoleView.swift

JetsamChanger_CFLAGS = -fobjc-arc -I./JetsamChanger -I./JetsamChanger/Core/Kernel
JetsamChanger_SWIFTFLAGS = -import-objc-header JetsamChanger/JetsamChanger-Bridging-Header.h -I./JetsamChanger -I./JetsamChanger/Core/Kernel
JetsamChanger_FRAMEWORKS = UIKit SwiftUI Security UniformTypeIdentifiers
JetsamChanger_CODESIGN_FLAGS = -SJetsamChanger/Resources/JetsamChanger.entitlements

include $(THEOS_MAKE_PATH)/application.mk
