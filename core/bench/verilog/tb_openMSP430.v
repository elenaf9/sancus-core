//----------------------------------------------------------------------------
// Copyright (C) 2017 Authors
//
// This source file may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// This source file is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// This source is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
// License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this source; if not, write to the Free Software Foundation,
// Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
//
//----------------------------------------------------------------------------
// 
// *File Name: tb_openMSP430.v
// 
// *Module Description:
//                      openMSP430 testbench and Sancus simulator
//
// *Author(s):
//              - Olivier Girard,    olgirard@gmail.com
//              - Job Noorman,       job.noorman@cs.kuleuven.be
//              - Jo Van Bulck,      jo.vanbulck@cs.kuleuven.be
//
//----------------------------------------------------------------------------
// $Rev$
// $LastChangedBy$
// $LastChangedDate$
//----------------------------------------------------------------------------
`include "timescale.v"
`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

// Include DMEM and PMEM memory locations that are written by dma_task
//`define SHOW_PMEM_WAVES  
//`define SHOW_DMEM_WAVES
  

module  tb_openMSP430;

//
// Wire & Register definition
//------------------------------

// Data Memory interface
wire [`DMEM_MSB:0] dmem_addr;
wire               dmem_cen;
wire        [15:0] dmem_din;
wire         [1:0] dmem_wen;
wire        [15:0] dmem_dout;

// Program Memory interface
wire [`PMEM_MSB:0] pmem_addr;
wire               pmem_cen;
wire        [15:0] pmem_din;
wire         [1:0] pmem_wen;
wire        [15:0] pmem_dout;

// Peripherals interface
wire        [13:0] per_addr;
wire        [15:0] per_din;
wire        [15:0] per_dout;
wire         [1:0] per_we;
wire               per_en;

// Direct Memory Access interface
wire        [15:0] dma_dout;
wire               dma_ready;
wire               dma_resp;
reg         [15:1] dma_addr;
reg         [15:0] dma_din;
reg                dma_en;
reg                dma_priority;
reg          [1:0] dma_we;
reg                dma_wkup;

// Digital I/O
wire               irq_port1;
wire               irq_port2;
wire        [15:0] per_dout_dio;
wire         [7:0] p1_dout;
wire         [7:0] p1_dout_en;
wire         [7:0] p1_sel;
wire         [7:0] p2_dout;
wire         [7:0] p2_dout_en;
wire         [7:0] p2_sel;
wire         [7:0] p3_dout;
wire         [7:0] p3_dout_en;
wire         [7:0] p3_sel;
wire         [7:0] p4_dout;
wire         [7:0] p4_dout_en;
wire         [7:0] p4_sel;
wire         [7:0] p5_dout;
wire         [7:0] p5_dout_en;
wire         [7:0] p5_sel;
wire         [7:0] p6_dout;
wire         [7:0] p6_dout_en;
wire         [7:0] p6_sel;
reg          [7:0] p1_din;
reg          [7:0] p2_din;
reg          [7:0] p3_din;
reg          [7:0] p4_din;
reg          [7:0] p5_din;
reg          [7:0] p6_din;

// Peripheral templates
wire        [15:0] per_dout_temp_8b;
wire        [15:0] per_dout_temp_16b;

// SPI master
wire        [15:0] per_dout_spi;
wire               spi_mosi;
wire               spi_miso;
wire               spi_sck;
wire        [2:0]  spi_ss;

// Simple full duplex UART
wire        [15:0] per_dout_uart;
wire               irq_uart_rx;
wire               irq_uart_tx;
wire               uart_txd;
reg                uart_rxd;

// Timer A
wire               irq_ta0;
wire               irq_ta1;
wire        [15:0] per_dout_timerA;
reg                inclk;
reg                taclk;
reg                ta_cci0a;
reg                ta_cci0b;
reg                ta_cci1a;
reg                ta_cci1b;
reg                ta_cci2a;
reg                ta_cci2b;
wire               ta_out0;
wire               ta_out0_en;
wire               ta_out1;
wire               ta_out1_en;
wire               ta_out2;
wire               ta_out2_en;

// Time Stamp Counter
wire        [15:0] per_dout_tsc;
wire        [63:0] cur_tsc;

// LED digits
wire        [15:0] per_dout_led;
wire         [7:0] led_so;

// File IO
wire        [15:0] per_dout_file_io;

