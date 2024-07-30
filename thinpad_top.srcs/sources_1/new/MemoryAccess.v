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
    input wire clk,
    input wire rst,
    // 访 存 控 制 信 号
    input wire [1:0] wr_in , // 访 存 单 元 读/写 控 制 信 号
    input wire [31:0] addr_in , // 访 存 地 址 （其 实 是 EXU 输 出）
    input wire [2:0] type ,
    input wire [3:0] sram_be_n ,
    // 000:一 字 节符号扩展 001:两 字 节符号扩展 010:四 字 节 011:输 出 执 行 单 元 计 算 结 果
    // 100:一字节零扩展     101：两字节零扩展
    // 访 存 数 据 信 号
    input wire [31:0] data_in , // 访 存 单 元 输 入 数 据
    output reg [31:0] data_out ,// 访 存 单 元 输 出 数 据
    //回 写 单 元 控 制 信 号
    input wire [4:0] waddr_reg ,
    input wire gr_we ,

    output reg [4:0] waddr_reg_r,
    output reg gr_we_r,
    
    output   wire [31:0] in1_araddr,
    output   wire        in1_arvalid,
    input  wire        in1_arready,
    input  wire [31:0] in1_rdata,
    input  wire        in1_rvalid,
    output   wire        in1_rready,
    output   wire [31:0] in1_waddr,
    output   wire [31:0] in1_wdata,
    output   wire [3:0]  in1_wstrb,
    output   wire        in1_wvalid,
    input  wire        in1_wready,
    
    input wire EXU_valid,
    output wire LSU_ready,
    output wire LSU_valid
);

reg [1:0] state,next_state;
parameter IDLE = 3'b00, READ = 3'b01, WRITE = 3'b10, NONE = 3'b11;

always @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: next_state = EXU_valid ? (wr_in[1] ? READ : (wr_in[0] ? WRITE : NONE)) : IDLE;
        READ: next_state = in1_rvalid ? IDLE : READ;
        WRITE: next_state = in1_wready ? IDLE : WRITE;
        NONE : next_state = IDLE;
    endcase
end

reg [1:0] wr_in_r;
reg [2:0] type_r;
reg [31:0] wdata_r,addr_in_r;
reg [3:0] sram_be_n_r;

always @(posedge clk) begin
    if(rst) begin
        wr_in_r <= 2'b0;
        type_r <= 3'b0;
        wdata_r <= 32'b0;
        sram_be_n_r <= 4'b0;
        waddr_reg_r <= 5'b0;
        gr_we_r <= 1'b0;
        addr_in_r <= 32'b0;
    end
    else if(state == IDLE) begin
        wr_in_r <= wr_in;
        type_r <= type;
        wdata_r <= data_in;
        sram_be_n_r <= sram_be_n;
        waddr_reg_r <= waddr_reg;
        gr_we_r <= gr_we;
        addr_in_r <= addr_in;
    end
end


assign in1_arvalid = (state == READ);
assign in1_rready = (state == READ);
assign in1_wvalid = (state == WRITE);
assign LSU_ready = ~(state == IDLE);
assign LSU_valid = (state == READ)| (state == NONE);
assign in1_araddr = (state == READ) ? addr_in_r : 32'b0;
assign in1_waddr = (state == WRITE) ? addr_in_r : 32'b0;
assign in1_wdata = (state == WRITE) ? wdata_r : 32'b0;
assign in1_wstrb = (state == WRITE) ? sram_be_n_r : 4'b0;

always @(*) begin
    case(type_r)
        3'b000: begin
            case(addr_in[1:0])
                2'b00: data_out = {{24{in1_rdata[7]}},in1_rdata[7:0]};
                2'b01: data_out = {{24{in1_rdata[15]}},in1_rdata[15:8]};
                2'b10: data_out = {{24{in1_rdata[23]}},in1_rdata[23:16]};
                2'b11: data_out = {{24{in1_rdata[31]}},in1_rdata[31:24]};
            endcase
        end
        3'b001: begin
            case(addr_in[1])
                1'b0: data_out = {{16{in1_rdata[15]}},in1_rdata[15:0]};
                1'b1: data_out = {{16{in1_rdata[31]}},in1_rdata[31:16]};
            endcase
        end
        3'b010: data_out = in1_rdata;
        3'b011: data_out = addr_in_r; // 如 果 是 11， 输 出 ALUresult
        3'b100: begin
            case(addr_in[1:0])
                2'b00: data_out = {24'b0,in1_rdata[7:0]};
                2'b01: data_out = {24'b0,in1_rdata[15:8]};
                2'b10: data_out = {24'b0,in1_rdata[23:16]};
                2'b11: data_out = {24'b0,in1_rdata[31:24]};
            endcase
        end
        3'b101: begin
            case(addr_in[1])
                1'b0: data_out = {16'b0,in1_rdata[15:0]};
                1'b1: data_out = {16'b0,in1_rdata[31:16]};
            endcase
        end
        default: data_out = 32'b0;
    endcase
end

endmodule