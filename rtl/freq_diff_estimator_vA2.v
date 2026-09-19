`timescale 1ns/1ps

// Version A: high-resolution power-of-two approximation
//
// Exact quadratic scale:
//     32 / 25 = 1.28
//
// Implemented approximation:
//     43980465111 / 2^35
//     = 1.2799999999988358...
//
// The approximation error is small enough to avoid the cancellation-sensitive
// failures observed with 171798692 / 2^27.

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

    wire signed [84:0] term2_num;
    wire signed [85:0] term2_num_ext;
    wire signed [85:0] term2_rounded_num;
    wire signed [85:0] term2_div;
    wire signed [49:0] term2_q23;

    wire signed [50:0] total_q23;

    // T_est is Q8.8 and 25 degrees C is 25 * 256 = 6400.
    // Over the DRS temperature range of -40 C to +85 C,
    // dT ranges from -16640 to +15360 and fits in 16 signed bits.
    assign dT = T_est - 16'sd6400;

    // Linear term:
    // TC1 * dT * 2^13
    assign term1_mul = dT * TC1;
    assign term1_ext = $signed({{13{term1_mul[31]}}, term1_mul});
    assign term1_q23 = term1_ext <<< 13;

    // Quadratic base product:
    // TC2 * dT^2
    assign dT_sq = dT * dT;
    assign term2_mul1 = dT_sq * TC2;

    // High-resolution quadratic scaling:
    // round(term2_mul1 * 43980465111 / 2^35)
    assign term2_num = term2_mul1 * $signed(37'sd43980465111);
    assign term2_num_ext = $signed({term2_num[84], term2_num});

    // Round to nearest before signed division.
    // Half of 2^35 is 2^34 = 17179869184.
    assign term2_rounded_num = term2_num_ext[85]
                             ? term2_num_ext - 86'sd17179869184
                             : term2_num_ext + 86'sd17179869184;

    assign term2_div = term2_rounded_num / 86'sd34359738368;
    assign term2_q23 = term2_div[49:0];

    // Signed Q1.23 accumulation.
    assign total_q23 =
        $signed({{6{term1_q23[44]}}, term1_q23}) +
        $signed({term2_q23[49], term2_q23}) +
        $signed({{27{epsilon_aging[23]}}, epsilon_aging});

    // Output register, saturation and handshake.
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
