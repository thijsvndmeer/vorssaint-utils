// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// Glance-inspired laser halos, screen-edge waves, and surface finish options
/// rendered under Dynamic Island Settings -> Activity.
struct NotchLightsSettingsCard: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.notchLightsEnabled) private var lightsEnabled = true
    @AppStorage(DefaultsKey.notchHaloStyle) private var haloStyle = NotchHaloStyle.rays.rawValue
    @AppStorage(DefaultsKey.notchHaloArmWidth) private var armWidth = NotchHaloArmWidth.medium.rawValue
    @AppStorage(DefaultsKey.notchHaloThickness) private var thickness = 1.0
    @AppStorage(DefaultsKey.notchHaloEntry) private var entryMode = NotchHaloEntryMode.sweep.rawValue
    @AppStorage(DefaultsKey.notchHaloMotion) private var motion = NotchHaloMotion.ondulation.rawValue
    @AppStorage(DefaultsKey.notchHaloTransition) private var transition = NotchHaloTransitionEffect.hybrid.rawValue
    @AppStorage(DefaultsKey.notchEdgeWaveEnabled) private var edgeWaveEnabled = true
    @AppStorage(DefaultsKey.notchLightSurfaceStyle) private var lightSurfaceStyle = NotchLightSurfaceStyle.neon.rawValue
    @AppStorage(DefaultsKey.notchLightsAgentActivity) private var agentActivity = true
    @AppStorage(DefaultsKey.notchLightsMusicActivity) private var musicActivity = true
    @AppStorage(DefaultsKey.notchLightsCopySweep) private var copySweep = true
    @AppStorage(DefaultsKey.notchLightsNotices) private var notices = true

    var body: some View {
        let lights = NotchLightsStrings.localized(l10n.language)
        SettingsCard(title: lights.title) {
            SettingsRow(symbol: "sparkles", title: lights.enable, caption: lights.description) {
                Toggle(lights.enable, isOn: $lightsEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            if lightsEnabled {
                SettingsMenuRow(symbol: "wand.and.stars", title: lights.style, selection: $haloStyle) {
                    ForEach(NotchHaloStyle.allCases) { item in
                        Text(lights.styleName(item)).tag(item.rawValue)
                    }
                }
                SettingsChoiceRow(symbol: "arrow.left.and.right", title: lights.armWidth, selection: $armWidth) {
                    ForEach(NotchHaloArmWidth.allCases) { item in
                        Text(lights.armWidthName(item)).tag(item.rawValue)
                    }
                }
                SettingsRow(symbol: "dial.medium", title: lights.thickness) {
                    Slider(
                        value: Binding(
                            get: { NotchLightsSupport.clampedThickness(thickness) },
                            set: { thickness = NotchLightsSupport.clampedThickness($0) }
                        ),
                        in: NotchLightsSupport.thicknessRange,
                        step: 0.05
                    ) {
                        Text(lights.thickness)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsChoiceRow(symbol: "bolt.horizontal", title: lights.entry, selection: $entryMode) {
                    ForEach(NotchHaloEntryMode.allCases) { item in
                        Text(lights.entryName(item)).tag(item.rawValue)
                    }
                }
                SettingsMenuRow(symbol: "waveform.path", title: lights.motion, selection: $motion) {
                    ForEach(NotchHaloMotion.allCases) { item in
                        Text(lights.motionName(item)).tag(item.rawValue)
                    }
                }
                SettingsMenuRow(symbol: "sparkles.rectangle.stack", title: lights.transition, selection: $transition) {
                    ForEach(NotchHaloTransitionEffect.allCases) { item in
                        Text(lights.transitionName(item)).tag(item.rawValue)
                    }
                }
                SettingsRow(symbol: "circle.dashed", title: lights.edgeWave, caption: lights.edgeWaveHint) {
                    Toggle(lights.edgeWave, isOn: $edgeWaveEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SettingsChoiceRow(symbol: "sun.max", title: lights.lightSurface, selection: $lightSurfaceStyle) {
                    ForEach(NotchLightSurfaceStyle.allCases) { item in
                        Text(lights.surfaceName(item)).tag(item.rawValue)
                    }
                }
                Text(lights.lightSurfaceHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, settingsRowTextInset)
                Divider()
                SettingsRow(symbol: "cpu", title: lights.agentActivity) {
                    Toggle(lights.agentActivity, isOn: $agentActivity)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SettingsRow(symbol: "music.note", title: lights.musicActivity) {
                    Toggle(lights.musicActivity, isOn: $musicActivity)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SettingsRow(symbol: "doc.on.clipboard", title: lights.copySweep) {
                    Toggle(lights.copySweep, isOn: $copySweep)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SettingsRow(symbol: "bell", title: lights.notices) {
                    Toggle(lights.notices, isOn: $notices)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                Divider()
                SettingsRow(symbol: "play.circle", title: lights.preview) {
                    HStack(spacing: 8) {
                        Button(lights.previewHalo) {
                            NotchHaloController.shared.previewHalo()
                        }
                        Button(lights.previewWave) {
                            NotchHaloController.shared.previewEdgeWave()
                        }
                    }
                }
            }
        }
        .onChange(of: [
            String(lightsEnabled), haloStyle, armWidth, String(thickness), entryMode, motion, transition,
            String(edgeWaveEnabled), lightSurfaceStyle, String(agentActivity), String(musicActivity),
            String(copySweep), String(notices)
        ]) { _, _ in
            NotchHaloController.shared.syncWithPreferences()
        }
    }
}
