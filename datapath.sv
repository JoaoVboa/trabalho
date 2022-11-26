module datapath
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    input  logic                    branch,
    input  logic                    pc_enable,
    input  logic                    ir_enable,
    input  logic                    addr_sel,
    input  logic                    c_sel,
    input  logic              [1:0] operation,
    input  logic                    write_reg_enable,
    input  logic                    flags_reg_enable,
    output decoded_instruction_type decoded_instruction,
    output logic                    zero_op,
    output logic                    neg_op,
    output logic                    unsigned_overflow,
    output logic                    signed_overflow,
    output logic              [4:0] ram_addr,
    output logic             [15:0] data_out,
    input  logic             [15:0] data_in
);

logic [15:0] bus_a;
logic [15:0] bus_b;
logic [15:0] bus_c;
logic [15:0] alu_out;
logic [1:0] a_addr;
logic [1:0] b_addr;
logic [1:0] c_addr;
logic [4:0] mem_addr;
logic [4:0] program_counter;
logic [15:0] instruction;
logic zero_f;
logic neg_f;
logic ov_f;
logic sov_f;
logic carry_in_ultimo;

logic [15:0] banco_reg[4]; // banco de registradores

always_ff @(posedge clk) begin
    if(ir_enable)
    instruction <= data_in;    
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    program_counter = 'd0;
    end
    else if(pc_enable) begin
        if(branch)
        program_counter <= mem_addr;
        else
        program_counter <= program_counter + 1;
    end
end

always_comb begin
    case (operation)
    2'b00: begin
        {carry_in_ultimo,alu_out[14:0]} = bus_a[14:0] + bus_b[14:0];
        {sov_f,alu_out[15]} = bus_a[15] + bus_b[15] + carry_in_ultimo;
        sov_f = ov_f ^ carry_in_ultimo;
    end
    2'b01: begin
        alu_out = bus_a & bus_b;
        ov_f = 1'b0;
        sov_f = 1'b0;
        carry_in_ultimo = 1'b0;
    end
    2'b10: begin  
        alu_out = bus_a | bus_b;
        ov_f = 1'b0;
        sov_f = 1'b0;
        carry_in_ultimo = 1'b0;  
    end
    2'b11 : begin
        bus_b = (~bus_b);
        bus_b = bus_b + 1;
        {carry_in_ultimo,alu_out[14:0]} = bus_a[14:0] + bus_b[14:0];
        {sov_f,alu_out[15]} = bus_a[15] + bus_b[15] + carry_in_ultimo;
        sov_f = ov_f ^ carry_in_ultimo;
    end 
    endcase
end

assign zero_f = ~|(alu_out);
assign neg_f = alu_out[15];

always_comb begin
    a_addr = 'd0;
    b_addr = 'd0;
    c_addr = 'd0;
    mem_addr = 'd0;
    case(instruction[15:8])
    8'b1000_0001 : begin //load
    decoded_instruction = I_LOAD;
    c_addr = instruction[6:5];
    mem_addr = instruction[4:0];
    end
    8'b1000_0010 : begin //store
    decoded_instruction = I_STORE;
    a_addr = instruction[6:5];
    mem_addr = instruction[4:0];
    end
    8'b1001_0001 : begin //move
    decoded_instruction = I_MOVE;
    c_addr = instruction[3:2];
    a_addr = instruction[1:0];
    b_addr = instruction[1:0];
    end
    8'b1010_0001 : begin //add
    decoded_instruction = I_ADD;
    a_addr = instruction[1:0];
    b_addr = instruction[3:2];
    c_addr = instruction[5:4];
    end
    8'b1010_0010 : begin //sub
    decoded_instruction = I_SUB;
    a_addr = instruction[1:0];
    b_addr = instruction[3:2];
    c_addr = instruction[5:4];
    end
    8'b1010_0011 : begin //and
    decoded_instruction = I_AND;
    a_addr = instruction[1:0];
    b_addr = instruction[3:2];
    c_addr = instruction[5:4];
    end
    8'b1010_0100 : begin //or
    decoded_instruction = I_OR;
    a_addr = instruction[1:0];
    b_addr = instruction[3:2];
    c_addr = instruction[5:4];
    end
    8'b0000_0001 : begin //branch
    decoded_instruction = I_BRANCH;
    mem_addr = instruction[4:0];
    end
    8'b0000_0010 : begin //bzero
    decoded_instruction = I_BZERO;
    mem_addr = instruction[4:0];
    end
    8'b0000_0011 : begin //bneg
    decoded_instruction = I_BNEG;
    mem_addr = instruction[4:0];
    end
    8'b0000_0101 : begin //bov
    decoded_instruction = I_BOV;
    mem_addr = instruction[4:0];
    end
    8'b0000_0110 : begin //bnov
    decoded_instruction = I_BNOV;
    mem_addr = instruction[4:0];
    end
    8'b0000_1010 : begin //bnneg
    decoded_instruction = I_BNNEG;
    mem_addr = instruction[4:0];
    end
    8'b0000_1011 : begin //bnzero
    decoded_instruction = I_BNZERO;
    mem_addr = instruction[4:0];
    end
    8'b1111_1111 : begin //halt
    decoded_instruction = I_HALT;
    end
    default : begin // nop
    decoded_instruction = I_NOP;
    end
    endcase
end

assign bus_a = banco_reg[a_addr];
assign bus_b = banco_reg[b_addr];

assign bus_c = (c_sel?data_in:alu_out);

always_ff @(posedge clk) begin
if(write_reg_enable) 
 banco_reg[c_addr] = bus_c;
end

assign ram_addr = (addr_sel?program_counter:mem_addr);

endmodule