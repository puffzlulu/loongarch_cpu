`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 21:48:43
// Design Name: 
// Module Name: InstructionFetchUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstructionFetchUnit(
    // Ê± ÖÓ ÐÅ ºÅ
    input wire clk,
    // ¸´ Î» ÐÅ ºÅ
    input wire rst,
    // PC¼Ä ´æ Æ÷
    output reg [31:0] pc,
    output wire [31:0] inst,
    input wire NPCsel,
    input wire [31:0] NPCaddr,
    output   wire [31:0] in2_araddr,
    output   wire        in2_arvalid,
    input  wire        in2_arready,
    input  wire [31:0] in2_rdata,
    input  wire        in2_rvalid,
    output   wire        in2_rready,
    output   wire [31:0] in2_waddr,
    output   wire [31:0] in2_wdata,
    output   wire [3:0]  in2_wstrb,
    output   wire        in2_wvalid,
    input  wire        in2_wready,
    output wire IF_valid,
    input wire ID_ready,
    input wire ID_valid
);

reg [1:0] state,next_state;
parameter IDLE = 2'b00,IF = 2'b01,WAIT = 2'b10;

always @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: next_state = in2_arready ? (in2_rvalid ? (ID_ready ? IDLE : WAIT) : IF) : IDLE;
        IF: next_state = in2_rvalid ? (ID_ready ? IDLE : WAIT) : IF;
        WAIT: next_state = ID_ready ? IDLE : WAIT;
    endcase
end

wire stall;
reg [31:0] inst_r;
assign in2_araddr = pc;
assign in2_arvalid = (state == IDLE);
assign in2_rready = (state == IDLE);
assign IF_valid = (state == IF) | (state == WAIT) | in2_rvalid;
assign in2_waddr = 32'b0;
assign in2_wdata = 32'b0;
assign in2_wstrb = 4'b0;
assign in2_wvalid = 1'b0;
assign inst = in2_rvalid ? in2_rdata : inst_r;
assign stall = ~(IF_valid & ID_ready);

always @(posedge clk) begin
    if(rst) pc <= 32'h80000000;
    else if(NPCsel) pc <= NPCaddr;
    else if(~stall) pc <= pc + 32'h4;
end

always @(posedge clk) begin
    if(rst) inst_r <= 32'b0;
    else if(in2_rvalid) inst_r <= inst;
end

endmodule