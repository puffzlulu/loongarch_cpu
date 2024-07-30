`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 21:43:25
// Design Name: 
// Module Name: DecodeUnit
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


module DecodeUnit(
    input wire clk,
    input wire rst,
    // 当 前 指 令 地 址
    input wire [31:0] pc,
    // 指 令
    input wire [31:0] inst ,
    // 寄 存 器 堆
    output wire [4:0] raddr1 ,
    input wire [31:0] rdata1 ,
    output wire [4:0] raddr2 ,
    input wire [31:0] rdata2 ,
    output wire src2_is_imm ,
    // 执 行 单 元 控 制 信 号
    output wire [18:0] exeopcode , // 执 行 单 元 执 行 码
    // 执 行 单 元 数 据 信 号
    output wire [31:0] operandA ,
    output wire [31:0] operandB ,
    // 访 存 单 元 控 制 信 号
    output wire[1:0] wr,
    output wire [2:0] type ,
    // 访 存 单 元 数 据 信 号
    output wire [31:0] wdata ,
    output reg [3:0] sram_be_n ,
    // 回 写 单 元 控 制 信 号
    output wire [4:0] waddr ,
    output wire gr_we ,
    // 取 指 单 元 控 制 信 号
    output wire NPCsel ,
    output wire [31:0] NPCaddr ,
    
    input wire IF_valid ,
    output wire ID_ready ,
    output wire ID_valid ,
    input wire EXU_ready
);

assign ID_ready = EXU_ready;
assign ID_valid = IF_valid;

reg [31:0] inst_r;
always @(posedge clk) begin
    if(rst) inst_r <= 32'b0;
    else if(IF_valid) inst_r <= inst;
end

//此模块需要完成的工作是：
//1.判断exeopcode 为ExecuteUnit模块提供operandA和operandB
//2.判断访存模块是读是写还是无访存，即确定wr和type
//3.确定回写寄存器和回写控制信号，即确定waddr和rf_we
//4.确定下一条指令，即确定NPCsel和NPCaddr

wire        load_op;
wire        src1_is_pc;
//wire        src2_is_imm;
wire        res_from_mem;
wire        dst_is_r1;
wire        src_reg_is_rd;
wire        rj_eq_rd;
wire        rj_lt_rd_sign;
wire        rj_lt_rd_unsign;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] br_offs; 
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;

//wire      inst_preld;
//wire      inst_ll_w;
//wire      inst_sc_w;
//wire      inst_dbar;
//wire      inst_ibar;
//wire      inst_break;
//wire      inst_syscall;
//wire      inst_rdcntvl_w;
//wire      inst_rdcntvh_w;
//wire      inst_rdcntid;
wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slti;
wire        inst_sltui;
wire        inst_pcaddu12i;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_mod_w;
wire        inst_div_wu;
wire        inst_mod_wu;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_blt;
wire        inst_bge;
wire        inst_bltu;
wire        inst_bgeu;
wire        inst_ld_b;
wire        inst_ld_h;
wire        inst_st_b;
wire        inst_st_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;

wire        need_ui5;
wire        need_si12;
wire        need_ui12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

assign op_31_26  = inst_r[31:26];
assign op_25_22  = inst_r[25:22];
assign op_21_20  = inst_r[21:20];
assign op_19_15  = inst_r[19:15];

assign rd   = inst_r[ 4: 0];
assign rj   = inst_r[ 9: 5];
assign rk   = inst_r[14:10];

assign i12  = inst_r[21:10];
assign i20  = inst_r[24: 5];
assign i16  = inst_r[25:10];
assign i26  = {inst_r[ 9: 0], inst_r[25:10]};

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_jirl   = op_31_26_d[6'h13];
assign inst_b      = op_31_26_d[6'h14];
assign inst_bl     = op_31_26_d[6'h15];
assign inst_beq    = op_31_26_d[6'h16];
assign inst_bne    = op_31_26_d[6'h17];
assign inst_lu12i_w= op_31_26_d[6'h05] & ~inst_r[25];
assign inst_slti        = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui       = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_pcaddu12i   = op_31_26_d[6'h07] & ~inst_r[25];
assign inst_andi        = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori         = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori        = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_mul_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulh_wu     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h01];
assign inst_div_wu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_mod_wu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h03];
assign inst_sll_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_blt         = op_31_26_d[6'h18];
assign inst_bge         = op_31_26_d[6'h19];
assign inst_bltu        = op_31_26_d[6'h1a];
assign inst_bgeu        = op_31_26_d[6'h1b];
assign inst_ld_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_h        = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_st_b        = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h        = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
assign inst_ld_bu       = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ld_hu       = op_31_26_d[6'h0a] & op_25_22_d[4'h9];

// 000:一 字 节符号扩展 001:两 字 节符号扩展 010:四 字 节 011:输 出 执 行 单 元 计 算 结 果
// 100:一字节零扩展     101：两字节零扩展
assign  type = (inst_ld_w | inst_st_w) ? 010 : 
               (inst_ld_b | inst_st_b) ? 000 :
               (inst_ld_h | inst_st_h) ? 001 :
               (inst_ld_bu) ?            100 :
               (inst_ld_hu) ?            101 : 011;
               
assign exeopcode[0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b
                    | inst_ld_h | inst_st_b | inst_st_h | inst_ld_bu | inst_ld_hu;
assign exeopcode[1] = inst_sub_w;
assign exeopcode[2] = inst_slt | inst_slti;
assign exeopcode[3] = inst_sltu | inst_sltui;
assign exeopcode[3] = inst_sltu | inst_sltui;
assign exeopcode[4] = inst_and | inst_andi;
assign exeopcode[5] = inst_nor;
assign exeopcode[6] = inst_or | inst_ori;
assign exeopcode[7] = inst_xor | inst_xori;
assign exeopcode[8] = inst_slli_w | inst_sll_w;
assign exeopcode[9] = inst_srli_w | inst_srl_w;
assign exeopcode[10] = inst_srai_w | inst_sra_w;
assign exeopcode[11] = inst_lu12i_w;
assign exeopcode[12] = inst_mul_w;
assign exeopcode[13] = inst_mulh_w;
assign exeopcode[14] = inst_mulh_wu;
assign exeopcode[15] = inst_div_w;
assign exeopcode[16] = inst_mod_w;
assign exeopcode[17] = inst_div_wu;
assign exeopcode[18] = inst_mod_wu;

wire[31:0] address;
assign address = operandA + operandB;

always@(*) begin
    case(type)
        3'b000: begin
            case(address[1:0])
                2'b00: sram_be_n = 4'b1110;
                2'b01: sram_be_n = 4'b1101;
                2'b10: sram_be_n = 4'b1011;
                2'b11: sram_be_n = 4'b0111;
            endcase
        end
        3'b001: begin
            case(address[1])
                1'b0: sram_be_n = 4'b1100;
                1'b1: sram_be_n = 4'b0011;
            endcase
        end
        default: sram_be_n = 4'b0000;
    endcase
end

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | inst_st_b | inst_st_h;
assign need_ui12  =  inst_andi | inst_ori | inst_xori;
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui12 ? {20'b0 , i12[11:0]}        :
//             need_si26 ? {{4{i26[25]}},i26[25:0],2'b0} : 
             need_ui5  ? {27'b0,inst_r[14:10]}        :
/*need_ui5 || need_si12*/{{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_st_b | inst_st_h;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_ld_b   |
                       inst_ld_h   |
                       inst_ld_bu  |
                       inst_ld_hu  |
                       inst_st_b   |
                       inst_st_h   |
                       inst_pcaddu12i;

assign res_from_mem  = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu & ~inst_st_b & ~inst_st_h;
assign wr[0]     = inst_st_w | inst_st_b | inst_st_h;
assign wr[1]     = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
assign waddr          = dst_is_r1 ? 5'd1 : rd;

assign raddr1 = rj;
assign raddr2 = src_reg_is_rd ? rd :rk;

assign rj_value  = rdata1;
assign rkd_value = rdata2;

assign wdata = rkd_value;

assign rj_eq_rd = (rj_value == rkd_value);
assign rj_lt_rd_sign = ($signed(rj_value) < $signed(rkd_value));
assign rj_lt_rd_unsign = (rj_value < rkd_value);
assign NPCsel = (   inst_beq  &&  rj_eq_rd
                   || inst_bne  && !rj_eq_rd
                   || inst_blt  && rj_lt_rd_sign
                   || inst_bge  && !rj_lt_rd_sign
                   || inst_bltu && rj_lt_rd_unsign
                   || inst_bgeu && !rj_lt_rd_unsign
                   || inst_jirl
                   || inst_bl
                   || inst_b
                  );
assign NPCaddr = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bge || inst_bltu || inst_bgeu) ? (pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);
//assign is_branch = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_b;

assign operandA = src1_is_pc  ? pc[31:0] : rj_value;
assign operandB = src2_is_imm ? imm : rkd_value;

endmodule
