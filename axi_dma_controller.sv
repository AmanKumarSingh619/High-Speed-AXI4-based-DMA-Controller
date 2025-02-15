module axi_dma_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)(
    input  wire                   clk,
    input  wire                   reset_n,
    // AXI Read Master Signals
    output wire [ADDR_WIDTH-1:0]   araddr,
    output wire                    arvalid,
    input  wire                    arready,
    input  wire [DATA_WIDTH-1:0]   rdata,
    input  wire                    rvalid,
    output wire                    rready,
    // AXI Write Master Signals
    output wire [ADDR_WIDTH-1:0]   awaddr,
    output wire                    awvalid,
    input  wire                    awready,
    output wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wvalid,
    input  wire                    wready,
    input  wire [1:0]              bresp,
    input  wire                    bvalid,
    output wire                    bready
);

// Internal FIFO Signals
reg [DATA_WIDTH-1:0] fifo [FIFO_DEPTH-1:0]; // Simple register-based FIFO
reg [3:0] read_ptr, write_ptr;
reg fifo_full, fifo_empty;

// Declare wires for FIFO control
wire fifo_wr_en;
wire fifo_rd_en;
wire wvalid_signal; 

// ✅ FIX: Declare `fifo_write_data` and `fifo_read_data` as wires
wire [DATA_WIDTH-1:0] fifo_write_data;
wire [DATA_WIDTH-1:0] fifo_read_data;

// ✅ FIX: Use continuous assignment instead of procedural assignment
assign fifo_write_data = fifo[write_ptr];  
assign fifo_read_data = fifo[read_ptr];    

// FIFO Write Logic (From Read Master)
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        write_ptr <= 0;
        fifo_full <= 0;
    end else if (fifo_wr_en && !fifo_full) begin
        fifo[write_ptr] <= rdata;
        write_ptr <= write_ptr + 1;
        if (write_ptr == FIFO_DEPTH-1) fifo_full <= 1;
        fifo_empty <= 0;  
    end
end

// FIFO Read Logic (To Write Master)
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        read_ptr <= 0;
        fifo_empty <= 1;
    end else if (fifo_rd_en && !fifo_empty) begin
        read_ptr <= read_ptr + 1;
        if (read_ptr == FIFO_DEPTH-1) fifo_empty <= 1;
        fifo_full <= 0; 
    end
end

// Instantiate AXI Read Master
axi_dma_read #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) axi_read (
    .clk(clk),
    .reset_n(reset_n),
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rvalid(rvalid),
    .rready(rready),
    .fifo_data(fifo_write_data), // ✅ Fixed connection using wire
    .fifo_wr_en(fifo_wr_en)
);

// Assign FIFO Write Enable
assign fifo_wr_en = rvalid && rready; 

// Assign FIFO Read Enable
assign fifo_rd_en = wready && wvalid_signal; 

// Assign wvalid separately
assign wvalid_signal = !fifo_empty;  

// Instantiate AXI Write Master
axi_dma_write #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) axi_write (
    .clk(clk),
    .reset_n(reset_n),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(fifo_read_data), // ✅ Fixed connection using wire
    .wvalid(wvalid_signal),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    .fifo_data(fifo_read_data),
    .fifo_rd_en(fifo_rd_en)
);

endmodule
