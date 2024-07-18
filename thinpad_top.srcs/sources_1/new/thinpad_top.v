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

//---------------------------- mycpu ------------------------
// �� �� �� �� ��
reg[31:0] inst;
wire [31:0] pc;
wire [4:0] raddr1,raddr2;
wire [31:0] rdata1,rdata2;
wire [18:0] exeopcode;
wire [31:0] operandA,operandB;
wire [1:0] wr;
wire [2:0] type,cpu_type;
wire [31:0] decode_wdata_out;
wire [4:0] waddr;
wire NPCsel;
wire [31:0] NPCaddr,ALUresult,memoryaccess_data_out;
wire memoryaccess_wr_out;
wire [31:0] memoryaccess_addr_out,memoryaccess_wdata_out;
wire [31:0] cpu_rdata;
reg oen,wen;
reg[3:0] sram_be_n;
wire[3:0] ram_be_n;
reg[31:0] cpu_address;
reg[31:0] data_out;
reg[31:0] data_in;
reg pc_next;
wire sram_done;
reg reg_we;
wire is_branch;

InstructionFetchUnit InstructionFetchUint(
    .clk(clk_10M),
    .rst(reset_btn),
    .pc(pc),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    .next(pc_next)
);

DecodeUnit DecodeUnit(
    .clk(clk_10M),
    .pc(pc),
    .inst(inst),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .exeopcode(exeopcode), 
    .operandA(operandA),
    .operandB(operandB),
    .wr(wr),
    .type(type),
    .wdata(decode_wdata_out),
    .waddr(waddr),
    .NPCsel(NPCsel),
    .NPCaddr(NPCaddr),
    .sram_be_n(ram_be_n),
    .is_branch(is_branch)
);

// �� �� �� ��
regfile Registers(
    .clk(clk_10M),
    .raddr1(raddr1),
    .rdata1(rdata1),
    .raddr2(raddr2),
    .rdata2(rdata2),
    .we(reg_we),
    .waddr(waddr),
    .wdata(memoryaccess_data_out)
);

// ִ �� �� Ԫ
ExecuteUnit ExecuteUnit(
//    .clk(cpu_clk),
//    .rst(rst),
    .alu_op(exeopcode),
    .alu_src1(operandA),
    .alu_src2(operandB),
    .alu_result(ALUresult)
);

// �� �� �� Ԫ
MemoryAccess MemoryAccess(
    .wr_in(wr),
    .addr_in(ALUresult),
    .type(type),
    .data_in(decode_wdata_out),
    .data_out(memoryaccess_data_out),
    .wr_out(memoryaccess_wr_out),
    .addr_out(memoryaccess_addr_out),
    .cpu_type(cpu_type),
    .wdata_out(memoryaccess_wdata_out),
    .rdata_in(data_out)
);

//---------------------------    cpu����״̬��         ----------------------
reg [2:0] state;
parameter BOOT = 3'b000, IF = 3'b001, IF_2 = 3'b010, DEC = 3'b011,EXE = 3'b100, MEM = 3'b101, WB = 3'b110;

always@(posedge clk_10M or posedge reset_btn) begin
    if(reset_btn)begin
        state <= BOOT;
        inst <= 32'b0;
        {wen, oen} <= 2'b11;
        cpu_address <= 32'b0;   
        sram_be_n <= 4'b0;
        pc_next <= 0;
        reg_we <= 0;
    end
    else begin
        case (state)
            BOOT: begin
                cpu_address <= pc;
                oen <= 0;
                state <= sram_done ? DEC : IF_2;
            end
            IF: begin
//                pc_next <= 0;
//                if(inst == 32'b0) pc_next <= 0;
//                else pc_next <= 1;
                pc_next <= 1;
                if(is_branch & NPCsel) cpu_address <= NPCaddr;
                else cpu_address <= pc + 32'h4;
                reg_we <= 0;
//                cpu_address <= pc;
                sram_be_n <= 4'b0;
                oen <= 1'b0;
                state <= sram_done ? DEC : IF_2;
            end
            IF_2: begin
