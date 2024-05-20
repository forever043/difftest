/***************************************************************************************
* Copyright (c) 2024 Beijing Institute of Open Source Chip (BOSC)
* Copyright (c) 2020-2024 Institute of Computing Technology, Chinese Academy of Sciences
* Copyright (c) 2020-2021 Peng Cheng Laboratory
*
* DiffTest is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

`include "DifftestMacros.v"
module tb_top();

`ifdef PALLADIUM
  `ifdef SYNTHESIS
  `define WIRE_CLK //clock will be generated by ixclkgen
  `endif // SYNTHESIS
`endif // PALLADIUM

`ifdef WIRE_CLK
wire        clock;
`else
reg         clock;
`endif // WIRE_CLK
reg         reset;
wire [63:0] difftest_logCtrl_begin;
wire [63:0] difftest_logCtrl_end;
wire [63:0] difftest_logCtrl_level;
wire        difftest_perfCtrl_clean;
wire        difftest_perfCtrl_dump;
wire        difftest_uart_out_valid;
wire [ 7:0] difftest_uart_out_ch;
wire        difftest_uart_in_valid;
wire [ 7:0] difftest_uart_in_ch;
wire [`CONFIG_DIFFTEST_STEPWIDTH - 1:0] difftest_step;

string wave_type;

initial begin
`ifndef WIRE_CLK
  clock = 0;
`endif // WIRE_CLK
  reset = 1;

`ifdef VCS
  // enable waveform
  if ($test$plusargs("dump-wave")) begin
    $value$plusargs("dump-wave=%s", wave_type);
    if (wave_type == "vpd") begin
      $vcdplusfile("simv.vpd");
      $vcdpluson;
    end
`ifdef CONSIDER_FSDB
    else if (wave_type == "fsdb") begin
      $fsdbDumpfile("simv.fsdb");
      $fsdbDumpvars(0,"+mda");
    end
`endif
    else begin
      $display("unknown wave file format, want [vpd, fsdb] but:%s\n", wave_type);
      $fatal;
    end
  end
`endif
end

// Note: reset delay #100 should be larger than RANDOMIZE_DELAY
`ifdef PALLADIUM
  `define RESET_COUNTER
`elsif ENABLE_WORKLOAD_SWITCH
  `define RESET_COUNTER
`endif

`ifndef RESET_COUNTER
initial begin
  #100 reset = 0;
end
`else
reg [7:0] reset_counter;
initial reset_counter = 0;
always @(posedge clock) begin
`ifdef ENABLE_WORKLOAD_SWITCH
  if (workload_switch) begin
    reset_counter <= 8'd0;
    reset         <= 1'b1;
    $display("workload switch");
  end
  else
`endif // ENABLE_WORKLOAD_SWITCH
  begin
    reset_counter <= reset_counter + 8'd1;
    if (reset && (reset_counter == 8'd100)) begin
      reset <= 1'b0;
    end
  end
end
`endif // RESET_COUNTER

`ifndef WIRE_CLK
always #1 clock <= ~clock;
`endif // WIRE_CLK

SimTop sim(
  .clock(clock),
  .reset(reset),
  .difftest_logCtrl_begin(difftest_logCtrl_begin),
  .difftest_logCtrl_end(difftest_logCtrl_end),
  .difftest_logCtrl_level(difftest_logCtrl_level),
  .difftest_perfCtrl_clean(difftest_perfCtrl_clean),
  .difftest_perfCtrl_dump(difftest_perfCtrl_dump),
  .difftest_uart_out_valid(difftest_uart_out_valid),
  .difftest_uart_out_ch(difftest_uart_out_ch),
  .difftest_uart_in_valid(difftest_uart_in_valid),
  .difftest_uart_in_ch(difftest_uart_in_ch),
  .difftest_step(difftest_step)
);

DifftestEndpoint difftest(
  .clock(clock),
  .reset(reset),
  .difftest_logCtrl_begin(difftest_logCtrl_begin),
  .difftest_logCtrl_end(difftest_logCtrl_end),
  .difftest_logCtrl_level(difftest_logCtrl_level),
  .difftest_perfCtrl_clean(difftest_perfCtrl_clean),
  .difftest_perfCtrl_dump(difftest_perfCtrl_dump),
  .difftest_uart_out_valid(difftest_uart_out_valid),
  .difftest_uart_out_ch(difftest_uart_out_ch),
  .difftest_uart_in_valid(difftest_uart_in_valid),
  .difftest_uart_in_ch(difftest_uart_in_ch),
  .difftest_step(difftest_step)
);

endmodule
