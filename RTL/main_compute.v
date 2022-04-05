`define SINGLE_POINT_WIDTH 32//means the single coordinate of the projective coordinates,
                             //also the scalar length
`define FIFO_DEPTH 15
`define INDEX_WIDTH 4
//Read two scalar-points pairs each cycle pipelined,
//and then distribute them to corresponding bucket or FIFO
module main_compute #(parameter POINT_WIDTH = 3*(`SINGLE_POINT_WIDTH),FIFO_DEPTH=`FIFO_DEPTH,INDEX_WIDTH=`INDEX_WIDTH) 
(
    input                     clk,
    input                     rst,
    //-----------------control signal-----------------
    input                     start,        //start read the data
    input                     write_over,   //data write over
    output                    done,         //one main compute period is done,
                                            //could start next period,result has been output to next stage
    output                    stall,        //do not write, FIFOs are full,need to wait
    input  [INDEX_WIDTH-1:0] scalar_label_1,//default 4 bit
    input  [INDEX_WIDTH-1:0] scalar_label_2,//default 4 bit
    input  [POINT_WIDTH-1:0] points_label_1,
    input  [POINT_WIDTH-1:0] points_label_2,
    //for debug
    //input re_fifo_u1,
    //input re_fifo_u2,
    //--end---
    output [POINT_WIDTH-1:0] points_result,
    output [INDEX_WIDTH-1:0] result_label   //signal to symbol the number of bucket 
);
//TODO:need a Mux in the input direction&& a Mux in the output direction 
reg  [POINT_WIDTH-1:0]    buckets      [(1<<INDEX_WIDTH)-2:0];//15 buckets totally,0-14 maps index from 1 to 15
reg  [0:0]                bucket_flags [(1<<INDEX_WIDTH)-2:0];//to flag if the data in the corresponding bucket is valid
//points pair 1 for writing fifo_1
reg  [POINT_WIDTH-1:0]    points_pair1_X;
reg  [POINT_WIDTH-1:0]    points_pair1_Y;
reg  [INDEX_WIDTH-1:0]    points_pair1_index;

wire [2*POINT_WIDTH-1:0]  pin_fifo_u1;
wire [2*POINT_WIDTH-1:0]  pout_fifo_u1;
wire [INDEX_WIDTH-1:  0]  index_in_fifo_u1;
wire [INDEX_WIDTH-1:  0]  index_out_fifo_u1;

wire                      full_fifo_u1;
wire                      empty_fifo_u1;
reg                       we_fifo_u1;
reg                       re_fifo_u1;
//points pair 2 for writing fifo_2
reg  [POINT_WIDTH-1:0]    points_pair2_X;
reg  [POINT_WIDTH-1:0]    points_pair2_Y;
reg  [INDEX_WIDTH-1:0]    points_pair2_index;

wire [2*POINT_WIDTH-1:0]  pin_fifo_u2;
wire [2*POINT_WIDTH-1:0]  pout_fifo_u2;
wire [INDEX_WIDTH-1:  0]  index_in_fifo_u2;
wire [INDEX_WIDTH-1:  0]  index_out_fifo_u2;

wire                      full_fifo_u2;
wire                      empty_fifo_u2;
reg                       we_fifo_u2;
reg                       re_fifo_u2;
//points pair for fifo_result_tmp
reg  [POINT_WIDTH-1:0]    points_pair_result_tmp_X;
reg  [POINT_WIDTH-1:0]    points_pair_result_tmp_Y;
reg  [INDEX_WIDTH-1:0]    points_pair_result_tmp_index;

wire [2*POINT_WIDTH-1:0]  pin_fifo_u2;
wire [2*POINT_WIDTH-1:0]  pout_fifo_u2;
wire [INDEX_WIDTH-1:  0]  index_in_fifo_u2;
wire [INDEX_WIDTH-1:  0]  index_out_fifo_u2;

wire                      full_fifo_u2;
wire                      empty_fifo_u2;
reg                       we_fifo_u2;
reg                       re_fifo_u2;



assign  pin_fifo_u1 = {points_pair1_X,points_pair1_Y};
assign  pin_fifo_u2 = {points_pair2_X,points_pair2_Y};
assign index_in_fifo_u1 = points_pair1_index;
assign index_in_fifo_u2 = points_pair2_index;
//-------------------instance 3 FIFOs-------------------
FIFO #(.DATA_WIDTH(POINT_WIDTH),.FIFO_DEPTH(FIFO_DEPTH),.INDEX_WIDTH(INDEX_WIDTH))//this is the main fifo
    fifo_u1
