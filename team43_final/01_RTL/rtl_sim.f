// -----------------------------------------------------------------------------
// Simulation: CVSD 2024 Spring Final Project
// -----------------------------------------------------------------------------

// Simulation Settings
// -----------------------------------------------------------------------------
+v2k 
-debug_access+all 
-P /usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/novas.tab
/usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/pli.a
-sverilog
+notimingcheck

// Verilog Library Extensions
// -----------------------------------------------------------------------------
+libext+.v+.sv+.vlib

// Module Search Path
// -----------------------------------------------------------------------------
-y /usr/cad/synopsys/synthesis/cur/dw/sim_ver 
+incdir+/usr/cad/synopsys/synthesis/cur/dw/sim_ver/+

// Testbench File
// -----------------------------------------------------------------------------
../00_TESTBED/testbed.sv

// =============================================================================
//                  Your Can Only Modify The Below Part
// =============================================================================

// Your Design Files
// -----------------------------------------------------------------------------
./CSA_add.v
./CPA_add.v
./CSA_sub.v
./CPA_sub.v
./ModSub.v
./ModAdd.v
./ModMul.sv
./point_alu.sv
./ed25519.sv

// Define Flags
// -----------------------------------------------------------------------------
+define+RANDOM_IO_HANDSHAKE+FSDB