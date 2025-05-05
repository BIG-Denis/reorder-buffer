module mem_2ps #(  // memory simple dual-port
  ADDR_WIDTH = 4,
  DATA_WIDTH = 8
) (
  input  logic clk,
  // write port
  input  logic                  write_en_i,
  input  logic [ADDR_WIDTH-1:0] addr_write_i,
  input  logic [DATA_WIDTH-1:0] data_write_i,
  // read port
  input  logic [ADDR_WIDTH-1:0] addr_read_i,
  output logic [DATA_WIDTH-1:0] data_read_o
);

localparam MEM_DEPTH = 2**ADDR_WIDTH;

logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
// logic [DATA_WIDTH-1:0] output_ff;
assign data_read_o = mem[addr_read_i];
// assign data_read_o = output_ff;

always_ff @( posedge clk ) begin  // write port
  if ( write_en_i ) begin
    mem[addr_write_i] <= data_write_i;
  end
end

// always_ff @( posedge clk ) begin  // read port
//   output_ff <= mem[addr_read_i];
// end

endmodule
