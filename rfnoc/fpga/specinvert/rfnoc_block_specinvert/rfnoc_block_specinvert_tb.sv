//
// Copyright 2025 <author>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Module: rfnoc_block_specinvert_tb
//
// Description: Testbench for the specinvert RFNoC block.
//

`default_nettype none


module rfnoc_block_specinvert_tb;

  `include "test_exec.svh"

  import PkgTestExec::*;
  import rfnoc_chdr_utils_pkg::*;
  import PkgChdrData::*;
  import PkgRfnocBlockCtrlBfm::*;
  import PkgRfnocItemUtils::*;

  //---------------------------------------------------------------------------
  // Testbench Configuration
  //---------------------------------------------------------------------------

  localparam [31:0] NOC_ID          = 32'h14130901;
  localparam [ 9:0] THIS_PORTID     = 10'h123;
  localparam int    CHDR_W          = 64;    // CHDR size in bits
  localparam int    MTU             = 10;    // Log2 of max transmission unit in CHDR words
  localparam int    NUM_PORTS_I     = 1;
  localparam int    NUM_PORTS_O     = 1;
  localparam int    ITEM_W          = 32;    // Sample size in bits
  localparam int    SPP             = 64;    // Samples per packet
  localparam int    PKT_SIZE_BYTES  = SPP * (ITEM_W/8);
  localparam int    STALL_PROB      = 25;    // Default BFM stall probability
  localparam real   CHDR_CLK_PER    = 5.0;   // 200 MHz
  localparam real   CTRL_CLK_PER    = 8.0;   // 125 MHz
  localparam real   CE_CLK_PER      = 4.0;   // 250 MHz
  
  // Register addresses
  localparam REG_INVERT_CONTROL      = 20'h00;
  localparam REG_INVERT_STATUS       = 20'h04;
  localparam REG_DETECTION_THRESHOLD = 20'h08;
  localparam REG_DETECTION_WINDOW    = 20'h0C;

  //---------------------------------------------------------------------------
  // Clocks and Resets
  //---------------------------------------------------------------------------

  bit rfnoc_chdr_clk;
  bit rfnoc_ctrl_clk;
  bit ce_clk;

  sim_clock_gen #(CHDR_CLK_PER) rfnoc_chdr_clk_gen (.clk(rfnoc_chdr_clk), .rst());
  sim_clock_gen #(CTRL_CLK_PER) rfnoc_ctrl_clk_gen (.clk(rfnoc_ctrl_clk), .rst());
  sim_clock_gen #(CE_CLK_PER) ce_clk_gen (.clk(ce_clk), .rst());

  //---------------------------------------------------------------------------
  // Bus Functional Models
  //---------------------------------------------------------------------------

  // Backend Interface
  RfnocBackendIf backend (rfnoc_chdr_clk, rfnoc_ctrl_clk);

  // AXIS-Ctrl Interface
  AxiStreamIf #(32) m_ctrl (rfnoc_ctrl_clk, 1'b0);
  AxiStreamIf #(32) s_ctrl (rfnoc_ctrl_clk, 1'b0);

  // AXIS-CHDR Interfaces
  AxiStreamIf #(CHDR_W) m_chdr [NUM_PORTS_I] (rfnoc_chdr_clk, 1'b0);
  AxiStreamIf #(CHDR_W) s_chdr [NUM_PORTS_O] (rfnoc_chdr_clk, 1'b0);

  // Block Controller BFM
  RfnocBlockCtrlBfm #(CHDR_W, ITEM_W) blk_ctrl = new(backend, m_ctrl, s_ctrl);

  // CHDR word and item/sample data types
  typedef ChdrData #(CHDR_W, ITEM_W)::chdr_word_t chdr_word_t;
  typedef ChdrData #(CHDR_W, ITEM_W)::item_t      item_t;

  // Connect block controller to BFMs
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_bfm_input_connections
    initial begin
      blk_ctrl.connect_master_data_port(i, m_chdr[i], PKT_SIZE_BYTES);
      blk_ctrl.set_master_stall_prob(i, STALL_PROB);
    end
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_bfm_output_connections
    initial begin
      blk_ctrl.connect_slave_data_port(i, s_chdr[i]);
      blk_ctrl.set_slave_stall_prob(i, STALL_PROB);
    end
  end

  //---------------------------------------------------------------------------
  // Device Under Test (DUT)
  //---------------------------------------------------------------------------

  // DUT Slave (Input) Port Signals
  logic [CHDR_W*NUM_PORTS_I-1:0] s_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_I-1:0] s_rfnoc_chdr_tready;

  // DUT Master (Output) Port Signals
  logic [CHDR_W*NUM_PORTS_O-1:0] m_rfnoc_chdr_tdata;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tlast;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tvalid;
  logic [       NUM_PORTS_O-1:0] m_rfnoc_chdr_tready;

  // Map the array of BFMs to a flat vector for the DUT connections
  for (genvar i = 0; i < NUM_PORTS_I; i++) begin : gen_dut_input_connections
    // Connect BFM master to DUT slave port
    assign s_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W] = m_chdr[i].tdata;
    assign s_rfnoc_chdr_tlast[i]                = m_chdr[i].tlast;
    assign s_rfnoc_chdr_tvalid[i]               = m_chdr[i].tvalid;
    assign m_chdr[i].tready                     = s_rfnoc_chdr_tready[i];
  end
  for (genvar i = 0; i < NUM_PORTS_O; i++) begin : gen_dut_output_connections
    // Connect BFM slave to DUT master port
    assign s_chdr[i].tdata        = m_rfnoc_chdr_tdata[CHDR_W*i+:CHDR_W];
    assign s_chdr[i].tlast        = m_rfnoc_chdr_tlast[i];
    assign s_chdr[i].tvalid       = m_rfnoc_chdr_tvalid[i];
    assign m_rfnoc_chdr_tready[i] = s_chdr[i].tready;
  end

  rfnoc_block_specinvert #(
    .THIS_PORTID         (THIS_PORTID),
    .CHDR_W              (CHDR_W),
    .MTU                 (MTU)
  ) dut (
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .ce_clk              (ce_clk),
    .rfnoc_core_config   (backend.cfg),
    .rfnoc_core_status   (backend.sts),
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    .s_rfnoc_ctrl_tdata  (m_ctrl.tdata),
    .s_rfnoc_ctrl_tlast  (m_ctrl.tlast),
    .s_rfnoc_ctrl_tvalid (m_ctrl.tvalid),
    .s_rfnoc_ctrl_tready (m_ctrl.tready),
    .m_rfnoc_ctrl_tdata  (s_ctrl.tdata),
    .m_rfnoc_ctrl_tlast  (s_ctrl.tlast),
    .m_rfnoc_ctrl_tvalid (s_ctrl.tvalid),
    .m_rfnoc_ctrl_tready (s_ctrl.tready)
  );

  //---------------------------------------------------------------------------
  // Helper Tasks
  //---------------------------------------------------------------------------

  // Generate complex sinusoid for testing
  function item_t complex_sinusoid(real phase);
    real i_val, q_val;
    shortint i_sample, q_sample;
    
    i_val = $cos(phase) * 32767.0 * 0.7;  // 70% amplitude to avoid clipping
    q_val = $sin(phase) * 32767.0 * 0.7;
    
    i_sample = shortint'(i_val);
    q_sample = shortint'(q_val);
    
    return {q_sample, i_sample};  // sc16 format: [31:16]=Q, [15:0]=I
  endfunction

  // Verify spectral inversion (complex conjugation)
  function bit verify_conjugate(item_t input_sample, item_t output_sample);
    shortint in_i, in_q, out_i, out_q;
    
    in_i = input_sample[15:0];
    in_q = input_sample[31:16];
    out_i = output_sample[15:0];
    out_q = output_sample[31:16];
    
    // Check if output is conjugate of input (I same, Q negated)
    if (out_i != in_i) return 0;
    if (out_q != -in_q) return 0;
    
    return 1;
  endfunction

  //---------------------------------------------------------------------------
  // Main Test Process
  //---------------------------------------------------------------------------

  initial begin : tb_main
    logic [31:0] val;
    item_t send_samples[$];
    item_t recv_samples[$];
    real phase;
    int num_samples;
    int errors;

    // Initialize the test exec object for this testbench
    test.start_tb("rfnoc_block_specinvert_tb");

    // Start the BFMs running
    blk_ctrl.run();

    //--------------------------------
    // Reset
    //--------------------------------

    test.start_test("Flush block then reset it", 10us);
    blk_ctrl.flush_and_reset();
    test.end_test();

    //--------------------------------
    // Verify Block Info
    //--------------------------------

    test.start_test("Verify Block Info", 2us);
    `ASSERT_ERROR(blk_ctrl.get_noc_id() == NOC_ID, "Incorrect NOC_ID Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_i() == NUM_PORTS_I, "Incorrect NUM_DATA_I Value");
    `ASSERT_ERROR(blk_ctrl.get_num_data_o() == NUM_PORTS_O, "Incorrect NUM_DATA_O Value");
    `ASSERT_ERROR(blk_ctrl.get_mtu() == MTU, "Incorrect MTU Value");
    test.end_test();

    //--------------------------------
    // Test Sequences
    //--------------------------------

    //--------------------------------
    // Test Register Access
    //--------------------------------

    test.start_test("Register Access Test", 10us);
    
    // Test control register
    blk_ctrl.reg_write(REG_INVERT_CONTROL, 32'h00000003);  // Enable both bits
    blk_ctrl.reg_read(REG_INVERT_CONTROL, val);
    `ASSERT_ERROR(val == 32'h00000003, "Control register readback failed");
    
    // Test threshold register
    blk_ctrl.reg_write(REG_DETECTION_THRESHOLD, 32'h12345678);
    blk_ctrl.reg_read(REG_DETECTION_THRESHOLD, val);
    `ASSERT_ERROR(val == 32'h12345678, "Threshold register readback failed");
    
    // Test window register
    blk_ctrl.reg_write(REG_DETECTION_WINDOW, 32'h87654321);
    blk_ctrl.reg_read(REG_DETECTION_WINDOW, val);
    `ASSERT_ERROR(val == 32'h87654321, "Window register readback failed");
    
    // Enable inversion only (disable auto-detect)
    blk_ctrl.reg_write(REG_INVERT_CONTROL, 32'h00000001);
    
    test.end_test();

    //--------------------------------
    // Test Basic Spectral Inversion
    //--------------------------------

    test.start_test("Basic Spectral Inversion Test", 100us);
    
    // Generate test signal
    send_samples = {};
    num_samples = 256;
    phase = 0;
    
    for (int i = 0; i < num_samples; i++) begin
      phase = 2.0 * 3.14159 * i / 64.0;  // Normalized frequency
      send_samples.push_back(complex_sinusoid(phase));
    end
    
    // Send the samples
    blk_ctrl.send_items(0, send_samples);
    
    // Receive the processed samples
    blk_ctrl.recv_items(0, recv_samples);
    
    // Verify conjugation
    errors = 0;
    for (int i = 0; i < num_samples; i++) begin
      if (!verify_conjugate(send_samples[i], recv_samples[i])) begin
        errors++;
        if (errors <= 5) begin  // Limit error messages
          $display("Sample %d failed: In=%08x, Out=%08x", 
                   i, send_samples[i], recv_samples[i]);
        end
      end
    end
    
    `ASSERT_ERROR(errors == 0, $sformatf("Spectral inversion failed: %d errors", errors));
    
    test.end_test();

    //--------------------------------
    // Test Bypass Mode
    //--------------------------------

    test.start_test("Bypass Mode Test", 100us);
    
    // Disable inversion
    blk_ctrl.reg_write(REG_INVERT_CONTROL, 32'h00000000);
    
    // Generate test signal
    send_samples = {};
    for (int i = 0; i < 128; i++) begin
      phase = 2.0 * 3.14159 * i / 32.0;
      send_samples.push_back(complex_sinusoid(phase));
    end
    
    // Send and receive
    blk_ctrl.send_items(0, send_samples);
    blk_ctrl.recv_items(0, recv_samples);
    
    // Verify samples pass through unchanged
    errors = 0;
    for (int i = 0; i < 128; i++) begin
      if (send_samples[i] != recv_samples[i]) begin
        errors++;
      end
    end
    
    `ASSERT_ERROR(errors == 0, $sformatf("Bypass mode failed: %d errors", errors));
    
    test.end_test();

    //--------------------------------
    // Test Multiple Packets
    //--------------------------------

    test.start_test("Multiple Packet Test", 200us);
    
    // Re-enable inversion
    blk_ctrl.reg_write(REG_INVERT_CONTROL, 32'h00000001);
    
    // Send multiple packets
    for (int pkt = 0; pkt < 4; pkt++) begin
      send_samples = {};
      for (int i = 0; i < SPP; i++) begin
        phase = 2.0 * 3.14159 * (pkt * SPP + i) / 128.0;
        send_samples.push_back(complex_sinusoid(phase));
      end
      blk_ctrl.send_items(0, send_samples);
    end
    
    // Receive and verify
    for (int pkt = 0; pkt < 4; pkt++) begin
      blk_ctrl.recv_items(0, recv_samples);
      `ASSERT_ERROR(recv_samples.size() == SPP, "Incorrect packet size");
    end
    
    // Read status register
    blk_ctrl.reg_read(REG_INVERT_STATUS, val);
    $display("Status register: %08x (processed samples: %d)", val, val[31:1]);
    
    test.end_test();

    //--------------------------------
    // Test Nyquist Zone Recovery
    //--------------------------------

    test.start_test("Nyquist Zone Recovery Simulation", 150us);
    
    // Simulate undersampled signal from 2nd Nyquist zone
    // This would appear as frequency inversion in baseband
    send_samples = {};
    for (int i = 0; i < 256; i++) begin
      // Simulate inverted spectrum due to undersampling
      phase = -2.0 * 3.14159 * i / 64.0;  // Negative frequency
      send_samples.push_back(complex_sinusoid(phase));
    end
    
    blk_ctrl.send_items(0, send_samples);
    blk_ctrl.recv_items(0, recv_samples);
    
    // After spectral inversion, spectrum should be corrected
    $display("Nyquist zone recovery test completed");
    
    test.end_test();

    //--------------------------------
    // Finish Up
    //--------------------------------

    // Display final statistics and results
    test.end_tb();
  end : tb_main

endmodule : rfnoc_block_specinvert_tb


`default_nettype wire
