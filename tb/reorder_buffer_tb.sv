module reorder_buffer_tb();

localparam DATA_WIDTH = 8;
localparam SEND_MAX_DELAY = 5;
localparam BACK_MAX_DELAY = 3;

localparam RANDOM_SEED = 100;
localparam TEST_ITERATIONS = 1000;

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

// tasks flags, just to look at waveform
bit sending_ids;
bit sending_back;

// tasks variables
bit clear_gotten_ids;
bit goto_next_data;

logic [3:0]            ids_collected_order  [16];
logic [DATA_WIDTH-1:0] data_collected_order [16];

logic [3:0] ids_send_order [16] = '{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
logic [3:0] ids_back_order [16] = '{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
int gotten_ids [16] = '{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };

int i = 0;
int j = 0;
int k = 0;
int t = 0;


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


// random arm_ready change
always_ff @( negedge clk ) begin
  if ( ~rstn ) begin
    arm_ready = 0;
  end
  else begin
    if ( $urandom() % 10 == 0 ) begin
      arm_ready = ~arm_ready;
    end
  end
end

// random rs_ready change
always_ff @( negedge clk ) begin
  if ( ~rstn ) begin
    rs_ready = 0;
  end
  else begin
    if ( $urandom() % 10 == 0 ) begin
      rs_ready = ~rs_ready;
    end
  end
end


initial forever begin
  clk = ~clk;
  #5;
end

initial begin
  // repeating multiple times work as random seed
  repeat(RANDOM_SEED) ids_back_order.shuffle();
  ids_send_order.shuffle();
  rstn = 0;
  #15;
  rstn = 1;
  // repeat processing multiple times
  repeat(TEST_ITERATIONS) begin
    ids_send_order.shuffle();
    ids_back_order.shuffle();
    i = 0;
    k = 0;
    clear_gotten_ids = 1;
    repeat(2) @( posedge clk );
    clear_gotten_ids = 0;
    fork
      send_all_ids();
      send_all_data_back();
    join
    wait ( goto_next_data );
    @( posedge clk );
  end
  $display("TESTS PASSED! (random seed %d, %d iterations)", RANDOM_SEED, TEST_ITERATIONS);
  $finish(0);
end

// collecting data | read slave side
always_ff @( posedge clk ) begin
  if ( rs_ready && rs_valid ) begin
    ids_collected_order[t] = rs_id;
    data_collected_order[t] = rs_data;
    t = t + 1;
  end
  if ( t == 16 ) begin
    $display("Correct order : %p", ids_send_order);
    $display("Gotten ids    : %p", ids_collected_order);
    $display("Gotten data   : %p\n", data_collected_order);
    if ( ids_send_order != ids_collected_order ) begin
      $display("Test failed!");
      $stop();
    end
    t = 0;
    goto_next_data = 1;
  end
  else begin
    goto_next_data = 0;
  end
end

// getting data to process on addr read master
always_ff @( posedge clk ) begin
  if ( arm_ready && arm_valid ) begin
    gotten_ids[j] = arm_id;
    j = j + 1;
  end
  if ( clear_gotten_ids ) begin
    gotten_ids = '{ -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
  end
  if ( j >= 16 ) begin
    j = 0;
  end
end

task send_single_id (logic [3:0] id);
  repeat( $urandom() % SEND_MAX_DELAY ) @( posedge clk );  // random delay
  @( negedge clk );
  ars_id = id;
  ars_valid = 'b1;
  @( posedge clk iff ( ars_valid && ars_ready ) );
  ars_valid = 'b0;
endtask

task automatic send_all_ids ();
  sending_ids = 1;
  repeat(16) begin  // send one id 16 times
    send_single_id(ids_send_order[i]);
    i = i + 1;
  end
  sending_ids = 0;
endtask

task automatic send_all_data_back ();
  sending_back = 1;
  repeat(2147483647) begin  // max int32, read as inf
    @( negedge clk );  // not to change signal on rising edge
    if ( gotten_ids[ids_back_order[k]] != -1 ) begin  // value is collected then send
      rm_data  = gotten_ids[ids_back_order[k]] + 8'd10;  // data = id+16 for testbench convenience
      rm_id    = gotten_ids[ids_back_order[k]];
      rm_valid = 1;
      @( posedge clk iff ( rm_valid && rm_ready ) );
      rm_valid = 0;
      k = k + 1;
      if ( k == 16 ) begin
        break;
      end
    end
    else begin
      repeat($urandom() % BACK_MAX_DELAY) @( posedge clk );  // random delay
    end
  end
  sending_back = 0;
endtask

endmodule
