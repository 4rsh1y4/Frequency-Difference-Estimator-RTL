`timescale 1ns/1ps

//`define POSTSYN_SIM

`ifdef POSTSYN_SIM
   `include "/home/cad/TECH.D/TSMC180/Verilog/tsmc18.v"
`endif

module tb_freq_diff_estimator;

    reg clk;
    reg rst_n;
    reg signed [15:0] T_est;
    reg signed [23:0] epsilon_aging;
    reg signed [15:0] TC1;
    reg signed [15:0] TC2;
    reg update_en;

    wire signed [23:0] epsilon_RO;
    wire busy;
    wire done;

    reg printOut;
    reg pass;

    integer test_count;
    integer fail_count;
    integer max_diff;
    integer worst_expected;
    integer worst_actual;

    reg signed [15:0] worst_t;
    reg signed [15:0] worst_tc1;
    reg signed [15:0] worst_tc2;
    reg signed [23:0] worst_age;

    `ifdef POSTSYN_SIM
        localparam integer NUM_RANDOM_TESTS = 1000;
    `else
        localparam integer NUM_RANDOM_TESTS = 1000000;
    `endif

    `ifdef POSTSYN_SIM
        freq_diff_estimator uut_postsyn (
            .clk(clk), .rst_n(rst_n), .T_est(T_est), .epsilon_aging(epsilon_aging),
            .TC1(TC1), .TC2(TC2), .update_en(update_en),
            .epsilon_RO(epsilon_RO), .busy(busy), .done(done)
        );
    `else
        freq_diff_estimator uut_func (
            .clk(clk), .rst_n(rst_n), .T_est(T_est), .epsilon_aging(epsilon_aging),
            .TC1(TC1), .TC2(TC2), .update_en(update_en),
            .epsilon_RO(epsilon_RO), .busy(busy), .done(done)
        );
    `endif

    // Exact period for 131.072 kHz:
    // T = 1 / 131072 Hz = 7629.39453125 ns
    localparam real CLK_HALF_PERIOD = 3814.697265625;
    localparam real CLK_PERIOD = 7629.394531250;

    initial begin
        clk = 0;
        forever #(CLK_HALF_PERIOD) clk = ~clk;
    end

    function integer compute_epsilon_RO_golden;
        input signed [15:0] T_est_q8;
        input signed [15:0] TC1_in;
        input signed [15:0] TC2_in;
        input signed [23:0] eps_aging_q23;

        real T;
        real TC1_real;
        real TC2_real;
        real eps_aging;
        real eps;
        real eps_q23_real;

        begin
            T = T_est_q8 / 256.0;
            TC1_real = TC1_in * 0.25;
            TC2_real = TC2_in * 0.01;
            eps_aging = eps_aging_q23 / 8388608.0;

            eps = (TC1_real * (T - 25.0))
                + (TC2_real * (T - 25.0) * (T - 25.0))
                + eps_aging;

            eps_q23_real = eps * 8388608.0;

            if (eps_q23_real > 8388607.0)
                eps_q23_real = 8388607.0;
            else if (eps_q23_real < -8388608.0)
                eps_q23_real = -8388608.0;

            if (eps_q23_real >= 0)
                compute_epsilon_RO_golden = $rtoi(eps_q23_real + 0.5);
            else
                compute_epsilon_RO_golden = $rtoi(eps_q23_real - 0.5);
        end
    endfunction

    task record_failure;
        input [1023:0] message;
        begin
            $display("FAIL | %0s", message);
            pass = 0;
            fail_count = fail_count + 1;
        end
    endtask

    task check_vector;
        input signed [15:0] t_in;
        input signed [15:0] tc1_in;
        input signed [15:0] tc2_in;
        input signed [23:0] aging_in;

        integer expected_val;
        integer actual_val;
        integer diff;
        reg signed [23:0] pre_update_RO;

        begin
            test_count = test_count + 1;

            T_est = t_in;
            TC1 = tc1_in;
            TC2 = tc2_in;
            epsilon_aging = aging_in;

            pre_update_RO = epsilon_RO;
            @(posedge clk);
            #1;

            if (epsilon_RO !== pre_update_RO) begin
                $display("FAIL | Output changed without an update_en pulse.");
                pass = 0;
                fail_count = fail_count + 1;
            end

            update_en = 1'b1;
            @(posedge clk);
            #1;

            if (busy !== 1'b1 || done !== 1'b1) begin
                $display("FAIL | Handshake signals busy/done failed to assert.");
                pass = 0;
                fail_count = fail_count + 1;
            end

            update_en = 1'b0;
            @(posedge clk);
            #1;

            if (busy !== 1'b0 || done !== 1'b0) begin
                $display("FAIL | Handshake signals busy/done failed to clear.");
                pass = 0;
                fail_count = fail_count + 1;
            end

            expected_val = compute_epsilon_RO_golden(t_in, tc1_in, tc2_in, aging_in);

            actual_val = $signed(epsilon_RO);
            diff = actual_val - expected_val;

            if (diff < 0)
                diff = -diff;

            if (diff > max_diff) begin
                max_diff = diff;
                worst_t = t_in;
                worst_tc1 = tc1_in;
                worst_tc2 = tc2_in;
                worst_age = aging_in;
                worst_expected = expected_val;
                worst_actual = actual_val;
            end

            if (diff > 168) begin
                $display("FAIL | T:%h TC1:%h TC2:%h Age:%h | RTL:%0d Gold:%0d | Diff:%0d LSBs",
                         t_in, tc1_in, tc2_in, aging_in, actual_val, expected_val, diff);
                pass = 0;
                fail_count = fail_count + 1;
            end else if (printOut) begin
                $display("PASS | T:%h TC1:%h TC2:%h Age:%h | Diff:%0d LSBs",
                         t_in, tc1_in, tc2_in, aging_in, diff);
            end
        end
    endtask

    reg signed [15:0] temps [0:2];
    reg signed [15:0] tc1_vals [0:2];
    reg signed [15:0] tc2_vals [0:2];
    reg signed [23:0] aging_vals [0:2];

    reg signed [15:0] rand_t;
    reg signed [15:0] rand_tc1;
    reg signed [15:0] rand_tc2;
    reg signed [23:0] rand_age;

    integer i;
    integer j;
    integer k;
    integer m;

    initial begin
        `ifdef SDF_SIM
            $display("--- Simulation Mode: vC Post-Synthesis with MAXIMUM SDF ---");
            $sdf_annotate(
                "./synthesis/synout_vC/freq_diff_estimator_vC_postsyn.sdf",
                uut_postsyn, , , "MAXIMUM"
            );
        `elsif POSTSYN_SIM
            $display("--- Simulation Mode: vC Post-Synthesis Zero-Delay ---");
        `else
            $display("--- Simulation Mode: vC RTL Functional ---");
        `endif

        rst_n = 0;
        T_est = 0;
        epsilon_aging = 0;
        TC1 = 0;
        TC2 = 0;
        update_en = 0;
        printOut = 1;
        pass = 1;

        test_count = 0;
        fail_count = 0;
        max_diff = 0;
        worst_expected = 0;
        worst_actual = 0;
        worst_t = 0;
        worst_tc1 = 0;
        worst_tc2 = 0;
        worst_age = 0;

        $display("==================================================");
        $display("--- Frequency Difference Estimator Verification ---");

        $display("\n--- Power-on Reset Initialization ---");
        #(CLK_PERIOD * 2);

        if (epsilon_RO !== 24'sd0 || busy !== 1'b0 || done !== 1'b0) begin
            $display("FAIL | Reset failed to clear the registers.");
            pass = 0;
            fail_count = fail_count + 1;
        end else begin
            $display("PASS | Registers successfully cleared on boot.");
        end

        rst_n = 1;
        #(CLK_PERIOD);

        $display("\n--- Testing Specific Operating Points ---");
        check_vector(16'h1900, 16'h0000, 16'h0000, 24'h000000);
        check_vector(16'h1900, 16'h0010, 16'h0000, 24'h000000);
        check_vector(16'h1A00, 16'hFFF0, 16'h0000, 24'h000000);
        check_vector(16'h1900, 16'h0000, 16'h0001, 24'h000000);
        check_vector(16'h1A00, 16'h0000, 16'h0001, 24'h000000);

        $display("\n--- Verifying Aging Offset Injection ---");
        check_vector(16'h1900, 16'h0000, 16'h0000, 24'sd4194);

        $display("\n--- Testing Exhaustive Boundary Corners ---");

        temps[0] = 16'hD800; // -40 C
        temps[1] = 16'h1900; //  25 C
        temps[2] = 16'h5500; //  85 C

        tc1_vals[0] = 16'h8000;
        tc1_vals[1] = 16'h0000;
        tc1_vals[2] = 16'h7FFF;

        tc2_vals[0] = 16'h8000;
        tc2_vals[1] = 16'h0000;
        tc2_vals[2] = 16'h7FFF;

        aging_vals[0] = -24'sd4194;
        aging_vals[1] = 24'sd0;
        aging_vals[2] = 24'sd4194;

        for (i = 0; i < 3; i = i + 1)
            for (j = 0; j < 3; j = j + 1)
                for (k = 0; k < 3; k = k + 1)
                    for (m = 0; m < 3; m = m + 1)
                        check_vector(temps[i], tc1_vals[j], tc2_vals[k], aging_vals[m]);

        $display("\n--- Verifying Clipping Limits ---");

        // Positive saturation at +85 C
        check_vector(16'h5500, 16'h7FFF, 16'h7FFF, 24'sd4194);

        // Negative saturation at +85 C
        check_vector(16'h5500, 16'h8000, 16'h8000, -24'sd4194);

        $display("\n--- Running %0d Constrained-Random Test Vectors ---", NUM_RANDOM_TESTS);
        $display("PASS logs are suppressed for speed; failures remain visible.");

        printOut = 0;

        for (i = 0; i < NUM_RANDOM_TESTS; i = i + 1) begin
            // T_est constrained to -40 C through +85 C in Q8.8.
            rand_t = -10240 + ($unsigned($random) % 32001);

            // Full signed input range for both coefficients.
            rand_tc1 = $random;
            rand_tc2 = $random;

            // epsilon_aging constrained to approximately +/-500 ppm.
            rand_age = -4194 + ($unsigned($random) % 8389);

            check_vector(rand_t, rand_tc1, rand_tc2, rand_age);
        end
	$display("\n--- Testing Previously Detected Cancellation Cases ---");

	check_vector(16'he104, 16'habe0, 16'hda6f, 24'hfffb27);
	check_vector(16'h0e00, 16'h34ac, 16'h77b5, 24'h0002db);
	check_vector(16'h2f63, 16'he34b, 16'h200f, 24'hfffa1f);
	check_vector(16'h342a, 16'h7d20, 16'h8cd8, 24'h000cde);
	check_vector(16'hfdbd, 16'hd134, 16'hd516, 24'hfffdc8);
	check_vector(16'h058a, 16'h349a, 16'h4393, 24'hfff6cb);
	check_vector(16'heecb, 16'h863f, 16'hb7e2, 24'hfffe2a);
	check_vector(16'h3392, 16'hcbdc, 16'h310f, 24'h000ee5);


        $display("\n---------------- Verification Summary ----------------");
        $display("Checked vectors             : %0d", test_count);
        $display("Recorded failures           : %0d", fail_count);
        $display("Maximum numerical difference: %0d LSBs", max_diff);
        $display("Worst vector: T=%h TC1=%h TC2=%h Age=%h",
                 worst_t, worst_tc1, worst_tc2, worst_age);
        $display("Worst result: RTL=%0d Golden=%0d", worst_actual, worst_expected);
        $display("Maximum equivalent error    : %0.6f ppm",
                 max_diff * 1000000.0 / 8388608.0);

        if (pass)
            $display("FINAL RESULT: PASS -- no check exceeded 20 ppm.");
        else
            $display("FINAL RESULT: FAIL -- one or more checks failed.");

        $display("==================================================");
        $finish;
    end

endmodule