// Clock / Reset & Interrupts
reg                dco_clk;
wire               dco_enable;
wire               dco_wkup;
reg                dco_local_enable;
reg                lfxt_clk;
wire               lfxt_enable;
wire               lfxt_wkup;
reg                lfxt_local_enable;
wire               mclk;
wire               aclk;
wire               aclk_en;
wire               smclk;
wire               smclk_en;
reg                reset_n;
wire               puc_rst;
reg                nmi;
reg         [13:0] irq;
wire        [13:0] irq_acc;
wire        [13:0] irq_in;
reg                cpu_en;
reg         [13:0] wkup;
wire        [13:0] wkup_in;
wire               sm_violation;

// Scan (ASIC version only)
reg                scan_enable;
reg                scan_mode;

// Debug interface
reg                dbg_en;
wire               dbg_freeze;
wire               dbg_uart_txd;
wire               dbg_uart_rxd;
reg                dbg_uart_rxd_sel;
reg                dbg_uart_rxd_dly;
reg                dbg_uart_rxd_pre;
reg                dbg_uart_rxd_meta;
reg         [15:0] dbg_uart_buf;
reg                dbg_uart_rx_busy;
reg                dbg_uart_tx_busy;

// Core testbench debuging signals
wire    [8*32-1:0] i_state;
wire    [8*32-1:0] e_state;
wire        [31:0] inst_cycle;
wire    [8*32-1:0] inst_full;
wire        [31:0] inst_number;
wire        [15:0] inst_pc;
wire    [8*32-1:0] inst_short;

// Testbench variables

integer            tmp_seed;
integer            error;
reg                stimulus_done;
integer 		   index_mem_dbg;


//
// Include files
//------------------------------

// CPU & Memory registers
`include "registers.v"

// Sancus-specific register/wire definitions
`include "sancus-def.v"
`include "irq_macros.v"

// Debug interface tasks
`include "dbg_uart_tasks.v"

// Simple uart tasks
//`include "uart_tasks.v"

`ifndef NO_STIMULUS
// Verilog stimulus
`include "stimulus.v"
`endif

// Direct Memory Access interface background tasks
// (excluded for sancus-sim simulations)
`ifndef __SANCUS_SIM
`include "dma_tasks.v"
`else
    reg        dma_tfx_cancel;
`endif
   
//
// Initialize ROM
//------------------------------
`ifndef PMEM_FILE
`define PMEM_FILE "./pmem.mem"
`endif

initial
  begin
    #10 $readmemh(`PMEM_FILE, pmem_0.mem);
  end

//
// Generate Clock & Reset
//------------------------------
initial
  begin
     dco_clk          = 1'b0;
     dco_local_enable = 1'b0;
     forever
       begin
	  #25;   // 20 MHz
	  dco_local_enable = (dco_enable===1) ? dco_enable : (dco_wkup===1);
	  if (dco_local_enable)
	    dco_clk = ~dco_clk;
       end
  end

initial
  begin
     lfxt_clk          = 1'b0;
     lfxt_local_enable = 1'b0;
     forever
       begin
	  #763;  // 655 kHz
	  lfxt_local_enable = (lfxt_enable===1) ? lfxt_enable : (lfxt_wkup===1);
	  if (lfxt_local_enable)
	    lfxt_clk = ~lfxt_clk;
       end
  end

initial
  begin
     reset_n       = 1'b1;
     #93;
     reset_n       = 1'b0;
     #593;
     reset_n       = 1'b1;
  end

