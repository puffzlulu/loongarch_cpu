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
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  // Clock in ports
  .clk_in1(clk_50M),  // 外部时钟输入
  // Clock out ports
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置  
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置  
  // Status and control signals
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );

reg reset_of_clk10M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
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

// 不使用内存、串口时，禁用其使能信号
//assign base_ram_ce_n = 1'b1;
//assign base_ram_oe_n = 1'b1;
//assign base_ram_we_n = 1'b1;

//assign ext_ram_ce_n = 1'b1;
//assign ext_ram_oe_n = 1'b1;
//assign ext_ram_we_n = 1'b1;

// 输入端口1 - LSU
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

// 输入端口2 - IFU
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

// 输出端口1 - 指令存储器 baseram
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

// 输出端口2 - 数据存储器 extram
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

// 输出端口3 - 串口
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
  // 输入端口1 - LSU
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
  // 输入端口2 - IFU
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
  // 输出端口1 - 指令存储器 baseram
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
  // 输出端口2 - 数据存储器 extram
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
  // 输出端口3 - 串口
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
  // 读地址通道
    .araddr(base_ram_araddr),
    .arvalid(out1_arvalid),
    .arready(out1_arready),
  // 读数据通道
    .rdata(out1_rdata),
    .rvalid(out1_rvalid),
    .rready(out1_rready),
  // 写地址&写数据通道
    .waddr(base_ram_waddr),
    .wdata(out1_wdata),
    .wstrb(out1_wstrb),
    .wvalid(out1_wvalid),
    .wready(out1_wready),

  // 顶层信号
    .ram_data(base_ram_data),
    .ram_addr(base_ram_addr),
    .ram_be_n(base_ram_be_n),
  // output  wire        ram_ce_n, RAM一直处于片选状态
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
  // 读地址通道
    .araddr(ext_ram_araddr),
    .arvalid(out2_arvalid),
    .arready(out2_arready),
  // 读数据通道
    .rdata(out2_rdata),
    .rvalid(out2_rvalid),
    .rready(out2_rready),
  // 写地址&写数据通道
    .waddr(ext_ram_waddr),
    .wdata(out2_wdata),
    .wstrb(out2_wstrb),
    .wvalid(out2_wvalid),
    .wready(out2_wready),

  // 顶层信号
    .ram_data(ext_ram_data),
    .ram_addr(ext_ram_addr),
    .ram_be_n(ext_ram_be_n),
  // output  wire        ram_ce_n, RAM一直处于片选状态
    .ram_oe_n(ext_ram_oe_n),
    .ram_we_n(ext_ram_we_n)
);

mycpu_top mycpu(
  .clock(clk_10M),
  .reset(reset_of_clk10M),
  // 输入端口1 - LSU
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
  // 输入端口2 - IFU
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

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
//SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
//SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

//reg[15:0] led_bits;
//assign leds = led_bits;
//assign leds = {data_rdata,ext_uart_buffer};

//always@(posedge clock_btn or posedge reset_btn) begin
//    if(reset_btn)begin //复位按下，设置LED为初始值
//        led_bits <= 16'h1;
//    end
//    else begin //每次按下时钟按钮，LED循环左移
////        led_bits <= {led_bits[14:0],led_bits[15]};
//        led_bits[7:0] <=  ext_uart_buffer;
//    end
//end

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
