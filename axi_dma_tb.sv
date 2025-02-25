module axi_dma_tb;

  // Testbench Parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter FIFO_DEPTH = 16;

  // Clock & Reset
  reg clk;
  reg reset_n;

  // AXI Read Master Signals
  wire [ADDR_WIDTH-1:0] araddr;
  wire arvalid;
  reg arready;
  reg [DATA_WIDTH-1:0] rdata;
  reg rvalid;
  wire rready;

  // AXI Write Master Signals
  wire [ADDR_WIDTH-1:0] awaddr;
  wire awvalid;
  reg awready;
  wire [DATA_WIDTH-1:0] wdata;
  wire wvalid;
  reg wready;
  reg [1:0] bresp;
  reg bvalid;
  wire bready;

  // Instantiate AXI DMA Controller
  axi_dma_controller #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) dma_inst (
      .clk(clk),
      .reset_n(reset_n),
      .araddr(araddr),
      .arvalid(arvalid),
      .arready(arready),
      .rdata(rdata),
      .rvalid(rvalid),
      .rready(rready),
      .awaddr(awaddr),
      .awvalid(awvalid),
      .awready(awready),
      .wdata(wdata),
      .wvalid(wvalid),
      .wready(wready),
      .bresp(bresp),
      .bvalid(bvalid),
      .bready(bready)
  );

  // Clock Generation
  always #5 clk = ~clk;

  // Testbench Stimulus
  initial begin
      // Initialize Signals
      clk = 0;
      reset_n = 0;
      arready = 0;
      rdata = 32'h0;
      rvalid = 0;
      awready = 0;
      wready = 0;
      bresp = 2'b00;
      bvalid = 0;
      
      // Apply Reset
      #10 reset_n = 1;
      
      // AXI Read Stimulus
      #20 arready = 1; // Accept Read Address
      #30 rdata = 32'hA5A5A5A5; rvalid = 1; // Provide Read Data
      #40 rvalid = 0; // End Read Transaction
      
      // AXI Write Stimulus
      #50 awready = 1; // Accept Write Address
      #60 wready = 1; // Accept Write Data
      #70 bvalid = 1; bresp = 2'b00; // Write Success Response
      #80 bvalid = 0; // End Write Transaction

      // Simulation End
      #100 $finish;
  end

  // Monitor Data Transfers
  always @(posedge clk) begin
      if (rvalid && rready) 
          $display("Read Data: %h", rdata);
      if (wvalid && wready) 
          $display("Write Data: %h", wdata);
  end

endmodule