//                cpu_address <= pc;
                oen <= 1'b1;
                state <= sram_done ? DEC : IF_2;
                if(sram_done) inst <= data_out;
                //inst <= data_out;
                else inst <= inst;
                pc_next <= 0;
            end
            DEC: begin
//                cpu_address <= pc;
                state <= EXE;
            end
            EXE: begin
                if(is_branch) begin
                    state <= IF;
                    //pc_next <= 1;
                end
                else state <= (wr == 2'b00) ? WB : MEM;
                //state <= (wr == 2'b00) ? WB : MEM;
            end
            MEM: begin
                if(wr[1]) begin
                    oen <= 1'b0;
                    sram_be_n <= 4'b0;
                    cpu_address <= ALUresult;
                    state <= (sram_done) ? WB : MEM;
                    if(sram_done) oen <= 1;
                end
                else if(wr[0]) begin
                    // д��ʱ����Ҫ��ֵ�ֽ�ʹ��
                    wen <= 1'b0;
                    sram_be_n <= ram_be_n;
                    cpu_address <= ALUresult;
                    data_in <= memoryaccess_wdata_out;
                    state <= (sram_done) ? IF : MEM;
                    if(sram_done) begin
                        wen <= 1;
                        //pc_next <= 1;
                    end
                end
                else begin
                    // ���û�зô��Ǿ�ֱ��д��
                    state <= WB;
                end
            end
            WB: begin
                //{oen, wen} <= 2'b11;
                reg_we <= 1'b1;
                state <= IF;
                //pc_next <= 1;
            end
        endcase 
    end
end

// ��ʹ���ڴ桢����ʱ��������ʹ���ź�
//assign base_ram_ce_n = 1'b1;
//assign base_ram_oe_n = 1'b1;
//assign base_ram_we_n = 1'b1;

//assign ext_ram_ce_n = 1'b1;
//assign ext_ram_oe_n = 1'b1;
//assign ext_ram_we_n = 1'b1;

//---------------------- sram������ ---------------------
reg base_ram_oen, base_ram_wen;
reg[31:0] base_ram_data_in;
wire[31:0] base_ram_data_out;
wire base_ram_done;

sram_ctrl base_ram_ctrl(
    .clk(clk_10M),
    .rst(reset_btn),
    .oen(base_ram_oen),
    .wen(base_ram_wen),
    .data_in(base_ram_data_in),
    .data_out(base_ram_data_out),
    .done(base_ram_done),
    
    .ram_data_wire(base_ram_data),
    .ram_ce_n(base_ram_ce_n),       //RAMƬѡ������Ч
    .ram_oe_n(base_ram_oe_n),       //RAM��ʹ�ܣ�����Ч
    .ram_we_n(base_ram_we_n)        //RAMдʹ�ܣ�����Ч
);

reg ext_ram_oen,ext_ram_wen;
reg[31:0] ext_ram_data_in;
wire[31:0] ext_ram_data_out;
wire ext_ram_done;

sram_ctrl ext_ram_ctrl(
    .clk(clk_10M),
    .rst(reset_btn),
    .oen(ext_ram_oen),
    .wen(ext_ram_wen),
    .data_in(ext_ram_data_in),
    .data_out(ext_ram_data_out),
    .done(ext_ram_done),
    
    .ram_data_wire(ext_ram_data),
    .ram_ce_n(ext_ram_ce_n),       //RAMƬѡ������Ч
    .ram_oe_n(ext_ram_oe_n),       //RAM��ʹ�ܣ�����Ч
    .ram_we_n(ext_ram_we_n)        //RAMдʹ�ܣ�����Ч
);

//-----------------------��ַӳ��-----------------------
wire[1:0] sram_type;
wire[19:0] sram_address; //sram�е������ַ
parameter BASERAM = 2'b00, EXTRAM = 2'b01, UART = 2'b10;
address_mapping addr_map(
    .cpu_address(cpu_address), //cpu���ȡ���߼���ַ
    .type(sram_type),
    .sram_address(sram_address)
);


//-----------------------��������------------------------
wire[31:0] final_data;
load_data_from_sram ldfs(
    .ram_be_n(sram_be_n),
    .type(sram_type),
    .base_data(base_ram_data_out),
    .ext_data(ext_ram_data_out),
    .final_data(final_data)
);
    
//-----------------------״̬��--------------------------
reg[1:0] sram_state;
parameter IDLE = 2'b00, READ = 2'b01, WRITE = 2'b10, DONE = 2'b11;
reg[19:0] base_ram_addr_reg;
reg[3:0] base_ram_be_n_reg;
assign base_ram_addr = base_ram_addr_reg;
assign base_ram_be_n = base_ram_be_n_reg;

reg[19:0] ext_ram_addr_reg;
reg[3:0] ext_ram_be_n_reg;
assign ext_ram_addr = ext_ram_addr_reg;
assign ext_ram_be_n = ext_ram_be_n_reg;

assign sram_done = (sram_state == DONE);

always @(posedge clk_10M or posedge reset_btn) begin
    if(reset_btn) begin
        base_ram_addr_reg <= 20'b0; //BaseRAM��ַ
        base_ram_be_n_reg <= 4'b0;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
        base_ram_oen <= 1;
        base_ram_wen <= 1;
        base_ram_data_in <= 32'b0;
    
        ext_ram_addr_reg <= 20'b0;  //ExtRAM��ַ
        ext_ram_be_n_reg <= 4'b0;
        ext_ram_oen <= 1;
        ext_ram_wen <= 1;
        ext_ram_data_in <= 32'b0;
        sram_state <= IDLE;
    end
    else begin
        case(sram_state)
            IDLE: begin
                if(oen & wen) sram_state <= IDLE;
                else if(~oen) begin 
                    case(sram_type)
                        BASERAM: begin
                            base_ram_addr_reg <= sram_address;
                            base_ram_be_n_reg <= 4'b0;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
                            base_ram_oen <= 0;
                            base_ram_wen <= 1;
                            base_ram_data_in <= 32'b0;
                            sram_state <= READ;
                        end
                        EXTRAM: begin
                            ext_ram_addr_reg <= sram_address;
                            ext_ram_be_n_reg <= 4'b0;
                            ext_ram_oen <= 0;
                            ext_ram_wen <= 1;
                            ext_ram_data_in <= 32'b0;
                            sram_state <= READ;
                        end
                    endcase
                end
                else begin
                    case(sram_type)
                        BASERAM: begin
                            base_ram_addr_reg <= sram_address;
                            base_ram_be_n_reg <= sram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
                            base_ram_oen <= 1;
                            base_ram_wen <= 0;
                            base_ram_data_in <= data_in;
                            sram_state <= WRITE;
                        end
                        EXTRAM: begin
                            ext_ram_addr_reg <= sram_address;
                            ext_ram_be_n_reg <= sram_be_n;  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
                            ext_ram_oen <= 1;
                            ext_ram_wen <= 0;
                            ext_ram_data_in <= data_in;
                            sram_state <= WRITE;
                        end
                    endcase
                end
            end
            READ: begin
                case(sram_type)
                    BASERAM: begin
                        sram_state <= base_ram_done ? DONE : READ;
                        if(base_ram_done) begin
                            base_ram_oen <= 1;
                            data_out <= final_data;
                        end
                    end
                    EXTRAM: begin
                        sram_state <= ext_ram_done ? DONE : READ;
                        if(ext_ram_done) begin
                            ext_ram_oen <= 1;
                            data_out <= final_data;
                        end
                    end
                endcase
            end
            WRITE: begin
                case(sram_type)
                    BASERAM: begin
                        sram_state <= base_ram_done ? DONE : WRITE;
                        if(base_ram_done) begin
                            base_ram_be_n_reg <= 4'b0;
                            base_ram_wen <= 1;
                        end
                    end
                    EXTRAM: begin
                        sram_state <= ext_ram_done ? DONE : WRITE;
                        if(ext_ram_done) begin
                            ext_ram_be_n_reg <= 4'b0;
                            ext_ram_wen <= 1;
                        end
                    end
                endcase
            end
            DONE: sram_state <= IDLE;
        endcase
    end
end

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
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
        led_bits <= 16'h1;
    end
    else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
assign number = ext_uart_buffer;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //��������ext_uart_buffer���ͳ�ȥ
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

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
