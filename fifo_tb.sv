module fifotb;
    parameter DATA_WIDTH = 64;
    parameter FIFO_DEPTH = 8;
    bit clk;
    logic rst_n, wen, rready;
    logic [DATA_WIDTH-1:0] in_data;
    logic [DATA_WIDTH-1:0] out_data;
    logic full, empty;
    int crr_count=0, err_count=0, reads=0, writes=0;

    scfifo_mk DUT (.*);
    initial begin
        forever begin
            #1; clk=~clk;
        end
    end

    initial begin
        rst_n = 0;
        in_data=$random;
        repeat(10) begin
            @(negedge clk);
            if(out_data) begin
                err_count++;
            end
            else begin
                crr_count++;
            end
        end
        rst_n = 1;
        in_data=$random;
        repeat(100) begin
            @(negedge clk);
            constr1(wen, 80);
            in_data=$random;
            rready=0;
        end
        wen = 0;
        repeat(100) begin
            @(negedge clk);
            constr2(rready, 80);
            in_data=$random;
            wen=0;
        end
        repeat(100) begin
            @(negedge clk);
            wen = $random;
            rready = $random;
            in_data=$random;
        end
        $stop;
    end

    task constr1 (output inp_sig , input percent);
        static int count=0, not_count=0;
        if(count/(count+not_count)*100 < percent) begin
            inp_sig = 1;
            count++;
        end
        else begin
            inp_sig = 0;
            not_count++;
        end
    endtask

    task constr2 (output inp_sig , input percent);
        static int count=0, not_count=0;
        if(count/(count+not_count)*100 < percent) begin
            inp_sig = 1;
            count++;
        end
        else begin
            inp_sig = 0;
            not_count++;
        end
    endtask

    always_ff @(posedge clk) begin 
        if(wen && !DUT.full) begin
            writes<=writes+1;
        end 
        if(rready && !DUT.empty) begin
            reads<=reads+1;
        end
    end

    always_ff @(posedge clk) begin
        if(reads == writes && !DUT.empty) begin
            err_count++;
        end
        else begin
            crr_count++;
        end
        if(writes-reads==FIFO_DEPTH && !DUT.full) begin
            err_count++;
        end
        else begin
            crr_count++;
        end
    end


endmodule