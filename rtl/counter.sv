module counter #(
  WIDTH = 4
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             en_i,
  output logic [WIDTH-1:0] data_o
);

logic [WIDTH-1:0] data;

assign data_o = data;

always_ff @( posedge clk ) begin
  if ( ~rst_n ) begin
    data <= 'b0;
  end
  else begin
    if ( en_i ) begin
      data <= data + 'b1;
    end
  end
end
    
endmodule
