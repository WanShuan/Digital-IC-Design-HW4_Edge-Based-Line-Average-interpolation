`timescale 1ns/10ps
`define	CYCLE      19.0				// Modify your clock period here
`define	End_CYCLE  10000000			// Modify cycle times once your design need more cycle times!
`define	tb

`ifdef tb
	`define	PAT		"./img.dat"
	`define	EXP		"./golden.dat"
`endif

module TB_ELA;
    reg		[7:0]	pat_mem				[0:511];
    reg		[7:0]	exp_mem				[0:991];  
    reg		[7:0]	result_image_mem	[0:991];
    reg				clk;
    reg				rst;
    wire			req;
    reg		[7:0]	in_data;
    wire			wen;			// 0 read 1 write
    wire	[9:0]	addr;
    wire	[7:0]	data_wr;
    reg		[7:0]	data_rd;
	wire			done;
	reg				ready;
	reg				startInput;

    integer		p0, p1, p2;
    integer		err_odd, err_even_edge, err_even_middle;
    integer		i, j, pat_count;

    ELA u_ela(
        .clk(clk),
		.rst(rst),
		.req(req),
		.in_data(in_data),
        .wen(wen),
		.addr(addr),
        .data_wr(data_wr),
        .data_rd(data_rd),
        .done(done)
    );


	initial $readmemh (`PAT, pat_mem);
	initial $readmemh (`EXP, exp_mem);

	always begin
		#(`CYCLE/2) clk = ~clk;
	end

	initial begin
		#0;
		clk				= 1'b0;
		rst				= 1'b0;
		in_data			= 8'hzz;
		data_rd			= 8'hzz;
		err_odd			= 0;
		err_even_edge	= 0;
		err_even_middle	= 0;
		ready			= 1'b0;
		startInput		= 1'b0;

		i				= 0;
		j				= 0;
		pat_count		= 0;
	end

    initial begin
	    $display("----------------------------------------------------------------\n");
 	    $display("    START!!! Simulation Start .....\n");
 	    $display("----------------------------------------------------------------\n");
		 
		#1
		@(posedge clk)	rst = 1'b1;
		@(negedge clk) begin
			#(`CYCLE*1.25)
			rst = 1'b0;
		end
    end

	always @ (negedge clk) begin
		if(rst) ready = 1'b1;
	end

	always @ (*) begin
		if(ready) begin
			startInput = (req) ? 1'b1: (pat_count[4:0] == 0) ? 1'b0:1'b1;
		end
		else begin
			startInput = 1'b0;
		end
		
	end
    
    always @ (negedge clk) begin
		if(ready && !rst) begin
			if (startInput) begin
				in_data <= pat_mem[pat_count];
				pat_count <= pat_count + 1;
			end
			else begin
				in_data <= 8'hx;			
			end
		end
	end

	always @ (posedge clk) begin
		if (wen == 1) begin
			result_image_mem[addr] <= data_wr; 
	    end
    end
    always @ (negedge clk) begin
	    if (wen == 0) begin
			data_rd <= result_image_mem[addr] ;
	    end
    end

    
	initial begin
        #`End_CYCLE ;
 	    $display("----------------------------F A I L-----------------------------\n");
 	    $display("    Error!!!\n");
		$display("    The simulation can't be terminated under normal operation.\n");
		$display("    You can adjust End_CYCLE and try again.\n");
 	    $display("----------------------------------------------------------------\n");
 	    $finish;
    end


    initial begin
    	wait(done);
		for (i = 0; i < 31; i = i + 1) begin
			for(j = 0; j < 32; j = j + 1) begin
				if( result_image_mem[i*32+j] == exp_mem[i*32+j] ) begin
					err_odd = err_odd;
				end
				else begin
					$display("    error at (%2d, %2d), your result is %4h, expect %4h", i+1, j, result_image_mem[i*32+j], exp_mem[i*32+j]);
					if(i % 2 == 0) begin
						err_odd = err_odd + 1;
					end
					else if(j == 0 || j == 31) begin
						err_even_edge = err_even_edge + 1;
					end
					else begin
						err_even_middle = err_even_middle + 1;
					end
				end
			end
			
		end

		$display("\n");
		$display("------------------------S U M M A R Y---------------------------\n");
		if( err_odd==0 && err_even_edge==0 && err_even_middle==0) begin
			$display("    Congratulations!\n");
			$display("    Result image data are generated successfully!\n");
			$display("    The result is PASS!!!\n");			
		end
		else begin
			$display("    Result image is FAIL, there are %4d errors!!!\n", err_odd + err_even_edge + err_even_middle);
			$display("    ");
			if (err_odd == 0) $display("    odd field  : pass");
			else $display("    odd field  : fail, there are %4d errors.\n", err_odd);

			$display("    even field :");
			if (err_even_edge == 0) $display("        boundary part: pass");
			else $display("        boundary part: fail, there are %4d errors.", err_even_edge);

			if (err_even_middle == 0) $display("        middle part  : pass\n");
			else $display("        middle part  : fail, there are %4d errors.\n", err_even_middle);
		end
		$display("----------------------------------------------------------------\n");
			
		#(`CYCLE/2);
		$finish;

    end


endmodule