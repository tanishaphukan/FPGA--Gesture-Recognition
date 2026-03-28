# Documentation Index

Complete guide to all documentation files in this project.

## 🚀 Quick Start (Start Here!)

| Document | Purpose | Time |
|----------|---------|------|
| **[QUICKSTART.md](QUICKSTART.md)** | Main quick start guide | 5 min |
| **[QUICKSTART_FPGA.md](QUICKSTART_FPGA.md)** | FPGA deployment quick start | 5 min |
| **[SPARTAN_QUICKSTART.md](SPARTAN_QUICKSTART.md)** | Spartan board quick start | 3 min |

**New to the project?** Start with `QUICKSTART.md`

---

## 📘 Deployment Guides

### General FPGA Deployment

| Document | Purpose | Audience |
|----------|---------|----------|
| **[FPGA_DEPLOYMENT_GUIDE.md](FPGA_DEPLOYMENT_GUIDE.md)** | Complete step-by-step FPGA guide | All users |
| **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** | Overview of deployment process | All users |
| **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** | Verification checklist | All users |

### Spartan-Specific

| Document | Purpose | Audience |
|----------|---------|----------|
| **[SPARTAN_DEPLOYMENT.md](SPARTAN_DEPLOYMENT.md)** | Complete Spartan board guide | Spartan users |
| **[SPARTAN_SUMMARY.md](SPARTAN_SUMMARY.md)** | Spartan support overview | Spartan users |
| **[docs/board_comparison.txt](docs/board_comparison.txt)** | Visual board comparison | Board selection |

**Using Basys 3 or Spartan-6?** Read `SPARTAN_DEPLOYMENT.md`

---

## 🧠 Machine Learning

| Document | Purpose | Audience |
|----------|---------|----------|
| **[ml_model/README_ML_PIPELINE.md](ml_model/README_ML_PIPELINE.md)** | ML pipeline documentation | ML developers |
| **[ml_model/train_with_real_dataset.py](ml_model/train_with_real_dataset.py)** | Training script (with comments) | ML developers |

**Want to understand the model?** Read `ml_model/README_ML_PIPELINE.md`

---

## 🔧 System Architecture

| Document | Purpose | Audience |
|----------|---------|----------|
| **[docs/system_architecture.md](docs/system_architecture.md)** | System design overview | Architects |
| **[docs/hardware_specifications.md](docs/hardware_specifications.md)** | Hardware specs | Hardware engineers |
| **[docs/fpga_implementation_guide.md](docs/fpga_implementation_guide.md)** | FPGA implementation details | FPGA developers |
| **[docs/system_block_diagram.txt](docs/system_block_diagram.txt)** | Visual block diagram | All users |
| **[docs/fpga_deployment_workflow.txt](docs/fpga_deployment_workflow.txt)** | Visual deployment workflow | All users |

**Want to understand the system?** Start with `docs/system_architecture.md`

---

## 📜 Scripts and Automation

### TCL Scripts (Vivado)

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **[create_vivado_project.tcl](create_vivado_project.tcl)** | Creates Vivado project | First time setup |
| **[run_complete_flow.tcl](run_complete_flow.tcl)** | Runs synthesis → bitstream | Build automation |
| **[program_fpga.tcl](program_fpga.tcl)** | Programs FPGA board | After build |

### Platform Scripts

| Script | Purpose | Platform |
|--------|---------|----------|
| **[build_and_program.bat](build_and_program.bat)** | Complete automation | Windows |
| **[build_and_program.sh](build_and_program.sh)** | Complete automation | Linux/Mac |

**Want automation?** Use `build_and_program.bat` (Windows) or `.sh` (Linux/Mac)

---

## 🗂️ Hardware Files

### RTL (Verilog)

