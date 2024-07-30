`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/29 23:19:42
// Design Name: 
// Module Name: launch
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


module launch(
    input wire clk,
    input wire rst,
    input wire [4:0] ID_rd,
    input wire [4:0] ID_in1,
    input wire [4:0] ID_in2,
    input wire src2_is_imm,
    input wire [4:0] WB_waddr,
    input wire reg_we,
    input wire ID_valid,
    output wire IS_ready,
    output wire IS_valid,
    input wire EXU_ready,
    input wire LSU_valid
);

reg busy [31:0];
integer i;
always @(posedge clk) begin
    if(rst) begin
        for(i = 0; i < 32; i = i + 1) begin
            busy[i] = 1'b0;
        end
    end
    else begin
        if(ID_valid & reg_we & (ID_rd != 5'b0) & (ID_rd != ID_in1) & (ID_rd != ID_in2)) busy[ID_rd] <= 1'b1;
        if(LSU_valid) busy[WB_waddr] <= 1'b0;
    end
end

wire is_busy;
//assign is_busy = src2_is_imm ? busy[ID_in1] : (busy[ID_in1] | busy[ID_in2]);
assign is_busy = src2_is_imm ? busy[ID_in1] : (busy[ID_in1] | busy[ID_in2]);
assign IS_ready = is_busy ? 1'b0 : EXU_ready;
assign IS_valid = is_busy ? 1'b0 : ID_valid;

endmodule
