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
  input  wire [18:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result
);

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
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];
assign op_mul  = alu_op[12];
assign op_mulh = alu_op[13];
assign op_mulhu= alu_op[14];
assign op_div  = alu_op[15];
assign op_mod  = alu_op[16];
assign op_divu = alu_op[17];
assign op_modu = alu_op[18];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
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

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

//mul result
assign multiply_result_unsign = alu_src1 * alu_src2;
assign multiply_result_sign = $signed(alu_src1) * $signed(alu_src2);
assign mul_result = multiply_result_unsign[31:0];
assign mulh_result = multiply_result_sign[63:32];
assign mulhu_result = multiply_result_unsign[63:32];

//div,mod result
assign div_result = $signed(alu_src1) / $signed(alu_src2);
assign mod_result = $signed(alu_src1) % $signed(alu_src2);
assign divu_result = alu_src1 / alu_src2;
assign modu_result = alu_src1 % alu_src2;

// SLL result
assign sll_result = alu_src2 << alu_src1[4:0];   //rj << i5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2[31]}}, alu_src2[31:0]} >> alu_src1[4:0]; //rj >> i5

assign sr_result   = sr64_result[30:0];

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul       }} & mul_result)
                  | ({32{op_mulh      }} & mulh_result)
                  | ({32{op_mulhu     }} & mulhu_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_mod       }} & mod_result)
                  | ({32{op_divu      }} & divu_result)
                  | ({32{op_modu      }} & modu_result);

endmodule