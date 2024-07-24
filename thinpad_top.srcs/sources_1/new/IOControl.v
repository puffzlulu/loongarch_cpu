`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/21 12:26:11
// Design Name: 
// Module Name: IOControl
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


module IOControl(
    input wire clk,
    input wire rst,
    output reg inst_en, //内存已准备好指令
    input wire inst_ren, //取指模块想从内存获取数据
    input wire [31:0] inst_addr, 
    output reg [31:0] inst_rdata,
    output wire stall,

    output reg data_en,//内存已准备好数据
    input wire data_wen,//LSU模块是读是写
    input wire [3:0] data_be_n,
    input wire data_ren,//LSU模块给出信号有效
    input wire [31:0] data_addr,
    input wire [31:0] data_wdata,
    output reg [31:0] data_rdata,
    
    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire [3:0] base_ram_be_n,
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效
    
    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire [3:0] ext_ram_be_n,
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效
    
    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端
    output reg [7:0] ext_uart_buffer,
    output reg ext_uart_avai
);

wire [31:0] addr;

//仲裁
assign addr = inst_ren ? inst_addr : data_addr;
//always @(*) begin
//    if(rst) begin
//        addr <= 32'b0;
//    end
//    else begin
//        if(inst_ren) addr <= inst_addr;
//        else if(data_ren) addr <= data_addr;
//    end
//end

wire [19:0] sram_address;
wire [1:0] type; //2'b00: extRam 2'b01: baseRam 2'b10: uartData 2'b11: uartFlag
parameter BASERAM = 1, EXTRAM = 0;
address_mapping addr_map(
    .cpu_address(addr),
    .type(type),
    .sram_address(sram_address)
);

reg [31:0] uart_rdata;
reg uart_en;
wire uart_done;
reg [31:0] sram_rdata;

always @(*) begin
    case(type[1])
        1'b1: begin
            if(uart_done) begin
                data_rdata = uart_rdata;
                data_en = 1;
            end
            else data_en = 0;
        end
        1'b0: begin
            if(sram_done) begin
                if(inst_ren) begin
                    inst_rdata = sram_rdata;
                    inst_en = 1;
                end
                else begin
                    data_rdata = sram_rdata;
                    data_en = 1;
                end
            end
            else begin
                inst_en = 0;
                data_en = 0;
            end
        end
    endcase
end

reg base_ram_oen, base_ram_wen;
reg[31:0] base_ram_data_in;
wire[31:0] base_ram_data_out;
wire base_ram_done;

reg ext_ram_oen,ext_ram_wen;
reg[31:0] ext_ram_data_in;
wire[31:0] ext_ram_data_out;
wire ext_ram_done;

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
//reg  [7:0] ext_uart_buffer;
reg  [7:0] ext_uart_tx;
wire ext_uart_ready, ext_uart_busy, TxD_done, ext_uart_rbusy, ext_uart_clear;
reg ext_uart_start;

async_receiver #(.ClkFrequency(10000000),.Baud(9600)) //接收模块，9600无检验位
ext_uart_r(
    .clk(clk),                       //外部时钟信号
    .RxD(rxd),                        //外部串行信号输入
    .RxD_data_ready(ext_uart_ready),  //数据接收到标志
    .busy(ext_uart_rbusy),
    .RxD_clear(ext_uart_clear),       //清除接收标志
    .RxD_data(ext_uart_rx)            //接收到的一字节数据
);

assign ext_uart_clear = ext_uart_ready;
always @(posedge clk) begin //接收到缓冲区ext_uart_buffer
    if(rst) begin
        ext_uart_buffer <= 8'b0;
        ext_uart_avai <= 0;
//          ext_uart_buffer <= 8'b01010100;
//          ext_uart_avai <= 1;
//        ext_uart_clear <= 1;
    end
//    else begin
//        if(ext_uart_ready & (uart_state == READ)) ext_uart_buffer <= ext_uart_rx;
//    end
    else if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
        //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
//        ext_uart_clear <= 1;
    end 
//    else if((type == 2'b10) && ~data_wen && ext_uart_avai)begin 
    else if((type == 2'b10) && (uart_state == READ))begin 
        ext_uart_avai <= 1'b0;
//        ext_uart_clear <= 0;
    end
end

always @(posedge clk) begin 
    if(!ext_uart_busy && (type == 2'b10) && (uart_state == WRITE))begin 
        ext_uart_tx <= data_wdata[7:0];
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(10000000),.Baud(9600)) //发送模块，9600无检验位
ext_uart_t(
    .clk(clk),                      //外部时钟信号
    .TxD(txd),                      //串行信号输出
    .TxD_busy(ext_uart_busy),       //发送器忙状态指示
    .TxD_start(ext_uart_start),    //开始发送信号
    .TxD_data(ext_uart_tx),        //待发送的数据
    .TxD_done(TxD_done)
);

reg [2:0] uart_state;
parameter IDLE = 3'b000, READ = 3'b001, WRITE = 3'b010, DONE = 3'b011, READ2 = 3'b100;
assign uart_done = (uart_state == DONE);
wire uart_busy;
assign uart_busy = ~(uart_state == IDLE);

always @(posedge clk) begin
    if(rst) begin
        uart_state <= IDLE;
        uart_rdata <= 32'b0;
        uart_en <= 0;
    end
    else begin
        case(uart_state) 
            IDLE: begin
                uart_en <= 0;
                uart_rdata <= 32'b0;
                if(type[1] & data_wen & data_ren) uart_state <= WRITE;
                else if(type[1] & ~data_wen & data_ren) uart_state <= READ;
                else uart_state <= uart_state;
            end
            READ: begin
                if(type[0]) begin //串口标志
                    uart_en <= 1;
                    uart_rdata <= {30'b0,ext_uart_avai,~ext_uart_busy};
                    uart_state <= DONE;
                end
                else begin
//                    uart_state <= ext_uart_ready ? READ2 : READ;
//                    if(ext_uart_ready) begin
                        uart_en <= 1;
                        uart_rdata <= {24'b0,ext_uart_buffer};
                        uart_state <= DONE;
//                    end
                end
            end
//            READ2: begin
//                uart_en <= 1;
//                uart_rdata <= ext_uart_buffer;
//                uart_state <= DONE;
//            end
            WRITE: begin
                uart_state <= TxD_done ? DONE : WRITE;
            end
            DONE: begin
//                if(inst_en) uart_state <= IDLE;
//                else uart_state <= uart_state;
                uart_state <= IDLE;
            end
        endcase
    end
end


sram_ctrl base_ram_ctrl(
    .clk(clk),
    .rst(rst),
    .oen(base_ram_oen),
    .wen(base_ram_wen),
    .data_in(base_ram_data_in),
    .data_out(base_ram_data_out),
    .done(base_ram_done),
    .busy(base_ram_busy),
    
    .ram_data_wire(base_ram_data),
    .ram_ce_n(base_ram_ce_n),       //RAM片选，低有效
    .ram_oe_n(base_ram_oe_n),       //RAM读使能，低有效
    .ram_we_n(base_ram_we_n)        //RAM写使能，低有效
);

sram_ctrl ext_ram_ctrl(
    .clk(clk),
    .rst(rst),
    .oen(ext_ram_oen),
    .wen(ext_ram_wen),
    .data_in(ext_ram_data_in),
    .data_out(ext_ram_data_out),
    .done(ext_ram_done),
    .busy(ext_ram_busy),
    
    .ram_data_wire(ext_ram_data),
    .ram_ce_n(ext_ram_ce_n),       //RAM片选，低有效
    .ram_oe_n(ext_ram_oe_n),       //RAM读使能，低有效
    .ram_we_n(ext_ram_we_n)        //RAM写使能，低有效
);

reg[1:0] sram_state;
reg[19:0] base_ram_addr_reg;
reg[3:0] base_ram_be_n_reg;
assign base_ram_addr = base_ram_addr_reg;
assign base_ram_be_n = base_ram_be_n_reg;

reg[19:0] ext_ram_addr_reg;
reg[3:0] ext_ram_be_n_reg;
assign ext_ram_addr = ext_ram_addr_reg;
assign ext_ram_be_n = ext_ram_be_n_reg;

wire sram_busy;
assign sram_done = (sram_state == DONE);
assign sram_busy = ~((sram_state == IDLE) | (sram_state == DONE));
assign stall = sram_busy | uart_busy | ext_uart_busy | ext_uart_rbusy;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        base_ram_addr_reg <= 20'b0; //BaseRAM地址
        base_ram_be_n_reg <= 4'b0;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        base_ram_oen <= 1;
        base_ram_wen <= 1;
        base_ram_data_in <= 32'b0;
    
        ext_ram_addr_reg <= 20'b0;  //ExtRAM地址
        ext_ram_be_n_reg <= 4'b0;
        ext_ram_oen <= 1;
        ext_ram_wen <= 1;
        ext_ram_data_in <= 32'b0;
        
        sram_rdata <= 32'b0;
        
        sram_state <= IDLE;
    end
    else begin
        case(sram_state)
            IDLE: begin
                sram_rdata <= 32'b0;
                if((~inst_ren & ~data_ren) | type[1]) sram_state <= IDLE;
                else if(inst_ren | ~data_wen) begin 
                    case(type[0])
                        BASERAM: begin
                            base_ram_addr_reg <= sram_address;
                            base_ram_be_n_reg <= 4'b0;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
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
                    case(type[0])
                        BASERAM: begin
                            base_ram_addr_reg <= sram_address;
                            base_ram_be_n_reg <= data_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
                            base_ram_oen <= 1;
                            base_ram_wen <= 0;
                            base_ram_data_in <= data_wdata;
                            sram_state <= WRITE;
                        end
                        EXTRAM: begin
                            ext_ram_addr_reg <= sram_address;
                            ext_ram_be_n_reg <= data_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
                            ext_ram_oen <= 1;
                            ext_ram_wen <= 0;
                            ext_ram_data_in <= data_wdata;
                            sram_state <= WRITE;
                        end
                    endcase
                end
            end
            READ: begin
                case(type[0])
                    BASERAM: begin
                        sram_state <= base_ram_done ? DONE : READ;
                        if(base_ram_done) begin
                            base_ram_oen <= 1;
                            sram_rdata <= base_ram_data_out;
                        end
                    end
                    EXTRAM: begin
                        sram_state <= ext_ram_done ? DONE : READ;
                        if(ext_ram_done) begin
                            ext_ram_oen <= 1;
                            sram_rdata <= ext_ram_data_out;
                        end
                    end
                endcase
            end
            WRITE: begin
                case(type[0])
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
            DONE: begin
                sram_state <= IDLE;
            end
        endcase
    end
end

endmodule
