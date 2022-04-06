//===========================================
//      CL Tech Limited's Proprietary
//              Confidential
//      Any unauthorized disclosure of
//      this file is a violation of the law.
//
// file name: ff.sv
// author: baihu
// contact: baihu@chipltech.com
// description: flip-flop macros
//===========================================

`ifndef FLIP_FLOP_MACRO
`define FLIP_FLOP_MACRO

// Flip-flop without load enable.
// _name is the name of ther flip-flop and it is output of the flip-flop.
// _input is the input of the flip-flop.
// _rst is the reset signal.
// _rst_value is the reset value of the flip-flop.
// _clk is the clock of the flip-flop.
`define FF(_name, _input, _rst_value, _rst, _clk) \
  always_ff @(posedge (_clk)) begin \
    _name <= _rst ? (_rst_value) : (_input); \
  end

// Flip-flop without load enable or reset.
// _name is the name of ther flip-flop and it is output of the flip-flop.
// _input is the input of the flip-flop.
// _clk is the clock of the flip-flop.
`define FFNR(_name, _input, _clk) \
  always_ff @(posedge (_clk)) begin \
    _name <= (_input); \
  end

// Flip-flop with load enable.
// _name is the name of ther flip-flop and it is output of the flip-flop.
// _input is the input of the flip-flop.
// _load is the load enable signal.
// _rst is the reset signal.
// _rst_value is the reset value of the flip-flop.
// _clk is the clock of the flip-flop.
`define FFL(_name, _input, _load, _rst_value, _rst, _clk) \
  always_ff @(posedge (_clk)) begin \
    _name <= _rst ? (_rst_value) : (_load) ? (_input) : _name; \
  end

// Flip-flop with load enable not reset.
// _name is the name of ther flip-flop and it is output of the flip-flop.
// _input is the input of the flip-flop.
// _load is the load enable signal.
// _clk is the clock of the flip-flop.
`define FFLNR(_name, _input, _load, _clk) \
  always_ff @(posedge (_clk)) begin \
    _name <= (_load) ? (_input) : _name; \
  end

// Asynchronous Reset without load enable.
// _name is the name of the flip-flop and it is out of the flip-flop.
// _input is the input of the flip-flop.
// _rst is the asynchronous reset.
// _rst_value is the asynchronous rest value of the flip-flop.
// _clk is the clock of the flip-flop.
`define AFF(_name, _input, _rst_value, _rst, _clk) \
  always_ff @(posedge (_clk) or posedge (_rst)) begin \
    if (_rst) begin _name <= (_rst_value); end \
    else begin _name <= (_input); end \
  end

// Asynchronous Reset with load enable.
// _name is the name of the flip-flop and it is out of the flip-flop.
// _input is the input of the flip-flop.
// _load is the load enable of the flip-flop.
// _rst is the asynchronous reset.
// _rst_value is the asynchronous rest value of the flip-flop.
// _clk is the clock of the flip-flop.
`define AFFL(_name, _input, _load, _rst_value, _rst, _clk) \
  always_ff @(posedge (_clk) or posedge (_rst)) begin \
    if (_rst) begin _name <= (_rst_value); end \
    else begin _name <= _load ? (_input) : _name; end \
  end

`endif // FLIP_FLOP_MACRO
