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
  input   wire        clock,
  input   wire        reset,
  // 输入端口1 - LSU
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
  // 输入端口2 - IFU
  output   wire [31:0] in2_araddr,
  output   wire        in2_arvalid,
  input  wire        in2_arready,
  input  wire [31:0] in2_rdata,
  input  wire        in2_rvalid,
  output   wire        in2_rready,
  output   wire [31:0] in2_waddr,
  output   wire [31:0] in2_wdata,
  output   wire [3:0]  in2_wstrb,
  output   wire        in2_wvalid,
  input  wire        in2_wready
);

// 各 部 分 连 线
wire [4:0] raddr1,raddr2;
wire [31:0] rdata1,rdata2;
wire [18:0] exeopcode;
wire [31:0] operandA,operandB;
wire [1:0] wr; //2'b00无访存形为 2'b01访存写 2'b10访存读
wire [2:0] type;
wire [31:0] decode_wdata_out;
wire [3:0] sram_be_n;
wire [4:0] waddr_reg;
wire NPCsel,gr_we;
wire [31:0] NPCaddr,ALUresult,memoryaccess_data_out;

wire IF_valid,ID_ready;
wire IS_ready,IS_valid;
wire ID_valid,EXU_ready;
wire EXU_valid,LSU_ready;
wire LSU_valid,WB_ready;
wire [1:0] wr_r;
wire [2:0] type_r;
wire [31:0] wdata_r;
wire [3:0] sram_be_n_r;
wire [4:0] waddr_reg_r,waddr_reg_rr;
wire gr_we_r,gr_we_rr;
wire [31:0] pc,LSU_addr,inst;
wire src2_is_imm;

InstructionFetchUnit InstructionFetchUint(
    .clk(clock),
    .rst(reset),
    .pc(pc),
    .inst(inst),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    //和外设交互部分
    .in2_araddr(in2_araddr),
    .in2_arvalid(in2_arvalid),
    .in2_arready(in2_arready),
    .in2_rdata(in2_rdata),
    .in2_rvalid(in2_rvalid),
    .in2_rready(in2_rready),
    .in2_waddr(in2_waddr),
    .in2_wdata(in2_wdata),
    .in2_wstrb(in2_wstrb),
    .in2_wvalid(in2_wvalid),
    .in2_wready(in2_wready),
    //和ID交互部分
    .IF_valid(IF_valid),
    .ID_ready(ID_ready)
);

DecodeUnit DecodeUnit(
    .clk(clock),
    .rst(reset),
    .pc(pc),
    .inst(inst),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .src2_is_imm(src2_is_imm),
    .exeopcode(exeopcode), 
    .operandA(operandA),
    .operandB(operandB),
    .wr(wr),
    .type(type),
    .wdata(decode_wdata_out),
    .sram_be_n(sram_be_n),
    .waddr(waddr_reg),
    .gr_we(gr_we),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    .IF_valid(IF_valid),
    .ID_ready(ID_ready),
    .ID_valid(ID_valid),
    .EXU_ready(IS_ready)
);

launch score_board(
    .clk(clock),
    .rst(reset),
    .ID_rd(waddr_reg),
    .ID_in1(raddr1),
    .ID_in2(raddr2),
    .src2_is_imm(src2_is_imm),
    .WB_waddr(waddr_reg_rr),
    .reg_we(gr_we),
    .ID_valid(ID_valid),
    .IS_ready(IS_ready),
    .IS_valid(IS_valid),
    .EXU_ready(EXU_ready),
    .LSU_valid(LSU_valid)
);

// 寄 存 器 堆
regfile Registers(
    .clk(clock),
    .rst(reset),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .waddr(waddr_reg_rr),
    .wdata(memoryaccess_data_out),
    .we(gr_we_rr),
    .LSU_valid(LSU_valid)
);

// 执 行 单 元
ExecuteUnit ExecuteUnit(
    .clk(clock),
    .rst(reset),
    .alu_op(exeopcode),
    .alu_src1(operandA),
    .alu_src2(operandB),
    .alu_result(ALUresult),
    .wr(wr),
    .type(type),
    .wdata(decode_wdata_out),
    .sram_be_n(sram_be_n),
    .waddr(waddr_reg),
    .gr_we(gr_we),
    .wr_r(wr_r),
    .type_r(type_r),
    .wdata_r(wdata_r),
    .sram_be_n_r(sram_be_n_r),
    .waddr_r(waddr_reg_r),
    .gr_we_r(gr_we_r),
    .ID_valid(IS_valid),
    .EXU_ready(EXU_ready),
    .EXU_valid(EXU_valid),
    .LSU_ready(LSU_ready)
);

// 访 存 单 元
MemoryAccess MemoryAccess(
    .clk(clock),
    .rst(reset),
    .wr_in(wr_r), 
    .addr_in(ALUresult),
    .type(type_r),
    .sram_be_n(sram_be_n_r),
    .data_in(wdata_r),
    .data_out(memoryaccess_data_out),
    .waddr_reg(waddr_reg_r),
    .gr_we(gr_we_r),
    .waddr_reg_r(waddr_reg_rr),
    .gr_we_r(gr_we_rr),
    .in1_araddr(in1_araddr),
    .in1_arvalid(in1_arvalid),
    .in1_arready(in1_arready),
    .in1_rdata(in1_rdata),
    .in1_rvalid(in1_rvalid),
    .in1_rready(in1_rready),
    .in1_waddr(in1_waddr),
    .in1_wdata(in1_wdata),
    .in1_wstrb(in1_wstrb),
    .in1_wvalid(in1_wvalid),
    .in1_wready(in1_wready),
    .EXU_valid(EXU_valid),
    .LSU_ready(LSU_ready),
    .LSU_valid(LSU_valid)
);

endmodule
