`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 12:00:34
// Design Name: 
// Module Name: regfile
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


module regfile(
    input  wire        clk,
    input wire rst,
    // READ PORT 1
    input  wire [ 4:0] raddr1,
    output wire [31:0] rdata1,
    // READ PORT 2
    input  wire [ 4:0] raddr2,
    output wire [31:0] rdata2,
    // WRITE PORT
    input  wire        we,       //write enable, HIGH valid
    input  wire [ 4:0] waddr,
    input  wire [31:0] wdata,
    input wire [31:0] wdata_alu,
    input wire [1:0] wr,
    input wire inst_en
);
reg [31:0] rf[31:0];

//WRITE
//always @(posedge clk) begin
//    if (we & (wr == 2'b00)) rf[waddr] <= wdata_alu;
//    else if(we && wr) rf[waddr] <= wdata;
////    if(we) rf[waddr] <= wdata;
//end

reg [1:0] state;
parameter WRITE = 2'b00, WAIT = 2'b01;

always @(posedge clk) begin
    if(rst) state <= WRITE;
    else begin
        case(state) 
            WRITE: begin
                if (we & (wr == 2'b00)) begin
                    rf[waddr] <= wdata_alu;
                    state <= WAIT;
                end
                else if(we && wr) begin
                    rf[waddr] <= wdata;
                    state <= state;
                end
                else state <= state;
            end
            WAIT: begin
                if(inst_en) state <= WRITE;
                else state <= state;
            end
        endcase
    end
end

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];

//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];

endmodule