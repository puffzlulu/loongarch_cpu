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

wire IFUvalid,LSUvalid;
wire IFUready,LSUready;
wire [31:0] pc;
wire [31:0] inst;
wire wr,stall;
wire [3:0] sram_be_n;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire [7:0] ext_uart_buffer;
wire ext_uart_avai;

IOControl IOController(
    .clk(clk_10M),
    .rst(reset_btn),
    .inst_en          (IFUready   ), //�ڴ���׼����ָ��
    .inst_ren         (IFUvalid   ), //ȡָģ������ڴ��ȡ����
    .inst_addr        (pc         ), 
    .inst_rdata       (inst       ),
    .stall            (stall      ),

    .data_en          (LSUready   ),//�ڴ���׼��������
    .data_wen         (wr         ),//LSUģ���Ƕ���д
    .data_be_n        (sram_be_n  ),
    .data_ren         (LSUvalid   ),//LSUģ������ź���Ч
    .data_addr        (data_addr  ),
    .data_wdata       (data_wdata ),
    .data_rdata       (data_rdata ),
    
    //BaseRAM�ź�
    .base_ram_data(base_ram_data),  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    .base_ram_addr(base_ram_addr), //BaseRAM��ַ
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),       //BaseRAMƬѡ������Ч
    .base_ram_oe_n(base_ram_oe_n),       //BaseRAM��ʹ�ܣ�����Ч
    .base_ram_we_n(base_ram_we_n),       //BaseRAMдʹ�ܣ�����Ч
    
    //ExtRAM�ź�
    .ext_ram_data(ext_ram_data),  //ExtRAM����
    .ext_ram_addr(ext_ram_addr), //ExtRAM��ַ
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),       //ExtRAMƬѡ������Ч
    .ext_ram_oe_n(ext_ram_oe_n),       //ExtRAM��ʹ�ܣ�����Ч
    .ext_ram_we_n(ext_ram_we_n),       //ExtRAMдʹ�ܣ�����Ч
    
    //ֱ�������ź�
    .txd(txd),  //ֱ�����ڷ��Ͷ�
    .rxd(rxd),  //ֱ�����ڽ��ն�
    .ext_uart_buffer(ext_uart_buffer),
    .ext_uart_avai(ext_uart_avai)
);

mycpu_top mycpu(
    .clk(clk_10M),
    .rst(reset_btn),
    .inst_en          (IFUready   ), //�ڴ���׼����ָ��
    .inst_ren         (IFUvalid   ), //ȡָģ������ڴ��ȡ����
    .inst_addr        (pc         ), 
    .inst_rdata       (inst       ),
    .stall            (stall      ),

    .data_en          (LSUready   ),//�ڴ���׼��������
    .data_wen         (wr         ),//LSUģ���Ƕ���д
    .data_be_n        (sram_be_n  ),
    .data_ren         (LSUvalid   ),//LSUģ������ź���Ч
    .data_addr        (data_addr  ),
    .data_wdata       (data_wdata ),
    .data_rdata       (data_rdata )
);

//�ٲ�
//always @(posedge clk_10M) begin
//    if(reset_btn) begin
//        IFUready <= 0;
//        LSUready <= 0;
//        inst <= 32'b0;
//        data_rdata <= 32'b0;
//    end
//    else begin
//        if(IFUvalid) begin
//            addr <= pc;
//        end
//    end
//end

////�ٲ�
//reg [31:0] inst_rdata_reg;
//reg [31:0] data_rdata_reg;
//wire is_inst;

//always @ (*) begin
//    if (reset_btn) begin
//        inst_rdata_reg <= 32'b0;
//        data_rdata_reg <= 32'b0;
//    end
//    else begin
//        inst_rdata_reg <= ~is_inst ? inst_rdata_reg 
//                            : ready ? IO_rdata 
//                            : inst_rdata_reg;
//        data_rdata_reg <= is_inst ? data_rdata_reg
//                            : ready ? IO_rdata
//                            : data_rdata_reg;
//    end
//end
//assign inst_rdata = inst_rdata_reg;
//assign data_rdata = data_rdata_reg;
//assign is_inst = ~data_addr;

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
assign leds = {data_rdata,ext_uart_buffer};

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