| File | Purpose |
|------|---------|
| **[fpga_rtl/top_module.v](fpga_rtl/top_module.v)** | Top-level integration |
| **[fpga_rtl/emg_preprocessor.v](fpga_rtl/emg_preprocessor.v)** | Signal preprocessing |
| **[fpga_rtl/conv1d_layer.v](fpga_rtl/conv1d_layer.v)** | Convolutional layer |
| **[fpga_rtl/dense_layer.v](fpga_rtl/dense_layer.v)** | Fully connected layer |
| **[fpga_rtl/mac_unit.v](fpga_rtl/mac_unit.v)** | Multiply-accumulate unit |
| **[fpga_rtl/weight_memory.v](fpga_rtl/weight_memory.v)** | Weight storage |
| **[fpga_rtl/argmax.v](fpga_rtl/argmax.v)** | Classification output |

### Constraints

| File | Purpose | Board |
|------|---------|-------|
| **[fpga_rtl/constraints.xdc](fpga_rtl/constraints.xdc)** | Timing constraints | All boards |
| **[fpga_rtl/pin_assignments_arty_a7.xdc](fpga_rtl/pin_assignments_arty_a7.xdc)** | Pin mapping | Arty A7 |
| **[fpga_rtl/pin_assignments_basys3.xdc](fpga_rtl/pin_assignments_basys3.xdc)** | Pin mapping | Basys 3 |
| **[fpga_rtl/pin_assignments_spartan6.xdc](fpga_rtl/pin_assignments_spartan6.xdc)** | Pin mapping | Spartan-6 |

---

## 🧪 Testing and Simulation

| File | Purpose |
|------|---------|
| **[simulation/system_simulator.py](simulation/system_simulator.py)** | System-level simulation |
| **[testbenches/tb_mac_unit.v](testbenches/tb_mac_unit.v)** | MAC unit testbench |

---

## 📊 Workflow Documents

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[docs/deployment_workflow.md](docs/deployment_workflow.md)** | Detailed workflow | Planning deployment |
| **[docs/COMPLETE_WORKFLOW_GUIDE.md](docs/COMPLETE_WORKFLOW_GUIDE.md)** | End-to-end guide | Understanding full system |

---

## 📖 Main Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[README.md](README.md)** | Project overview | Everyone |
| **[requirements.txt](requirements.txt)** | Python dependencies | Setup |

---

## 🎯 Documentation by Use Case

### "I want to deploy to FPGA quickly"
1. Read: `QUICKSTART_FPGA.md`
2. Run: `build_and_program.bat` or `.sh`
3. Check: `DEPLOYMENT_CHECKLIST.md`

### "I have a Basys 3 board"
1. Read: `SPARTAN_QUICKSTART.md`
2. Configure: Edit `create_vivado_project.tcl`
3. Deploy: Run automation script
4. Reference: `SPARTAN_DEPLOYMENT.md`

### "I want to understand the system"
1. Read: `README.md`
2. Read: `docs/system_architecture.md`
3. Read: `docs/COMPLETE_WORKFLOW_GUIDE.md`
4. View: `docs/system_block_diagram.txt`

### "I want to modify the ML model"
1. Read: `ml_model/README_ML_PIPELINE.md`
2. Edit: `ml_model/train_with_real_dataset.py`
3. Run: Training script
4. Deploy: New weights to FPGA

### "I want to choose a board"
1. Read: `docs/board_comparison.txt`
2. Read: `SPARTAN_DEPLOYMENT.md` (Board-specific notes)
3. Decide: Basys 3 recommended!

### "I'm having issues"
1. Check: `DEPLOYMENT_CHECKLIST.md`
2. Read: Troubleshooting in `FPGA_DEPLOYMENT_GUIDE.md`
3. Read: Board-specific troubleshooting in `SPARTAN_DEPLOYMENT.md`

---

## 📁 File Organization

