ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:17.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = JetsamChanger

JetsamChanger_FILES = \
    JetsamChanger/App/JetsamChangerApp.swift \
    JetsamChanger/Core/Kernel/KernelMemory.c \
    JetsamChanger/Core/Kernel/KernelExploit.m \
    JetsamChanger/Core/Kernel/JetsamModifier.m \
    JetsamChanger/Core/Process/ProcessManager.swift \
    JetsamChanger/UI/Theme.swift \
    JetsamChanger/UI/ContentView.swift \
    JetsamChanger/UI/ProcessDetailView.swift \
    JetsamChanger/UI/KernelConsoleView.swift

JetsamChanger_CFLAGS = -fobjc-arc -I./JetsamChanger/Core/Kernel
JetsamChanger_SWIFTFLAGS = -import-objc-header JetsamChanger/JetsamChanger-Bridging-Header.h
JetsamChanger_FRAMEWORKS = UIKit SwiftUI Security
JetsamChanger_LIBRARIES = proc
JetsamChanger_CODESIGN_FLAGS = -SJetsamChanger/Resources/JetsamChanger.entitlements

include $(THEOS_MAKE_PATH)/application.mk
