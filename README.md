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

## 🗑️ System Cleanup & Factory Reset


The `cleanup_pc.sh` script acts as a destructive rollback engine. It treats your local machine like a disposable environment—allowing you to tear down specific modules or completely reset your operating system back to its original factory defaults (similar to a Docker Desktop reset).

### How it Works
1. **Uninstalls Added Apps:** Reads your `install.properties` files and completely purges those applications.
2. **Restores Bloatware/Defaults:** Reads your `purge.properties` files and re-installs the core system packages that were removed during optimization.
3. **Deep Cleans Leftovers:** Automatically runs an aggressive `autoremove --purge` and clears the local `apt` cache to eliminate orphan library dependencies.
4. **Wipes the Blueprints:** Truncates the targeted `install.properties` files back to a blank canvas so you can start fresh.
   
### Usage Instructions

Before running the script, ensure it has execution permissions:
```bash
chmod +x cleanup_pc.sh

```

#### 1. Targeted Profile Cleanup

If you finished a specific project or semester and want to wipe out only the tools associated with specific modules (e.g., removing chemistry tools but keeping everything else intact):

```bash
sudo ./cleanup_pc.sh chemistry

```

*To remove multiple profiles at once:*

```bash
sudo ./cleanup_pc.sh physics chemistry

```

#### 2. Full Factory Reset (The "Clean Slate")

To completely undo all modifications, restore all original Ubuntu default software, purge all custom applications, and clear out every single `install.properties` file across the repository, run the script **without any arguments**:

```bash
sudo ./cleanup_pc.sh

```

---

### ⚠️ Important Notes

* **Destructive Action:** Running this script with no arguments will clear the contents of your `install.properties` files. Back up your properties files if you wish to reuse those specific application lists later.
* **Log Tracking:** Every single uninstallation, restoration, or error is cleanly caught and saved to `./pc_cleanup.log` for debugging.


