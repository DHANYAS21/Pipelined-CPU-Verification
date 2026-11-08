module processor (
    input  [31:0] instruction,
    output reg [31:0] immediate
);

    always @(*) begin
        case (instruction[6:0])

            // I-type: ADDI, LW
            7'b0010011,
            7'b0000011: begin
                immediate = {{20{instruction[31]}},
                             instruction[31:20]};
            end

            // S-type: SW
            7'b0100011: begin
                immediate = {{20{instruction[31]}},
                             instruction[31:25],
                             instruction[11:7]};
            end

            default: begin
                immediate = 32'b0;
            end

        endcase
    end

endmodule