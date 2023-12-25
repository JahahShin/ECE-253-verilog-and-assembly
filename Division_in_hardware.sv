module part3(
input logic Clock,
input logic Reset,
input logic Go,
input logic [3:0] Divisor,
input logic [3:0] Dividend,
output logic [3:0] Quotient,
output logic [3:0] Remainder,
output logic ResultValid
);

// 1. Initialize the registers;
//N = # of bits is divided ? ? do we need it ?
// 2. Shift contents of AQ by one unit 
// A is 00000 register A, Divisior and put 0 at the most left side of divisor. 
// 3. Peform A = A - divisor 
// 4. If A > 0 LSB of q_0 = 1
// 	  else: LSB of q_0 = 0
// 5. Since there is 4 bits, this takes 4 times to do.. Just loop step 2 to 4 until N = 0; 
// 6. make output as Quotient and Remainder 

    // lots of wires to connect our datapath and control
    logic ld_a, ld_r;

    logic operate_func;
//	logic                        aluop_internal;

    control C0(
        .clk(Clock),
        .reset(Reset),

        .go(Go),
        
        .ld_a(ld_a),

        .ld_r(ld_r),

      //  .aluop_internal(aluop_internal),

        .operate_func(operate_func),
        .result_valid(ResultValid)
    );
	

    datapath D0(
        .clk(Clock),
        .reset(Reset),

	
        .ld_a(ld_a),

        .ld_r(ld_r),


       //.aluop_internal(aluop_internal),

		.Quotient(Quotient),
		.Remainder(Remainder),
		.Divisior(Divisor),
		.Dividend(Dividend),
		.operate_func(operate_func)
		
    );

 endmodule
 

 

module control(
    input logic clk,
    input logic reset,
    input logic go,

    output logic ld_a, ld_r,

   // output logic aluop_internal, 

	output logic operate_func,
    output logic result_valid
    );

    typedef enum logic [3:0]  { SLOAD_RST = 'd0,
                                S_LOAD = 'd1,
                                S_CYCLE_0 = 'd2,
                                S_CYCLE_1 = 'd3,
                                S_CYCLE_2 = 'd4,
                                S_CYCLE_3 = 'd5
								} statetype;
                                
    statetype current_state, next_state;                            

    // Next state logic aka our state table
    always_comb begin
        case (current_state)
            SLOAD_RST: next_state = go ? S_CYCLE_0 : SLOAD_RST; 
            S_LOAD: next_state = go ? S_CYCLE_0 : S_LOAD;     
            S_CYCLE_0: next_state = S_CYCLE_1;
            S_CYCLE_1: next_state = S_CYCLE_2;
			S_CYCLE_2: next_state = S_CYCLE_3;	
			S_CYCLE_3: next_state = S_LOAD;
            default:   next_state = SLOAD_RST;
        endcase
    end // state_table

    always_comb begin

		operate_func = 1'b0;
        ld_a = 1'b0;
        ld_r = 1'b0;
      //  aluop_internal       = 1'b0; 
        result_valid = 1'b0;


        case (current_state)
            SLOAD_RST: begin
                ld_a = 1'b1;
                end
            S_LOAD: begin
                ld_a = 1'b1;
                result_valid = 1'b1;
                end
            S_CYCLE_0: begin 
                operate_func = 1'b1;
            end
            S_CYCLE_1: begin
                operate_func = 1'b1;
            end
            S_CYCLE_2: begin
                operate_func = 1'b1;
            end
			S_CYCLE_3: begin
			ld_r = 1'b1;
            operate_func = 1'b1;
            end

        endcase
    end 

    always_ff@(posedge clk) begin
        if(reset)
            current_state <= SLOAD_RST;
        else
            current_state <= next_state;
    end 
endmodule


module datapath(
    input logic clk,
    input logic reset,
    input logic [3:0] Divisior,
	input logic [3:0] Dividend,
	
	input logic ld_a,
    input logic ld_r,
    //output logic aluop_internal,

	input logic operate_func, 
    output logic [3:0] Quotient, Remainder
    );
	
	

    logic [3:0] DIVIDENT;
    logic [4:0] register_A;
	logic [4:0] DIVISOR;
	logic [8:0] temp_AQ;
	logic [4:0] temp_A;
	logic [3:0] temp_Q;
	// reg aluop_internal;
	// logic aluop_internal;
    always@(posedge clk) begin
        if(reset) begin
            DIVIDENT <= 4'b0;
            DIVISOR <= 5'b0;
			// register_A <= 5'b0;
        end

        else begin 
		if(ld_a) begin 
			DIVIDENT <= Dividend; 
			DIVISOR <= {1'b0, Divisior}; // this is good. it cnoscates well... 
			register_A <= 5'b0;
        end
    end

end

 always @(posedge clk) begin
        if (reset) begin
            Remainder <= 4'b0;
            Quotient <= 4'b0;
        end 
		// my A currently storing -m divisor for some reason 
		else if (operate_func) begin
		temp_AQ = {register_A, DIVIDENT};
		temp_AQ = temp_AQ << 1;
		temp_A = temp_AQ[8:4];
		register_A = temp_A - DIVISOR;
		DIVIDENT = temp_AQ[3:0];
            if (register_A[4] == 1'b1) begin
                DIVIDENT[0] = 1'b0;
           //    aluop_internal = 1'b0; // performs addition A + DIVISOR 
		   register_A = temp_A;
            end else begin
                DIVIDENT[0] = 1'b1;
            end
			end
		if (ld_r) begin
        Quotient = DIVIDENT; 
        Remainder = register_A; 
    end
	end
	
	// aluop_internal = 1'b1; // temp A - DIVISOR 
	//register_A = register_A << 1; // shift of A by 1 bit 
            //register_A[0] = DIVIDENT[3];
            //DIVIDENT = DIVIDENT << 1; // shift of DIVIDEND 
            //aluop_internal = 1'b1; // do A - DIVISOR 

	//case (aluop_internal)
        //    0: temp_A <= temp_A + DIVISOR;
    //        1: temp_A <= temp_A - DIVISOR;
         //   default: temp_A <= 5'b0;
     //   endcase

endmodule