initial
  begin
  	 tmp_seed         = `SEED;
     tmp_seed         = $urandom(tmp_seed);
     error            = 0;
     stimulus_done    = 1;
     irq              = 14'h0000;
     nmi              = 1'b0;
     wkup             = 14'h0000;
     dma_addr         = 15'h0000;
     dma_din          = 16'h0000;
     dma_en           = 1'b0;
     dma_priority     = 1'b0;
     dma_we           = 2'b00;
     dma_wkup         = 1'b0;
     dma_tfx_cancel   = 1'b0;
     cpu_en           = 1'b1;
     dbg_en           = 1'b0;
     dbg_uart_rxd_sel = 1'b0;
     dbg_uart_rxd_dly = 1'b1;
     dbg_uart_rxd_pre = 1'b1;
     dbg_uart_rxd_meta= 1'b0;
     dbg_uart_buf     = 16'h0000;
     dbg_uart_rx_busy = 1'b0;
     dbg_uart_tx_busy = 1'b0;
     p1_din           = 8'h00;
     p2_din           = 8'h00;
     p3_din           = 8'h00;
     p4_din           = 8'h00;
     p5_din           = 8'h00;
     p6_din           = 8'h00;
     inclk            = 1'b0;
     taclk            = 1'b0;
     ta_cci0a         = 1'b0;
     ta_cci0b         = 1'b0;
     ta_cci1a         = 1'b0;
     ta_cci1b         = 1'b0;
     ta_cci2a         = 1'b0;
     ta_cci2b         = 1'b0;
     uart_rxd         = 1'b1;
     scan_enable      = 1'b0;
     scan_mode        = 1'b0;
  end

   
//
// Program Memory
//----------------------------------

ram #(`PMEM_MSB, `PMEM_SIZE) pmem_0 (

// OUTPUTs
    .ram_dout    (pmem_dout),          // Program Memory data output

// INPUTs
    .ram_addr    (pmem_addr),          // Program Memory address
    .ram_cen     (pmem_cen),           // Program Memory chip enable (low active)
    .ram_clk     (mclk),               // Program Memory clock
    .ram_din     (pmem_din),           // Program Memory data input
    .ram_wen     (pmem_wen)            // Program Memory write enable (low active)
);


//
// Data Memory
//----------------------------------

ram #(`DMEM_MSB, `DMEM_SIZE) dmem_0 (

// OUTPUTs
    .ram_dout    (dmem_dout),          // Data Memory data output

// INPUTs
    .ram_addr    (dmem_addr),          // Data Memory address
    .ram_cen     (dmem_cen),           // Data Memory chip enable (low active)
    .ram_clk     (mclk),               // Data Memory clock
    .ram_din     (dmem_din),           // Data Memory data input
    .ram_wen     (dmem_wen)            // Data Memory write enable (low active)
);


//
// openMSP430 Instance
//----------------------------------

openMSP430 dut (

// OUTPUTs
    .aclk         (aclk),              // ASIC ONLY: ACLK
    .aclk_en      (aclk_en),           // FPGA ONLY: ACLK enable
    .dbg_freeze   (dbg_freeze),        // Freeze peripherals
    .dbg_uart_txd (dbg_uart_txd),      // Debug interface: UART TXD
    .dco_enable   (dco_enable),        // ASIC ONLY: Fast oscillator enable
    .dco_wkup     (dco_wkup),          // ASIC ONLY: Fast oscillator wake-up (asynchronous)
    .dmem_addr    (dmem_addr),         // Data Memory address
    .dmem_cen     (dmem_cen),          // Data Memory chip enable (low active)
    .dmem_din     (dmem_din),          // Data Memory data input
    .dmem_wen     (dmem_wen),          // Data Memory write enable (low active)
    .irq_acc      (irq_acc),           // Interrupt request accepted (one-hot signal)
    .lfxt_enable  (lfxt_enable),       // ASIC ONLY: Low frequency oscillator enable
    .lfxt_wkup    (lfxt_wkup),         // ASIC ONLY: Low frequency oscillator wake-up (asynchronous)
    .mclk         (mclk),              // Main system clock
    .dma_dout          (dma_dout),             // Direct Memory Access data output
    .dma_ready         (dma_ready),            // Direct Memory Access is complete
    .dma_resp          (dma_resp),             // Direct Memory Access response (0:Okay / 1:Error)
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_we       (per_we),            // Peripheral write enable (high active)
    .per_en       (per_en),            // Peripheral enable (high active)
    .pmem_addr    (pmem_addr),         // Program Memory address
    .pmem_cen     (pmem_cen),          // Program Memory chip enable (low active)
    .pmem_din     (pmem_din),          // Program Memory data input (optional)
    .pmem_wen     (pmem_wen),          // Program Memory write enable (low active) (optional)
    .puc_rst      (puc_rst),           // Main system reset
    .smclk        (smclk),             // ASIC ONLY: SMCLK
    .smclk_en     (smclk_en),          // FPGA ONLY: SMCLK enable
    .spm_violation (sm_violation),

// INPUTs
    .cpu_en       (cpu_en),            // Enable CPU code execution (asynchronous)
    .dbg_en       (dbg_en),            // Debug interface enable (asynchronous)
    .dbg_uart_rxd (dbg_uart_rxd),      // Debug interface: UART RXD (asynchronous)
    .dco_clk      (dco_clk),           // Fast oscillator (fast clock)
    .dmem_dout    (dmem_dout),         // Data Memory data output
    .irq          (irq_in),            // Maskable interrupts
    .lfxt_clk     (lfxt_clk),          // Low frequency oscillator (typ 32kHz)
    .dma_addr          (dma_addr),             // Direct Memory Access address
    .dma_din           (dma_din),              // Direct Memory Access data input
    .dma_en            (dma_en),               // Direct Memory Access enable (high active)
    .dma_priority      (dma_priority),         // Direct Memory Access priority (0:low / 1:high)
    .dma_we            (dma_we),               // Direct Memory Access write byte enable (high active)
    .dma_wkup          (dma_wkup),             // ASIC ONLY: DMA Sub-System Wake-up (asynchronous and non-glitchy)
    .nmi          (nmi),               // Non-maskable interrupt (asynchronous)
    .per_dout     (per_dout),          // Peripheral data output
    .pmem_dout    (pmem_dout),         // Program Memory data output
    .reset_n      (reset_n),           // Reset Pin (low active, asynchronous)
    .scan_enable  (scan_enable),       // ASIC ONLY: Scan enable (active during scan shifting)
    .scan_mode    (scan_mode),         // ASIC ONLY: Scan mode
    .wkup         (|wkup_in)           // ASIC ONLY: System Wake-up (asynchronous)
);

//
// Digital I/O
//----------------------------------

`ifdef CVER
omsp_gpio #(1,
            1,
            1,
            1,
            1,
            1)         gpio_0 (
`else
omsp_gpio #(.P1_EN(1),
            .P2_EN(1),
            .P3_EN(1),
            .P4_EN(1),
            .P5_EN(1),
            .P6_EN(1)) gpio_0 (
`endif

// OUTPUTs
    .irq_port1    (irq_port1),         // Port 1 interrupt
    .irq_port2    (irq_port2),         // Port 2 interrupt
    .p1_dout      (p1_dout),           // Port 1 data output
    .p1_dout_en   (p1_dout_en),        // Port 1 data output enable
    .p1_sel       (p1_sel),            // Port 1 function select
    .p2_dout      (p2_dout),           // Port 2 data output
    .p2_dout_en   (p2_dout_en),        // Port 2 data output enable
    .p2_sel       (p2_sel),            // Port 2 function select
    .p3_dout      (p3_dout),           // Port 3 data output
    .p3_dout_en   (p3_dout_en),        // Port 3 data output enable
    .p3_sel       (p3_sel),            // Port 3 function select
    .p4_dout      (p4_dout),           // Port 4 data output
    .p4_dout_en   (p4_dout_en),        // Port 4 data output enable
    .p4_sel       (p4_sel),            // Port 4 function select
    .p5_dout      (p5_dout),           // Port 5 data output
    .p5_dout_en   (p5_dout_en),        // Port 5 data output enable
    .p5_sel       (p5_sel),            // Port 5 function select
    .p6_dout      (p6_dout),           // Port 6 data output
    .p6_dout_en   (p6_dout_en),        // Port 6 data output enable
    .p6_sel       (p6_sel),            // Port 6 function select
    .per_dout     (per_dout_dio),      // Peripheral data output
			     
// INPUTs
    .mclk         (mclk),              // Main system clock
    .p1_din       (p1_din),            // Port 1 data input
    .p2_din       (p2_din),            // Port 2 data input
    .p3_din       (p3_din),            // Port 3 data input
    .p4_din       (p4_din),            // Port 4 data input
    .p5_din       (p5_din),            // Port 5 data input
    .p6_din       (p6_din),            // Port 6 data input
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_en       (per_en),            // Peripheral enable (high active)
    .per_we       (per_we),            // Peripheral write enable (high active)
    .puc_rst      (puc_rst)            // Main system reset
);

