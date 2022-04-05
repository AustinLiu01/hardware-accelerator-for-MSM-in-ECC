//compute P + Q = R in ECC domain
//P,Q,R are all in projective coordinates and in montgomery representations
//fully pipeline latency = 4*(INTMUL_DELAY+2*L_SIZE+1)
//only support prime which meets q = qH*(2*RING_LENGTH)+1
`define SINGLE_POINT_WIDTH 30
`define RING_LENGTH 2048
//L = ceil(DATA_WIDTH/log2(2*RING_LENGTH))
module PADD #(parameter DATA_WIDTH=`SINGLE_POINT_WIDTH, RING_LENGTH=`RING_LENGTH) 
    (
    input  clk,
    input  rst,
    input  [DATA_WIDTH-1:0] X_P,
    input  [DATA_WIDTH-1:0] Y_P,
    input  [DATA_WIDTH-1:0] Z_P,
    input  [DATA_WIDTH-1:0] X_Q,
    input  [DATA_WIDTH-1:0] Y_Q,
    input  [DATA_WIDTH-1:0] Z_Q,
    input  [DATA_WIDTH-1:0] mod,
    output [DATA_WIDTH-1:0] X_R,
    output [DATA_WIDTH-1:0] Y_R,
    output [DATA_WIDTH-1:0] Z_R
);
    localparam RING_DEPTH = ($clog2(RING_LENGTH));
    localparam W_SIZE = ((RING_DEPTH)+1);//OMEGA=log2(2n)
    localparam L_SIZE = ((DATA_WIDTH > W_SIZE) ? ((DATA_WIDTH > (W_SIZE * 2)) ? ((DATA_WIDTH > (W_SIZE * 3)) ? ((DATA_WIDTH > (W_SIZE * 4)) ? ((DATA_WIDTH > (W_SIZE * 5)) ? ((DATA_WIDTH > (W_SIZE * 6)) ? ((DATA_WIDTH > (W_SIZE * 7)) ? 8 : 7) : 6) : 5) : 4) : 3) : 2) : 1);
    localparam INTMUL_DELAY = 3;
    reg [DATA_WIDTH-1:0] X_P_reg;
    reg [DATA_WIDTH-1:0] Y_P_reg;
    reg [DATA_WIDTH-1:0] Z_P_reg;
    reg [DATA_WIDTH-1:0] X_Q_reg;
    reg [DATA_WIDTH-1:0] Y_Q_reg;
    reg [DATA_WIDTH-1:0] Z_Q_reg;
    reg [DATA_WIDTH-1:0] mod_reg;
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            X_P_reg<=0;
            Y_P_reg<=0;
            Z_P_reg<=0;
            X_Q_reg<=0;
            Y_Q_reg<=0;
            Z_Q_reg<=0;
            mod_reg<=0;
        end
        else begin
            X_P_reg<=X_P;
            Y_P_reg<=Y_P;
            Z_P_reg<=Z_P;
            X_Q_reg<=X_Q;
            Y_Q_reg<=Y_Q;
            Z_Q_reg<=Z_Q;
            mod_reg<=mod;
        end
    end

    wire [DATA_WIDTH-1:0] U1;
    wire [DATA_WIDTH-1:0] U2;
    wire [DATA_WIDTH-1:0] U2_delay24;
    wire [DATA_WIDTH-1:0] V1;
    wire [DATA_WIDTH-1:0] V2;
    wire [DATA_WIDTH-1:0] V2_delay23;
    wire [DATA_WIDTH-1:0] W;
    wire [DATA_WIDTH-1:0] W_delay23;
    wire [DATA_WIDTH-1:0] W_delay24;
    wire [DATA_WIDTH-1:0] U;
    wire [DATA_WIDTH-1:0] U_delay24;
    wire [DATA_WIDTH-1:0] V;
    wire [DATA_WIDTH-1:0] V_delay23;
    wire [DATA_WIDTH-1:0] V_delay24;
    wire [DATA_WIDTH-1:0] UU;
    wire [DATA_WIDTH-1:0] VV;
    wire [DATA_WIDTH-1:0] A1;
    wire [DATA_WIDTH-1:0] A2;
    wire [DATA_WIDTH-1:0] A3;
    wire [DATA_WIDTH-1:0] A_temp_1;
    wire [DATA_WIDTH-1:0] A_temp_2;
    wire [DATA_WIDTH-1:0] A;
    wire [DATA_WIDTH-1:0] Y_R_temp;
    wire [DATA_WIDTH-1:0] Y_R_1;
    wire [DATA_WIDTH-1:0] Y_R_2;

