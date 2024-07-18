`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/13 13:48:45
// Design Name: 
// Module Name: MemoryAccess
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


// �� �� ģ ��
module MemoryAccess(
    // �� �� �� �� �� ��
    input wire [1:0] wr_in , // �� �� �� Ԫ ��/д �� �� �� ��
    input wire [31:0] addr_in , // �� �� �� ַ
    input wire [2:0] type ,
    // 000:һ �� �ڷ�����չ 001:�� �� �ڷ�����չ 010:�� �� �� 011:�� �� ִ �� �� Ԫ �� �� �� ��
    // 100:һ�ֽ�����չ     101�����ֽ�����չ
    // �� �� �� �� �� ��
    input wire [31:0] data_in , // �� �� �� Ԫ �� �� �� ��
    output reg [31:0] data_out ,// �� �� �� Ԫ �� �� �� ��
    // �� �� �� �� �� �� ��
    output wire [1:0] wr_out , // �� �� �� ��/д �� �� �� ��
    output reg [31:0] addr_out , // �� �� �� �� д �� ַ
    output wire [2:0] cpu_type ,
    // �� �� �� �� �� �� ��
    output wire [31:0] wdata_out , // �� �� �� д �� ��
    input wire [31:0] rdata_in // �� �� �� �� �� ��
);

// �� �� �� Ԫ �� �� �� ��
assign wr_out = wr_in;
assign cpu_type = type;

// �� ַ �� ��
always @(*) begin
    case(type)
    3'b000: addr_out = addr_in;
    3'b001: addr_out = {addr_in[31:1],1'b0};
    3'b010: addr_out = {addr_in[31:2],2'b00};
    3'b011: addr_out = addr_in;
    3'b100: addr_out = addr_in;
    3'b101: addr_out = {addr_in[31:1],1'b0};
    default: addr_out = addr_in;
    endcase
end

// �� �� �� Ԫ �� �� �� ��
// �� �� �� д �� ��
assign wdata_out = data_in;

// �� �� �� �� �� ��
always @(*) begin
    if(wr_in[0]) begin // д�� �� �� �� ��
        data_out = 32'b0;
    end
    else begin
        case(type)
            3'b000: begin
                data_out = {{24{rdata_in[7]}},rdata_in[7:0]};
//                $display("memory access addr_in: %h ",addr_in);
//                $display("memory access data_in: %h ",data_in);
//                $display("memory access rdata_in: %h ",rdata_in);
//                $display("lb memory access data_out: %h",data_out);
            end
            3'b001: data_out = {{16{rdata_in[15]}},rdata_in[15:0]};
            3'b010: data_out = rdata_in;
            3'b011: data_out = addr_in; // �� �� �� 11�� �� �� ALUresult
            3'b100: data_out = {24'b0,rdata_in[7:0]};
            3'b101: data_out = {16'b0,rdata_in[15:0]};
            default: data_out = 32'b0;
        endcase
    end
end

endmodule