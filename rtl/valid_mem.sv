module valid_mem #(
  ADDR_WIDTH = 4
) (
  input  logic clk,
  input  logic rst_n,
  // write side
  input  logic                  set_i,
  input  logic [ADDR_WIDTH-1:0] addr_write_i,
  // read side
  input  logic                  clear_i,
  input  logic [ADDR_WIDTH-1:0] addr_read_i,
  output logic                  read_data_o
);

localparam DATA_WIDTH = 2**ADDR_WIDTH;

logic [DATA_WIDTH-1:0] data;
logic                  output_ff;

always_ff @( posedge clk ) begin  // sync write, with reset and clear
  if ( ~rst_n ) begin
    data <= 'b0;
  end
  else begin
    if ( clear_i ) begin
      data <= 'b0;
    end
    else begin
      if ( set_i ) begin
        data[addr_write_i] <= 'b1;
      end
      output_ff <= data[addr_read_i];
    end
  end
end

assign read_data_o = data[addr_read_i];  // async read

endmodule
