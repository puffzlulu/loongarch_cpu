`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/14 00:31:47
// Design Name: 
// Module Name: thinpad_top
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


module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // �ⲿʱ������
  // Clock out ports
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������  
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������  
  // Status and control signals
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end

//always@(posedge clk_10M or posedge reset_of_clk10M) begin
//    if(reset_of_clk10M)begin
//        // Your Code
//    end
//    else begin
//        // Your Code
//    end
//end

// ��ʹ���ڴ桢����ʱ��������ʹ���ź�
//assign base_ram_ce_n = 1'b1;
//assign base_ram_oe_n = 1'b1;
//assign base_ram_we_n = 1'b1;

//assign ext_ram_ce_n = 1'b1;
//assign ext_ram_oe_n = 1'b1;
//assign ext_ram_we_n = 1'b1;

// ����˿�1 - LSU
wire [31:0] in1_araddr;
wire        in1_arvalid;
wire        in1_arready;
wire [31:0] in1_rdata;
wire        in1_rvalid;
wire        in1_rready;
wire [31:0] in1_waddr;
wire [31:0] in1_wdata;
wire [3:0]  in1_wstrb;
wire        in1_wvalid;
wire        in1_wready;

// ����˿�2 - IFU
wire [31:0] in2_araddr;
wire        in2_arvalid;
wire        in2_arready;
wire [31:0] in2_rdata;
wire        in2_rvalid;
wire        in2_rready;
wire [31:0] in2_waddr;
wire [31:0] in2_wdata;
wire [3:0]  in2_wstrb;
wire        in2_wvalid;
wire        in2_wready;

// ����˿�1 - ָ��洢�� baseram
wire [31:0] out1_araddr;
wire        out1_arvalid;
wire        out1_arready;
wire [31:0] out1_rdata;
wire        out1_rvalid;
wire        out1_rready;
wire [31:0] out1_waddr;
wire [31:0] out1_wdata;
wire [3:0]  out1_wstrb;
wire        out1_wvalid;
wire        out1_wready;

// ����˿�2 - ���ݴ洢�� extram
wire [31:0] out2_araddr;
wire        out2_arvalid;
wire        out2_arready;
wire [31:0] out2_rdata;
wire        out2_rvalid;
wire        out2_rready;
wire [31:0] out2_waddr;
wire [31:0] out2_wdata;
wire [3:0]  out2_wstrb;
wire        out2_wvalid;
wire        out2_wready;

// ����˿�3 - ����
wire [31:0] out3_araddr;
wire        out3_arvalid;
wire        out3_arready;
wire [31:0] out3_rdata;
wire        out3_rvalid;
wire        out3_rready;
wire [31:0] out3_waddr;
wire [31:0] out3_wdata;
wire [3:0]  out3_wstrb;
wire        out3_wvalid;
wire        out3_wready;

IOXbar ioo(
  .clock(clk_10M),
  .reset(reset_of_clk10M),
  // ����˿�1 - LSU
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
  // ����˿�2 - IFU
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
  // ����˿�1 - ָ��洢�� baseram
  .out1_araddr(out1_araddr),
  .out1_arvalid(out1_arvalid),
  .out1_arready(out1_arready),
  .out1_rdata(out1_rdata),
  .out1_rvalid(out1_rvalid),
  .out1_rready(out1_rready),
  .out1_waddr(out1_waddr),
  .out1_wdata(out1_wdata),
  .out1_wstrb(out1_wstrb),
  .out1_wvalid(out1_wvalid),
  .out1_wready(out1_wready),
  // ����˿�2 - ���ݴ洢�� extram
  .out2_araddr(out2_araddr),
  .out2_arvalid(out2_arvalid),
  .out2_arready(out2_arready),
  .out2_rdata(out2_rdata),
  .out2_rvalid(out2_rvalid),
  .out2_rready(out2_rready),
  .out2_waddr(out2_waddr),
  .out2_wdata(out2_wdata),
  .out2_wstrb(out2_wstrb),
  .out2_wvalid(out2_wvalid),
  .out2_wready(out2_wready),
  // ����˿�3 - ����
  .out3_araddr(out3_araddr),
  .out3_arvalid(out3_arvalid),
  .out3_arready(out3_arready),
  .out3_rdata(out3_rdata),
  .out3_rvalid(out3_rvalid),
  .out3_rready(out3_rready),
  .out3_waddr(out3_waddr),
  .out3_wdata(out3_wdata),
  .out3_wstrb(out3_wstrb),
  .out3_wvalid(out3_wvalid),
  .out3_wready(out3_wready)
);

wire [19:0] base_ram_araddr,base_ram_waddr;
assign base_ram_araddr = out1_araddr [21:2];
assign base_ram_waddr = out1_waddr [21:2];
assign base_ram_ce_n = 1'b0;
SRAMController base_ram_ctrl(
    .clock(clk_10M),
    .reset(reset_of_clk10M),
  // ����ַͨ��
    .araddr(base_ram_araddr),
    .arvalid(out1_arvalid),
    .arready(out1_arready),
  // ������ͨ��
    .rdata(out1_rdata),
    .rvalid(out1_rvalid),
    .rready(out1_rready),
  // д��ַ&д����ͨ��
    .waddr(base_ram_waddr),
    .wdata(out1_wdata),
    .wstrb(out1_wstrb),
    .wvalid(out1_wvalid),
    .wready(out1_wready),

  // �����ź�
    .ram_data(base_ram_data),
    .ram_addr(base_ram_addr),
    .ram_be_n(base_ram_be_n),
  // output  wire        ram_ce_n, RAMһֱ����Ƭѡ״̬
    .ram_oe_n(base_ram_oe_n),
    .ram_we_n(base_ram_we_n)
);

wire [31:0] araddr,waddr;
wire [19:0] ext_ram_araddr,ext_ram_waddr;
assign araddr = out2_araddr - 24'h400000;
assign waddr = out2_waddr - 24'h400000;
assign ext_ram_araddr = araddr[21:2];
assign ext_ram_waddr = waddr[21:2];
assign ext_ram_ce_n = 1'b0;
SRAMController ext_ram_ctrl(
    .clock(clk_10M),
    .reset(reset_of_clk10M),
  // ����ַͨ��
    .araddr(ext_ram_araddr),
    .arvalid(out2_arvalid),
    .arready(out2_arready),
  // ������ͨ��
    .rdata(out2_rdata),
    .rvalid(out2_rvalid),
    .rready(out2_rready),
  // д��ַ&д����ͨ��
    .waddr(ext_ram_waddr),
    .wdata(out2_wdata),
    .wstrb(out2_wstrb),
    .wvalid(out2_wvalid),
    .wready(out2_wready),

  // �����ź�
    .ram_data(ext_ram_data),
    .ram_addr(ext_ram_addr),
    .ram_be_n(ext_ram_be_n),
  // output  wire        ram_ce_n, RAMһֱ����Ƭѡ״̬
    .ram_oe_n(ext_ram_oe_n),
    .ram_we_n(ext_ram_we_n)
);

mycpu_top mycpu(
  .clock(clk_10M),
  .reset(reset_of_clk10M),
  // ����˿�1 - LSU
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
  // ����˿�2 - IFU
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
  .in2_wready(in2_wready)
);

// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
//SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
//SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

//reg[15:0] led_bits;
//assign leds = led_bits;
//assign leds = {data_rdata,ext_uart_buffer};

//always@(posedge clock_btn or posedge reset_btn) begin
//    if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
//        led_bits <= 16'h1;
//    end
//    else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
////        led_bits <= {led_bits[14:0],led_bits[15]};
//        led_bits[7:0] <=  ext_uart_buffer;
//    end
//end

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //������
    .vdata(),      //������
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
