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
    // ʱ �� �� ��
    input wire clk,
    // �� λ �� ��
    input wire rst,
    // PC�� �� ��
    output reg [31:0] pc,
    // PC�� �� �� �� �� �� �� �� ��
    input wire NPCsel ,
    input wire [31:0] NPCaddr,
    input wire next
);

wire[31:0] seq_pc;
assign seq_pc = pc + 32'h4;

always @(posedge clk) begin
    if(rst) begin
        pc <= 32'h80000000;
    end
    else begin
        if(next) begin
            if(NPCsel) begin
                pc <= NPCaddr;
            end
            else begin
                pc <= seq_pc;
            end
        end
        else pc <= pc;
    end
end

endmodule