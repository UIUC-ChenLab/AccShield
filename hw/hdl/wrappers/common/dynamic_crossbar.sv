`timescale 1ns / 1ps
	
import lynxTypes::*;

`include "axi_macros.svh"
`include "lynx_macros.svh"
	
module dynamic_crossbar #(
    parameter integer                       ID_DYN = 0
) (
    // Clock and reset
    input  logic                            aclk,
    input  logic                            aresetn,

    // AXI4 Lite control in
    AXI4L.s                                 s_axi_ctrl [N_REGIONS],
    
    // AXI4 Lite control out
    AXI4L.m                                 m_axi_ctrl_cnfg [N_REGIONS],
    // AXI4 Lite control out
    AXI4L.m                                 m_axi_ctrl_sTlb [N_REGIONS],
    
    // AXI4 Lite control out
    AXI4L.m                                 m_axi_ctrl_lTlb [N_REGIONS],
    
    // AXI4 Lite control out
    AXI4L.m                                 m_axi_ctrl_user [N_REGIONS]
);
    
    // ----------------------------------------------------------------------
	// Control crossbar 
	// ----------------------------------------------------------------------
	// Crossbar out
	logic[N_REGIONS-1:0][4*AXI_ADDR_BITS-1:0]       axi_xbar_araddr;
	logic[N_REGIONS-1:0][11:0]                      axi_xbar_arprot;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_arready;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_arvalid;
	logic[N_REGIONS-1:0][4*AXI_ADDR_BITS-1:0]       axi_xbar_awaddr;
	logic[N_REGIONS-1:0][11:0]                      axi_xbar_awprot;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_awready;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_awvalid;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_bready;
	logic[N_REGIONS-1:0][7:0]                       axi_xbar_bresp;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_bvalid;
	logic[N_REGIONS-1:0][4*AXIL_DATA_BITS-1:0]      axi_xbar_rdata;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_rready;
	logic[N_REGIONS-1:0][7:0]                       axi_xbar_rresp;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_rvalid;
	logic[N_REGIONS-1:0][4*AXIL_DATA_BITS-1:0]      axi_xbar_wdata;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_wready;
	logic[N_REGIONS-1:0][4*(AXIL_DATA_BITS/8)-1:0]  axi_xbar_wstrb;
	logic[N_REGIONS-1:0][3:0]                       axi_xbar_wvalid;
	
	for(genvar i = 0; i < N_REGIONS; i++) begin
	
        // Config
        assign m_axi_ctrl_cnfg[i].araddr                  = axi_xbar_araddr[i][4*AXI_ADDR_BITS-1:3*AXI_ADDR_BITS];
        assign m_axi_ctrl_cnfg[i].arprot                  = axi_xbar_arprot[i][11:9];
        assign m_axi_ctrl_cnfg[i].arvalid                 = axi_xbar_arvalid[i][3];
        assign m_axi_ctrl_cnfg[i].awaddr                  = axi_xbar_awaddr[i][4*AXI_ADDR_BITS-1:3*AXI_ADDR_BITS];
        assign m_axi_ctrl_cnfg[i].awprot                  = axi_xbar_awprot[i][11:9];
        assign m_axi_ctrl_cnfg[i].awvalid                 = axi_xbar_awvalid[i][3];
        assign m_axi_ctrl_cnfg[i].bready                  = axi_xbar_bready[i][3];
        assign m_axi_ctrl_cnfg[i].rready                  = axi_xbar_rready[i][3];
        assign m_axi_ctrl_cnfg[i].wdata                   = axi_xbar_wdata[i][4*AXIL_DATA_BITS-1:3*AXIL_DATA_BITS];
        assign m_axi_ctrl_cnfg[i].wstrb                   = axi_xbar_wstrb[i][4*(AXIL_DATA_BITS/8)-1:3*(AXIL_DATA_BITS/8)];
        assign m_axi_ctrl_cnfg[i].wvalid                  = axi_xbar_wvalid[i][3];
        
        assign axi_xbar_arready[i][3]                   = m_axi_ctrl_cnfg[i].arready;
        assign axi_xbar_awready[i][3]                   = m_axi_ctrl_cnfg[i].awready;
        assign axi_xbar_bresp[i][7:6]                   = m_axi_ctrl_cnfg[i].bresp;
        assign axi_xbar_bvalid[i][3]                    = m_axi_ctrl_cnfg[i].bvalid;
        assign axi_xbar_rdata[i][4*AXIL_DATA_BITS-1:3*AXIL_DATA_BITS] = m_axi_ctrl_cnfg[i].rdata;
        assign axi_xbar_rresp[i][7:6]                   = m_axi_ctrl_cnfg[i].rresp;
        assign axi_xbar_rvalid[i][3]                    = m_axi_ctrl_cnfg[i].rvalid;
        assign axi_xbar_wready[i][3]                    = m_axi_ctrl_cnfg[i].wready;
    
        // lTlb
        assign m_axi_ctrl_lTlb[i].araddr                  = axi_xbar_araddr[i][AXI_ADDR_BITS-1:0];
        assign m_axi_ctrl_lTlb[i].arprot                  = axi_xbar_arprot[i][2:0];
        assign m_axi_ctrl_lTlb[i].arvalid                 = axi_xbar_arvalid[i][0];
        assign m_axi_ctrl_lTlb[i].awaddr                  = axi_xbar_awaddr[i][AXI_ADDR_BITS-1:0];
        assign m_axi_ctrl_lTlb[i].awprot                  = axi_xbar_awprot[i][2:0];
        assign m_axi_ctrl_lTlb[i].awvalid                 = axi_xbar_awvalid[i][0];
        assign m_axi_ctrl_lTlb[i].bready                  = axi_xbar_bready[i][0];
        assign m_axi_ctrl_lTlb[i].rready                  = axi_xbar_rready[i][0];
        assign m_axi_ctrl_lTlb[i].wdata                   = axi_xbar_wdata[i][AXIL_DATA_BITS-1:0];
        assign m_axi_ctrl_lTlb[i].wstrb                   = axi_xbar_wstrb[i][(AXIL_DATA_BITS/8)-1:0];
        assign m_axi_ctrl_lTlb[i].wvalid                  = axi_xbar_wvalid[i][0];
        
        assign axi_xbar_arready[i][0]                   = m_axi_ctrl_lTlb[i].arready;
        assign axi_xbar_awready[i][0]                   = m_axi_ctrl_lTlb[i].awready;
        assign axi_xbar_bresp[i][1:0]                   = m_axi_ctrl_lTlb[i].bresp;
        assign axi_xbar_bvalid[i][0]                    = m_axi_ctrl_lTlb[i].bvalid;
        assign axi_xbar_rdata[i][AXIL_DATA_BITS-1:0]    = m_axi_ctrl_lTlb[i].rdata;
        assign axi_xbar_rresp[i][1:0]                   = m_axi_ctrl_lTlb[i].rresp;
        assign axi_xbar_rvalid[i][0]                    = m_axi_ctrl_lTlb[i].rvalid;
        assign axi_xbar_wready[i][0]                    = m_axi_ctrl_lTlb[i].wready;
    
        // sTlb
        assign m_axi_ctrl_sTlb[i].araddr                  = axi_xbar_araddr[i][2*AXI_ADDR_BITS-1:AXI_ADDR_BITS];
        assign m_axi_ctrl_sTlb[i].arprot                  = axi_xbar_arprot[i][5:3];
        assign m_axi_ctrl_sTlb[i].arvalid                 = axi_xbar_arvalid[i][1];
        assign m_axi_ctrl_sTlb[i].awaddr                  = axi_xbar_awaddr[i][2*AXI_ADDR_BITS-1:AXI_ADDR_BITS];
        assign m_axi_ctrl_sTlb[i].awprot                  = axi_xbar_awprot[i][5:3];
        assign m_axi_ctrl_sTlb[i].awvalid                 = axi_xbar_awvalid[i][1];
        assign m_axi_ctrl_sTlb[i].bready                  = axi_xbar_bready[i][1];
        assign m_axi_ctrl_sTlb[i].rready                  = axi_xbar_rready[i][1];
        assign m_axi_ctrl_sTlb[i].wdata                   = axi_xbar_wdata[i][2*AXIL_DATA_BITS-1:AXIL_DATA_BITS];
        assign m_axi_ctrl_sTlb[i].wstrb                   = axi_xbar_wstrb[i][2*(AXIL_DATA_BITS/8)-1:AXIL_DATA_BITS/8];
        assign m_axi_ctrl_sTlb[i].wvalid                  = axi_xbar_wvalid[i][1];
        
        assign axi_xbar_arready[i][1]                   = m_axi_ctrl_sTlb[i].arready;
        assign axi_xbar_awready[i][1]                   = m_axi_ctrl_sTlb[i].awready;
        assign axi_xbar_bresp[i][3:2]                   = m_axi_ctrl_sTlb[i].bresp;
        assign axi_xbar_bvalid[i][1]                    = m_axi_ctrl_sTlb[i].bvalid;
        assign axi_xbar_rdata[i][2*AXIL_DATA_BITS-1:AXIL_DATA_BITS] = m_axi_ctrl_sTlb[i].rdata;
        assign axi_xbar_rresp[i][3:2]                   = m_axi_ctrl_sTlb[i].rresp;
        assign axi_xbar_rvalid[i][1]                    = m_axi_ctrl_sTlb[i].rvalid;
        assign axi_xbar_wready[i][1]                    = m_axi_ctrl_sTlb[i].wready;
    
        // User logic
        assign m_axi_ctrl_user[i].araddr                  = axi_xbar_araddr[i][3*AXI_ADDR_BITS-1:2*AXI_ADDR_BITS];
        assign m_axi_ctrl_user[i].arprot                  = axi_xbar_arprot[i][8:6];
        assign m_axi_ctrl_user[i].arvalid                 = axi_xbar_arvalid[i][2];
        assign m_axi_ctrl_user[i].awaddr                  = axi_xbar_awaddr[i][3*AXI_ADDR_BITS-1:2*AXI_ADDR_BITS];
        assign m_axi_ctrl_user[i].awprot                  = axi_xbar_awprot[i][8:6];
        assign m_axi_ctrl_user[i].awvalid                 = axi_xbar_awvalid[i][2];
        assign m_axi_ctrl_user[i].bready                  = axi_xbar_bready[i][2];
        assign m_axi_ctrl_user[i].rready                  = axi_xbar_rready[i][2];
        assign m_axi_ctrl_user[i].wdata                   = axi_xbar_wdata[i][3*AXIL_DATA_BITS-1:2*AXIL_DATA_BITS];
        assign m_axi_ctrl_user[i].wstrb                   = axi_xbar_wstrb[i][3*(AXIL_DATA_BITS/8)-1:2*(AXIL_DATA_BITS/8)];
        assign m_axi_ctrl_user[i].wvalid                  = axi_xbar_wvalid[i][2];
        
        assign axi_xbar_arready[i][2]                   = m_axi_ctrl_user[i].arready;
        assign axi_xbar_awready[i][2]                   = m_axi_ctrl_user[i].awready;
        assign axi_xbar_bresp[i][5:4]                   = m_axi_ctrl_user[i].bresp;
        assign axi_xbar_bvalid[i][2]                    = m_axi_ctrl_user[i].bvalid;
        assign axi_xbar_rdata[i][3*AXIL_DATA_BITS-1:2*AXIL_DATA_BITS] = m_axi_ctrl_user[i].rdata;
        assign axi_xbar_rresp[i][5:4]                   = m_axi_ctrl_user[i].rresp;
        assign axi_xbar_rvalid[i][2]                    = m_axi_ctrl_user[i].rvalid;
        assign axi_xbar_wready[i][2]                    = m_axi_ctrl_user[i].wready;
    
    end
    
    dyn_crossbar_0 inst_dyn_crossbar_0 (
        .aclk(aclk),                    
        .aresetn(aresetn),             
        .s_axi_awaddr(s_axi_ctrl[0].awaddr),    
        .s_axi_awprot(s_axi_ctrl[0].awprot),    
        .s_axi_awvalid(s_axi_ctrl[0].awvalid),  
        .s_axi_awready(s_axi_ctrl[0].awready),  
        .s_axi_wdata(s_axi_ctrl[0].wdata),      
        .s_axi_wstrb(s_axi_ctrl[0].wstrb),      
        .s_axi_wvalid(s_axi_ctrl[0].wvalid),    
        .s_axi_wready(s_axi_ctrl[0].wready),    
        .s_axi_bresp(s_axi_ctrl[0].bresp),      
        .s_axi_bvalid(s_axi_ctrl[0].bvalid),    
        .s_axi_bready(s_axi_ctrl[0].bready),    
        .s_axi_araddr(s_axi_ctrl[0].araddr),    
        .s_axi_arprot(s_axi_ctrl[0].arprot),    
        .s_axi_arvalid(s_axi_ctrl[0].arvalid),  
        .s_axi_arready(s_axi_ctrl[0].arready),  
        .s_axi_rdata(s_axi_ctrl[0].rdata),      
        .s_axi_rresp(s_axi_ctrl[0].rresp),      
        .s_axi_rvalid(s_axi_ctrl[0].rvalid),    
        .s_axi_rready(s_axi_ctrl[0].rready),    
        .m_axi_awaddr(axi_xbar_awaddr[0]),    
        .m_axi_awprot(axi_xbar_awprot[0]),    
        .m_axi_awvalid(axi_xbar_awvalid[0]),  
        .m_axi_awready(axi_xbar_awready[0]),  
        .m_axi_wdata(axi_xbar_wdata[0]),      
        .m_axi_wstrb(axi_xbar_wstrb[0]),      
        .m_axi_wvalid(axi_xbar_wvalid[0]),    
        .m_axi_wready(axi_xbar_wready[0]),    
        .m_axi_bresp(axi_xbar_bresp[0]),      
        .m_axi_bvalid(axi_xbar_bvalid[0]),    
        .m_axi_bready(axi_xbar_bready[0]),    
        .m_axi_araddr(axi_xbar_araddr[0]),    
        .m_axi_arprot(axi_xbar_arprot[0]),    
        .m_axi_arvalid(axi_xbar_arvalid[0]),  
        .m_axi_arready(axi_xbar_arready[0]),  
        .m_axi_rdata(axi_xbar_rdata[0]),      
        .m_axi_rresp(axi_xbar_rresp[0]),      
        .m_axi_rvalid(axi_xbar_rvalid[0]),    
        .m_axi_rready(axi_xbar_rready[0])
    );

    dyn_crossbar_1 inst_dyn_crossbar_1 (
        .aclk(aclk),                    
        .aresetn(aresetn),             
        .s_axi_awaddr(s_axi_ctrl[1].awaddr),    
        .s_axi_awprot(s_axi_ctrl[1].awprot),    
        .s_axi_awvalid(s_axi_ctrl[1].awvalid),  
        .s_axi_awready(s_axi_ctrl[1].awready),  
        .s_axi_wdata(s_axi_ctrl[1].wdata),      
        .s_axi_wstrb(s_axi_ctrl[1].wstrb),      
        .s_axi_wvalid(s_axi_ctrl[1].wvalid),    
        .s_axi_wready(s_axi_ctrl[1].wready),    
        .s_axi_bresp(s_axi_ctrl[1].bresp),      
        .s_axi_bvalid(s_axi_ctrl[1].bvalid),    
        .s_axi_bready(s_axi_ctrl[1].bready),    
        .s_axi_araddr(s_axi_ctrl[1].araddr),    
        .s_axi_arprot(s_axi_ctrl[1].arprot),    
        .s_axi_arvalid(s_axi_ctrl[1].arvalid),  
        .s_axi_arready(s_axi_ctrl[1].arready),  
        .s_axi_rdata(s_axi_ctrl[1].rdata),      
        .s_axi_rresp(s_axi_ctrl[1].rresp),      
        .s_axi_rvalid(s_axi_ctrl[1].rvalid),    
        .s_axi_rready(s_axi_ctrl[1].rready),    
        .m_axi_awaddr(axi_xbar_awaddr[1]),    
        .m_axi_awprot(axi_xbar_awprot[1]),    
        .m_axi_awvalid(axi_xbar_awvalid[1]),  
        .m_axi_awready(axi_xbar_awready[1]),  
        .m_axi_wdata(axi_xbar_wdata[1]),      
        .m_axi_wstrb(axi_xbar_wstrb[1]),      
        .m_axi_wvalid(axi_xbar_wvalid[1]),    
        .m_axi_wready(axi_xbar_wready[1]),    
        .m_axi_bresp(axi_xbar_bresp[1]),      
        .m_axi_bvalid(axi_xbar_bvalid[1]),    
        .m_axi_bready(axi_xbar_bready[1]),    
        .m_axi_araddr(axi_xbar_araddr[1]),    
        .m_axi_arprot(axi_xbar_arprot[1]),    
        .m_axi_arvalid(axi_xbar_arvalid[1]),  
        .m_axi_arready(axi_xbar_arready[1]),  
        .m_axi_rdata(axi_xbar_rdata[1]),      
        .m_axi_rresp(axi_xbar_rresp[1]),      
        .m_axi_rvalid(axi_xbar_rvalid[1]),    
        .m_axi_rready(axi_xbar_rready[1])
    );

    dyn_crossbar_2 inst_dyn_crossbar_2 (
        .aclk(aclk),                    
        .aresetn(aresetn),             
        .s_axi_awaddr(s_axi_ctrl[2].awaddr),    
        .s_axi_awprot(s_axi_ctrl[2].awprot),    
        .s_axi_awvalid(s_axi_ctrl[2].awvalid),  
        .s_axi_awready(s_axi_ctrl[2].awready),  
        .s_axi_wdata(s_axi_ctrl[2].wdata),      
        .s_axi_wstrb(s_axi_ctrl[2].wstrb),      
        .s_axi_wvalid(s_axi_ctrl[2].wvalid),    
        .s_axi_wready(s_axi_ctrl[2].wready),    
        .s_axi_bresp(s_axi_ctrl[2].bresp),      
        .s_axi_bvalid(s_axi_ctrl[2].bvalid),    
        .s_axi_bready(s_axi_ctrl[2].bready),    
        .s_axi_araddr(s_axi_ctrl[2].araddr),    
        .s_axi_arprot(s_axi_ctrl[2].arprot),    
        .s_axi_arvalid(s_axi_ctrl[2].arvalid),  
        .s_axi_arready(s_axi_ctrl[2].arready),  
        .s_axi_rdata(s_axi_ctrl[2].rdata),      
        .s_axi_rresp(s_axi_ctrl[2].rresp),      
        .s_axi_rvalid(s_axi_ctrl[2].rvalid),    
        .s_axi_rready(s_axi_ctrl[2].rready),    
        .m_axi_awaddr(axi_xbar_awaddr[2]),    
        .m_axi_awprot(axi_xbar_awprot[2]),    
        .m_axi_awvalid(axi_xbar_awvalid[2]),  
        .m_axi_awready(axi_xbar_awready[2]),  
        .m_axi_wdata(axi_xbar_wdata[2]),      
        .m_axi_wstrb(axi_xbar_wstrb[2]),      
        .m_axi_wvalid(axi_xbar_wvalid[2]),    
        .m_axi_wready(axi_xbar_wready[2]),    
        .m_axi_bresp(axi_xbar_bresp[2]),      
        .m_axi_bvalid(axi_xbar_bvalid[2]),    
        .m_axi_bready(axi_xbar_bready[2]),    
        .m_axi_araddr(axi_xbar_araddr[2]),    
        .m_axi_arprot(axi_xbar_arprot[2]),    
        .m_axi_arvalid(axi_xbar_arvalid[2]),  
        .m_axi_arready(axi_xbar_arready[2]),  
        .m_axi_rdata(axi_xbar_rdata[2]),      
        .m_axi_rresp(axi_xbar_rresp[2]),      
        .m_axi_rvalid(axi_xbar_rvalid[2]),    
        .m_axi_rready(axi_xbar_rready[2])
    );

    dyn_crossbar_3 inst_dyn_crossbar_3 (
        .aclk(aclk),                    
        .aresetn(aresetn),             
        .s_axi_awaddr(s_axi_ctrl[3].awaddr),    
        .s_axi_awprot(s_axi_ctrl[3].awprot),    
        .s_axi_awvalid(s_axi_ctrl[3].awvalid),  
        .s_axi_awready(s_axi_ctrl[3].awready),  
        .s_axi_wdata(s_axi_ctrl[3].wdata),      
        .s_axi_wstrb(s_axi_ctrl[3].wstrb),      
        .s_axi_wvalid(s_axi_ctrl[3].wvalid),    
        .s_axi_wready(s_axi_ctrl[3].wready),    
        .s_axi_bresp(s_axi_ctrl[3].bresp),      
        .s_axi_bvalid(s_axi_ctrl[3].bvalid),    
        .s_axi_bready(s_axi_ctrl[3].bready),    
        .s_axi_araddr(s_axi_ctrl[3].araddr),    
        .s_axi_arprot(s_axi_ctrl[3].arprot),    
        .s_axi_arvalid(s_axi_ctrl[3].arvalid),  
        .s_axi_arready(s_axi_ctrl[3].arready),  
        .s_axi_rdata(s_axi_ctrl[3].rdata),      
        .s_axi_rresp(s_axi_ctrl[3].rresp),      
        .s_axi_rvalid(s_axi_ctrl[3].rvalid),    
        .s_axi_rready(s_axi_ctrl[3].rready),    
        .m_axi_awaddr(axi_xbar_awaddr[3]),    
        .m_axi_awprot(axi_xbar_awprot[3]),    
        .m_axi_awvalid(axi_xbar_awvalid[3]),  
        .m_axi_awready(axi_xbar_awready[3]),  
        .m_axi_wdata(axi_xbar_wdata[3]),      
        .m_axi_wstrb(axi_xbar_wstrb[3]),      
        .m_axi_wvalid(axi_xbar_wvalid[3]),    
        .m_axi_wready(axi_xbar_wready[3]),    
        .m_axi_bresp(axi_xbar_bresp[3]),      
        .m_axi_bvalid(axi_xbar_bvalid[3]),    
        .m_axi_bready(axi_xbar_bready[3]),    
        .m_axi_araddr(axi_xbar_araddr[3]),    
        .m_axi_arprot(axi_xbar_arprot[3]),    
        .m_axi_arvalid(axi_xbar_arvalid[3]),  
        .m_axi_arready(axi_xbar_arready[3]),  
        .m_axi_rdata(axi_xbar_rdata[3]),      
        .m_axi_rresp(axi_xbar_rresp[3]),      
        .m_axi_rvalid(axi_xbar_rvalid[3]),    
        .m_axi_rready(axi_xbar_rready[3])
    );

	
endmodule
	