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
    input wire [31:0] addr_in , // 访 存 地 址
    input wire [2:0] type ,
    // 000:一 字 节符号扩展 001:两 字 节符号扩展 010:四 字 节 011:输 出 执 行 单 元 计 算 结 果
    // 100:一字节零扩展     101：两字节零扩展
    // 访 存 数 据 信 号
    input wire [31:0] data_in , // 访 存 单 元 输 入 数 据
    output reg [31:0] data_out ,// 访 存 单 元 输 出 数 据
    // 存 储 器 控 制 信 号
    output reg wr_out , // 存 储 器 读/写 控 制 信 号
    output reg [31:0] addr_out , // 存 储 器 读 写 地 址
    output wire [2:0] cpu_type ,
    // 存 储 器 数 据 信 号
    output wire [31:0] wdata_out , // 存 储 器 写 数 据
    input wire [31:0] rdata_in, // 存 储 器 读 数 据
    input wire ready, //存储器读数据有效
    output reg valid,
    output reg mem_done,
    input wire inst_en
//    input wire inst_ren
//    input wire gr_we,
//    output reg rf_we
);

// 访 存 单 元 控 制 部 分
//assign wr_out = wr_in[0];
assign cpu_type = type;

// 地 址 对 齐
//always @(*) begin
//    case(type)
//    3'b000: addr_out = addr_in;
//    3'b001: addr_out = {addr_in[31:1],1'b0};
//    3'b010: addr_out = {addr_in[31:2],2'b00};
//    3'b011: addr_out = addr_in;
//    3'b100: addr_out = addr_in;
//    3'b101: addr_out = {addr_in[31:1],1'b0};
//    default: addr_out = addr_in;
//    endcase
//end

assign wdata_out = data_in;

//reg [31:0] mem_data_out;
//reg flag;

//always @(*) begin
//    if(~wr_in) data_out = addr_in;
//    else begin
//        if(flag) data_out = mem_data_out;
//    end
//end

reg [1:0] state;
parameter IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10, WAIT = 2'b11;

always @(posedge clk) begin
    if(rst) begin
        valid <= 0;
        state <= IDLE;
        mem_done <= 1;
    end
    else begin
    case(state)
        IDLE: begin
            if(wr_in[0]) begin
                state <= WRITE;
                mem_done <= 0;
            end
            else if(wr_in[1]) begin
                state <= READ;
                mem_done <= 0;
            end
            else begin
                state <= state;
                data_out = addr_in;
                mem_done <= 1;
                valid <= 0;
            end
            if(wr_in) begin
                valid <= 1;
                wr_out = wr_in[0];
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
            else begin
                addr_out <= 32'b0;
                valid <= 0;
            end
        end
        READ: begin
            if(ready) begin
                state <= WAIT;
                mem_done <= 1;
                valid <= 0;
                wr_out <= 0;
                case(type)
                    3'b000: begin
                        case(addr_in[1:0])
                            2'b00: data_out = {{24{rdata_in[7]}},rdata_in[7:0]};
                            2'b01: data_out = {{24{rdata_in[15]}},rdata_in[15:8]};
                            2'b10: data_out = {{24{rdata_in[23]}},rdata_in[23:16]};
                            2'b11: data_out = {{24{rdata_in[31]}},rdata_in[31:24]};
                        endcase
                    end
                    3'b001: begin
                        case(addr_in[1])
                            1'b0: data_out = {{16{rdata_in[15]}},rdata_in[15:0]};
                            1'b1: data_out = {{16{rdata_in[31]}},rdata_in[31:16]};
                        endcase
                    end
                    3'b010: data_out = rdata_in;
                    3'b011: data_out = addr_in; // 如 果 是 11， 输 出 ALUresult
                    3'b100: begin
                        case(addr_in[1:0])
                            2'b00: data_out = {24'b0,rdata_in[7:0]};
                            2'b01: data_out = {24'b0,rdata_in[15:8]};
                            2'b10: data_out = {24'b0,rdata_in[23:16]};
                            2'b11: data_out = {24'b0,rdata_in[31:24]};
                        endcase
                    end
                3'b101: begin
                    case(addr_in[1])
                        1'b0: data_out = {16'b0,rdata_in[15:0]};
                        1'b1: data_out = {16'b0,rdata_in[31:16]};
                    endcase
                end
                default: data_out = 32'b0;
                endcase
            end
            else state <= state;
        end
        WRITE: begin
            if(ready) begin
                wr_out <= 0;
                mem_done <= 1;
                valid <= 0;
                state <= WAIT;
            end
            else state <= state;
        end
        WAIT: begin
           /* wr_out <= 0;*/
            mem_done <= 0;
            if(inst_en) state <= IDLE;
            else state <= state;
        end
    endcase
    end
end

endmodule