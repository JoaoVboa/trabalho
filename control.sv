module control_unit
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    output logic                    branch,
    output logic                    pc_enable,
    output logic                    ir_enable,
    output logic                    write_reg_enable,
    output logic                    addr_sel,
    output logic                    c_sel,
    output logic              [1:0] operation,
    output logic                    flags_reg_enable,
    input  decoded_instruction_type decoded_instruction,
    input  logic                    zero_op,
    input  logic                    neg_op,
    input  logic                    unsigned_overflow,
    input  logic                    signed_overflow,
    output logic                    ram_write_enable,
    output logic                    halt
);

typedef enum {  
BUSCA_INSTR,
REG_INTR,
DECODIFICA,
FIM_PROGRAMA,
LOAD_1,
LOAD_2,
STORE,
STORE_1,
MOVE,
ADD,
OR,
AND,
SUB,
BRANCH,
BZERO,
BNEG,
BOV,
BNOV,
BNNEG,
BNZERO
}state_t;

state_t state;
state_t next_state;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    state <= BUSCA_INSTR;
    else
    state <= next_state;
end

always_comb begin
branch = 1'b0;
pc_enable = 1'b0;
ir_enable = 1'b0;
write_reg_enable = 1'b0;
addr_sel = 1'b0;
c_sel = 2'b0;
operation = 1'b0;
flags_reg_enable = 1'b0;
ram_write_enable = 1'b0;
halt = 1'b0;

    case(state)

    REG_INTR: begin
        next_state = BUSCA_INSTR;
    end
    BUSCA_INSTR : begin
    next_state = DECODIFICA;
    ir_enable = 1'b1;
    pc_enable = 1'b1;
    end
    DECODIFICA : begin
    next_state = BUSCA_INSTR;
    if(decoded_instruction == I_HALT)
    next_state = FIM_PROGRAMA;
    else if(decoded_instruction == LOAD_1) begin
    next_state = LOAD_1;
    addr_sel = 1'b1;
    end
    else if(decoded_instruction == I_STORE) begin
        next_state = STORE
        addr_sel = 1'b1;
    end
    else if(decoded_instruction == I_MOVE) begin
        next_state = MOVE
    end
    else if(decoded_instruction == I_ADD) begin
        next_state = ADD;
    end
    else if(decoded_instruction == I_AND) begin
        next_state = AND;
    end
    else if(decoded_instruction == I_OR) begin
        next_state = OR;
    end
    else if(decoded_instruction == I_SUB) begin
        next_state = SUB;
    end
    else if(decoded_instruction == I_BRANCH) begin
        next_state = BRANCH;
        branch = 1'b1;
    end
     else if(decoded_instruction == I_BZERO) begin
        next_state = BZERO;
        branch = 1'b1;
    end
      else if(decoded_instruction == I_BOV) begin
        next_state = BOV;
        branch = 1'b1;
    end
      else if(decoded_instruction == I_BNOV) begin
        next_state = BNOV;
        branch = 1'b1;
    end
      else if(decoded_instruction == I_BNNEG) begin
        next_state = BNNEG;
        branch = 1'b1;
    end
      else if(decoded_instruction == I_BNZERO) begin
        next_state = BNZERO;
        branch = 1'b1;
    end
    end

    LOAD_1: begin
        next_state = LOAD_2;
        addr_sel = 1'b1;
        c_sel = 1'b1;
    end

    LOAD_2: begin
        next_state = BUSCA_INSTR;
        addr_sel = 1'b1;
        c_sel = 1'b1;
        write_reg_enable = 1'b1;
    end

    STORE: begin
        next_state = BUSCA_INSTR;
        ir_enable = 1'b1;
    end

    STORE_1: begin
        next_state = BUSCA_INSTR;
        ir_enable = 1'b1;
        ram_write_enable = 1'b1;
    end

    MOVE: begin
        next_state = BUSCA_INSTR;
        operation = 2'b10;
        write_reg_enable = 1'b1;
    end

    ADD: begin
    next_state = BUSCA_INSTR;
    operation = 2'b00;
    write_reg_enable = 1'b1;
    flags_reg_enable = 1'b1;
    c_sel = 1'b1;
    end

    AND: begin
    next_state = BUSCA_INSTR;
    operation = 2'b01;
    write_reg_enable = 1'b1;
    flags_reg_enable = 1'b1;
    c_sel = 1'b1;
    end

    OR: begin
    next_state = BUSCA_INSTR;
    operation = 2'b10;
    write_reg_enable = 1'b1;
    flags_reg_enable = 1'b1;
    c_sel = 1'b1;
    end

    SUB: begin
    next_state = BUSCA_INSTR;
    operation = 2'b00;
    write_reg_enable = 1'b1;
    flags_reg_enable = 1'b1;
    c_sel = 1'b1;
    end

    BRANCH : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BZERO : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BNEG : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BOV : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BNOV : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BNNEG : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    BNZERO : begin
        next_state = BUSCA_INSTR;
        pc_enable = 1'b1;
    end

    FIM_PROGRAMA: begin
        next_state = FIM_PROGRAMA;
        halt = 1'b1;
    end
    endcase
end

endmodule : control_unit