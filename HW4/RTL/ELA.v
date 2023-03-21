`timescale 1ns/10ps

module ELA(clk, rst, in_data, data_rd, req, wen, addr, data_wr, done);

input				clk;
input				rst;
input		[7:0]	in_data;
input		[7:0]	data_rd;
output	reg			req;
output	reg			wen;
output	reg	[9:0]	addr;
output	reg	[7:0]	data_wr;
output	reg			done;

reg 		[1:0] 	current_state;
reg 		[1:0] 	next_state;
reg 		[3:0]	row_counter;
reg 		[4:0]	column_counter;
reg			[7:0]	image_buffer_row_one[31:0];
reg			[7:0]	image_buffer_row_two[31:0];
reg			[1:0]	min_direction;
reg			[7:0]	distance[2:0];
reg					finish;

parameter [1:0] REQUEST=0, Interpolation=1, MIN=2, WRITE=3;

always@(posedge clk or posedge rst) begin
    if(rst) begin
	    current_state <= REQUEST;
	end
	else begin
	    current_state <= next_state;
	end
end

always@(*) begin
    case(current_state)
	    REQUEST: 
		    next_state = (row_counter >= 1 && column_counter == 31)? Interpolation : REQUEST;
		Interpolation: 
		   next_state = MIN;
		MIN:
			next_state = WRITE;
		WRITE:
		    next_state = (row_counter >= 1 && column_counter == 31)? REQUEST : Interpolation;
	endcase
end

always@(posedge clk or posedge rst) begin
	if(rst) begin
		row_counter <= 4'b0;
		column_counter <= 5'b0;
		req <= 1'b0;
		wen <= 1'b0;
		addr <= 10'b0;
		data_wr <= 10'b0;
		done <= 1'b0;
		distance[0] <= 255;
		distance[1] <= 255;
		distance[2] <= 255;
		min_direction <= 0;
	end
	else begin
		case(current_state)
			REQUEST: begin
				req <= (column_counter == 0)? 1 : 0; //&& row_counter <= 15
				row_counter <= (column_counter == 31)? row_counter+1 : row_counter;
				column_counter <= (req == 1 || column_counter != 0)? column_counter+1 : column_counter;
				wen <= (req == 1 || column_counter != 0)? 1 : 0;
				addr <= row_counter*64 + column_counter;
				data_wr <= in_data;
				image_buffer_row_one[column_counter] <= (row_counter == 0)? in_data : (row_counter == 1)? image_buffer_row_one[column_counter] : image_buffer_row_two[column_counter];
				image_buffer_row_two[column_counter] <= in_data;
			end
			Interpolation: begin
				if(column_counter == 0 || column_counter == 31) begin
					distance[1] <= (image_buffer_row_one[column_counter] > image_buffer_row_two[column_counter])? 
									image_buffer_row_one[column_counter] - image_buffer_row_two[column_counter] : image_buffer_row_two[column_counter] - image_buffer_row_one[column_counter];
				end
				else begin
					distance[0] <= (image_buffer_row_one[column_counter-1] > image_buffer_row_two[column_counter+1])? 
									image_buffer_row_one[column_counter-1] - image_buffer_row_two[column_counter+1] : image_buffer_row_two[column_counter+1] - image_buffer_row_one[column_counter-1];
					distance[1] <= (image_buffer_row_one[column_counter] > image_buffer_row_two[column_counter])? 
									image_buffer_row_one[column_counter] - image_buffer_row_two[column_counter] : image_buffer_row_two[column_counter] - image_buffer_row_one[column_counter];
					distance[2] <= (image_buffer_row_one[column_counter+1] > image_buffer_row_two[column_counter-1])? 
									image_buffer_row_one[column_counter+1] - image_buffer_row_two[column_counter-1] : image_buffer_row_two[column_counter-1] - image_buffer_row_one[column_counter+1];
				end	
				done <= (finish == 1)? 1 : 0;
			end
			MIN: begin
				min_direction <= (distance[0] <= distance[2])? (distance[1] <= distance[0])? 2 : 1 : (distance[1] <= distance[2])? 2 : 3;
			end
			WRITE: begin
				wen <= 1;
				addr <= row_counter*64 - 96 + column_counter;
				case(min_direction)
					1: data_wr <= (image_buffer_row_one[column_counter-1] + image_buffer_row_two[column_counter+1]) / 2;
					2: data_wr <= (image_buffer_row_one[column_counter] + image_buffer_row_two[column_counter]) / 2;
					3: data_wr <= (image_buffer_row_one[column_counter+1] + image_buffer_row_two[column_counter-1]) / 2;
				endcase
				column_counter <= (column_counter == 31)? 0 : column_counter+1;
				finish <= (row_counter == 0 && column_counter == 31)? 1 : 0;
				req <= (column_counter == 31)? 1 : 0;
				distance[0] <= 255;
				distance[1] <= 255;
				distance[2] <= 255;
			end
		endcase
	end
end

endmodule