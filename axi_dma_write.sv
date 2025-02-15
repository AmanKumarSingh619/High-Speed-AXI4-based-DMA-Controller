module axi_dma_write #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BURST_LEN  = 8  // Number of beats per burst
)(
    input  wire                   clk,
    input  wire                   reset_n,
    // AXI Write Address Channel
    output reg  [ADDR_WIDTH-1:0]   awaddr,
    output reg                     awvalid,
    input  wire                    awready,
    // AXI Write Data Channel
    output reg [DATA_WIDTH-1:0]    wdata,
    output reg                     wvalid,
    input  wire                    wready,
    // AXI Write Response Channel
    input  wire [1:0]              bresp,
    input  wire                    bvalid,
    output reg                     bready,
    // FIFO Interface
    input  wire [DATA_WIDTH-1:0]   fifo_data,
    input  wire                    fifo_rd_en
);

// State Encoding
typedef enum logic [1:0] {
    IDLE  = 2'b00,
    ADDR  = 2'b01,
    WRITE = 2'b10,
    RESP  = 2'b11
} state_t;

state_t state, next_state;

// AXI Write Logic
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state   <= IDLE;
        awvalid <= 0;
        wvalid  <= 0;
        bready  <= 0;
    end else begin
        state <= next_state;
    end
end

// State Transition Logic
always @(*) begin
    case (state)
        IDLE: begin
            awvalid = 1;   // Request write transaction
            if (awready) next_state = ADDR;
            else next_state = IDLE;
        end
        ADDR: begin
            awvalid = 0;
            wvalid  = 1;  // Send write data
            next_state = WRITE;
        end
        WRITE: begin
            if (wready) next_state = RESP; // Wait for response
            else next_state = WRITE;
        end
        RESP: begin
            bready = 1;  // Acknowledge write response
            if (bvalid) next_state = IDLE;
            else next_state = RESP;
        end
        default: next_state = IDLE;
    endcase
end

// Data Handling Logic
always @(posedge clk) begin
    if (fifo_rd_en) begin
        wdata  <= fifo_data;
    end
end

endmodule