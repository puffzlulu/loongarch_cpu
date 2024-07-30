`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 21:40:58
// Design Name: 
// Module Name: ExecuteUnit
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


module ExecuteUnit(
  input wire clk,
  input wire rst,
  input  wire [18:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result,
  
  input wire [1:0] wr,
  input wire [2:0] type,
  input wire [31:0] wdata,
  input wire [3:0] sram_be_n,
  input wire [4:0] waddr,
  input wire gr_we,
  
  output reg [1:0] wr_r,
  output reg [2:0] type_r,
  output reg [31:0] wdata_r,
  output reg [3:0] sram_be_n_r,
  output reg [4:0] waddr_r,
  output reg gr_we_r,
  
  input wire ID_valid,
  output wire EXU_ready,
  output wire EXU_valid,
  input wire LSU_ready
);

assign EXU_ready = LSU_ready;
assign EXU_valid = ID_valid;

reg [18:0] alu_op_r;
reg [31:0] alu_src1_r;
reg [31:0] alu_src2_r;

always @(posedge clk) begin
    if(rst) begin
        alu_op_r <= 19'b0;
        alu_src1_r <= 32'b0;
        alu_src2_r <= 32'b0;
        wr_r <= 2'b0;
        type_r <= 3'b0;
        wdata_r <= 32'b0;
        sram_be_n_r <= 4'b0;
        waddr_r <= 5'b0;
        gr_we_r <= 1'b0;
    end
    else if(ID_valid) begin
        alu_op_r <= alu_op;
        alu_src1_r <= alu_src1;
        alu_src2_r <= alu_src2;
        wr_r <= wr;
        type_r <= type;
        wdata_r <= wdata;
        sram_be_n_r <= sram_be_n;
        waddr_r <= waddr;
        gr_we_r <= gr_we;
    end
end

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate
wire op_mul;   //mul result[31:0]
wire op_mulh;  //mul result[63:32] sign
wire op_mulhu; //mul result[63:32] unsign
wire op_div;   //div operation
wire op_mod;   //mod operation
wire op_divu;  //div unsign
wire op_modu;  //mod unsign

// control code decomposition
assign op_add  = alu_op_r[ 0];
assign op_sub  = alu_op_r[ 1];
assign op_slt  = alu_op_r[ 2];
assign op_sltu = alu_op_r[ 3];
assign op_and  = alu_op_r[ 4];
assign op_nor  = alu_op_r[ 5];
assign op_or   = alu_op_r[ 6];
assign op_xor  = alu_op_r[ 7];
assign op_sll  = alu_op_r[ 8];
assign op_srl  = alu_op_r[ 9];
assign op_sra  = alu_op_r[10];
assign op_lui  = alu_op_r[11];
assign op_mul  = alu_op_r[12];
assign op_mulh = alu_op_r[13];
assign op_mulhu= alu_op_r[14];
assign op_div  = alu_op_r[15];
assign op_mod  = alu_op_r[16];
assign op_divu = alu_op_r[17];
assign op_modu = alu_op_r[18];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [31:0] sra_result;
wire [31:0] srl_result;
wire [63:0] multiply_result_unsign;
wire [63:0] multiply_result_sign;
wire [31:0] mul_result;
wire [31:0] mulh_result; 
wire [31:0] mulhu_result;
wire [31:0] div_result;
wire [31:0] mod_result;
wire [31:0] divu_result;
wire [31:0] modu_result;


// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;
wire [31:0] sub_result;
wire [31:0] test_sub_result;

assign adder_a   = alu_src1_r;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2_r : alu_src2_r;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;
assign sub_result = alu_src1_r - alu_src2_r;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1_r[31] & ~alu_src2_r[31])
                        | ((alu_src1_r[31] ~^ alu_src2_r[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1_r & alu_src2_r;
assign or_result  = alu_src1_r | alu_src2_r;
assign nor_result = ~or_result;
assign xor_result = alu_src1_r ^ alu_src2_r;
assign lui_result = alu_src2_r;

//mul result
assign multiply_result_unsign = alu_src1_r * alu_src2_r;
assign multiply_result_sign = $signed(alu_src1_r) * $signed(alu_src2_r);
assign mul_result = multiply_result_unsign[31:0];
assign mulh_result = multiply_result_sign[63:32];
assign mulhu_result = multiply_result_unsign[63:32];

//div,mod result
assign div_result = $signed(alu_src1_r) / $signed(alu_src2_r);
assign mod_result = $signed(alu_src1_r) % $signed(alu_src2_r);
assign divu_result = alu_src1_r / alu_src2_r;
assign modu_result = alu_src1_r % alu_src2_r;

// SLL result
assign sll_result = alu_src1_r << alu_src2_r[4:0];   //rj << i5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2_r[31]}}, alu_src2_r[31:0]} >> alu_src1_r[4:0]; //rj >> i5

//assign sr_result   = sr64_result[30:0];
assign sra_result   = alu_src1_r >>> alu_src2_r[4:0];
assign srl_result   = alu_src1_r >> alu_src2_r[4:0];


// final result mux
assign alu_result = ({32{op_add       }} & add_sub_result)
                  | ({32{op_sub       }} & sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_sra       }} & sra_result)
                  | ({32{op_srl       }} & srl_result)
                  | ({32{op_mul       }} & mul_result)
                  | ({32{op_mulh      }} & mulh_result)
                  | ({32{op_mulhu     }} & mulhu_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_mod       }} & mod_result)
                  | ({32{op_divu      }} & divu_result)
                  | ({32{op_modu      }} & modu_result);
assign test_sub_result = ({32{op_sub       }} & sub_result);

endmodule