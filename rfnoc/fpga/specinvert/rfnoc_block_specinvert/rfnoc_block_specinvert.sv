//
// Copyright 2025 <author>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Module: rfnoc_block_specinvert
//
// Description:
//
//   <Add block description here>
//
// Parameters:
//
//   THIS_PORTID : Control crossbar port to which this block is connected
//   CHDR_W      : AXIS-CHDR data bus width
//   MTU         : Maximum transmission unit (i.e., maximum packet size in
//                 CHDR words is 2**MTU).
//

`default_nettype none

module rfnoc_block_specinvert #(
  parameter [9:0] THIS_PORTID     = 10'd0,
  parameter       CHDR_W          = 64,
  parameter [5:0] MTU             = 10
)(
  // RFNoC Framework Clocks and Resets
  input  wire                   rfnoc_chdr_clk,
  input  wire                   rfnoc_ctrl_clk,
  input  wire                   ce_clk,
  // AXIS-CHDR Input Ports (from framework)
  input  wire [(1)*CHDR_W-1:0] s_rfnoc_chdr_tdata,
  input  wire [(1)-1:0]        s_rfnoc_chdr_tlast,
  input  wire [(1)-1:0]        s_rfnoc_chdr_tvalid,
  output wire [(1)-1:0]        s_rfnoc_chdr_tready,
  // AXIS-CHDR Output Ports (to framework)
  output wire [(1)*CHDR_W-1:0] m_rfnoc_chdr_tdata,
  output wire [(1)-1:0]        m_rfnoc_chdr_tlast,
  output wire [(1)-1:0]        m_rfnoc_chdr_tvalid,
  input  wire [(1)-1:0]        m_rfnoc_chdr_tready,
  // AXIS-Ctrl Input Port (from framework)
  input  wire [31:0]            s_rfnoc_ctrl_tdata,
  input  wire                   s_rfnoc_ctrl_tlast,
  input  wire                   s_rfnoc_ctrl_tvalid,
  output wire                   s_rfnoc_ctrl_tready,
  // AXIS-Ctrl Output Port (to framework)
  output wire [31:0]            m_rfnoc_ctrl_tdata,
  output wire                   m_rfnoc_ctrl_tlast,
  output wire                   m_rfnoc_ctrl_tvalid,
  input  wire                   m_rfnoc_ctrl_tready,
  // RFNoC Backend Interface
  input  wire [511:0]           rfnoc_core_config,
  output wire [511:0]           rfnoc_core_status
);

  //---------------------------------------------------------------------------
  // Signal Declarations
  //---------------------------------------------------------------------------

  // Clocks and Resets
  wire               ctrlport_clk;
  wire               ctrlport_rst;
  wire               axis_data_clk;
  wire               axis_data_rst;
  // CtrlPort Master
  wire               m_ctrlport_req_wr;
  wire               m_ctrlport_req_rd;
  wire [19:0]        m_ctrlport_req_addr;
  wire [31:0]        m_ctrlport_req_data;
  wire               m_ctrlport_resp_ack;
  wire [31:0]        m_ctrlport_resp_data;
  // Data Stream to User Logic: in
  wire [32*1-1:0]    m_in_axis_tdata;
  wire [1-1:0]       m_in_axis_tkeep;
  wire               m_in_axis_tlast;
  wire               m_in_axis_tvalid;
  wire               m_in_axis_tready;
  wire [63:0]        m_in_axis_ttimestamp;
  wire               m_in_axis_thas_time;
  wire [15:0]        m_in_axis_tlength;
  wire               m_in_axis_teov;
  wire               m_in_axis_teob;
  // Data Stream from User Logic: out
  wire [32*1-1:0]    s_out_axis_tdata;
  wire [0:0]         s_out_axis_tkeep;
  wire               s_out_axis_tlast;
  wire               s_out_axis_tvalid;
  wire               s_out_axis_tready;
  wire [63:0]        s_out_axis_ttimestamp;
  wire               s_out_axis_thas_time;
  wire [15:0]        s_out_axis_tlength;
  wire               s_out_axis_teov;
  wire               s_out_axis_teob;

  //---------------------------------------------------------------------------
  // NoC Shell
  //---------------------------------------------------------------------------

  noc_shell_specinvert #(
    .CHDR_W              (CHDR_W),
    .THIS_PORTID         (THIS_PORTID),
    .MTU                 (MTU)
  ) noc_shell_specinvert_i (
    //---------------------
    // Framework Interface
    //---------------------

    // Clock Inputs
    .rfnoc_chdr_clk      (rfnoc_chdr_clk),
    .rfnoc_ctrl_clk      (rfnoc_ctrl_clk),
    .ce_clk              (ce_clk),
    // Reset Outputs
    .rfnoc_chdr_rst      (),
    .rfnoc_ctrl_rst      (),
    .ce_rst              (),
    // CHDR Input Ports  (from framework)
    .s_rfnoc_chdr_tdata  (s_rfnoc_chdr_tdata),
    .s_rfnoc_chdr_tlast  (s_rfnoc_chdr_tlast),
    .s_rfnoc_chdr_tvalid (s_rfnoc_chdr_tvalid),
    .s_rfnoc_chdr_tready (s_rfnoc_chdr_tready),
    // CHDR Output Ports (to framework)
    .m_rfnoc_chdr_tdata  (m_rfnoc_chdr_tdata),
    .m_rfnoc_chdr_tlast  (m_rfnoc_chdr_tlast),
    .m_rfnoc_chdr_tvalid (m_rfnoc_chdr_tvalid),
    .m_rfnoc_chdr_tready (m_rfnoc_chdr_tready),
    // AXIS-Ctrl Input Port (from framework)
    .s_rfnoc_ctrl_tdata  (s_rfnoc_ctrl_tdata),
    .s_rfnoc_ctrl_tlast  (s_rfnoc_ctrl_tlast),
    .s_rfnoc_ctrl_tvalid (s_rfnoc_ctrl_tvalid),
    .s_rfnoc_ctrl_tready (s_rfnoc_ctrl_tready),
    // AXIS-Ctrl Output Port (to framework)
    .m_rfnoc_ctrl_tdata  (m_rfnoc_ctrl_tdata),
    .m_rfnoc_ctrl_tlast  (m_rfnoc_ctrl_tlast),
    .m_rfnoc_ctrl_tvalid (m_rfnoc_ctrl_tvalid),
    .m_rfnoc_ctrl_tready (m_rfnoc_ctrl_tready),

    //---------------------
    // Client Interface
    //---------------------

    // CtrlPort Clock and Reset
    .ctrlport_clk              (ctrlport_clk),
    .ctrlport_rst              (ctrlport_rst),
    // CtrlPort Master
    .m_ctrlport_req_wr         (m_ctrlport_req_wr),
    .m_ctrlport_req_rd         (m_ctrlport_req_rd),
    .m_ctrlport_req_addr       (m_ctrlport_req_addr),
    .m_ctrlport_req_data       (m_ctrlport_req_data),
    .m_ctrlport_resp_ack       (m_ctrlport_resp_ack),
    .m_ctrlport_resp_data      (m_ctrlport_resp_data),

    // AXI-Stream Clock and Reset
    .axis_data_clk (axis_data_clk),
    .axis_data_rst (axis_data_rst),
    // Data Stream to User Logic: in
    .m_in_axis_tdata      (m_in_axis_tdata),
    .m_in_axis_tkeep      (m_in_axis_tkeep),
    .m_in_axis_tlast      (m_in_axis_tlast),
    .m_in_axis_tvalid     (m_in_axis_tvalid),
    .m_in_axis_tready     (m_in_axis_tready),
    .m_in_axis_ttimestamp (m_in_axis_ttimestamp),
    .m_in_axis_thas_time  (m_in_axis_thas_time),
    .m_in_axis_tlength    (m_in_axis_tlength),
    .m_in_axis_teov       (m_in_axis_teov),
    .m_in_axis_teob       (m_in_axis_teob),
    // Data Stream from User Logic: out
    .s_out_axis_tdata      (s_out_axis_tdata),
    .s_out_axis_tkeep      (s_out_axis_tkeep),
    .s_out_axis_tlast      (s_out_axis_tlast),
    .s_out_axis_tvalid     (s_out_axis_tvalid),
    .s_out_axis_tready     (s_out_axis_tready),
    .s_out_axis_ttimestamp (s_out_axis_ttimestamp),
    .s_out_axis_thas_time  (s_out_axis_thas_time),
    .s_out_axis_tlength    (s_out_axis_tlength),
    .s_out_axis_teov       (s_out_axis_teov),
    .s_out_axis_teob       (s_out_axis_teob),

    //---------------------------
    // RFNoC Backend Interface
    //---------------------------
    .rfnoc_core_config   (rfnoc_core_config),
    .rfnoc_core_status   (rfnoc_core_status)
  );

  //---------------------------------------------------------------------------
  // User Logic
  //---------------------------------------------------------------------------

  // Register addresses
  localparam REG_INVERT_CONTROL       = 20'h00;
  localparam REG_INVERT_STATUS        = 20'h04;
  localparam REG_DETECTION_THRESHOLD  = 20'h08;
  localparam REG_DETECTION_WINDOW     = 20'h0C;
  
  // Control register bits
  reg         invert_enable = 1'b1;  // Enable spectral inversion
  reg         auto_detect = 1'b0;    // Auto-detect Nyquist zone
  reg [31:0]  detection_threshold = 32'h1000;
  reg [31:0]  detection_window = 32'd1024;
  
  // Status registers
  reg [31:0]  samples_processed = 32'd0;
  reg         inversion_active = 1'b0;
  
  //---------------------------------------------------------------------------
  // Control Port Interface
  //---------------------------------------------------------------------------
  
  always @(posedge ctrlport_clk) begin
    if (ctrlport_rst) begin
      invert_enable <= 1'b1;
      auto_detect <= 1'b0;
      detection_threshold <= 32'h1000;
      detection_window <= 32'd1024;
      m_ctrlport_resp_ack <= 1'b0;
      m_ctrlport_resp_data <= 32'd0;
    end else begin
      // Default: clear ack
      m_ctrlport_resp_ack <= 1'b0;
      
      // Handle write requests
      if (m_ctrlport_req_wr) begin
        m_ctrlport_resp_ack <= 1'b1;
        case (m_ctrlport_req_addr)
          REG_INVERT_CONTROL: begin
            invert_enable <= m_ctrlport_req_data[0];
            auto_detect <= m_ctrlport_req_data[1];
          end
          REG_DETECTION_THRESHOLD: begin
            detection_threshold <= m_ctrlport_req_data;
          end
          REG_DETECTION_WINDOW: begin
            detection_window <= m_ctrlport_req_data;
          end
          default: begin
            // Unknown register
          end
        endcase
      end
      
      // Handle read requests
      if (m_ctrlport_req_rd) begin
        m_ctrlport_resp_ack <= 1'b1;
        case (m_ctrlport_req_addr)
          REG_INVERT_CONTROL: begin
            m_ctrlport_resp_data <= {30'd0, auto_detect, invert_enable};
          end
          REG_INVERT_STATUS: begin
            m_ctrlport_resp_data <= {samples_processed[30:0], inversion_active};
          end
          REG_DETECTION_THRESHOLD: begin
            m_ctrlport_resp_data <= detection_threshold;
          end
          REG_DETECTION_WINDOW: begin
            m_ctrlport_resp_data <= detection_window;
          end
          default: begin
            m_ctrlport_resp_data <= 32'hDEADBEEF;
          end
        endcase
      end
    end
  end

  //---------------------------------------------------------------------------
  // Spectral Inversion Processing
  //---------------------------------------------------------------------------
  
  // Extract I and Q components from input (sc16 format)
  // sc16: [31:16] = Q (imaginary), [15:0] = I (real)
  wire signed [15:0] in_i = m_in_axis_tdata[15:0];
  wire signed [15:0] in_q = m_in_axis_tdata[31:16];
  
  // Perform spectral inversion (complex conjugation)
  // Conjugate: I_out = I_in, Q_out = -Q_in
  wire signed [15:0] out_i;
  wire signed [15:0] out_q;
  
  assign out_i = in_i;  // Real part unchanged
  assign out_q = invert_enable ? -in_q : in_q;  // Negate imaginary when enabled
  
  // Combine I and Q for output
  wire [31:0] inverted_data = {out_q, out_i};
  
  // Register the output for timing
  reg [31:0] out_data_reg;
  reg         out_valid_reg;
  reg         out_last_reg;
  reg         out_eob_reg;
  reg         out_eov_reg;
  reg [63:0]  out_timestamp_reg;
  reg         out_has_time_reg;
  reg [15:0]  out_length_reg;
  
  always @(posedge axis_data_clk) begin
    if (axis_data_rst) begin
      out_data_reg <= 32'd0;
      out_valid_reg <= 1'b0;
      out_last_reg <= 1'b0;
      out_eob_reg <= 1'b0;
      out_eov_reg <= 1'b0;
      out_timestamp_reg <= 64'd0;
      out_has_time_reg <= 1'b0;
      out_length_reg <= 16'd0;
      samples_processed <= 32'd0;
      inversion_active <= 1'b0;
    end else begin
      if (m_in_axis_tvalid && m_in_axis_tready) begin
        // Process data
        out_data_reg <= inverted_data;
        out_valid_reg <= 1'b1;
        out_last_reg <= m_in_axis_tlast;
        out_eob_reg <= m_in_axis_teob;
        out_eov_reg <= m_in_axis_teov;
        out_timestamp_reg <= m_in_axis_ttimestamp;
        out_has_time_reg <= m_in_axis_thas_time;
        out_length_reg <= m_in_axis_tlength;
        
        // Update status
        samples_processed <= samples_processed + 1'b1;
        inversion_active <= invert_enable;
      end else if (s_out_axis_tready) begin
        out_valid_reg <= 1'b0;
      end
    end
  end

  // Connect output signals
  assign s_out_axis_tdata = out_data_reg;
  assign s_out_axis_tkeep = 1'b1;
  assign s_out_axis_tlast = out_last_reg;
  assign s_out_axis_tvalid = out_valid_reg;
  assign s_out_axis_ttimestamp = out_timestamp_reg;
  assign s_out_axis_thas_time = out_has_time_reg;
  assign s_out_axis_tlength = out_length_reg;
  assign s_out_axis_teov = out_eov_reg;
  assign s_out_axis_teob = out_eob_reg;
  
  // Ready signal - we're ready when output is ready or we don't have valid data
  assign m_in_axis_tready = s_out_axis_tready || !out_valid_reg;

  // // Nothing to do yet, so just drive control signals to default values
  // assign m_ctrlport_resp_ack = 1'b0;
  // assign m_in_axis_tready = {1{1'b0}};
  // assign s_out_axis_tvalid = {1{1'b0}};

endmodule // rfnoc_block_specinvert

`default_nettype wire
