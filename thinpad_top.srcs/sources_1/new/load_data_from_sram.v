`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 23:20:23
// Design Name: 
// Module Name: load_data_from_sram
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


module load_data_from_sram(
    input[3:0] ram_be_n,
    input[1:0] type,
    input[31:0] base_data,
    input[31:0] ext_data,
    input [7:0] uart_data,
    output reg[31:0] final_data
);

wire[31:0] data;
reg positive;
wire[23:0] sign;
assign data = (type == 2'b00) ? base_data : ext_data;
assign sign = positive ? 24'b0 : 24'hffffff;

always @(*) begin
    if(type == 2'b10) begin
        positive = uart_data[7];
        final_data = {{24{positive}},uart_data};
    end
    else begin
        case(ram_be_n)
            4'b0000: final_data = data;
            4'b1110: begin
                positive = data[7];
                final_data = {sign, data[7:0]};
            end
            4'b1101: begin
                positive = data[15];
                final_data = {sign, data[15:8]};
            end
            4'b1011: begin
                positive = data[23];
                final_data = {sign, data[23:16]};
            end
            4'b0111: begin
                positive = data[31];
                final_data = {sign, data[31:24]};
            end
        endcase
    end
end
    
endmodule
