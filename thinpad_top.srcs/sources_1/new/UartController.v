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
  // ����ַͨ��
  input   wire [31:0] araddr,
  input   wire        arvalid,
  output  wire        arready,
  // ������ͨ��
  output  wire [31:0] rdata,
  output  wire        rvalid,
  input   wire        rready,
  // д��ַ&д����ͨ��
  input   wire [31:0] waddr,
  input   wire [31:0] wdata,
  input   wire [3:0]  wstrb,
  input   wire        wvalid,
  output  wire        wready,
  
  output reg   [7:0] ext_uart_buffer,

  // �����ź�
  output  wire        txd,
  input   wire        rxd
);

// ��ģ����Ҫ�õ��ļĴ���������
wire  [7:0] ext_uart_rx;
reg   [7:0] ext_uart_tx;
wire        ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg         ext_uart_start, ext_uart_avai;
reg   [31:0] addrreg;

// ���ڽ�����ģ��
async_receiver #(.ClkFrequency(73000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clock),                          //�ⲿʱ���ź�
        .RxD(rxd),                            //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),      //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),           //������ձ�־
        .RxD_data(ext_uart_rx)                //���յ���һ�ֽ�����
    );
assign ext_uart_clear = ext_uart_ready;       //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��

// ���ڷ�����ģ��
async_transmitter #(.ClkFrequency(73000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clock),                          //�ⲿʱ���ź�
        .TxD(txd),                            //�����ź����
        .TxD_busy(ext_uart_busy),             //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),           //��ʼ�����ź�
        .TxD_data(ext_uart_tx)                //�����͵�����
    );

// ����ʽ����״̬��
// ״̬����
reg [1:0] CurState, NextState;
parameter [1:0]
  s_idle            = 2'b00,
  s_read            = 2'b01,
  s_read_wait_ready = 2'b10,
  s_write           = 2'b11;

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
    s_read_wait_ready:  NextState = rready ? s_idle : s_read_wait_ready;
    s_write:            NextState = s_idle;
    default:            NextState = s_idle;
  endcase
end

// �Ĵ�������
always @(posedge clock) begin
  if(reset) begin
    ext_uart_buffer <= 8'b0;
    ext_uart_avai   <= 1'b0;
  end
  else if(ext_uart_ready) begin
    ext_uart_buffer <= ext_uart_rx;
    ext_uart_avai   <= 1'b1;
  end
  else if((CurState==s_read)&&(araddr == 32'hBFD003F8)) begin     // �����Ҫ���䴮�����ݼĴ�����ַ
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


// ������ ״̬�����
assign arready = (CurState == s_read);              // �����ݽ׶η���ready
assign rdata =  (CurState == s_read) ? ((araddr == 32'hBFD003F8) ? ext_uart_buffer : {30'b0,ext_uart_avai,~ext_uart_busy}) : //(����araddr���ؿ��ƼĴ�������ext_uart_buffer)
                (CurState == s_read_wait_ready) ? ((addrreg == 32'hBFD003F8) ? ext_uart_buffer : {30'b0,ext_uart_avai,~ext_uart_busy}) : 32'b0; //(����addrreg���ؿ��ƼĴ�������ext_uart_buffer)
assign rvalid =  ((CurState == s_read) || (CurState == s_read_wait_ready));  // ������s_read����s_read_wait_readyʱΪ��
assign wready = (CurState == s_write);

endmodule