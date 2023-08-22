`timescale 1ns / 1ps

import lynxTypes::*;

`include "axi_macros.svh"
`include "lynx_macros.svh"

/**
 * User logic
 * 
 */
module design_user_logic_c0_2 (
    // AXI4L CONTROL
    AXI4L.s                     axi_ctrl,

    // AXI4S HOST STREAMS
    AXI4SR.s                    axis_host_0_sink,
    AXI4SR.m                    axis_host_0_src,

    // AXI4S CARD STREAMS
    AXI4SR.s                    axis_card_0_sink,
    AXI4SR.m                    axis_card_0_src,

    
    // Clock and reset
    input  wire                 aclk,
    input  wire[0:0]            aresetn
);

/* -- Tie-off unused interfaces and signals ----------------------------- */
//always_comb axi_ctrl.tie_off_s();
//always_comb axis_host_0_sink.tie_off_s();
//always_comb axis_host_0_src.tie_off_m();
//  always_comb axis_card_0_sink.tie_off_s();
//  always_comb axis_card_0_src.tie_off_m();

/* -- USER LOGIC -------------------------------------------------------- */



endmodule