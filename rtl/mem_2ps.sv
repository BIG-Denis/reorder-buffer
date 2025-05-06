module mem_2ps #(  // memory simple dual-port (async read)
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

always_ff @( posedge clk ) begin  // write port (sync)
  if ( write_en_i ) begin
    mem[addr_write_i] <= data_write_i;
  end
end

assign data_read_o = mem[addr_read_i];  // read port (async)

endmodule
