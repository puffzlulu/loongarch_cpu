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
    input wire ID_ready
);

assign in2_araddr = pc;
reg [1:0] state,next_state;
parameter IDLE = 2'b00,IF = 2'b01,WAIT = 2'b10;

always @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: next_state = in2_arready ? IF : IDLE;
        IF: next_state = in2_rvalid ? (ID_ready ? IDLE : WAIT) : IF;
        WAIT: next_state = ID_ready ? IDLE : WAIT;
    endcase
end

reg [31:0] inst_r;
always @(posedge clk) begin
    if(rst) inst_r <= 32'b0;
    else if(in2_rvalid) inst_r <= in2_rdata;
end

//jirl 0 1 0 0 1 1
//b 0 1 0 1 0 0
//beq 0 1 0 1 1 0
//bne 0 1 0 1 1 1
//bl 0 1 0 1 0 1
wire B_type;
assign B_type = (in2_rdata[31:26] == 6'b010011) | (inst_r[31:26] == 6'b010011) |
                (in2_rdata[31:26] == 6'b010100) | (inst_r[31:26] == 6'b010100) |
                (in2_rdata[31:26] == 6'b010110) | (inst_r[31:26] == 6'b010110) |
                (in2_rdata[31:26] == 6'b010111) | (inst_r[31:26] == 6'b010111) |
                (in2_rdata[31:26] == 6'b010101) | (inst_r[31:26] == 6'b010101) ;

assign in2_arvalid = (state == IDLE);
assign in2_rready = (state == IF);
assign in2_waddr = 32'b0;
assign in2_wdata = 32'b0;
assign in2_wstrb = 4'b0;
assign in2_wvalid = 1'b0;
assign IF_valid = (state == IF) | (state == WAIT);
assign inst = (state == IF) ? in2_rdata : inst_r;

reg flag1,flag2;

always @(posedge clk) begin
    if(rst) begin
        pc <= 32'h80000000;
        flag1 = 0;
        flag2 = 0;
    end
    else begin
        if(in2_arready) begin
            if(B_type & ~flag1) begin
                pc <= pc;
                flag1 <= 1;
            end
            else begin
                if(NPCsel & ~flag2) begin
                    pc <= NPCaddr;
                    flag2 <= 1;
                end
                else begin
                    pc <= pc + 4;
                    flag1 <= 0;
                    flag2 <= 0;
                end
            end
        end
        else pc <= pc;
    end
end

endmodule