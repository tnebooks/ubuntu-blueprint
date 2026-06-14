# Edubuntu Workstation Provisioning Tool

This project provides an automated, configuration-driven system to optimize stock Edubuntu/Ubuntu installations for specific school labs (like Physics or Chemistry).

It uses a **base + profile architecture** to remove generic clutter (like desktop games or preschool apps) and install specialized scientific tools in a single command.

---

## 🔬 Why and What We Do

### The Problem

Out-of-the-box operating systems come with many unneeded applications. Manually configuring individual computers for specialized high school or university labs is time-consuming, prone to human error, and difficult to repeat cleanly.

### Our Solution

This tool automates the cleanup and setup process using lightweight configuration tables.

1. **Baseline Cleanup & Setup:** Runs a global pass on all machines to remove consumer games and install universal essentials (like VLC and Java).
2. **Profile Adaptation:** Layers subject-specific configurations (e.g., Physics or Chemistry) dynamically over the baseline layout depending on the target classroom.
3. **Idempotency:** Uses `dpkg-query` state checking so you can safely run the script multiple times on the same machine without breaking anything or reinstalling existing apps.

---

## 📁 Repository Structure

Ensure your project folders and files match this tree structure before running:

```text
TEACHER_MACHINE/
├── optimize_pc.sh             # Core execution engine
├── install.properties         # Universal apps for ALL machines (e.g., VLC, JRE)
├── purge.properties           # Universal bloatware to remove (e.g., stock games)
├── physics/
│   ├── install.properties     # Physics-only tools (Stellarium, Step, SciDAVis)
│   └── purge.properties       # Physics overrides (e.g., removing chemistry tools)
└── chemistry/
    ├── install.properties     # Chemistry-only tools (Avogadro, Chemtool)
    └── purge.properties       # Chemistry overrides (e.g., removing physics tools)

```

---

## 🚀 Setup and Run

Follow these quick steps to deploy the provisioning suite on a target workstation.

### 1. Download the Project

Clone the repository to the machine you want to configure:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

```

### 2. Grant Execution Permissions

Make the core script executable by updating its security flags:

```bash
chmod +x optimize_pc.sh

```

### 3. Run the Script with a Target Profile

Execute the script using `sudo`. 

* **For a Standard Machine (Baseline configuration only):**
```bash
sudo ./optimize_pc.sh

```

Pass the name of your specific subfolder profile as an argument:

* **For a Physics Machine:**
```bash
sudo ./optimize_pc.sh physics

```

* **For a Physics & Chemistry Machine:**
```bash
sudo ./optimize_pc.sh physics chemistry

`

### 4. Review the Output

Once completed, the script outputs a comprehensive transaction record detailing every action taken. You can review this anytime:

```bash
cat pc_management.log

```
