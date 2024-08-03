`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/30 21:40:24
// Design Name: 
// Module Name: UartController
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


module UartController(
  input   wire        clock,
  input   wire        reset,
  // 读地址通道
  input   wire [31:0] araddr,
  input   wire        arvalid,
  output  wire        arready,
  // 读数据通道
  output  wire [31:0] rdata,
  output  wire        rvalid,
  input   wire        rready,
  // 写地址&写数据通道
  input   wire [31:0] waddr,
  input   wire [31:0] wdata,
  input   wire [3:0]  wstrb,
  input   wire        wvalid,
  output  wire        wready,
  
  output reg   [7:0] ext_uart_buffer,

  // 顶层信号
  output  wire        txd,
  input   wire        rxd
);

// 本模块需要用到的寄存器或者线
wire  [7:0] ext_uart_rx;
reg   [7:0] ext_uart_tx;
wire        ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg         ext_uart_start, ext_uart_avai;
reg   [31:0] addrreg;

// 串口接收者模块
async_receiver #(.ClkFrequency(73000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clock),                          //外部时钟信号
        .RxD(rxd),                            //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),      //数据接收到标志
        .RxD_clear(ext_uart_clear),           //清除接收标志
        .RxD_data(ext_uart_rx)                //接收到的一字节数据
    );
assign ext_uart_clear = ext_uart_ready;       //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中

// 串口发送者模块
async_transmitter #(.ClkFrequency(73000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clock),                          //外部时钟信号
        .TxD(txd),                            //串行信号输出
        .TxD_busy(ext_uart_busy),             //发送器忙状态指示
        .TxD_start(ext_uart_start),           //开始发送信号
        .TxD_data(ext_uart_tx)                //待发送的数据
    );

// 三段式有限状态机
// 状态声明
reg [1:0] CurState, NextState;
parameter [1:0]
  s_idle            = 2'b00,
  s_read            = 2'b01,
  s_read_wait_ready = 2'b10,
  s_write           = 2'b11;

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
    s_read_wait_ready:  NextState = rready ? s_idle : s_read_wait_ready;
    s_write:            NextState = s_idle;
    default:            NextState = s_idle;
  endcase
end

// 寄存器更新
always @(posedge clock) begin
  if(reset) begin
    ext_uart_buffer <= 8'b0;
    ext_uart_avai   <= 1'b0;
  end
  else if(ext_uart_ready) begin
    ext_uart_buffer <= ext_uart_rx;
    ext_uart_avai   <= 1'b1;
  end
  else if((CurState==s_read)&&(araddr == 32'hBFD003F8)) begin     // 这边需要补充串口数据寄存器地址
    ext_uart_avai   <= 1'b0;
  end
end

always @(posedge clock) begin
  if(reset) begin
    ext_uart_tx <= 8'b0;
    ext_uart_start <= 1'b0;
  end
  else if((NextState==s_write)) begin
    ext_uart_tx <= wdata[7:0];
    ext_uart_start <= 1'b1;
  end
  else ext_uart_start <= 1'b0;
end

always @(posedge clock) begin
  if(reset) addrreg <= 32'b0;
  else if((CurState == s_read)) addrreg <= araddr;
end


// 第三段 状态机输出
assign arready = (CurState == s_read);              // 读数据阶段返回ready
assign rdata =  (CurState == s_read) ? ((araddr == 32'hBFD003F8) ? ext_uart_buffer : {30'b0,ext_uart_avai,~ext_uart_busy}) : //(根据araddr返回控制寄存器或者ext_uart_buffer)
                (CurState == s_read_wait_ready) ? ((addrreg == 32'hBFD003F8) ? ext_uart_buffer : {30'b0,ext_uart_avai,~ext_uart_busy}) : 32'b0; //(根据addrreg返回控制寄存器或者ext_uart_buffer)
assign rvalid =  ((CurState == s_read) || (CurState == s_read_wait_ready));  // 当处于s_read或者s_read_wait_ready时为高
assign wready = (CurState == s_write);

endmodule