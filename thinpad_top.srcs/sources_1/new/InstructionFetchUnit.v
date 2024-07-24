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
    // 时 钟 信 号
    input wire clk,
    // 复 位 信 号
    input wire rst,
    // PC寄 存 器
    output reg [31:0] pc,
    // PC寄 存 器 更 新 相 关 信 号
    input wire NPCsel ,
    input wire [31:0] NPCaddr ,
    output reg valid ,
//    input wire stall,
    input wire ready,
    input wire mem_done
);

reg [1:0] state;
parameter IDLE = 2'b00, IF = 2'b01, DONE = 2'b10;

always @(posedge clk) begin
    if(rst) begin
        state <= IF;
        valid <= 1;
    end
    else begin
        case(state) 
            IDLE: begin
//                if(~stall) begin
//                    valid <= 1;
//                    state <= IF;
//                end
//                else begin
//                    valid <= 0;
//                    state <= state;
//                end
                valid <= 1;
                state <= IF;
            end
            IF: begin
                if(ready) begin
                    valid <= 0;
                    state <= DONE;
                end
                else state <= state;
            end
            DONE: begin
                if(mem_done) state <= IDLE;
                else state <= DONE;
            end
        endcase
    end
end

//wire[31:0] seq_pc;
//assign seq_pc = pc + 32'h4; 

always @(posedge clk) begin
    if(rst) begin
        pc <= 32'h80000000;
    end
    else begin
        if(state == IDLE) begin
            if(NPCsel) begin
                pc <= NPCaddr;
            end
            else begin
                pc <= pc + 4;
            end
        end
        else begin
            pc <= pc;
        end
    end
end

endmodule