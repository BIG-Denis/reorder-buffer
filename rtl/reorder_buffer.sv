module reorder_buffer #(
  parameter DATA_WIDTH = 8
)(
  input  logic clk,
  input  logic rst_n,
  //AR slave interface
  input  logic [3:0] s_arid_i,
  input  logic       s_arvalid_i,
  output logic       s_arready_o,
  //R slave interface
  output logic [DATA_WIDTH-1:0] s_rdata_o,
  output logic [3:0]            s_rid_o,
  output logic                  s_rvalid_o,
  input  logic                  s_rready_i,
  //AR master interface
  output logic [3:0] m_arid_o,
  output logic       m_arvalid_o,
  input  logic       m_arready_i,
  //R master interface
  input  logic [DATA_WIDTH-1:0] m_rdata_i,
  input  logic [3:0]            m_rid_i,
  input  logic                  m_rvalid_i,
  output logic                  m_rready_o
);

assign m_arid_o    = s_arid_i;     // id thread
assign m_arvalid_o = s_arvalid_i;  // valid thread
assign s_arready_o = m_arready_i;  // ready thread


// ID MEM connection

logic ar_handshake;
assign ar_handshake = s_arvalid_i && m_arready_i;

logic [3:0] cnt_w_data;

counter cnt_w_inst (  // write addr counter
  .clk    ( clk          ),
  .rst_n  ( rst_n        ),
  .en_i   ( ar_handshake ),
  .data_o ( cnt_w_data   )
);

logic [3:0] id_mem_read_data;
logic       id_mem_valid;
// logic [3:0] id_mem_read_data_ff;

// always_ff @( posedge clk ) begin
//   if ( ~rst_n ) begin
//     id_mem_read_data_ff <= 'b0;
//   end
//   else begin
//     id_mem_read_data_ff <= id_mem_read_data;
//   end
// end

mem_2ps #(  // ID MEM
  .DATA_WIDTH( 4 )
) id_mem_inst (
  .clk          ( clk          ),
  // write port
  .write_en_i   ( ar_handshake ),
  .addr_write_i ( cnt_w_data   ),
  .data_write_i ( s_arid_i     ),
  // read port
  .addr_read_i  ( cnt_r_data ),
  .data_read_o  ( id_mem_read_data )
);

valid_mem valid_mem_id_inst (
  .clk          ( clk ),
  .rst_n        ( rst_n ),
  // write side (slave)
  .set_i        ( ar_handshake ),
  .addr_write_i ( s_arid_i     ),
  // read side (master)
  .clear_i      ( valid_mem_clear ),
  .addr_read_i  ( cnt_r_data      ),
  .read_data_o  ( id_mem_valid    )
);


// DATA MEM & VALID MEM master-side connection

assign m_rready_o = 1'b1;

logic rm_handshake;
assign rm_handshake = m_rready_o && m_rvalid_i;

logic [DATA_WIDTH-1:0] data_mem_read_data;

mem_2ps #(  // DATA MEM
  .DATA_WIDTH ( DATA_WIDTH )
) data_mem_inst (
  .clk          ( clk          ),
  // write port
  .write_en_i   ( rm_handshake ),
  .addr_write_i ( m_rid_i      ),
  .data_write_i ( m_rdata_i    ),
  // read port
  .addr_read_i  ( id_mem_read_data ),
  .data_read_o  ( data_mem_read_data )
);

logic valid_mem_clear;
logic valid_mem_read_data;

valid_mem valid_mem_data_inst (
  .clk          ( clk ),
  .rst_n        ( rst_n ),
  // master side
  .set_i        ( rm_handshake ),
  .addr_write_i ( m_rid_i      ),
  // slave side
  .clear_i      ( valid_mem_clear     ),
  .addr_read_i  ( id_mem_read_data    ),
  .read_data_o  ( valid_mem_read_data )
);


// DATA MEM & VALID MEM slave-side connection

assign s_rvalid_o = valid_mem_read_data && id_mem_valid;

logic rs_handshake;
assign rs_handshake = s_rready_i && s_rvalid_o;

logic [3:0] cnt_r_data;

counter cnt_r_inst (  // read addr counter
  .clk    ( clk          ),
  .rst_n  ( rst_n        ),
  .en_i   ( rs_handshake ),
  .data_o ( cnt_r_data   )
);

assign valid_mem_clear = rs_handshake && ( cnt_r_data == 4'hf );

assign s_rdata_o = data_mem_read_data;
assign s_rid_o   = id_mem_read_data;

endmodule
