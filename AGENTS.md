# Disposable package-CI live validation

This is the user-authorized VOC-Experiments sandbox, separate from SNodeC. Canonical coordinator code must match the verified task bytes; deployment config/content and dummy source hooks differ. Workspace: /tmp/codex/checkouts/VOC-Experiments-demo-core/canonical-ci-live-validation. Temporary builds: /tmp/codex/build/VOC-Experiments/canonical-ci-live-validation. Retain until live verification and user-directed cleanup; do not delete unmerged evidence. No production SNodeC credentials or feed writes.

Applicable C format/analysis/editor baselines are committed locally; Makefile format/format-check invoke the canonical clang-format configuration. CMake modules do not apply. Native and OpenWrt packaging hooks own all product build commands.
