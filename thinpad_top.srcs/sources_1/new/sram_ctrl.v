`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 15:35:43
// Design Name: 
// Module Name: sram_ctrl
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


module SRAMController(
  input   wire        clock,
  input   wire        reset,
  // ����ַͨ��
  input   wire [19:0] araddr,
  input   wire        arvalid,
  output  wire        arready,
  // ������ͨ��
  output  wire [31:0] rdata,
  output  wire        rvalid,
  input   wire        rready,
  // д��ַ&д����ͨ��
  input   wire [19:0] waddr,
  input   wire [31:0] wdata,
  input   wire [3:0]  wstrb,
  input   wire        wvalid,
  output  wire        wready,

  // �����ź�
  inout   wire [31:0] ram_data,
  output  wire [19:0] ram_addr,
  output  wire [3:0]  ram_be_n,
  // output  wire        ram_ce_n, RAMһֱ����Ƭѡ״̬
  output  wire        ram_oe_n,
  output  wire        ram_we_n
);
// ģ����Ҫ�õ��ļĴ���
reg [31:0] datareg;

// ��̬�ţ�дʹ�ܵ���Ч����ЧʱΪ����̬
assign ram_data = ram_we_n ? 32'bz : wdata;

// ����ʽ����״̬��
// ״̬����
reg [1:0] CurState, NextState;
parameter [1:0]
  s_idle        = 2'b00,
  s_read        = 2'b01,
  s_write       = 2'b10,
  s_read_wait_ready = 2'b11;

// ��һ�� ״̬����
always @(posedge clock) begin
  if(reset) CurState <= s_idle;
  else CurState <= NextState;
end

// �ڶ��� NextState���£�����߼�
always @(*) begin
  case(CurState)
    s_idle:             NextState = arvalid ? s_read :
                                    wvalid ? s_write : s_idle;
    s_read:             NextState = rready ? s_idle : s_read_wait_ready;
    s_read_wait_ready : NextState = rready ? s_idle : s_read_wait_ready;
    s_write:            NextState = s_idle;
    default:            NextState = s_idle;
  endcase
end

// �Ĵ�������
always @(posedge clock) begin
  if(reset) datareg <= 32'b0;
  else if(CurState == s_read) datareg <= ram_data;      // �Ĵ����ݣ�����rreadyΪ��
end

// ������ ״̬�����
assign arready = (CurState == s_read) ? 1'b1 : 1'b0;                  // �ڶ����ݽ׶η���ready
assign rdata =  (CurState == s_read) ? ram_data :
                (CurState == s_read_wait_ready) ? datareg : 32'b0;
assign rvalid = ((CurState == s_read) || (CurState == s_read_wait_ready));  // ������s_read����s_read_wait_readyʱΪ��
assign wready = (CurState == s_write);                  // ����s_write�׶�ʱ�����д
assign ram_addr = arvalid ? araddr : waddr;// ���arvalidΪ1��Ϊ����ַ������Ϊд��ַ 
assign ram_be_n = arvalid ? 4'b0 : wstrb;              // ���arvalidΪ1��Ϊ����4�ֽ�ȫ����Ч������Ϊд
assign ram_oe_n = ~(CurState == s_read);
assign ram_we_n = ~(CurState == s_write);
endmodule
