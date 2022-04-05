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

//`include "defines.v"


module ModMult #(parameter DATA_WIDTH = 32,W_SIZE = 12,L_SIZE=3)
              (input clk,reset,
               input [DATA_WIDTH-1:0] A,B,
               input [DATA_WIDTH-1:0] q,
               output[DATA_WIDTH-1:0] C);

// --------------------------------------------------------------- connections
wire [(2*DATA_WIDTH)-1:0] P;
localparam TIME = (1 << ($clog2(DATA_WIDTH) - 4));
// --------------------------------------------------------------- modules
intMult #(.DATA_SIZE_ARB(DATA_WIDTH), .TIME(TIME)) im(clk,reset,A,B,P);
ModRed  #(.DATA_SIZE_ARB(DATA_WIDTH), .W_SIZE(W_SIZE),.L_SIZE(L_SIZE)) mr(clk,reset,q,P,C);

endmodule
