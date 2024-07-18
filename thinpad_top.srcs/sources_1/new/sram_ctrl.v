`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 15:35:43
// Design Name: 
// Module Name: sram_ctrl
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


module sram_ctrl(
    input wire clk,
    input wire rst,
    input wire oen,
    input wire wen,
    input wire[31:0] data_in,
    output reg[31:0] data_out,
    
    output wire done,
    inout wire[31:0] ram_data_wire,
    output wire ram_ce_n,       //RAM片选，低有效
    output wire ram_oe_n,       //RAM读使能，低有效
    output wire ram_we_n        //RAM写使能，低有效
);

parameter IDLE = 3'b000, READ0 = 3'b001, READ1 = 3'b010, READ2 = 3'b011, WRITE0 = 3'b100, WRITE1 = 3'b101, WRITE2 = 3'b110, DONE = 3'b111;
reg[2:0] state;
reg data_z;

reg ram_ce_n_reg;
reg ram_oe_n_reg;
reg ram_we_n_reg;
assign ram_ce_n = ram_ce_n_reg;
assign ram_oe_n = ram_oe_n_reg;
assign ram_we_n = ram_we_n_reg;

assign ram_data_wire = data_z ? 32'bz : data_in;
assign done = (state == DONE);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        ram_ce_n_reg <= 1;
        ram_oe_n_reg <= 1;
        ram_we_n_reg <= 1;
        data_z <= 1;
    end
    else begin
        case(state)
            IDLE: begin
                if(~oen) begin
                    state <= READ0;
                    data_z <= 1;
                end
                else if(~wen) begin
                    state <= WRITE0;
                    data_z <= 0;
                end
                else begin
                    state <= state;
                    data_z <= 1;
                end
            end
            READ0: begin
                ram_oe_n_reg <= 0;
                ram_ce_n_reg <= 0;
                state <= READ1;
            end
            READ1: state <= READ2;
            READ2: begin
                ram_oe_n_reg <= 1;
                ram_ce_n_reg <= 1;
                state <= DONE;
                data_out <= ram_data_wire;
            end
            DONE: begin
                //if(oen & wen) state <= IDLE;
                state <= IDLE;
//                else if(~oen) begin
//                    state <= READ0;
//                    data_z <= 1;
//                end
//                else begin
//                    state <= WRITE0;
//                    data_z <= 0;
//                end
            end
            WRITE0: begin
                ram_ce_n_reg <= 0;
                ram_we_n_reg <= 0;
                state <= WRITE1;
            end
            WRITE1: state <= WRITE2;
            WRITE2: begin
                ram_ce_n_reg <= 1;
                ram_we_n_reg <= 1;
                state <= DONE;
            end
        endcase
    end
end

endmodule
