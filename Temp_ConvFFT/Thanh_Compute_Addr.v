module AddressFFT #(
parameter integer N = 32,
localparam integer L = $clog2(N),
localparam integer LL = $clog2(L)
)(
input [L-2:0] step,
input [LL-1:0] state,
input Mux1, //0: DIF, 1: DIT
input Mux2, //0: RAM[N-1:0], 1: RAM[2N-1:N]
output [L:0] addr_RAM1,
output [L:0] addr_RAM2,
output [L-1:0] addr_ROM
);
wire [LL-1:0] m1;
wire [L-2:0] F;
wire [L-2:0] w1;
wire [L-2:0] w2;
wire [L-1:0] w3;
wire [L-1:0] wA;
wire [L-1:0] wB;
assign F = {L-1 {1'b1}};
assign m1 = Mux1? L - 1 - state : state; 
assign w1 = F >> m1;
assign w2 = ~w1;
assign w3 = ~(w1 | ({1'b0, w2}<<1));
assign wA = {1'b0, step} & w1;
assign wB = ({1'b0, step} & w2) << 1;
assign addr_RAM1 = {Mux2, wA | wB};
assign addr_RAM2 = {Mux2, wA | wB | w3};
wire [L-2:0] wROM; 
genvar i;
generate 
    for(i = 0; i < L-1; i=i+1) begin
        assign wROM[i] = w1[L-2 - i];
    end
endgenerate

assign addr_ROM = wROM & step;
endmodule