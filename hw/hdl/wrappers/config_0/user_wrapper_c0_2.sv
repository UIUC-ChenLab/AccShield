`timescale 1ns / 1ps
	 
import lynxTypes::*;

`include "axi_macros.svh"
`include "lynx_macros.svh"
	
/**
 * User logic wrapper
 * 
 */
module design_user_wrapper_2 (
    // AXI4L CONTROL
    input  logic[AXI_ADDR_BITS-1:0]             axi_ctrl_araddr,
    input  logic[2:0]                           axi_ctrl_arprot,
    output logic                                axi_ctrl_arready,
    input  logic                                axi_ctrl_arvalid,
    input  logic[AXI_ADDR_BITS-1:0]             axi_ctrl_awaddr,
    input  logic[2:0]                           axi_ctrl_awprot,
    output logic                                axi_ctrl_awready,
    input  logic                                axi_ctrl_awvalid, 
    input  logic                                axi_ctrl_bready,
    output logic[1:0]                           axi_ctrl_bresp,
    output logic                                axi_ctrl_bvalid,
    output logic[AXI_ADDR_BITS-1:0]             axi_ctrl_rdata,
    input  logic                                axi_ctrl_rready,
    output logic[1:0]                           axi_ctrl_rresp,
    output logic                                axi_ctrl_rvalid,
    input  logic[AXIL_DATA_BITS-1:0]            axi_ctrl_wdata,
    output logic                                axi_ctrl_wready,
    input  logic[(AXIL_DATA_BITS/8)-1:0]        axi_ctrl_wstrb,
    input  logic                                axi_ctrl_wvalid,
	
    // AXI4S HOST SINK
    input  logic[AXI_DATA_BITS-1:0]             axis_host_sink_tdata,
    input  logic[AXI_DATA_BITS/8-1:0]           axis_host_sink_tkeep,
    input  logic[PID_BITS-1:0]                  axis_host_sink_tid,
    input  logic                                axis_host_sink_tlast,
    output logic                                axis_host_sink_tready,
    input  logic                                axis_host_sink_tvalid,

	// AXI4S HOST SOURCE
    output logic[AXI_DATA_BITS-1:0]             axis_host_src_tdata,
    output logic[AXI_DATA_BITS/8-1:0]           axis_host_src_tkeep,
    output logic[PID_BITS-1:0]                  axis_host_src_tid,
    output logic                                axis_host_src_tlast,
    input  logic                                axis_host_src_tready,
    output logic                                axis_host_src_tvalid,
  
    // AXI4S CARD SINK
    input  logic[AXI_DATA_BITS-1:0]             axis_card_0_sink_tdata,
    input  logic[AXI_DATA_BITS/8-1:0]           axis_card_0_sink_tkeep,
    input  logic[PID_BITS-1:0]                  axis_card_0_sink_tid,
    input  logic                                axis_card_0_sink_tlast,
    output logic                                axis_card_0_sink_tready,
    input  logic                                axis_card_0_sink_tvalid,

    // AXI4S CARD SOURCE
    output logic[AXI_DATA_BITS-1:0]             axis_card_0_src_tdata,
    output logic[AXI_DATA_BITS/8-1:0]           axis_card_0_src_tkeep,
    output logic[PID_BITS-1:0]                  axis_card_0_src_tid,
    output logic                                axis_card_0_src_tlast,
    input  logic                                axis_card_0_src_tready,
    output logic                                axis_card_0_src_tvalid,
    // Clock and reset
    input  logic                                aclk,
    input  logic[0:0]                           aresetn,

    // BSCAN
    input  logic                                S_BSCAN_drck,
    input  logic                                S_BSCAN_shift,
    input  logic                                S_BSCAN_tdi,
    input  logic                                S_BSCAN_update,
    input  logic                                S_BSCAN_sel,
    output logic                                S_BSCAN_tdo,
    input  logic                                S_BSCAN_tms,
    input  logic                                S_BSCAN_tck,
    input  logic                                S_BSCAN_runtest,
    input  logic                                S_BSCAN_reset,
    input  logic                                S_BSCAN_capture,
    input  logic                                S_BSCAN_bscanid_en
);
	
    // Control
    AXI4L axi_ctrl_user();

    assign axi_ctrl_user.araddr                 = axi_ctrl_araddr;
    assign axi_ctrl_user.arprot                 = axi_ctrl_arprot;
    assign axi_ctrl_user.arvalid                = axi_ctrl_arvalid;
    assign axi_ctrl_user.awaddr                 = axi_ctrl_awaddr;
    assign axi_ctrl_user.awprot                 = axi_ctrl_awprot;
    assign axi_ctrl_user.awvalid                = axi_ctrl_awvalid;
    assign axi_ctrl_user.bready                 = axi_ctrl_bready;
    assign axi_ctrl_user.rready                 = axi_ctrl_rready;
    assign axi_ctrl_user.wdata                  = axi_ctrl_wdata;
    assign axi_ctrl_user.wstrb                  = axi_ctrl_wstrb;
    assign axi_ctrl_user.wvalid                 = axi_ctrl_wvalid;
    assign axi_ctrl_arready                     = axi_ctrl_user.arready;
    assign axi_ctrl_awready                     = axi_ctrl_user.awready;
    assign axi_ctrl_bresp                       = axi_ctrl_user.bresp;
    assign axi_ctrl_bvalid                      = axi_ctrl_user.bvalid;
    assign axi_ctrl_rdata                       = axi_ctrl_user.rdata;
    assign axi_ctrl_rresp                       = axi_ctrl_user.rresp;
    assign axi_ctrl_rvalid                      = axi_ctrl_user.rvalid;
    assign axi_ctrl_wready                      = axi_ctrl_user.wready;
	
    // AXIS host sink
    AXI4SR axis_host_sink();

    assign axis_host_sink.tdata                 = axis_host_sink_tdata;
    assign axis_host_sink.tkeep                 = axis_host_sink_tkeep;
    assign axis_host_sink.tid                   = axis_host_sink_tid;
    assign axis_host_sink.tlast                 = axis_host_sink_tlast;
    assign axis_host_sink.tvalid                = axis_host_sink_tvalid;
    assign axis_host_sink_tready                = axis_host_sink.tready;

    AXI4SR axis_host_sink_mux [N_STRM_AXI] ();

    `AXISR_ASSIGN(axis_host_sink, axis_host_sink_mux[0])

    // AXIS host source
    AXI4SR axis_host_src();

    assign axis_host_src_tdata                  = axis_host_src.tdata;
    assign axis_host_src_tkeep                  = axis_host_src.tkeep;
    assign axis_host_src_tid                    = axis_host_src.tid;
    assign axis_host_src_tlast                  = axis_host_src.tlast;
    assign axis_host_src_tvalid                 = axis_host_src.tvalid;
    assign axis_host_src.tready                 = axis_host_src_tready;

    AXI4SR axis_host_src_mux [N_STRM_AXI]();

    `AXISR_ASSIGN(axis_host_src_mux[0], axis_host_src)
    



    // AXIS card sink
    AXI4SR axis_card_sink [N_CARD_AXI]();
    
    assign axis_card_sink[0].tdata                 = axis_card_0_sink_tdata;
    assign axis_card_sink[0].tkeep                 = axis_card_0_sink_tkeep;
    assign axis_card_sink[0].tid                   = axis_card_0_sink_tid;
    assign axis_card_sink[0].tlast                 = axis_card_0_sink_tlast;
    assign axis_card_sink[0].tvalid                = axis_card_0_sink_tvalid;
    assign axis_card_0_sink_tready                 = axis_card_sink[0].tready;

    // AXIS card source
    AXI4SR axis_card_src [N_CARD_AXI]();
    
    assign axis_card_0_src_tdata                  = axis_card_src[0].tdata;
    assign axis_card_0_src_tkeep                  = axis_card_src[0].tkeep;
    assign axis_card_0_src_tid                    = axis_card_src[0].tid;
    assign axis_card_0_src_tlast                  = axis_card_src[0].tlast;
    assign axis_card_0_src_tvalid                 = axis_card_src[0].tvalid;
    assign axis_card_src[0].tready                = axis_card_0_src_tready;
        

    //
	// USER LOGIC
    //

`ifdef EN_HLS