```
Project Root
│
├── 📄 Quick Start Guides
│   ├── QUICKSTART.md
│   ├── QUICKSTART_FPGA.md
│   └── SPARTAN_QUICKSTART.md
│
├── 📘 Deployment Guides
│   ├── FPGA_DEPLOYMENT_GUIDE.md
│   ├── SPARTAN_DEPLOYMENT.md
│   ├── DEPLOYMENT_SUMMARY.md
│   ├── SPARTAN_SUMMARY.md
│   └── DEPLOYMENT_CHECKLIST.md
│
├── 🔧 Scripts
│   ├── create_vivado_project.tcl
│   ├── run_complete_flow.tcl
│   ├── program_fpga.tcl
│   ├── build_and_program.bat
│   └── build_and_program.sh
│
├── 📚 Documentation (docs/)
│   ├── system_architecture.md
│   ├── hardware_specifications.md
│   ├── fpga_implementation_guide.md
│   ├── deployment_workflow.md
│   ├── COMPLETE_WORKFLOW_GUIDE.md
│   ├── system_block_diagram.txt
│   ├── fpga_deployment_workflow.txt
│   └── board_comparison.txt
│
├── 🧠 ML Model (ml_model/)
│   ├── README_ML_PIPELINE.md
│   ├── train_with_real_dataset.py
│   ├── train_cnn.py
│   ├── quantize_model.py
│   └── export_weights.py
│
├── 🗂️ FPGA RTL (fpga_rtl/)
│   ├── *.v (Verilog modules)
│   └── *.xdc (Constraints)
│
└── 🧪 Testing (simulation/, testbenches/)
    ├── system_simulator.py
    └── tb_*.v
```

---

## 🎓 Learning Path

### Beginner
1. `README.md` - Understand project
2. `QUICKSTART.md` - Get started
3. `QUICKSTART_FPGA.md` - Deploy to FPGA
4. `DEPLOYMENT_CHECKLIST.md` - Verify success

### Intermediate
1. `docs/system_architecture.md` - System design
2. `ml_model/README_ML_PIPELINE.md` - ML pipeline
3. `FPGA_DEPLOYMENT_GUIDE.md` - Detailed deployment
4. `docs/fpga_implementation_guide.md` - FPGA details

### Advanced
1. `docs/COMPLETE_WORKFLOW_GUIDE.md` - Full workflow
2. RTL source files - Hardware implementation
3. `docs/deployment_workflow.md` - Production deployment
4. Modify and optimize system

---

## 📊 Document Statistics

- **Total Documents**: 25+
- **Quick Start Guides**: 3
- **Deployment Guides**: 5
- **Technical Docs**: 7
- **Scripts**: 5
- **RTL Files**: 7
- **Constraint Files**: 4

---

## 🔍 Search by Topic

### Board Selection
- `docs/board_comparison.txt`
- `SPARTAN_DEPLOYMENT.md` (Board-specific notes)

### Deployment
- `FPGA_DEPLOYMENT_GUIDE.md`
- `DEPLOYMENT_SUMMARY.md`
- `DEPLOYMENT_CHECKLIST.md`

### Spartan Boards
- `SPARTAN_DEPLOYMENT.md`
- `SPARTAN_QUICKSTART.md`
- `SPARTAN_SUMMARY.md`

### Machine Learning
- `ml_model/README_ML_PIPELINE.md`
- `ml_model/train_with_real_dataset.py`

### System Architecture
- `docs/system_architecture.md`
- `docs/system_block_diagram.txt`
- `docs/COMPLETE_WORKFLOW_GUIDE.md`

### Troubleshooting
- `DEPLOYMENT_CHECKLIST.md`
- `FPGA_DEPLOYMENT_GUIDE.md` (Troubleshooting section)
- `SPARTAN_DEPLOYMENT.md` (Troubleshooting section)

---

## 💡 Tips

- **Start simple**: Begin with quick start guides
- **Visual learners**: Check `.txt` files for ASCII diagrams
- **Board-specific**: Read Spartan docs if using Basys 3 or Spartan-6
- **Troubleshooting**: Always check the checklist first
- **Learning**: Follow the learning path above

---

## 📞 Still Need Help?

1. Check the relevant documentation above
2. Review troubleshooting sections
3. Open an issue on GitHub
4. Check Xilinx forums for FPGA-specific issues

---

**Happy deploying!** 🚀
