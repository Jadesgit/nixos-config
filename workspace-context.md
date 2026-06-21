# Project State & Architecture Specification

## 👤 User Profile & Environment
- **User:** jade (jadepropix@gmail.com)
- **OS Platform:** NixOS (Channel 26.05 "Yarara")
- **Workflow Style:** Declarative, reproducible, multi-machine Git-tracked Flakes.
- **License Tier:** Google Workspace Enterprise Standard (Gemini Code Assist Standard)
- **Editor Environment:** Native VS Code (Declarative Flake + Home Manager setup)
- **Additional Tooling:** Claude (Enterprise Team Plan integration)

---

## 🛑 1. What We Have Done (The Baseline)
We have successfully broken out of a standard, single-machine `configuration.nix` setup and engineered a unified, multi-machine Flake architecture. 

### Core Architecture Components:
* **`flake.nix` & `flake.lock`:** Orchestrates version locks and defines two distinct target profiles (`nixos` for desktop, `laptop` for ThinkPad). Both targets map out the same user package ecosystem via Home Manager.
* **`common.nix`:** Contains 80% of the system boilerplate shared by both machines (firewall rules, Tailscale, Mullvad VPN, locale profiles, PipeWire audio layers, Flatpaks, and core utilities).
* **`home-jade.nix`:** A declarative Home Manager profile that synchronizes user-space configurations, default Git identities, and native VS Code extension baselines.
* **Automated System Maintenance:** Implemented automated weekly Garbage Collection (`nix.gc`) and automated store optimization/hard-linking to preserve SSD health.

### Machine Specific Trait Deployments:
* **🖥️ Desktop (`configuration.nix`):** Legacy GRUB bootloader targeting `/dev/nvme0n1`. Uses an output profile workaround ("Pro Audio" via `pavucontrol`) to allow legacy PortAudio applications like SoundWire Server to capture audio at 44.1kHz bypassing PipeWire's default 48kHz consumer mixer limit.
* **💻 Laptop (`laptop.nix`):** Modern UEFI `systemd-boot` configurations. Optimized for a ThinkPad setup using `tlp` (with `power-profiles-daemon` explicitly disabled to prevent CPU governor resource wars). Integrates NVIDIA hybrid graphics switching utilizing verified hardware Bus IDs (`PCI:0:2:0` Intel / `PCI:2:0:0` NVIDIA MX150 Pascal).

---

## 🔄 2. What We Are Doing Right Now
* Activating Gemini Code Assist Standard inside vanilla VS Code using Workspace Enterprise credentials.
* Validating cross-machine repository synchronization via GitHub (`Jadesgit/nixos-config`).
* Importing legacy `docker-compose` configuration profiles to prepare for a headless server rebuild.

---

## 🚀 3. What We Plan To Do (Next Milestones)
Our next major initiative is constructing a headless, automated Home Server running NixOS, replacing manual Docker server maintenance with infrastructure-as-code.

### Server Objectives:
1.  **Declarative Containers:** Migrate raw `docker-compose.yml` stacks directly into native NixOS container declarations (`virtualisation.oci-containers` or declarative Docker configurations).
2.  **Infrastructure Automation:** Ensure the entire server profile is managed via the same Git-tracked Flake pattern so a total hardware failure can be recovered in under 10 minutes.
3.  **Storage & Networking Integration:** Incorporate automated network shares, automated firewalls, and secure remote infrastructure access utilizing our existing Tailscale mesh.