(
    .clk(clk),
    .rst(rst),
    .pin(pin_fifo_u1),
    .index_in(index_in_fifo_u1),
    .index_out(index_out_fifo_u1),
    .pout(pout_fifo_u1),
    .we(we_fifo_u1),//write enable
    .re(re_fifo_u1),//read enable
    .full(full_fifo_u1),//FIFO is full
    .empty(empty_fifo_u1)//FIFO is empty
);
FIFO #(.DATA_WIDTH(POINT_WIDTH),.FIFO_DEPTH(FIFO_DEPTH),.INDEX_WIDTH(INDEX_WIDTH))
    fifo_u2
(
    .clk(clk),
    .rst(rst),
    .pin(pin_fifo_u2),
    .index_in(index_in_fifo_u2),
    .index_out(index_out_fifo_u2),
    .pout(pout_fifo_u2),
    .we(we_fifo_u2),//write enable
    .re(re_fifo_u2),//read enable
    .full(full_fifo_u2),//FIFO is full
    .empty(empty_fifo_u2)//FIFO is empty
);

FIFO #(.DATA_WIDTH(POINT_WIDTH),.FIFO_DEPTH(FIFO_DEPTH),.INDEX_WIDTH(INDEX_WIDTH))
    fifo_u_result_tmp
(
    .clk(clk),
    .rst(rst),
    .pin(),
    .index_in(),
    .index_out(),
    .pout(),
    .we(),//write enable
    .re(),//read enable
    .full(),//FIFO is full
    .empty()//FIFO is empty
);

//--------------------------initialize the buckets----------------------------
genvar i_loop;
generate
for(i_loop=0;i_loop<15;i_loop=i_loop+1)begin
        always @(posedge clk or posedge rst)
        begin
            if(rst)begin
                bucket_flags[i_loop]<=0;
                buckets[i_loop]<=0;
            end
        end
    end
endgenerate
//---------------load points from the input to the bucket or FIFO--------------
always @(posedge clk or posedge rst)
begin
    if(rst)begin
        points_pair1_X<=0;
        points_pair1_Y<=0;
        points_pair1_index<=0;
        points_pair2_X<=0;
        points_pair2_Y<=0;
        points_pair2_index<=0;
        we_fifo_u1<=0;
        we_fifo_u2<=0;
    end
    else if(scalar_label_1!=scalar_label_2)begin
        //There are three types of cases
        //both invalid 
        //both valid
        //only scalar_label_1 is valid or scalar_label_2  is valid
        
        //if invalid,put the input data into the bucket，keep itself if valid,fresh its value if invalid
        buckets[scalar_label_1] <= bucket_flags[scalar_label_1] ? buckets[scalar_label_1] : points_label_1;
        buckets[scalar_label_2] <= bucket_flags[scalar_label_2] ? buckets[scalar_label_2] : points_label_2;
        //if valid,put the input data & bucket data to the point pair reg, at the most two pairs simultaneously
        points_pair1_X <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            points_label_1: ((bucket_flags[scalar_label_1]) ?
                            points_label_1: ((bucket_flags[scalar_label_2]) ?
                            points_label_2: 0));//points_pair1_X;
        points_pair1_Y <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            buckets[scalar_label_1]: ((bucket_flags[scalar_label_1]) ?
                            buckets[scalar_label_1]: ((bucket_flags[scalar_label_2]) ?
                            buckets[scalar_label_2]: 0));//points_pair1_Y;
        points_pair2_X <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            points_label_2: 0;//points_pair2_X;
        points_pair2_Y <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            buckets[scalar_label_2]: 0;//points_pair2_Y
        //put the index,zero means the points_pair data is valid
        points_pair1_index <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            scalar_label_1: ((bucket_flags[scalar_label_1]) ?
                            scalar_label_1: ((bucket_flags[scalar_label_2]) ?
                            scalar_label_2: 0));
        points_pair2_index <= (bucket_flags[scalar_label_1])&&(bucket_flags[scalar_label_2]) ? 
                            scalar_label_2: 0;
        we_fifo_u1 <= bucket_flags[scalar_label_1]||bucket_flags[scalar_label_2];
        we_fifo_u2 <= bucket_flags[scalar_label_1]&&bucket_flags[scalar_label_2];
        //inverse the flag
        bucket_flags[scalar_label_1]<= ~bucket_flags[scalar_label_1];
        bucket_flags[scalar_label_2]<= ~bucket_flags[scalar_label_2];
    end
    else begin//scalar_label_1=scalar_label_2,dispatch the points pair to the FIFO_U1
        points_pair1_X <= points_label_1;
        points_pair1_Y <= points_label_2;
        points_pair1_index<= scalar_label_1;
        bucket_flags[scalar_label_1]<= bucket_flags[scalar_label_1];
        we_fifo_u1<=1;
        we_fifo_u2<=0;
    end
end



endmodule