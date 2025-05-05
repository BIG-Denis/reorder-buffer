module reorder_buffer_tb();

localparam DATA_WIDTH = 8;

bit clk, rstn;

// ARS - addr read slave
logic [3:0] ars_id;
logic ars_valid, ars_ready;

// ARM - addr read master
logic [3:0] arm_id;
logic arm_valid, arm_ready;

// RS - read slave
logic [DATA_WIDTH-1:0] rs_data;
logic [3:0] rs_id;
logic rs_valid, rs_ready;

// RM - read master
logic [DATA_WIDTH-1:0] rm_data;
logic [3:0] rm_id;
logic rm_valid, rm_ready;

// tasks flags
bit sending_ids;
bit sending_back;

// tasks variables
logic [3:0] ids [16] = '{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
int i = 0;
int gotten_ids [16] = '{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
int j = 0;
int k = 0;
logic [3:0] ids_back_order [16] = '{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };

reorder_buffer #(
  .DATA_WIDTH ( DATA_WIDTH )
) DUT (
  .clk         ( clk  ),
  .rst_n       ( rstn ),
  //AR slave interface
  .s_arid_i    ( ars_id    ),
  .s_arvalid_i ( ars_valid ),
  .s_arready_o ( ars_ready ),
  //AR master interface
  .m_arid_o    ( arm_id    ),
  .m_arvalid_o ( arm_valid ),
  .m_arready_i ( arm_ready ),
  //R slave interface
  .s_rdata_o   ( rs_data   ),
  .s_rid_o     ( rs_id     ),
  .s_rvalid_o  ( rs_valid  ),
  .s_rready_i  ( rs_ready  ),
  //R master interface
  .m_rdata_i   ( rm_data   ),
  .m_rid_i     ( rm_id     ),
  .m_rvalid_i  ( rm_valid  ),
  .m_rready_o  ( rm_ready  )
);

assign arm_ready = 1;


initial forever begin
  clk = ~clk;
  #5;
end

initial begin
  ids_back_order.shuffle();
  rstn = 0;
  #15;
  rstn = 1;
  fork
    send_all_ids();
    send_all_data_back();
  join
  #1000;
end

always_ff @( posedge clk ) begin
  if ( arm_ready && arm_valid ) begin
    gotten_ids[j] = arm_id;
    j = j + 1;
  end
end

task send_single_id (logic [3:0] id);
  repeat( $urandom() % 3 ) @( posedge clk );  // random delay
  ars_id = id;
  ars_valid = 'b1;
  wait( arm_valid && ars_ready );
  @( posedge clk );
  ars_valid = 'b0;
endtask

task automatic send_all_ids ();
  sending_ids = 1;
  repeat(16) begin  // send one id 16 times
    send_single_id(ids[i]);
    i = i + 1;
  end
  sending_ids = 0;
endtask

task automatic send_all_data_back ();
  sending_back = 1;
  repeat(2147483647) begin
    if ( gotten_ids[ids_back_order[k]] != -1 ) begin  // value is collected then send
      rm_data  = gotten_ids[ids_back_order[k]];  // data = id for testbench convenience
      rm_id    = gotten_ids[ids_back_order[k]];
      rm_valid = 1;
      wait( rm_valid && rm_ready );
      @( posedge clk );
      rm_valid = 0;
      k = k + 1;
      if ( k == 16 ) begin
        break;
      end
    end
    else begin
      repeat($urandom() % 4) @( posedge clk );
    end
  end
  sending_back = 0;
endtask




endmodule
