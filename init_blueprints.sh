#!/bin/bash

echo "Initializing Ubuntu Blueprint structure with Snap-aware properties..."

mkdir -p ./physics
mkdir -p ./chemistry

# 1. Base Install Configuration
cat << 'EOF' > ./install.properties
# Baseline Installation Properties
inkscape = Inkscape Vector Graphics Editor (Great for drawing any lab diagram)
EOF

# 2. Base Purge Configuration (Updated with snap: modifiers)
cat << 'EOF' > ./purge.properties
# Baseline Purge Properties - Gaming Apps (APT)
aisleriot = Solitaire Card Games
gnome-mines = Minesweeper Game
gnome-sudoku = Sudoku Puzzle Game
gnome-mahjongg = Mahjongg Tile Game

# Baseline Purge Properties - Media Apps (APT)
rhythmbox = Rhythmbox Music Player
totem = Totem (Ubuntu Default Video Player)

# Baseline Purge Properties - LibreOffice Suite (APT)
libreoffice-core = LibreOffice Core Engine
libreoffice-common = LibreOffice Shared Common Files

# Baseline Purge Properties - Modern Snap Applications
snap:thunderbird = Thunderbird Mail Client (Managed via Snap)
EOF

# 3. Physics Configuration
cat << 'EOF' > ./physics/install.properties
# Physics Module Installation Properties
stellarium = Stellarium (3D Planetarium Simulation)
step = Step (KDE Interactive 2D Physics Simulator)
python3-matplotlib = Python 3 Matplotlib (Custom engineering plots)
octave = GNU Octave (Matrix laboratory for physics calculations)
gnuplot = Gnuplot (Command-line Mathematical Graphing Engine)
python3-numpy = Python 3 NumPy (Numerical computation framework)
grace = Grace (WYSIWYG 2D Plotting Tool)
texlive-science = TeX Live Science (LaTeX equations and structures)
EOF

cat << 'EOF' > ./physics/purge.properties
# Physics Module Purge Properties
EOF

# 4. Chemistry Configuration
cat << 'EOF' > ./chemistry/install.properties
# Chemistry Module Installation Properties
avogadro = Avogadro (Molecular Editor and Modeling)
kalzium = Advanced Interactive Periodic Table (Kalzium)
chemtool = Chemtool (Chemical Structure Drawing Program)
EOF

cat << 'EOF' > ./chemistry/purge.properties
# Chemistry Module Purge Properties
EOF

echo "Initialization Complete! Run cleanup_pc.sh next to process the changes."