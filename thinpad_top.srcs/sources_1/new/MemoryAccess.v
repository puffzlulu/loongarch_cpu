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


// 访 存 模 块
module MemoryAccess(
    // 访 存 控 制 信 号
    input wire [1:0] wr_in , // 访 存 单 元 读/写 控 制 信 号
    input wire [31:0] addr_in , // 访 存 地 址
    input wire [2:0] type ,
    // 000:一 字 节符号扩展 001:两 字 节符号扩展 010:四 字 节 011:输 出 执 行 单 元 计 算 结 果
    // 100:一字节零扩展     101：两字节零扩展
    // 访 存 数 据 信 号
    input wire [31:0] data_in , // 访 存 单 元 输 入 数 据
    output reg [31:0] data_out ,// 访 存 单 元 输 出 数 据
    // 存 储 器 控 制 信 号
    output wire [1:0] wr_out , // 存 储 器 读/写 控 制 信 号
    output reg [31:0] addr_out , // 存 储 器 读 写 地 址
    output wire [2:0] cpu_type ,
    // 存 储 器 数 据 信 号
    output wire [31:0] wdata_out , // 存 储 器 写 数 据
    input wire [31:0] rdata_in // 存 储 器 读 数 据
);

// 访 存 单 元 控 制 部 分
assign wr_out = wr_in;
assign cpu_type = type;

// 地 址 对 齐
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

// 访 存 单 元 数 据 部 分
// 存 储 器 写 数 据
assign wdata_out = data_in;

// 存 储 器 读 数 据
always @(*) begin
    if(wr_in[0]) begin // 写， 不 读 数 据
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
            3'b011: data_out = addr_in; // 如 果 是 11， 输 出 ALUresult
            3'b100: data_out = {24'b0,rdata_in[7:0]};
            3'b101: data_out = {16'b0,rdata_in[15:0]};
            default: data_out = 32'b0;
        endcase
    end
end

endmodule