//
// Timers
//----------------------------------

omsp_timerA timerA_0 (

// OUTPUTs
    .irq_ta0      (irq_ta0),           // Timer A interrupt: TACCR0
    .irq_ta1      (irq_ta1),           // Timer A interrupt: TAIV, TACCR1, TACCR2
    .per_dout     (per_dout_timerA),   // Peripheral data output
    .ta_out0      (ta_out0),           // Timer A output 0
    .ta_out0_en   (ta_out0_en),        // Timer A output 0 enable
    .ta_out1      (ta_out1),           // Timer A output 1
    .ta_out1_en   (ta_out1_en),        // Timer A output 1 enable
    .ta_out2      (ta_out2),           // Timer A output 2
    .ta_out2_en   (ta_out2_en),        // Timer A output 2 enable

// INPUTs
    .aclk_en      (aclk_en),           // ACLK enable (from CPU)
    .dbg_freeze   (dbg_freeze),        // Freeze Timer A counter
    .inclk        (inclk),             // INCLK external timer clock (SLOW)
    .irq_ta0_acc  (irq_acc[9]),        // Interrupt request TACCR0 accepted
    .mclk         (mclk),              // Main system clock
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_en       (per_en),            // Peripheral enable (high active)
    .per_we       (per_we),            // Peripheral write enable (high active)
    .puc_rst      (puc_rst),           // Main system reset
    .smclk_en     (smclk_en),          // SMCLK enable (from CPU)
    .ta_cci0a     (ta_cci0a),          // Timer A compare 0 input A
    .ta_cci0b     (ta_cci0b),          // Timer A compare 0 input B
    .ta_cci1a     (ta_cci1a),          // Timer A compare 1 input A
    .ta_cci1b     (ta_cci1b),          // Timer A compare 1 input B
    .ta_cci2a     (ta_cci2a),          // Timer A compare 2 input A
    .ta_cci2b     (ta_cci2b),          // Timer A compare 2 input B
    .taclk        (taclk)              // TACLK external timer clock (SLOW)
);
   
