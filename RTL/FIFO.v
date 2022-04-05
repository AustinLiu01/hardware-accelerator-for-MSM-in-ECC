`define SINGLE_POINT_WIDTH 30
`define FIFO_DEPTH 15
`define INDEX_WIDTH 4

module FIFO #(parameter DATA_WIDTH=(`SINGLE_POINT_WIDTH)*3,FIFO_DEPTH=`FIFO_DEPTH,INDEX_WIDTH=`INDEX_WIDTH)
(
    input clk,
    input rst,
    input  [2*DATA_WIDTH-1:0] pin,
    input  [INDEX_WIDTH-1:0] index_in,
    output [INDEX_WIDTH-1:0] index_out,
    output [2*DATA_WIDTH-1:0] pout,
    input we,//write enable
    input re,//read enable
    output full,//FIFO is full
    output empty//FIFO is empty
);

localparam DEPTH_WIDTH = $clog2(FIFO_DEPTH);
reg [DEPTH_WIDTH-1:0] wp;//write pointer
reg [DEPTH_WIDTH-1:0] rp;//read pointer
reg [DEPTH_WIDTH-1:0] cnt;//count for full signal & empty signal
reg [2*DATA_WIDTH+INDEX_WIDTH-1:0] RAM [0:FIFO_DEPTH-1];//space to store the data&index,default the width of index is 4 bits 
reg [2*DATA_WIDTH+INDEX_WIDTH-1:0] dout;
wire[2*DATA_WIDTH+INDEX_WIDTH-1:0] din;
assign din = {index_in,pin};
assign pout = dout[2*DATA_WIDTH-1:0];
assign index_out = dout[2*DATA_WIDTH+INDEX_WIDTH-1:2*DATA_WIDTH];
//full or empty
assign full =(cnt==FIFO_DEPTH);
assign empty=(cnt==0);
//count
always @(posedge clk or posedge rst)
begin
    if(rst)
        cnt<=0;
    else if(!empty & !full & re & we)
        cnt<=cnt;
    else if(!full & we)
        cnt<=cnt+1;
    else if(!empty & re)
        cnt<=cnt-1;
    else 
        cnt<=cnt;
end

//read pointer
always @(posedge clk or posedge rst)
begin
    if(rst)
        rp<=0;
    else if(!empty & re)
        rp<=(rp==(FIFO_DEPTH-1)) ? 0 : rp+1;
    else 
        rp<=rp;
end
//write pointer
always @(posedge clk or posedge rst)
begin
    if(rst)
        wp<=0;
    else if(!full & we)
        wp<=(wp==(FIFO_DEPTH-1)) ? 0 :wp+1;
    else
        wp<=wp;
end
//read operation
always @(posedge clk or posedge rst)
begin
    if(rst)
        dout<=0;//note we don't have bucket numbered 0
    else if(!empty && re)
        dout<=RAM[rp];
    else
        dout<=dout;
end

//write operation
always @(posedge clk or posedge rst)
    begin
        if(rst)
            RAM[wp]<=0;
        else if(!full && we)
            RAM[wp]<=din;
        else
            RAM[wp]<=RAM[wp];
    end

endmodule