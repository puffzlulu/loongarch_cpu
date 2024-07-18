`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 22:05:16
// Design Name: 
// Module Name: memory_access_method
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


module address_mapping(
    input[31:0] cpu_address,
    output reg[1:0] type,
    output reg[19:0] sram_address
);

//0x80000000-0x803FFFFF - baseram
//0x80400000-0x807FFFFF - extram
//0xBFD003F8-0xBFD003FD - uart

wire[31:0] ext_address = cpu_address - 24'h400000;

always @(*) begin
    if(cpu_address[31:28] == 4'hB) begin
        type <= 2'b10;
        sram_address <= 20'b0;
    end
    else if(cpu_address[23:22] == 2'b01) begin
        type <= 2'b01;
        sram_address <= cpu_address[21:2];
    end
    else begin
        type <= 2'b00;
        sram_address <= ext_address[21:2];
    end
end

endmodule