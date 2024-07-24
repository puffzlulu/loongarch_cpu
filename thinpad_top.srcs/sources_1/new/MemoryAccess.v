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
    input wire clk,
    input wire rst,
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
    output reg wr_out , // �� �� �� ��/д �� �� �� ��
    output reg [31:0] addr_out , // �� �� �� �� д �� ַ
    output wire [2:0] cpu_type ,
    // �� �� �� �� �� �� ��
    output wire [31:0] wdata_out , // �� �� �� д �� ��
    input wire [31:0] rdata_in, // �� �� �� �� �� ��
    input wire ready, //�洢����������Ч
    output reg valid,
    output reg mem_done,
    input wire inst_en
//    input wire inst_ren
//    input wire gr_we,
//    output reg rf_we
);

// �� �� �� Ԫ �� �� �� ��
//assign wr_out = wr_in[0];
assign cpu_type = type;

// �� ַ �� ��
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
                    3'b011: data_out = addr_in; // �� �� �� 11�� �� �� ALUresult
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