// modulu mul period 1   
ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP1_1
(.clk(clk),.reset(rst),.A(Y_Q_reg),.B(Z_P_reg),.q(mod_reg),.C(U1));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP1_2
(.clk(clk),.reset(rst),.A(Y_P_reg),.B(Z_Q_reg),.q(mod_reg),.C(U2));   

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP1_3
(.clk(clk),.reset(rst),.A(X_Q_reg),.B(Z_P_reg),.q(mod_reg),.C(V1));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP1_4
(.clk(clk),.reset(rst),.A(Z_Q_reg),.B(X_P_reg),.q(mod_reg),.C(V2));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP1_5
(.clk(clk),.reset(rst),.A(Z_Q_reg),.B(Z_P_reg),.q(mod_reg),.C(W));
//maybe overflow
assign U = (U1<U2) ? (U1-U2+mod) : (U1-U2);
assign V = (V1<V2) ? (V1-V2+mod) : (V1-V2);

ShiftReg #(.SHIFT(2*(INTMUL_DELAY+2*L_SIZE+1)),.DATA(DATA_WIDTH)) Us_U2_24(clk,reset,U2,U2_delay24);
ShiftReg #(.SHIFT(2*(INTMUL_DELAY+2*L_SIZE+1)),.DATA(DATA_WIDTH)) Us_W_24 (clk,reset,W,W_delay24);
ShiftReg #(.SHIFT(2*(INTMUL_DELAY+2*L_SIZE+1)),.DATA(DATA_WIDTH)) Us_U_24 (clk,reset,U,U_delay24);
ShiftReg #(.SHIFT(2*(INTMUL_DELAY+2*L_SIZE+1)),.DATA(DATA_WIDTH)) Us_V_24 (clk,reset,V,V_delay24);
ShiftReg #(.SHIFT(INTMUL_DELAY+2*L_SIZE+1),.DATA(DATA_WIDTH)) Us_V2_23 (clk,reset,V2,V2_delay23);
ShiftReg #(.SHIFT(INTMUL_DELAY+2*L_SIZE+1),.DATA(DATA_WIDTH)) Us_V_23 (clk,reset,V,V_delay23);
ShiftReg #(.SHIFT(INTMUL_DELAY+2*L_SIZE+1),.DATA(DATA_WIDTH)) Us_W_23 (clk,reset,W,W_delay23);
// modulu mul period 2
ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP2_1
(.clk(clk),.reset(rst),.A(U),.B(U),.q(mod),.C(UU));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP2_2
(.clk(clk),.reset(rst),.A(V),.B(V),.q(mod),.C(VV));  

// modulu mul period 3
ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP3_1
(.clk(clk),.reset(rst),.A(UU),.B(W_delay23),.q(mod),.C(A1));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP3_2
(.clk(clk),.reset(rst),.A(VV),.B(V_delay23),.q(mod),.C(A2)); 

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP3_3
(.clk(clk),.reset(rst),.A(VV),.B(V2_delay23),.q(mod),.C(A3)); 

assign A_temp_1 = (A1<A2) ? (A1-A2+mod) : (A1-A2);
assign A_temp_2 = (A_temp_1<A3) ? (A_temp_1-A3+mod) : (A_temp_1-A3);
assign A        = (A_temp_2<A3) ? (A_temp_2-A3+mod) : (A_temp_2-A3);
//// modulu mul period 4 
assign Y_R_temp = (A3<A)?(A3-A+mod):(A3-A); 
ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP4_1
(.clk(clk),.reset(rst),.A(V_delay24),.B(A),.q(mod),.C(X_R));

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP4_2
(.clk(clk),.reset(rst),.A(A2),.B(W_delay24),.q(mod),.C(Z_R)); 

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP4_3
(.clk(clk),.reset(rst),.A(U_delay24),.B(Y_R_temp),.q(mod),.C(Y_R_1)); 

ModMult #(.DATA_WIDTH(DATA_WIDTH),.W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) UP4_4
(.clk(clk),.reset(rst),.A(A2),.B(U2_delay24),.q(mod),.C(Y_R_2)); 

assign Y_R = (Y_R_1<Y_R_2)?(Y_R_1-Y_R_2+mod):(Y_R_1-Y_R_2);

endmodule