//
// Simple full duplex UART (8N1 protocol)
//----------------------------------------
//`ifdef READY_FOR_PRIMETIME
//omsp_uart #(.BASE_ADDR(15'h0080)) uart_0 (
//
//// OUTPUTs
//    .irq_uart_rx  (irq_uart_rx),   // UART receive interrupt
//    .irq_uart_tx  (irq_uart_tx),   // UART transmit interrupt
//    .per_dout     (per_dout_uart), // Peripheral data output
//    .uart_txd     (uart_txd),      // UART Data Transmit (TXD)
//
//// INPUTs
//    .mclk         (mclk),          // Main system clock
//    .per_addr     (per_addr),      // Peripheral address
//    .per_din      (per_din),       // Peripheral data input
//    .per_en       (per_en),        // Peripheral enable (high active)
//    .per_we       (per_we),        // Peripheral write enable (high active)
//    .puc_rst      (puc_rst),       // Main system reset
//    .smclk_en     (smclk_en),      // SMCLK enable (from CPU)
//    .uart_rxd     (uart_rxd)       // UART Data Receive (RXD)
//);
//`else
    assign irq_uart_rx   =  1'b0;
    assign irq_uart_tx   =  1'b0;
    assign per_dout_uart = 16'h0000;
    assign uart_txd      =  1'b0;
//`endif

omsp_uart_print #(.BASE_ADDR(15'h0080)) uart_0 (
    .per_dout (per_dout_uart),
    .mclk     (mclk),
    .per_addr (per_addr),
    .per_din  (per_din),
    .per_en   (per_en),
    .per_we   (per_we),
    .puc_rst  (puc_rst)
);



//
// Peripheral templates
//----------------------------------

