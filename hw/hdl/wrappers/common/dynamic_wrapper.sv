`timescale 1ns / 1ps
	
import lynxTypes::*;

`include "axi_macros.svh"
`include "lynx_macros.svh"
	
module design_dynamic_wrapper #(
    parameter integer                       ID_DYN = 0
) (
    // Clock and reset
    input  logic                            aresetn,
    input  logic                            aclk,
    input  logic                            uresetn,
    input  logic                            uclk,

    // AXI4 Lite control
    AXI4L.s                                 s_axi_ctrl [N_REGIONS],
    
    // AXI4 AVX control
    AXI4.s                                  s_axim_ctrl [N_REGIONS],
        
    // AXI4 DDR 
    AXI4.m									m_axi_ddr [1+N_REGIONS*N_CARD_AXI],
    
    // AXI4S host
    dmaIntf.m                               m_host_dma_rd_req,
    dmaIntf.m                               m_host_dma_wr_req,
    AXI4S.s                                 s_axis_host,
    AXI4S.m                                 m_axis_host,
        
    // AXI4S card
    dmaIntf.m                               m_card_dma_rd_req,
    dmaIntf.m                               m_card_dma_wr_req,
    AXI4S.s                                 s_axis_card,
    AXI4S.m                                 m_axis_card,
        
   
        
    // IRQ
    output logic[N_REGIONS-1:0]             usr_irq
);
	
	// Control lTLB
	AXI4L axi_ctrl_lTlb [N_REGIONS] ();
	
	// Control sTLB
	AXI4L axi_ctrl_sTlb [N_REGIONS] ();
	
    // Control config
    AXI4L axi_ctrl_cnfg [N_REGIONS] ();
    
    // Control user logic
    AXI4L axi_ctrl_user [N_REGIONS] ();
    
	// Control lTLB stream
	AXI4S axis_lTlb [N_REGIONS] ();
	
	// Control sTLB stream
	AXI4S axis_sTlb [N_REGIONS] ();
	
	// Decoupling signals
	logic [N_REG_DYN_DCPL-1:0][N_REGIONS-1:0] decouple;
    logic [N_REGIONS-1:0] decouple_uclk;  

    assign decouple_uclk = decouple[N_REG_DYN_DCPL-1];
    
    always_ff @(posedge aclk) begin
        if(~aresetn) begin
            for(int i = 1; i < N_REG_DYN_DCPL; i++) 
                decouple[i] <= 0;
        end 
        else begin
            for(int i = 1; i < N_REG_DYN_DCPL; i++) 
                decouple[i] <= decouple[i-1];
        end
    end

	
    // ----------------------------------------------------------------------
    // HOST 
    // ----------------------------------------------------------------------
    
    // XDMA host sync
    // ----------------------------------------------------------------------
    dmaIntf rd_XDMA_host();
    dmaIntf wr_XDMA_host();
    
    dma_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_req(rd_XDMA_host), .m_req(m_host_dma_rd_req));
    dma_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_req(wr_XDMA_host), .m_req(m_host_dma_wr_req));
    
    // Slice 0 
    // ----------------------------------------------------------------------
    AXI4S axis_host_in_s0();
    AXI4S axis_host_out_s0();

    axis_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(s_axis_host),      .m_axis(axis_host_in_s0));
    axis_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_host_out_s0), .m_axis(m_axis_host));
    
    // Multiplexing 
    // ----------------------------------------------------------------------
    AXI4S axis_host_in_s1 [N_REGIONS] ();
    AXI4S axis_host_out_s1 [N_REGIONS] ();
    muxIntf mux_host_rd_user ();
    muxIntf mux_host_wr_user ();

    axis_mux_user_src  (.aclk(aclk), .aresetn(aresetn), .m_mux_user(mux_host_rd_user), .s_axis(axis_host_in_s0),  .m_axis(axis_host_in_s1));
    axis_mux_user_sink (.aclk(aclk), .aresetn(aresetn), .m_mux_user(mux_host_wr_user), .s_axis(axis_host_out_s1), .m_axis(axis_host_out_s0));
    
    // Credits 
    // ----------------------------------------------------------------------
    AXI4SR axis_host_in_s2 [N_REGIONS] ();
    AXI4SR axis_host_out_s2 [N_REGIONS] ();
    logic [N_REGIONS-1:0] rxfer_host;
    logic [N_REGIONS-1:0] wxfer_host;
    cred_t [N_REGIONS-1:0] rd_dest_host;

    for(genvar i = 0; i < N_REGIONS; i++) begin
        data_queue_credits_src  (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_host_in_s1[i]),  .m_axis(axis_host_in_s2[i]), .rxfer(rxfer_host[i]), .rd_dest(rd_dest_host[i]));
        data_queue_credits_sink (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_host_out_s2[i]), .m_axis(axis_host_out_s1[i]), .wxfer(wxfer_host[i]));
    end
    
    // Clock crossing (if enabled)
    // ----------------------------------------------------------------------
    AXI4SR axis_host_in_s3 [N_REGIONS] ();
    AXI4SR axis_host_out_s3 [N_REGIONS] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        `AXISR_ASSIGN(axis_host_in_s2[i],  axis_host_in_s3[i])
        `AXISR_ASSIGN(axis_host_out_s3[i], axis_host_out_s2[i])
    end

	

    // Slice 1
    // ----------------------------------------------------------------------
    AXI4SR axis_host_in_s4 [N_REGIONS] ();
    AXI4SR axis_host_out_s4 [N_REGIONS] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        axisr_reg_array #(.N_STAGES(N_REG_DYN_HOST_S1)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_host_in_s3[i]),  .m_axis(axis_host_in_s4[i]));
        axisr_reg_array #(.N_STAGES(N_REG_DYN_HOST_S1)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_host_out_s4[i]), .m_axis(axis_host_out_s3[i]));
    end

    // Decoupling 
    // ----------------------------------------------------------------------
    AXI4SR axis_host_in_ul [N_REGIONS] ();
    AXI4SR axis_host_out_ul [N_REGIONS] ();

    axisr_decoupler (.decouple(decouple_uclk), .s_axis(axis_host_in_s4),    .m_axis(axis_host_in_ul));
    axisr_decoupler (.decouple(decouple_uclk), .s_axis(axis_host_out_ul), .m_axis(axis_host_out_s4));


	
    // ----------------------------------------------------------------------
    // CARD 
    // ----------------------------------------------------------------------
    AXI4 axi_ddr_s0[1+N_REGIONS*N_CARD_AXI] ();

    // XDMA card sync
    // ----------------------------------------------------------------------
    dmaIntf rd_XDMA_sync();
    dmaIntf wr_XDMA_sync();
    
    dma_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_req(rd_XDMA_sync), .m_req(m_card_dma_rd_req));
    dma_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_req(wr_XDMA_sync), .m_req(m_card_dma_wr_req));
    
    // Slice init stage sync 
    // ----------------------------------------------------------------------
    AXI4S axis_card_sync_in_s0();
    AXI4S axis_card_sync_out_s0();

    axis_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(s_axis_card),           .m_axis(axis_card_sync_in_s0));
    axis_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_sync_out_s0), .m_axis(m_axis_card));
    
    // Memory sync 
    // ----------------------------------------------------------------------	
    dmaIntf rd_CDMA_sync ();
    dmaIntf wr_CDMA_sync ();

    cdma (.aclk(aclk), .aresetn(aresetn),
        .rd_CDMA(rd_CDMA_sync), .wr_CDMA(wr_CDMA_sync), .s_axis_ddr(axis_card_sync_in_s0), .m_axis_ddr(axis_card_sync_out_s0), .m_axi_ddr(axi_ddr_s0[0]));
    
    //axi_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(axi_ddr_s0[0]), .m_axi(m_axi_ddr[0]));
    axi_stripe #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(axi_ddr_s0[0]), .m_axi(m_axi_ddr[0]));

    // Slice init stage
    // ----------------------------------------------------------------------
    AXI4S axis_card_in_s0 [N_REGIONS*N_CARD_AXI] ();
    AXI4S axis_card_out_s0 [N_REGIONS*N_CARD_AXI] ();
    AXI4S axis_card_in_s1 [N_REGIONS*N_CARD_AXI] ();
    AXI4S axis_card_out_s1 [N_REGIONS*N_CARD_AXI] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        for(genvar j = 0; j < N_CARD_AXI; j++) begin
            axis_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_in_s0[i*N_CARD_AXI+j]),  .m_axis(axis_card_in_s1[i*N_CARD_AXI+j]));
            axis_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_out_s1[i*N_CARD_AXI+j]), .m_axis(axis_card_out_s0[i*N_CARD_AXI+j]));
        end
    end
    
    // Memory 
    // ----------------------------------------------------------------------	
    dmaIntf rd_CDMA_card [N_REGIONS*N_CARD_AXI] ();
    dmaIntf wr_CDMA_card [N_REGIONS*N_CARD_AXI] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        for(genvar j = 0; j < N_CARD_AXI; j++) begin
            cdma (.aclk(aclk), .aresetn(aresetn), 
                .rd_CDMA(rd_CDMA_card[i*N_CARD_AXI+j]), .wr_CDMA(wr_CDMA_card[i*N_CARD_AXI+j]), .s_axis_ddr(axis_card_out_s0[i*N_CARD_AXI+j]), .m_axis_ddr(axis_card_in_s0[i*N_CARD_AXI+j]), .m_axi_ddr(axi_ddr_s0[i*N_CARD_AXI+j+1]));
        
            //axi_reg_array #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(axi_ddr_s0[i*N_CARD_AXI+j+1]), .m_axi(m_axi_ddr[i*N_CARD_AXI+j+1]));
            axi_stripe #(.N_STAGES(N_REG_DYN_CARD_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(axi_ddr_s0[i*N_CARD_AXI+j+1]), .m_axi(m_axi_ddr[i*N_CARD_AXI+j+1]));
        end
    end
    
    // Credits 
    // ----------------------------------------------------------------------
    AXI4SR axis_card_in_s2 [N_REGIONS*N_CARD_AXI]();
    AXI4SR axis_card_out_s2 [N_REGIONS*N_CARD_AXI] ();
    logic rxfer_card [N_REGIONS*N_CARD_AXI];
    logic wxfer_card [N_REGIONS*N_CARD_AXI];
    cred_t rd_dest_card [N_REGIONS*N_CARD_AXI];

    for(genvar i = 0; i < N_REGIONS; i++) begin
        for(genvar j = 0; j < N_CARD_AXI; j++) begin
            data_queue_credits_src  (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_in_s1[i*N_CARD_AXI+j]),  .m_axis(axis_card_in_s2[i*N_CARD_AXI+j]), .rxfer(rxfer_card[i*N_CARD_AXI+j]), .rd_dest(rd_dest_card[i*N_CARD_AXI+j]));
            data_queue_credits_sink (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_out_s2[i*N_CARD_AXI+j]), .m_axis(axis_card_out_s1[i*N_CARD_AXI+j]), .wxfer(wxfer_card[i*N_CARD_AXI+j]));
        end
    end
    
    // Clock crossing (if enabled)
    // ----------------------------------------------------------------------
    AXI4SR axis_card_in_s3 [N_REGIONS*N_CARD_AXI] ();
    AXI4SR axis_card_out_s3 [N_REGIONS*N_CARD_AXI] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        for(genvar j = 0; j < N_CARD_AXI; j++) begin
            `AXISR_ASSIGN(axis_card_in_s2[i*N_CARD_AXI+j],  axis_card_in_s3[i*N_CARD_AXI+j])
            `AXISR_ASSIGN(axis_card_out_s3[i*N_CARD_AXI+j], axis_card_out_s2[i*N_CARD_AXI+j])
        end
    end

	

    // Slice 1 
    // ----------------------------------------------------------------------
    AXI4SR axis_card_in_s4 [N_REGIONS*N_CARD_AXI] ();
    AXI4SR axis_card_out_s4 [N_REGIONS*N_CARD_AXI] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        for(genvar j = 0; j < N_CARD_AXI; j++) begin
            axisr_reg_array #(.N_STAGES(N_REG_DYN_CARD_S1)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_in_s3[i*N_CARD_AXI+j]),  .m_axis(axis_card_in_s4[i*N_CARD_AXI+j]));
            axisr_reg_array #(.N_STAGES(N_REG_DYN_CARD_S1)) (.aclk(aclk), .aresetn(aresetn), .s_axis(axis_card_out_s4[i*N_CARD_AXI+j]), .m_axis(axis_card_out_s3[i*N_CARD_AXI+j]));
        end
    end

    // Decoupling 
    // ----------------------------------------------------------------------		
    AXI4SR axis_card_in_ul [N_REGIONS*N_CARD_AXI] ();
    AXI4SR axis_card_out_ul [N_REGIONS*N_CARD_AXI] ();
    axisr_decoupler #(.N_STREAMS(N_CARD_AXI)) (.decouple(decouple_uclk), .s_axis(axis_card_in_s4),    .m_axis(axis_card_in_ul));
    axisr_decoupler #(.N_STREAMS(N_CARD_AXI)) (.decouple(decouple_uclk), .s_axis(axis_card_out_ul), .m_axis(axis_card_out_s4));
		
	
	
    // ----------------------------------------------------------------------
	// Rest of interfaces
	// ----------------------------------------------------------------------

    // Slice 0 
    // ----------------------------------------------------------------------
    AXI4L axi_ctrl_s0 [N_REGIONS] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        axil_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(s_axi_ctrl[i]), .m_axi(axi_ctrl_s0[i]));
    end

    AXI4 #(.AXI4_DATA_BITS(AVX_DATA_BITS)) axim_ctrl_s0 [N_REGIONS] ();

    for(genvar i = 0; i < N_REGIONS; i++) begin
        axim_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(s_axim_ctrl[i]), .m_axi(axim_ctrl_s0[i]));
    end


    // Clock crossing (if enabled)
    // ----------------------------------------------------------------------
    AXI4L axi_ctrl_user_s0 [N_REGIONS] ();
	


    for(genvar i = 0; i < N_REGIONS; i++) begin
        `AXIL_ASSIGN(axi_ctrl_user[i], axi_ctrl_user_s0[i])
	
    end

	

    // Slice 1
	// ----------------------------------------------------------------------
    AXI4L axi_ctrl_user_s1 [N_REGIONS] ();
	


    for(genvar i = 0; i < N_REGIONS; i++) begin
        axil_reg_array #(.N_STAGES(N_REG_DYN_HOST_S0)) (.aclk(aclk), .aresetn(aresetn), .s_axi(axi_ctrl_user_s0[i]), .m_axi(axi_ctrl_user_s1[i]));
	

    end	

	// Decoupling 
	// ----------------------------------------------------------------------
	AXI4L axi_ctrl_user_ul [N_REGIONS] ();
	
	axil_decoupler (.decouple(decouple_uclk), .s_axi(axi_ctrl_user_s1), .m_axi(axi_ctrl_user_ul));
	


	// ----------------------------------------------------------------------
	// MMU 
	// ----------------------------------------------------------------------
	dynamic_crossbar #(
        .ID_DYN(ID_DYN)
	) inst_dyn_crossbar (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_ctrl(axi_ctrl_s0),
        .m_axi_ctrl_cnfg(axi_ctrl_cnfg),
        .m_axi_ctrl_sTlb(axi_ctrl_sTlb),
        .m_axi_ctrl_lTlb(axi_ctrl_lTlb),
        .m_axi_ctrl_user(axi_ctrl_user)
	);
	
    for(genvar i = 0; i < N_REGIONS; i++) begin
        `AXIL_TIE_OFF_S(axi_ctrl_cnfg[i])
    end

	
	
	tlb_top #(
        .ID_DYN(ID_DYN)
	) inst_tlb_top (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_ctrl_lTlb(axi_ctrl_lTlb),
        .s_axi_ctrl_sTlb(axi_ctrl_sTlb),
		.s_axim_ctrl_cnfg(axim_ctrl_s0),
	
	
	
	
        .m_rd_XDMA_host(rd_XDMA_host),
        .m_wr_XDMA_host(wr_XDMA_host),
        .rxfer_host(rxfer_host),
        .wxfer_host(wxfer_host),
        .rd_dest_host(rd_dest_host),
        .s_mux_host_rd_user(mux_host_rd_user),
        .s_mux_host_wr_user(mux_host_wr_user),
	
        .m_rd_XDMA_sync(rd_XDMA_sync),
        .m_wr_XDMA_sync(wr_XDMA_sync),
        .m_rd_CDMA_sync(rd_CDMA_sync),
        .m_wr_CDMA_sync(wr_CDMA_sync),
        .m_rd_CDMA_card(rd_CDMA_card),
        .m_wr_CDMA_card(wr_CDMA_card),
        .rxfer_card(rxfer_card),
        .wxfer_card(wxfer_card),
        .rd_dest_card(rd_dest_card),
	
	
        .decouple(decouple[0]),
        .pf_irq(usr_irq)
	);
	
	// ----------------------------------------------------------------------
	// USER 
	// ----------------------------------------------------------------------
    design_user_wrapper_0 inst_user_wrapper_0 ( 
        .axi_ctrl_araddr        (axi_ctrl_user_ul[0].araddr),
        .axi_ctrl_arprot        (axi_ctrl_user_ul[0].arprot),
        .axi_ctrl_arready       (axi_ctrl_user_ul[0].arready),
        .axi_ctrl_arvalid       (axi_ctrl_user_ul[0].arvalid),
        .axi_ctrl_awaddr        (axi_ctrl_user_ul[0].awaddr),
        .axi_ctrl_awprot        (axi_ctrl_user_ul[0].awprot),
        .axi_ctrl_awready       (axi_ctrl_user_ul[0].awready),
        .axi_ctrl_awvalid       (axi_ctrl_user_ul[0].awvalid),
        .axi_ctrl_bready        (axi_ctrl_user_ul[0].bready),
        .axi_ctrl_bresp         (axi_ctrl_user_ul[0].bresp),
        .axi_ctrl_bvalid        (axi_ctrl_user_ul[0].bvalid),
        .axi_ctrl_rdata         (axi_ctrl_user_ul[0].rdata),
        .axi_ctrl_rready        (axi_ctrl_user_ul[0].rready),
        .axi_ctrl_rresp         (axi_ctrl_user_ul[0].rresp),
        .axi_ctrl_rvalid        (axi_ctrl_user_ul[0].rvalid),
        .axi_ctrl_wdata         (axi_ctrl_user_ul[0].wdata),
        .axi_ctrl_wready        (axi_ctrl_user_ul[0].wready),
        .axi_ctrl_wstrb         (axi_ctrl_user_ul[0].wstrb),
        .axi_ctrl_wvalid        (axi_ctrl_user_ul[0].wvalid),
	
        .axis_host_sink_tdata   (axis_host_in_ul[0].tdata),
        .axis_host_sink_tkeep   (axis_host_in_ul[0].tkeep),
        .axis_host_sink_tid     (axis_host_in_ul[0].tid),
        .axis_host_sink_tlast   (axis_host_in_ul[0].tlast),
        .axis_host_sink_tready  (axis_host_in_ul[0].tready),
        .axis_host_sink_tvalid  (axis_host_in_ul[0].tvalid),
        .axis_host_src_tdata    (axis_host_out_ul[0].tdata),
        .axis_host_src_tkeep    (axis_host_out_ul[0].tkeep),
        .axis_host_src_tid      (axis_host_out_ul[0].tid),
        .axis_host_src_tlast    (axis_host_out_ul[0].tlast),
        .axis_host_src_tready   (axis_host_out_ul[0].tready),
        .axis_host_src_tvalid   (axis_host_out_ul[0].tvalid),
        .axis_card_0_sink_tdata   (axis_card_in_ul[0*N_CARD_AXI+0].tdata),
        .axis_card_0_sink_tkeep   (axis_card_in_ul[0*N_CARD_AXI+0].tkeep),
        .axis_card_0_sink_tid     (axis_card_in_ul[0*N_CARD_AXI+0].tid),
        .axis_card_0_sink_tlast   (axis_card_in_ul[0*N_CARD_AXI+0].tlast),
        .axis_card_0_sink_tready  (axis_card_in_ul[0*N_CARD_AXI+0].tready),
        .axis_card_0_sink_tvalid  (axis_card_in_ul[0*N_CARD_AXI+0].tvalid),
        .axis_card_0_src_tdata    (axis_card_out_ul[0*N_CARD_AXI+0].tdata),
        .axis_card_0_src_tkeep    (axis_card_out_ul[0*N_CARD_AXI+0].tkeep),
        .axis_card_0_src_tid      (axis_card_out_ul[0*N_CARD_AXI+0].tid),
        .axis_card_0_src_tlast    (axis_card_out_ul[0*N_CARD_AXI+0].tlast),
        .axis_card_0_src_tready   (axis_card_out_ul[0*N_CARD_AXI+0].tready),
        .axis_card_0_src_tvalid   (axis_card_out_ul[0*N_CARD_AXI+0].tvalid),
        .aclk                   (aclk),
        .aresetn                (aresetn),
        .S_BSCAN_drck(),
        .S_BSCAN_shift(),
        .S_BSCAN_tdi(),
        .S_BSCAN_update(),
        .S_BSCAN_sel(),
        .S_BSCAN_tdo(),
        .S_BSCAN_tms(),
        .S_BSCAN_tck(),
        .S_BSCAN_runtest(),
        .S_BSCAN_reset(),
        .S_BSCAN_capture(),
        .S_BSCAN_bscanid_en()  
    );

    design_user_wrapper_1 inst_user_wrapper_1 ( 
        .axi_ctrl_araddr        (axi_ctrl_user_ul[1].araddr),
        .axi_ctrl_arprot        (axi_ctrl_user_ul[1].arprot),
        .axi_ctrl_arready       (axi_ctrl_user_ul[1].arready),
        .axi_ctrl_arvalid       (axi_ctrl_user_ul[1].arvalid),
        .axi_ctrl_awaddr        (axi_ctrl_user_ul[1].awaddr),
        .axi_ctrl_awprot        (axi_ctrl_user_ul[1].awprot),
        .axi_ctrl_awready       (axi_ctrl_user_ul[1].awready),
        .axi_ctrl_awvalid       (axi_ctrl_user_ul[1].awvalid),
        .axi_ctrl_bready        (axi_ctrl_user_ul[1].bready),
        .axi_ctrl_bresp         (axi_ctrl_user_ul[1].bresp),
        .axi_ctrl_bvalid        (axi_ctrl_user_ul[1].bvalid),
        .axi_ctrl_rdata         (axi_ctrl_user_ul[1].rdata),
        .axi_ctrl_rready        (axi_ctrl_user_ul[1].rready),
        .axi_ctrl_rresp         (axi_ctrl_user_ul[1].rresp),
        .axi_ctrl_rvalid        (axi_ctrl_user_ul[1].rvalid),
        .axi_ctrl_wdata         (axi_ctrl_user_ul[1].wdata),
        .axi_ctrl_wready        (axi_ctrl_user_ul[1].wready),
        .axi_ctrl_wstrb         (axi_ctrl_user_ul[1].wstrb),
        .axi_ctrl_wvalid        (axi_ctrl_user_ul[1].wvalid),
	
        .axis_host_sink_tdata   (axis_host_in_ul[1].tdata),
        .axis_host_sink_tkeep   (axis_host_in_ul[1].tkeep),
        .axis_host_sink_tid     (axis_host_in_ul[1].tid),
        .axis_host_sink_tlast   (axis_host_in_ul[1].tlast),
        .axis_host_sink_tready  (axis_host_in_ul[1].tready),
        .axis_host_sink_tvalid  (axis_host_in_ul[1].tvalid),
        .axis_host_src_tdata    (axis_host_out_ul[1].tdata),
        .axis_host_src_tkeep    (axis_host_out_ul[1].tkeep),
        .axis_host_src_tid      (axis_host_out_ul[1].tid),
        .axis_host_src_tlast    (axis_host_out_ul[1].tlast),
        .axis_host_src_tready   (axis_host_out_ul[1].tready),
        .axis_host_src_tvalid   (axis_host_out_ul[1].tvalid),
        .axis_card_0_sink_tdata   (axis_card_in_ul[1*N_CARD_AXI+0].tdata),
        .axis_card_0_sink_tkeep   (axis_card_in_ul[1*N_CARD_AXI+0].tkeep),
        .axis_card_0_sink_tid     (axis_card_in_ul[1*N_CARD_AXI+0].tid),
        .axis_card_0_sink_tlast   (axis_card_in_ul[1*N_CARD_AXI+0].tlast),
        .axis_card_0_sink_tready  (axis_card_in_ul[1*N_CARD_AXI+0].tready),
        .axis_card_0_sink_tvalid  (axis_card_in_ul[1*N_CARD_AXI+0].tvalid),
        .axis_card_0_src_tdata    (axis_card_out_ul[1*N_CARD_AXI+0].tdata),
        .axis_card_0_src_tkeep    (axis_card_out_ul[1*N_CARD_AXI+0].tkeep),
        .axis_card_0_src_tid      (axis_card_out_ul[1*N_CARD_AXI+0].tid),
        .axis_card_0_src_tlast    (axis_card_out_ul[1*N_CARD_AXI+0].tlast),
        .axis_card_0_src_tready   (axis_card_out_ul[1*N_CARD_AXI+0].tready),
        .axis_card_0_src_tvalid   (axis_card_out_ul[1*N_CARD_AXI+0].tvalid),
        .aclk                   (aclk),
        .aresetn                (aresetn),
        .S_BSCAN_drck(),
        .S_BSCAN_shift(),
        .S_BSCAN_tdi(),
        .S_BSCAN_update(),
        .S_BSCAN_sel(),
        .S_BSCAN_tdo(),
        .S_BSCAN_tms(),
        .S_BSCAN_tck(),
        .S_BSCAN_runtest(),
        .S_BSCAN_reset(),
        .S_BSCAN_capture(),
        .S_BSCAN_bscanid_en()  
    );

    design_user_wrapper_2 inst_user_wrapper_2 ( 
        .axi_ctrl_araddr        (axi_ctrl_user_ul[2].araddr),
        .axi_ctrl_arprot        (axi_ctrl_user_ul[2].arprot),
        .axi_ctrl_arready       (axi_ctrl_user_ul[2].arready),
        .axi_ctrl_arvalid       (axi_ctrl_user_ul[2].arvalid),
        .axi_ctrl_awaddr        (axi_ctrl_user_ul[2].awaddr),
        .axi_ctrl_awprot        (axi_ctrl_user_ul[2].awprot),
        .axi_ctrl_awready       (axi_ctrl_user_ul[2].awready),
        .axi_ctrl_awvalid       (axi_ctrl_user_ul[2].awvalid),
        .axi_ctrl_bready        (axi_ctrl_user_ul[2].bready),
        .axi_ctrl_bresp         (axi_ctrl_user_ul[2].bresp),
        .axi_ctrl_bvalid        (axi_ctrl_user_ul[2].bvalid),
        .axi_ctrl_rdata         (axi_ctrl_user_ul[2].rdata),
        .axi_ctrl_rready        (axi_ctrl_user_ul[2].rready),
        .axi_ctrl_rresp         (axi_ctrl_user_ul[2].rresp),
        .axi_ctrl_rvalid        (axi_ctrl_user_ul[2].rvalid),
        .axi_ctrl_wdata         (axi_ctrl_user_ul[2].wdata),
        .axi_ctrl_wready        (axi_ctrl_user_ul[2].wready),
        .axi_ctrl_wstrb         (axi_ctrl_user_ul[2].wstrb),
        .axi_ctrl_wvalid        (axi_ctrl_user_ul[2].wvalid),
	
        .axis_host_sink_tdata   (axis_host_in_ul[2].tdata),
        .axis_host_sink_tkeep   (axis_host_in_ul[2].tkeep),
        .axis_host_sink_tid     (axis_host_in_ul[2].tid),
        .axis_host_sink_tlast   (axis_host_in_ul[2].tlast),
        .axis_host_sink_tready  (axis_host_in_ul[2].tready),
        .axis_host_sink_tvalid  (axis_host_in_ul[2].tvalid),
        .axis_host_src_tdata    (axis_host_out_ul[2].tdata),
        .axis_host_src_tkeep    (axis_host_out_ul[2].tkeep),
        .axis_host_src_tid      (axis_host_out_ul[2].tid),
        .axis_host_src_tlast    (axis_host_out_ul[2].tlast),
        .axis_host_src_tready   (axis_host_out_ul[2].tready),
        .axis_host_src_tvalid   (axis_host_out_ul[2].tvalid),
        .axis_card_0_sink_tdata   (axis_card_in_ul[2*N_CARD_AXI+0].tdata),
        .axis_card_0_sink_tkeep   (axis_card_in_ul[2*N_CARD_AXI+0].tkeep),
        .axis_card_0_sink_tid     (axis_card_in_ul[2*N_CARD_AXI+0].tid),
        .axis_card_0_sink_tlast   (axis_card_in_ul[2*N_CARD_AXI+0].tlast),
        .axis_card_0_sink_tready  (axis_card_in_ul[2*N_CARD_AXI+0].tready),
        .axis_card_0_sink_tvalid  (axis_card_in_ul[2*N_CARD_AXI+0].tvalid),
        .axis_card_0_src_tdata    (axis_card_out_ul[2*N_CARD_AXI+0].tdata),
        .axis_card_0_src_tkeep    (axis_card_out_ul[2*N_CARD_AXI+0].tkeep),
        .axis_card_0_src_tid      (axis_card_out_ul[2*N_CARD_AXI+0].tid),
        .axis_card_0_src_tlast    (axis_card_out_ul[2*N_CARD_AXI+0].tlast),
        .axis_card_0_src_tready   (axis_card_out_ul[2*N_CARD_AXI+0].tready),
        .axis_card_0_src_tvalid   (axis_card_out_ul[2*N_CARD_AXI+0].tvalid),
        .aclk                   (aclk),
        .aresetn                (aresetn),
        .S_BSCAN_drck(),
        .S_BSCAN_shift(),
        .S_BSCAN_tdi(),
        .S_BSCAN_update(),
        .S_BSCAN_sel(),
        .S_BSCAN_tdo(),
        .S_BSCAN_tms(),
        .S_BSCAN_tck(),
        .S_BSCAN_runtest(),
        .S_BSCAN_reset(),
        .S_BSCAN_capture(),
        .S_BSCAN_bscanid_en()  
    );

    design_user_wrapper_3 inst_user_wrapper_3 ( 
        .axi_ctrl_araddr        (axi_ctrl_user_ul[3].araddr),
        .axi_ctrl_arprot        (axi_ctrl_user_ul[3].arprot),
        .axi_ctrl_arready       (axi_ctrl_user_ul[3].arready),
        .axi_ctrl_arvalid       (axi_ctrl_user_ul[3].arvalid),
        .axi_ctrl_awaddr        (axi_ctrl_user_ul[3].awaddr),
        .axi_ctrl_awprot        (axi_ctrl_user_ul[3].awprot),
        .axi_ctrl_awready       (axi_ctrl_user_ul[3].awready),
        .axi_ctrl_awvalid       (axi_ctrl_user_ul[3].awvalid),
        .axi_ctrl_bready        (axi_ctrl_user_ul[3].bready),
        .axi_ctrl_bresp         (axi_ctrl_user_ul[3].bresp),
        .axi_ctrl_bvalid        (axi_ctrl_user_ul[3].bvalid),
        .axi_ctrl_rdata         (axi_ctrl_user_ul[3].rdata),
        .axi_ctrl_rready        (axi_ctrl_user_ul[3].rready),
        .axi_ctrl_rresp         (axi_ctrl_user_ul[3].rresp),
        .axi_ctrl_rvalid        (axi_ctrl_user_ul[3].rvalid),
        .axi_ctrl_wdata         (axi_ctrl_user_ul[3].wdata),
        .axi_ctrl_wready        (axi_ctrl_user_ul[3].wready),
        .axi_ctrl_wstrb         (axi_ctrl_user_ul[3].wstrb),
        .axi_ctrl_wvalid        (axi_ctrl_user_ul[3].wvalid),
	
        .axis_host_sink_tdata   (axis_host_in_ul[3].tdata),
        .axis_host_sink_tkeep   (axis_host_in_ul[3].tkeep),
        .axis_host_sink_tid     (axis_host_in_ul[3].tid),
        .axis_host_sink_tlast   (axis_host_in_ul[3].tlast),
        .axis_host_sink_tready  (axis_host_in_ul[3].tready),
        .axis_host_sink_tvalid  (axis_host_in_ul[3].tvalid),
        .axis_host_src_tdata    (axis_host_out_ul[3].tdata),
        .axis_host_src_tkeep    (axis_host_out_ul[3].tkeep),
        .axis_host_src_tid      (axis_host_out_ul[3].tid),
        .axis_host_src_tlast    (axis_host_out_ul[3].tlast),
        .axis_host_src_tready   (axis_host_out_ul[3].tready),
        .axis_host_src_tvalid   (axis_host_out_ul[3].tvalid),
        .axis_card_0_sink_tdata   (axis_card_in_ul[3*N_CARD_AXI+0].tdata),
        .axis_card_0_sink_tkeep   (axis_card_in_ul[3*N_CARD_AXI+0].tkeep),
        .axis_card_0_sink_tid     (axis_card_in_ul[3*N_CARD_AXI+0].tid),
        .axis_card_0_sink_tlast   (axis_card_in_ul[3*N_CARD_AXI+0].tlast),
        .axis_card_0_sink_tready  (axis_card_in_ul[3*N_CARD_AXI+0].tready),
        .axis_card_0_sink_tvalid  (axis_card_in_ul[3*N_CARD_AXI+0].tvalid),
        .axis_card_0_src_tdata    (axis_card_out_ul[3*N_CARD_AXI+0].tdata),
        .axis_card_0_src_tkeep    (axis_card_out_ul[3*N_CARD_AXI+0].tkeep),
        .axis_card_0_src_tid      (axis_card_out_ul[3*N_CARD_AXI+0].tid),
        .axis_card_0_src_tlast    (axis_card_out_ul[3*N_CARD_AXI+0].tlast),
        .axis_card_0_src_tready   (axis_card_out_ul[3*N_CARD_AXI+0].tready),
        .axis_card_0_src_tvalid   (axis_card_out_ul[3*N_CARD_AXI+0].tvalid),
        .aclk                   (aclk),
        .aresetn                (aresetn),
        .S_BSCAN_drck(),
        .S_BSCAN_shift(),
        .S_BSCAN_tdi(),
        .S_BSCAN_update(),
        .S_BSCAN_sel(),
        .S_BSCAN_tdo(),
        .S_BSCAN_tms(),
        .S_BSCAN_tck(),
        .S_BSCAN_runtest(),
        .S_BSCAN_reset(),
        .S_BSCAN_capture(),
        .S_BSCAN_bscanid_en()  
    );

	
endmodule
	