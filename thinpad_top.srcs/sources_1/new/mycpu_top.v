`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/21 11:17:24
// Design Name: 
// Module Name: mycpu_top
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


module mycpu_top(
    input wire clk,
    input wire rst,
    input wire inst_en, //内存已准备好指令
    output wire inst_ren, //取指模块想从内存获取数据
    output wire [31:0] inst_addr, 
    input wire [31:0] inst_rdata,
    input wire stall,

    input wire data_en,//内存已准备好数据
    output wire data_wen,//LSU模块是读是写
    output wire [3:0] data_be_n,
    output wire data_ren,//LSU模块给出信号有效
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire [31:0] data_rdata
);

// 各 部 分 连 线
wire [4:0] raddr1,raddr2;
wire [31:0] rdata1,rdata2;
wire [18:0] exeopcode;
wire [31:0] operandA,operandB;
wire [1:0] wr; //2'b00无访存形为 2'b01访存写 2'b10访存读
wire [2:0] type,cpu_type;
wire [31:0] decode_wdata_out;
wire [4:0] waddr;
wire NPCsel,rf_we,gr_we;
wire [31:0] NPCaddr,ALUresult,memoryaccess_data_out;
wire memoryaccess_wr_out;
wire [31:0] cpu_rdata;
wire [31:0] memoryaccess_addr_out,inst;
wire mem_done;
wire new_stall;
assign new_stall = (inst_addr == 32'h80000000) ? stall : (stall | (wr & ~data_en));

InstructionFetchUnit InstructionFetchUint(
    .clk(clk),
    .rst(rst),
    .pc(inst_addr),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    .valid(inst_ren),
//    .stall(new_stall),
    .ready(inst_en),
    .mem_done(mem_done)
);

DecodeUnit DecodeUnit(
    .clk(clk),
    .pc(inst_addr),
    .inst(inst_rdata),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .exeopcode(exeopcode), 
    .operandA(operandA),
    .operandB(operandB),
    .wr(wr),
    .type(type),
    .wdata(decode_wdata_out),
    .waddr(waddr),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    .sram_be_n(data_be_n),
    .gr_we(rf_we)
);

// 寄 存 器 堆
regfile Registers(
    .clk(clk),
    .rst(rst),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .waddr(waddr),
    .wdata(memoryaccess_data_out),
    .wdata_alu(ALUresult),
    .wr(wr),
    .we(rf_we),
    .inst_en(inst_en)
);

// 执 行 单 元
ExecuteUnit ExecuteUnit(
//    .clk(cpu_clk),
//    .rst(rst),
    .alu_op(exeopcode),
    .alu_src1(operandA),
    .alu_src2(operandB),
    .alu_result(ALUresult)
);

// 访 存 单 元
MemoryAccess MemoryAccess(
    .clk(clk),
    .rst(rst),
    .wr_in(wr),
    .addr_in(ALUresult),
    .type(type),
    .data_in(decode_wdata_out),
    .data_out(memoryaccess_data_out),
    .wr_out(data_wen),
    .addr_out(data_addr),
    .cpu_type(cpu_type),
    .wdata_out(data_wdata),
    .rdata_in(data_rdata),
    .ready(data_en),
    .valid(data_ren),
    .mem_done(mem_done),
    .inst_en(inst_en)
//    .inst_ren(inst_ren)
//    .gr_we(gr_we),
//    .rf_we(rf_we)
);

endmodule
