module Control_FFTConv #(
    parameter integer N = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    output reg  [$clog2(2*N)-1:0]   addr_RAM1,
    output reg  [$clog2(2*N)-1:0]   addr_RAM2,
    output reg  [$clog2(N)-1:0]     addr_ROM,
    output reg                      enRAM1,
    output reg                      enRAM2,
    output reg                      enROM,
    output reg                      MUX_BMU,
    output reg                      MUX_in,
    output reg                      MUX_out,
    output reg                      MUX_MPW,
    output reg                      done
);

    localparam L             = $clog2(N);
    localparam LL            = $clog2(L);

    localparam S_IDLE        = 4'd0;
    localparam S_LOAD        = 4'd1;
    localparam S_FFTX_READ   = 4'd2;
    localparam S_FFTX_WRITE  = 4'd3;
    localparam S_FFTH_READ   = 4'd4;
    localparam S_FFTH_WRITE  = 4'd5;
    localparam S_MPW_READ    = 4'd6;
    localparam S_MPW_WRITE   = 4'd7;
    localparam S_IFFT_READ   = 4'd8;
    localparam S_IFFT_WRITE  = 4'd9;
    localparam S_OUT         = 4'd10;
    localparam S_DONE        = 4'd11;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [L + LL - 2:0] counter;
    reg [L + LL - 2:0] last_step;
    reg MUX_DIF;
    reg [L-1:0] last_ADDR_MPW;

    wire [L + LL - 2:0] step;
    wire [LL - 1 : 0] stage;
    wire [L-1:0] ADDR_MPW;
    wire [L:0] ADDRAM1;
    wire [L:0] ADDRAM2;
    wire [L-1:0] ADDROM;

    assign step = last_step + counter[3:0];
    assign stage = step[L + LL -2: L-1];
    assign ADDR_MPW = last_ADDR_MPW + counter[2:0];

    AddressFFT #(N) GenAddr(
        .step(step[L-2:0]),
        .state(stage),
        .Mux1(MUX_BMU),
        .Mux2(MUX_DIF),
        .addr_RAM1(ADDRAM1),
        .addr_RAM2(ADDRAM2),
        .addr_ROM(ADDROM)
    );

    always @(*) begin
        case (state)
            S_IDLE: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= 0;
                addr_RAM2   <= 0;
                addr_ROM    <= 0;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= start ? S_LOAD : S_IDLE;             
            end
            S_LOAD: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= {1'b0, counter[L-1:0]};
                addr_RAM2   <= {1'b1, counter[L-1:0]};
                addr_ROM    <= 0;
                enRAM1      <= 1;
                enRAM2      <= 1;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 1;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (counter == N - 1) ? S_FFTX_READ : S_LOAD;            
            end
            S_FFTX_READ: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 1;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (counter == 17) ? S_FFTX_WRITE : S_FFTX_READ;  
            end
            S_FFTX_WRITE: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 1;
                enRAM2      <= 1;
                enROM       <= 1;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (stage == L-1 && step[L-2:0] == N/2 -1) ? S_FFTH_READ : 
                               ((counter == 15) ? S_FFTX_READ : S_FFTX_WRITE);            
            end
            S_FFTH_READ: begin
                MUX_DIF     <= 1;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 1;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (counter == 17) ? S_FFTH_WRITE : S_FFTH_READ;
            end
            S_FFTH_WRITE: begin
                MUX_DIF     <= 1;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 1;
                enRAM2      <= 1;
                enROM       <= 1;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (stage == L-1 && step[L-2:0] == N/2 -1) ? S_MPW_READ : 
                               ((counter == 15) ? S_FFTH_READ : S_FFTH_WRITE);  
            end
            S_MPW_READ: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= {1'b0, ADDR_MPW};
                addr_RAM2   <= {1'b1, ADDR_MPW};
                addr_ROM    <= 0;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 1;
                done        <= 0;
                next_state  <= (counter == 13) ? S_MPW_WRITE : S_MPW_READ;
            end
            S_MPW_WRITE: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= {1'b0, ADDR_MPW};
                addr_RAM2   <= {1'b1, ADDR_MPW};
                addr_ROM    <= 0;
                enRAM1      <= 1;
                enRAM2      <= 0;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 1;
                done        <= 0;
                next_state  <= (ADDR_MPW == N-1) ? S_IFFT_READ : 
                               ((counter == 7) ? S_MPW_READ : S_MPW_WRITE);
            end
            S_IFFT_READ: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 1;
                MUX_BMU     <= 1;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (counter == 17) ? S_IFFT_WRITE : S_IFFT_READ;
            end
            S_IFFT_WRITE: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= ADDRAM1;
                addr_RAM2   <= ADDRAM2;
                addr_ROM    <= ADDROM;
                enRAM1      <= 1;
                enRAM2      <= 1;
                enROM       <= 1;
                MUX_BMU     <= 1;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (stage == L-1 && step[L-2:0] == N/2 -1) ? S_OUT : 
                               ((counter == 15) ? S_IFFT_READ : S_IFFT_WRITE);  
            end
            S_OUT: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= counter[L-1:0];
                addr_RAM2   <= 0;
                addr_ROM    <= 0;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= (counter == N) ? 0 : 1;
                MUX_MPW     <= 0;
                done        <= 0;
                next_state  <= (counter == 1) ? S_DONE : S_OUT;
            end
            S_DONE: begin
                MUX_DIF     <= 0;
                addr_RAM1   <= 0;
                addr_RAM2   <= 0;
                addr_ROM    <= 0;
                enRAM1      <= 0;
                enRAM2      <= 0;
                enROM       <= 0;
                MUX_BMU     <= 0;
                MUX_in      <= 0;
                MUX_out     <= 0;
                MUX_MPW     <= 0;
                done        <= 1;
                next_state  <= S_DONE;            
            end    
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(posedge clk) begin    
        case (state)
            S_IDLE: begin
                counter <= 0;
                last_step <= 0;
                last_ADDR_MPW <= 0;
            end
            S_LOAD: begin
                if(counter == N - 1) begin
                    counter <= 0;
                    last_step <= 0;
                end
                else counter <= counter + 1;
            end
            S_FFTX_READ: begin
                if(counter == 17) counter <= 0;
                else counter <= counter + 1;
            end
            S_FFTX_WRITE: begin
                if(stage == L-1 && step[L-2:0] == N/2 -1) begin
                    counter <= 0;
                    last_step <= 0;
                end
                else begin
                    if(counter == 15) begin
                        counter <= 0;
                        last_step <= last_step + 16;
                    end 
                    else counter <= counter + 1;
                end
            end
            S_FFTH_READ: begin
                if(counter == 17) counter <= 0;
                else counter <= counter + 1;
            end
            S_FFTH_WRITE: begin
                if(stage == L-1 && step[L-2:0] == N/2 -1) begin
                    counter <= 0;
                    last_ADDR_MPW <= 0;
                end
                else begin
                    if(counter == 15) begin
                        counter <= 0;
                        last_step <= last_step + 16;
                    end 
                    else counter <= counter + 1;
                end
            end
            S_MPW_READ: begin
                if(counter == 13) counter <= 0;
                else counter <= counter + 1;
            end
            S_MPW_WRITE: begin
                if(ADDR_MPW == N-1) begin 
                    counter <= 0;
                    last_step <= 0;
                end
                else begin
                    if(counter == 7) begin
                        counter <= 0;
                        last_ADDR_MPW <= last_ADDR_MPW + 8;
                    end
                    else counter <= counter + 1;
                end
            end
            S_IFFT_READ: begin
                if(counter == 17) counter <= 0;
                else counter <= counter + 1;
            end
            S_IFFT_WRITE: begin
                if(stage == L-1 && step[L-2:0] == N/2 -1) counter <= N;
                else begin
                    if(counter == 15) begin
                        counter <= 0;
                        last_step <= last_step + 16;
                    end 
                    else counter <= counter + 1;
                end
            end
            S_OUT: begin
                if(counter == 1) counter <= 0;
                else counter <= counter - 1;
            end
            S_DONE: begin
            end
        endcase
    end

endmodule