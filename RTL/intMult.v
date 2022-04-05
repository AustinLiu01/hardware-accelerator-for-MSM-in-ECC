/*
Copyright 2020, Ahmet Can Mert <ahmetcanmert@sabanciuniv.edu>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


// inputs are divided into 16-bit chunks
// multiplications are performed using DSP on 1 cc
// partial products are added using CSA in 1 cc
// final output (c, s) will be added in 1 cc

module intMult#(parameter DATA_SIZE_ARB=32, TIME=2)
                (input clk,reset,
			   input [DATA_SIZE_ARB-1:0] A,B,
			   output reg[(2*DATA_SIZE_ARB)-1:0] C);

localparam DATA_SIZE = (1<<$clog2(DATA_SIZE_ARB));
localparam CSA_LEVEL = (TIME>1)?(TIME*TIME-2):0;
// connections
(* use_dsp = "yes" *) reg [(2*DATA_SIZE)-1:0] output_dsp [TIME*TIME-1:0];
wire[(2*DATA_SIZE)-1:0] op_reg     [(CSA_LEVEL*3+2)-1:0];

reg [15:0] first_index_dsp  [TIME-1:0];
reg [15:0] second_index_dsp [TIME-1:0];

wire[(2*DATA_SIZE)-1:0] csa_out_c;
wire[(2*DATA_SIZE)-1:0] csa_out_s;

reg [(2*DATA_SIZE)-1:0] C_out;
reg [(2*DATA_SIZE)-1:0] S_out;

// --------------------------------------------------------------- divide inputs into 16-bit chunks
genvar i_gen_loop,m_gen_loop;

generate
  for(i_gen_loop=0; i_gen_loop < TIME; i_gen_loop=i_gen_loop+1)
  begin
	always @(*) begin
	   first_index_dsp [i_gen_loop] = (A >> (i_gen_loop*16));
	   second_index_dsp[i_gen_loop] = (B >> (i_gen_loop*16));
	end
  end
endgenerate

// --------------------------------------------------------------- multiply 16-bit chunks
integer i_loop=0;
integer m_loop=0;

always @(posedge clk or posedge reset)
begin
  for(i_loop=0; i_loop < TIME; i_loop=i_loop+1)
  begin
		for(m_loop=0; m_loop < TIME; m_loop=m_loop+1)
		begin
			if(reset)
				output_dsp[(i_loop*TIME)+m_loop][(2*DATA_SIZE)-1:0] <= 0;
			else
				output_dsp[(i_loop*TIME)+m_loop][(2*DATA_SIZE)-1:0] <= (first_index_dsp[i_loop][15:0] * second_index_dsp[m_loop][15:0])<<((i_loop+m_loop)*16);
		end
  end
end

// --------------------------------------------------------------- Carry-Save Adder for adder tree
// data initialization
generate
	genvar m;

	for(m=0; m<(TIME*TIME); m=m+1) begin: DUMMY
        assign op_reg[m] = output_dsp[m];
    end
endgenerate

// operation
generate
	genvar k;

	for(k=0; k<CSA_LEVEL; k=k+1) begin: CSA_LOOP
		CSA #(.DATA_SIZE(DATA_SIZE)) csau(op_reg[3*k+0],op_reg[3*k+1],op_reg[3*k+2],op_reg[(TIME*TIME)+2*k+0],op_reg[(TIME*TIME)+2*k+1]);
	end
endgenerate

// DFF value
always @(posedge clk or posedge reset) begin
	if(reset) begin
		C_out <= 0;
		S_out <= 0;
	end
	else begin
		C_out <= (DATA_SIZE > 16) ? op_reg[(CSA_LEVEL*3+2)-1] : op_reg[0];
		S_out <= (DATA_SIZE > 16) ? op_reg[(CSA_LEVEL*3+2)-2] : op_reg[0];
	end
end

// --------------------------------------------------------------- c + s operation
always @(posedge clk or posedge reset) begin
	if(reset)
		C <= 0;
	else
		C <= (DATA_SIZE > 16) ? (C_out + S_out) : S_out;
end

endmodule
