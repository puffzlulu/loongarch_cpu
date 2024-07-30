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
  // 读地址通道
  input   wire [19:0] araddr,
  input   wire        arvalid,
  output  wire        arready,
  // 读数据通道
  output  wire [31:0] rdata,
  output  wire        rvalid,
  input   wire        rready,
  // 写地址&写数据通道
  input   wire [19:0] waddr,
  input   wire [31:0] wdata,
  input   wire [3:0]  wstrb,
  input   wire        wvalid,
  output  wire        wready,

  // 顶层信号
  inout   wire [31:0] ram_data,
  output  wire [19:0] ram_addr,
  output  wire [3:0]  ram_be_n,
  // output  wire        ram_ce_n, RAM一直处于片选状态
  output  wire        ram_oe_n,
  output  wire        ram_we_n
);
// 模块需要用到的寄存器
reg [31:0] datareg;

// 三态门，写使能低有效，无效时为高阻态
assign ram_data = ram_we_n ? 32'bz : wdata;

// 三段式有限状态机
// 状态声明
reg [1:0] CurState, NextState;
parameter [1:0]
  s_idle        = 2'b00,
  s_read        = 2'b01,
  s_write       = 2'b10,
  s_read_wait_ready = 2'b11;

// 第一段 状态更新
always @(posedge clock) begin
  if(reset) CurState <= s_idle;
  else CurState <= NextState;
end

// 第二段 NextState更新，组合逻辑
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

// 寄存器更新
always @(posedge clock) begin
  if(reset) datareg <= 32'b0;
  else if(CurState == s_read) datareg <= ram_data;      // 寄存数据，放置rready为低
end

// 第三段 状态机输出
assign arready = (CurState == s_read) ? 1'b1 : 1'b0;                  // 在读数据阶段返回ready
assign rdata =  (CurState == s_read) ? ram_data :
                (CurState == s_read_wait_ready) ? datareg : 32'b0;
assign rvalid = ((CurState == s_read) || (CurState == s_read_wait_ready));  // 当处于s_read或者s_read_wait_ready时为高
assign wready = (CurState == s_write);                  // 处于s_write阶段时，完成写
assign ram_addr = arvalid ? araddr : waddr;// 如果arvalid为1则为读地址，否则为写地址 
assign ram_be_n = arvalid ? 4'b0 : wstrb;              // 如果arvalid为1则为读，4字节全部有效，否则为写
assign ram_oe_n = ~(CurState == s_read);
assign ram_we_n = ~(CurState == s_write);
endmodule
