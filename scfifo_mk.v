module scfifo_mk (clk, rst_n, in_data, out_data, full, empty, wen, rready);
    //defining parameters
    parameter DATA_WIDTH = 64;
    parameter FIFO_DEPTH = 8;
    localparam POINTER_WIDTH = $clog2(FIFO_DEPTH);
    //declaring inputs
    input clk, rst_n, wen, rready;
    input [DATA_WIDTH-1:0] in_data;
    //declaring outputs
    output wire [DATA_WIDTH-1:0] out_data;
    output full, empty;
    //placeholders
    reg [DATA_WIDTH-1:0] out_data_reg;
    //defining FIFO
    reg [DATA_WIDTH-1:0] sc_fifo [FIFO_DEPTH-1:0];
    //pointers
    wire [POINTER_WIDTH-1:0] used_wr_ptr, used_rd_ptr;
    reg [POINTER_WIDTH:0] rd_ptr;
    reg [POINTER_WIDTH:0] wr_ptr;
    //flags
    wire wready, rvalid;
    //init
    integer i;
    initial begin
        for (i=0; i<FIFO_DEPTH; i=i+1)begin
            sc_fifo[i]=0;
        end
    end
    //reading operation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_data_reg<=0;
        end
        else begin
            out_data_reg<=sc_fifo[used_rd_ptr];
        end   
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rd_ptr<=0;
        end
        else begin
            if(rvalid) begin
                if(rd_ptr [POINTER_WIDTH-1:0]== FIFO_DEPTH-1) begin
                    rd_ptr<={!rd_ptr[POINTER_WIDTH] , {(POINTER_WIDTH){1'b0}}};
                end
                else begin
                    rd_ptr<=rd_ptr+1;
                end
            end
        end
    end
    //write operation
    always @(posedge clk) begin
        if(wready) begin
            sc_fifo[used_wr_ptr] <= in_data;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wr_ptr<=0;
        end
        else begin
            if(wready) begin
                if(wr_ptr [POINTER_WIDTH-1:0]== FIFO_DEPTH-1) begin
                    wr_ptr<={!wr_ptr[POINTER_WIDTH] , {(POINTER_WIDTH){1'b0}}};
                end
                else begin
                    wr_ptr<=wr_ptr+1;
                end
            end     
        end
    end
    //wire assignments
    assign used_wr_ptr = wr_ptr[POINTER_WIDTH-1:0];
    assign used_rd_ptr = rd_ptr[POINTER_WIDTH-1:0];
    assign rvalid = rready && !empty;
    assign wready = wen && !full;
    assign empty = (wr_ptr==rd_ptr) ? 1'b1 : 1'b0;
    assign full =  ((wr_ptr[POINTER_WIDTH]^rd_ptr[POINTER_WIDTH]) && (wr_ptr[POINTER_WIDTH-1:0]==rd_ptr[POINTER_WIDTH-1:0])) ? 1'b1 : 1'b0;
    assign out_data = out_data_reg;
endmodule //scfifo_mk