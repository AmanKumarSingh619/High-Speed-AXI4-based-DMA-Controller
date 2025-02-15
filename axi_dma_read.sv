module axi_dma_read #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BURST_LEN  = 8  // Number of beats per burst
)(
    input  wire                   clk,
    input  wire                   reset_n,
    // AXI Read Address Channel
    output reg  [ADDR_WIDTH-1:0]   araddr,
    output reg                     arvalid,
    input  wire                    arready,
    // AXI Read Data Channel
    input  wire [DATA_WIDTH-1:0]   rdata,
    input  wire                    rvalid,
    output reg                     rready,
    // FIFO Interface
    output reg [DATA_WIDTH-1:0]    fifo_data,
    output reg                     fifo_wr_en
);

// State Encoding
typedef enum logic [1:0] {
    IDLE  = 2'b00,
    ADDR  = 2'b01,
    READ  = 2'b10
} state_t;

state_t state, next_state;

// Address Register
reg [ADDR_WIDTH-1:0] addr_reg;

// AXI Read Logic
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state   <= IDLE;
        arvalid <= 0;
        rready  <= 0;
    end else begin
        state <= next_state;
    end
end

// State Transition Logic
always @(*) begin
    case (state)
        IDLE: begin
            arvalid = 1;   // Request read transaction
            if (arready) next_state = ADDR;
            else next_state = IDLE;
        end
        ADDR: begin
            arvalid = 0;
            rready  = 1;  // Ready to receive data
            next_state = READ;
        end
        READ: begin
            if (rvalid) next_state = IDLE; // Go back to IDLE after reading
            else next_state = READ;
        end
        default: next_state = IDLE;
    endcase
end

// Data Handling Logic
always @(posedge clk) begin
    if (rvalid && rready) begin
        fifo_data  <= rdata;
        fifo_wr_en <= 1;  // Write to FIFO
    end else begin
        fifo_wr_en <= 0;
    end
end

endmodule