`timescale 1ns/1ps

// Version A:
// Quadratic scale = 171798692 / 2^27
//                 = 1.280000001192...
// Exact scale     = 32 / 25 = 1.28

module freq_diff_estimator (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [15:0] T_est,
    input  wire signed [23:0] epsilon_aging,
    input  wire signed [15:0] TC1,
    input  wire signed [15:0] TC2,
    input  wire               update_en,
    output reg  signed [23:0] epsilon_RO,
    output reg                busy,
    output reg                done
);

    wire signed [15:0] dT;

    wire signed [31:0] term1_mul;
    wire signed [44:0] term1_ext;
    wire signed [44:0] term1_q23;

    wire signed [31:0] dT_sq;
    wire signed [47:0] term2_mul1;

    wire signed [77:0] term2_num;
    wire signed [78:0] term2_num_ext;
    wire signed [78:0] term2_rounded_num;
    wire signed [78:0] term2_div;
    wire signed [49:0] term2_q23;

    wire signed [50:0] total_q23;

    assign dT = T_est - 16'sd6400;

    assign term1_mul = dT * TC1;
    assign term1_ext = $signed({{13{term1_mul[31]}}, term1_mul});
    assign term1_q23 = term1_ext <<< 13;

    assign dT_sq = dT * dT;
    assign term2_mul1 = dT_sq * TC2;

    // term2_q23 = round(term2_mul1 * 171798692 / 2^27)
    assign term2_num = term2_mul1 * $signed(30'sd171798692);
    assign term2_num_ext = $signed({term2_num[77], term2_num});

    // Round to nearest before signed division.
    // 2^26 is half of the 2^27 denominator.
    assign term2_rounded_num = term2_num_ext[78]
                             ? term2_num_ext - 79'sd67108864
                             : term2_num_ext + 79'sd67108864;

    assign term2_div = term2_rounded_num / 79'sd134217728;
    assign term2_q23 = term2_div[49:0];

    assign total_q23 =
        $signed({{6{term1_q23[44]}}, term1_q23}) +
        $signed({term2_q23[49], term2_q23}) +
        $signed({{27{epsilon_aging[23]}}, epsilon_aging});

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            epsilon_RO <= 24'sd0;
            busy <= 1'b0;
            done <= 1'b0;
        end else if (update_en) begin
            if (total_q23 > 51'sd8388607)
                epsilon_RO <= 24'sd8388607;
            else if (total_q23 < -51'sd8388608)
                epsilon_RO <= -24'sd8388608;
            else
                epsilon_RO <= total_q23[23:0];

            busy <= 1'b1;
            done <= 1'b1;
        end else begin
            busy <= 1'b0;
            done <= 1'b0;
        end
    end

endmodule