`ifdef PERIPH_TEMPLATE
template_periph_8b template_periph_8b_0 (

// OUTPUTs
    .per_dout     (per_dout_temp_8b),  // Peripheral data output

// INPUTs
    .mclk         (mclk),              // Main system clock
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_en       (per_en),            // Peripheral enable (high active)
    .per_we       (per_we),            // Peripheral write enable (high active)
    .puc_rst      (puc_rst)            // Main system reset
);

`ifdef CVER
template_periph_16b #(15'h0190)             template_periph_16b_0 (
`else
template_periph_16b #(.BASE_ADDR((15'd`PER_SIZE-15'h0070) & 15'h7ff8)) template_periph_16b_0 (
`endif
// OUTPUTs
    .per_dout     (per_dout_temp_16b), // Peripheral data output

// INPUTs
    .mclk         (mclk),              // Main system clock
    .per_addr     (per_addr),          // Peripheral address
    .per_din      (per_din),           // Peripheral data input
    .per_en       (per_en),            // Peripheral enable (high active)
    .per_we       (per_we),            // Peripheral write enable (high active)
    .puc_rst      (puc_rst)            // Main system reset
);
`else
//
// Time Stamp Counter
//----------------------------------
omsp_tsc tsc_0(
    .per_dout (per_dout_tsc),
    .mclk     (mclk),
    .per_addr (per_addr),
    .per_din  (per_din),
    .per_en   (per_en),
    .per_we   (per_we),
    .puc_rst  (puc_rst)
);

assign cur_tsc = tsc_0.tsc;

//
// LED Digits
//----------------------------------
omsp_led_digits led_digits(
    .per_dout (per_dout_led),
    .so       (led_so),
    .mclk     (mclk),
    .per_addr (per_addr),
    .per_din  (per_din),
    .per_en   (per_en),
    .per_we   (per_we),
    .puc_rst  (puc_rst)
);

`endif

//
// File IO peripheral
//----------------------------------------
file_io file_io_0 (
    .per_dout (per_dout_file_io),
    .mclk     (mclk),
    .per_addr (per_addr),
    .per_din  (per_din),
    .per_en   (per_en),
    .per_we   (per_we),
    .puc_rst  (puc_rst)
);

// SPI master
omsp_spi_master spi_master(
    .per_dout   (per_dout_spi),
    .sck        (spi_sck),
    .ss         (spi_ss),
    .mosi       (spi_mosi),

    .mclk       (mclk),
    .miso       (spi_miso),
    .per_addr   (per_addr),
    .per_din    (per_din),
    .per_en     (per_en),
    .per_we     (per_we),
    .puc_rst    (puc_rst)
);

//
// Combine peripheral data bus
//----------------------------------

assign per_dout = per_dout_dio       |
                  per_dout_timerA    |
                  per_dout_uart      |
                  per_dout_spi       |
`ifdef PERIPH_TEMPLATE
                  per_dout_temp_8b   |
                  per_dout_temp_16b  |
`else
                  per_dout_tsc       |
                  per_dout_led       |
`endif
                  per_dout_file_io;


//
// Map peripheral interrupts & wakeups
//----------------------------------------

assign irq_in  = irq  | {1'b0,           // Vector 13  (0xFFFA)
                         1'b0,           // Vector 12  (0xFFF8)
                         1'b0,           // Vector 11  (0xFFF6)
                         1'b0,           // Vector 10  (0xFFF4) - Watchdog -
                         irq_ta0,        // Vector  9  (0xFFF2)
                         irq_ta1,        // Vector  8  (0xFFF0)
                         irq_uart_rx,    // Vector  7  (0xFFEE)
                         irq_uart_tx,    // Vector  6  (0xFFEC)
                         1'b0,           // Vector  5  (0xFFEA)
                         1'b0,           // Vector  4  (0xFFE8)
                         irq_port2,      // Vector  3  (0xFFE6)
                         irq_port1,      // Vector  2  (0xFFE4)
                         1'b0,           // Vector  1  (0xFFE2)
                         1'b0};          // Vector  0  (0xFFE0)

assign wkup_in = wkup | {1'b0,           // Vector 13  (0xFFFA)
                         1'b0,           // Vector 12  (0xFFF8)
                         1'b0,           // Vector 11  (0xFFF6)
                         1'b0,           // Vector 10  (0xFFF4) - Watchdog -
                         1'b0,           // Vector  9  (0xFFF2)
                         1'b0,           // Vector  8  (0xFFF0)
                         1'b0,           // Vector  7  (0xFFEE)
                         1'b0,           // Vector  6  (0xFFEC)
                         1'b0,           // Vector  5  (0xFFEA)
                         1'b0,           // Vector  4  (0xFFE8)
                         1'b0,           // Vector  3  (0xFFE6)
                         1'b0,           // Vector  2  (0xFFE4)
                         1'b0,           // Vector  1  (0xFFE2)
                         1'b0};          // Vector  0  (0xFFE0)


//
// Debug utility signals
//----------------------------------------
msp_debug msp_debug_0 (

// OUTPUTs
    .e_state      (e_state),           // Execution state
    .i_state      (i_state),           // Instruction fetch state
    .inst_cycle   (inst_cycle),        // Cycle number within current instruction
    .inst_full    (inst_full),         // Currently executed instruction (full version)
    .inst_number  (inst_number),       // Instruction number since last system reset
    .inst_pc      (inst_pc),           // Instruction Program counter
    .inst_short   (inst_short),        // Currently executed instruction (short version)

// INPUTs
    .mclk         (mclk),              // Main system clock
    .puc_rst      (puc_rst)            // Main system reset
);


//
// Generate Waveform
//----------------------------------------

initial
  begin
   `ifdef NODUMP
   `else
     `ifdef VPD_FILE
        $vcdplusfile("tb_openMSP430.vpd");
        $vcdpluson();
     `else
       `ifdef TRN_FILE
          $recordfile ("tb_openMSP430.trn");
          $recordvars;
       `else
          `ifndef DUMPFILE
            `define DUMPFILE "tb_openMSP430.vcd"
          `endif
          $dumpfile(`DUMPFILE);
          $dumpvars(0, tb_openMSP430);
          `ifdef SHOW_PMEM_WAVES
          	for (index_mem_dbg= (`PMEM_SIZE-512)/2; i < (`PMEM_SIZE-512)/2+128; i=i+1)
          	$dumpvars(0, pmem_0.mem[index_mem_dbg]);//show the memory content into the waveform! (Sergio) 
       	  `endif
       	  `ifdef SHOW_DMEM_WAVES
          	for (index_mem_dbg= (`DMEM_SIZE-256)/2; i < (`DMEM_SIZE-256)/2+128; i=i+1)
          	$dumpvars(0, dmem_0.mem[index_mem_dbg]);//show the memory content into the waveform! (Sergio) 
       	  `endif 
       `endif
     `endif
   `endif
  end

//
// End of simulation
//----------------------------------------

initial // Timeout
  begin
   `ifdef NO_TIMEOUT
   `else
     `ifdef VERY_LONG_TIMEOUT
       #500000000;
     `else     
     `ifdef LONG_TIMEOUT
       #5000000;
     `else     
       #500000;
     `endif
     `endif
       $display(" ===============================================");
       $display("|               SIMULATION FAILED               |");
       $display("|              (simulation Timeout)             |");
       $display(" ===============================================");
       tb_extra_report;
       $finish;
   `endif
  end

initial // Normal end of test
  begin
     // finish on stimulus/CPU halt
    `ifdef NO_STIMULUS
         @(negedge inst_irq_rst);
         while(~cpuoff) @(posedge mclk);
    `else
         @(negedge stimulus_done);
         wait(inst_pc=='hffff);
    `endif

     $display(" ===============================================");
     if (error!=0)
       begin
	  $display("|               SIMULATION FAILED               |");
	  $display("|     (some verilog stimulus checks failed)     |");
       end
     else if (~stimulus_done)
       begin
	  $display("|               SIMULATION FAILED               |");
	  $display("|     (the verilog stimulus didn't complete)    |");
       end
     else 
       begin
	  $display("|               SIMULATION PASSED               |");
       end
     $display(" ===============================================");
     tb_extra_report;
     $finish;
  end


//
// Tasks Definition
//------------------------------

   task tb_error;
      input [65*8:0] error_string;
      begin
	 $display("ERROR: %s %t", error_string, $time);
	 error = error+1;
      end
   endtask
   
   task tb_extra_report;
      begin
`ifndef __SANCUS_SIM
         $display("DMA REPORT: Total Accesses: %-d Total RD: %-d Total WR: %-d", dma_cnt_rd+dma_cnt_wr,     dma_cnt_rd,   dma_cnt_wr);
         $display("            Total Errors:   %-d Error RD: %-d Error WR: %-d", dma_rd_error+dma_wr_error, dma_rd_error, dma_wr_error);
         if (!((`PMEM_SIZE>=4092) && (`DMEM_SIZE>=1024)))
           begin
	      $display("");
              $display("Note: DMA if verification disabled (PMEM must be 4kB or bigger, DMEM must be 1kB or bigger)");
           end
         $display("");
         $display("SIMULATION SEED: %d", `SEED);
         $display("");
`endif
      end
   endtask

   task tb_skip_finish;
      input [65*8-1:0] skip_string;
      begin
         $display(" ===============================================");
         $display("|               SIMULATION SKIPPED              |");
         $display("%s", skip_string);
         $display(" ===============================================");
         $display("");
         tb_extra_report;
         $finish;
      end
   endtask


endmodule