`ifdef VITIS_HLS

    design_user_hls_c0_2 inst_user_c0_2 (
	    .s_axi_control_AWVALID(axi_ctrl_user.awvalid),
        .s_axi_control_AWREADY(axi_ctrl_user.awready),
        .s_axi_control_AWADDR(axi_ctrl_user.awaddr),
        .s_axi_control_WVALID(axi_ctrl_user.wvalid),
        .s_axi_control_WREADY(axi_ctrl_user.wready),
        .s_axi_control_WDATA(axi_ctrl_user.wdata),
        .s_axi_control_WSTRB(axi_ctrl_user.wstrb),
        .s_axi_control_ARVALID(axi_ctrl_user.arvalid),
        .s_axi_control_ARREADY(axi_ctrl_user.arready),
        .s_axi_control_ARADDR(axi_ctrl_user.araddr),
        .s_axi_control_RVALID(axi_ctrl_user.rvalid),
        .s_axi_control_RREADY(axi_ctrl_user.rready),
        .s_axi_control_RDATA(axi_ctrl_user.rdata),
        .s_axi_control_RRESP(axi_ctrl_user.rresp),
        .s_axi_control_BVALID(axi_ctrl_user.bvalid),
        .s_axi_control_BREADY(axi_ctrl_user.bready),
        .s_axi_control_BRESP(axi_ctrl_user.bresp),
        .s_axis_host_0_sink_TDATA(axis_host_sink_mux[0].tdata),
        .s_axis_host_0_sink_TKEEP(axis_host_sink_mux[0].tkeep),
        .s_axis_host_0_sink_TID(axis_host_sink_mux[0].tid),
        .s_axis_host_0_sink_TLAST(axis_host_sink_mux[0].tlast),
        .s_axis_host_0_sink_TVALID(axis_host_sink_mux[0].tvalid),
        .s_axis_host_0_sink_TREADY(axis_host_sink_mux[0].tready),
        .m_axis_host_0_src_TDATA(axis_host_src_mux[0].tdata),
        .m_axis_host_0_src_TKEEP(axis_host_src_mux[0].tkeep),
        .m_axis_host_0_src_TID(axis_host_src_mux[0].tid),
        .m_axis_host_0_src_TLAST(axis_host_src_mux[0].tlast),
        .m_axis_host_0_src_TVALID(axis_host_src_mux[0].tvalid),
        .m_axis_host_0_src_TREADY(axis_host_src_mux[0].tready),
        .s_axis_card_0_sink_TDATA(axis_card_sink[0].tdata),
        .s_axis_card_0_sink_TKEEP(axis_card_sink[0].tkeep),
        .s_axis_card_0_sink_TID(axis_card_sink[0].tid),
        .s_axis_card_0_sink_TLAST(axis_card_sink[0].tlast),
        .s_axis_card_0_sink_TVALID(axis_card_sink[0].tvalid),
        .s_axis_card_0_sink_TREADY(axis_card_sink[0].tready),
        .m_axis_card_0_src_TDATA(axis_card_0_src.tdata),
        .m_axis_card_0_src_TKEEP(axis_card_0_src.tkeep),
        .m_axis_card_0_src_TID(axis_card_0_src.tid),
        .m_axis_card_0_src_TLAST(axis_card_0_src.tlast),
        .m_axis_card_0_src_TVALID(axis_card_0_src.tvalid),
        .m_axis_card_0_src_TREADY(axis_card_0_src.tready),
        .ap_clk(aclk),
	    .ap_rst_n(aresetn)
	);

`else 

    design_user_hls_c0_2 inst_user_c0_2 (
	    .s_axi_control_AWVALID(axi_ctrl_user.awvalid),
        .s_axi_control_AWREADY(axi_ctrl_user.awready),
        .s_axi_control_AWADDR(axi_ctrl_user.awaddr),
        .s_axi_control_WVALID(axi_ctrl_user.wvalid),
        .s_axi_control_WREADY(axi_ctrl_user.wready),
        .s_axi_control_WDATA(axi_ctrl_user.wdata),
        .s_axi_control_WSTRB(axi_ctrl_user.wstrb),
        .s_axi_control_ARVALID(axi_ctrl_user.arvalid),
        .s_axi_control_ARREADY(axi_ctrl_user.arready),
        .s_axi_control_ARADDR(axi_ctrl_user.araddr),
        .s_axi_control_RVALID(axi_ctrl_user.rvalid),
        .s_axi_control_RREADY(axi_ctrl_user.rready),
        .s_axi_control_RDATA(axi_ctrl_user.rdata),
        .s_axi_control_RRESP(axi_ctrl_user.rresp),
        .s_axi_control_BVALID(axi_ctrl_user.bvalid),
        .s_axi_control_BREADY(axi_ctrl_user.bready),
        .s_axi_control_BRESP(axi_ctrl_user.bresp),
        .s_axis_host_0_sink_TDATA(axis_host_sink_mux[0].tdata),
        .s_axis_host_0_sink_TKEEP(axis_host_sink_mux[0].tkeep),
        .s_axis_host_0_sink_TID(axis_host_sink_mux[0].tid),
        .s_axis_host_0_sink_TLAST(axis_host_sink_mux[0].tlast),
        .s_axis_host_0_sink_TVALID(axis_host_sink_mux[0].tvalid),
        .m_axis_host_0_src_TDATA(axis_host_src_mux[0].tdata),
        .m_axis_host_0_src_TKEEP(axis_host_src_mux[0].tkeep),
        .m_axis_host_0_src_TID(axis_host_src_mux[0].tid),
        .m_axis_host_0_src_TLAST(axis_host_src_mux[0].tlast),
        .m_axis_host_0_src_TVALID(axis_host_src_mux[0].tvalid),
        .m_axis_host_0_src_TREADY(axis_host_src_mux[0].tready),
        .s_axis_card_0_sink_TDATA(axis_card_sink[0].tdata),
        .s_axis_card_0_sink_TKEEP(axis_card_sink[0].tkeep),
        .s_axis_card_0_sink_TID(axis_card_sink[0].tid),
        .s_axis_card_0_sink_TLAST(axis_card_sink[0].tlast),
        .s_axis_card_0_sink_TVALID(axis_card_sink[0].tvalid),
        .s_axis_card_0_sink_TREADY(axis_card_sink[0].tready),
        .m_axis_card_0_src_TDATA(axis_card_0_src.tdata),
        .m_axis_card_0_src_TKEEP(axis_card_0_src.tkeep),
        .m_axis_card_0_src_TID(axis_card_0_src.tid),
        .m_axis_card_0_src_TLAST(axis_card_0_src.tlast),
        .m_axis_card_0_src_TVALID(axis_card_0_src.tvalid),
        .m_axis_card_0_src_TREADY(axis_card_0_src.tready),
        .ap_clk(aclk),
	    .ap_rst_n(aresetn)
	);

`endif

`else
    design_user_logic_c0_2 inst_user_c0_2 (
	    .axi_ctrl(axi_ctrl_user),
        .axis_host_0_sink(axis_host_sink_mux[0]),
        .axis_host_0_src(axis_host_src_mux[0]),
        .axis_card_0_sink(axis_card_sink[0]),
        .axis_card_0_src(axis_card_src[0]),
        .aclk(aclk),
	    .aresetn(aresetn)
	);

`endif
	
endmodule
	