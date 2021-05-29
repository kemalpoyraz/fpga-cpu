`timescale 1ns / 1ps
module SimpleCPU(clk, rst, data_fromRAM, wrEn, addr_toRAM, data_toRAM);

parameter SIZE = 10;

input clk, rst;
input wire [31:0] data_fromRAM;
output reg wrEn;
output reg [SIZE-1:0] addr_toRAM;
output reg [31:0] data_toRAM;

//input wire [31:0] data_fromRAM;
reg [SIZE-1:0] addr_toRAM_next;
reg [31:0] data_toRAM_next;
reg wrEn_next;

`define STATE0 0
`define STATE1 1
`define STATE2 2
`define STATE3 3
`define STATE4 4
`define STATE5 5
`define STATE6 6

reg [7:0] currentState, nextState;
reg [SIZE-1:0] pc, pcNext; //pc: program counter
reg [31:0] instructionWord, instructionWordNext;
reg [31:0] regA, regANext;
reg [31:0] regB, regBNext;

wire enable;
reg [24:0] slowdown;
always@(posedge clk) begin
	if (rst == 1'b1 || slowdown == 25'd390000 )
		slowdown <= 25'd0;
	else
		slowdown <= slowdown  + 1'b1;
	end
	
	assign enable = (slowdown== 25'd390000 )? 1:0;
	
//current state logic
always@(posedge clk) begin
	if(rst) begin
		currentState <= `STATE0;
		pc <= 0;
		instructionWord <= 0;
		regA <= 0;
		regB <= 0;
		addr_toRAM<=0;
		data_toRAM<=0;
		wrEn<=0;
	end
	else begin
		if (enable) begin
		currentState <= nextState;
		pc <= pcNext;
		instructionWord <= instructionWordNext;
		regA <= regANext;
		regB <= regBNext;
		addr_toRAM<=addr_toRAM_next;
		data_toRAM<=data_toRAM_next;
		wrEn<=wrEn_next;
		end
	end
end

//output logic and next state logic
always@(*) begin
	//DEFAULT VALUES are valid if they're not assigned any value within each case
	nextState = currentState;
	pcNext = pc;
	instructionWordNext = instructionWord;
	regANext = regA;
	regBNext = regB;
	wrEn_next = 0;
	addr_toRAM_next = addr_toRAM;
	data_toRAM_next = data_toRAM;
	case(currentState)
		//state: STATE0
		`STATE0: begin
			wrEn_next = 0;
			addr_toRAM_next = 0;
			data_toRAM_next = 0;
			pcNext = 0;
			instructionWordNext = 0;
			regANext = 0;
			regBNext = 0;
			nextState = `STATE1;
		end
		//state: STATE1
		`STATE1: begin
			wrEn_next = 0;
			addr_toRAM_next = pc; //Instruction Request 
			pcNext = pc + 1; //Next Instruction (After 5 State)
			nextState = `STATE2;
		end
		//state: STATE2
		`STATE2: begin
			addr_toRAM_next = data_fromRAM[27:14]; //address of A // A request 
			instructionWordNext = data_fromRAM; // We get Instruction from Ram
			nextState = `STATE3; //Next State
		end
		//state: STATE3
		`STATE3: begin
			regANext = data_fromRAM; // Get Data of A
			if(instructionWord[31:29] == 3'b101 ) begin // if CPI or CPIi Go To State4
				addr_toRAM_next = instructionWord[13:0];//address of B // B Request
				nextState = `STATE4;
			end
			//check if i bit is 1
			else if(~instructionWord[28]) begin 
				addr_toRAM_next = instructionWord[13:0]; //address of B // B Request
				nextState = `STATE4;
			end
			else begin
				nextState = `STATE5;
			end
		end
		//state: STATE4
		`STATE4: begin
			regBNext = data_fromRAM; //Get Data of B
			nextState = `STATE5;
		end
		//state: STATE6
		`STATE6: begin
			wrEn_next = 1;
			addr_toRAM_next = instructionWord[27:14];
			data_toRAM_next = data_fromRAM;
			nextState= `STATE1;
		end
		//state: STATE5
		`STATE5: begin
		  case(instructionWord[31:28]) //opcode: 3-bit + i: 1-bit
				{3'b000,1'b0}: begin //ADD // *A = (*A) + (*B)
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14]; // Put to address of A
					data_toRAM_next = (regA + regB);	//Data
				end
				{3'b000,1'b1}: begin //ADDi // *A = (*A) + B
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					data_toRAM_next = (regA + instructionWord[13:0]);
				end
				{3'b001,1'b0}: begin //NAND // *A = ~((*A) & (*B))
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					data_toRAM_next = ~(regA & regB);
				end
				{3'b001,1'b1}: begin //NANDi // *A = ~((*A) & B)
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					data_toRAM_next = ~(regA & instructionWord[13:0]);
				end

				{3'b010,1'b0}: begin //SRL // *A <- ((*B) < 32) ? ((*A) >> (*B)) : ((*A) << ((*B) - 32))
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					if (regB < 32) begin
						data_toRAM_next = (regA >> regB);
					end
					else begin
						data_toRAM_next = (regA << (regB - 32));
					end
				end

				{3'b010,1'b1}: begin //SRLi // *A <- (B < 32) ? ((*A) >> B) : ((*A) << (B - 32))
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					if (instructionWord[13:0] < 32) begin
						data_toRAM_next = (regA >> instructionWord[13:0]);
					end
					else begin
						data_toRAM_next = (regA << (instructionWord[13:0] - 32));
					end
				end

				{3'b011,1'b0}: begin //LT //*A <- ((*A) < (*B))
					wrEn_next = 1;		//if *A is Less Than *B then *A is set to 1, otherwise to 0.

					if (regA < regB) begin
						addr_toRAM_next = instructionWord[27:14];
						data_toRAM_next = 1'b1;
					end
					else begin
						addr_toRAM_next = instructionWord[27:14];
						data_toRAM_next = 1'b0;
					end
				end
				{3'b011,1'b1}: begin //LTi //*A <- ((*A) < B)
					wrEn_next = 1;		//if *A is Less Than B then *A is set to 1, otherwise to 0.

					if (regA < instructionWord[13:0]) begin
						addr_toRAM_next = instructionWord[27:14];
						data_toRAM_next = 1'b1;
					end
					else begin
						addr_toRAM_next = instructionWord[27:14];
						data_toRAM_next = 1'b0;
					end
				end
				{3'b100,1'b0}: begin //CP // *A <- *B
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					data_toRAM_next = regB;
				end
				{3'b100,1'b1}: begin //CPi // *A <- B
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14];  // Put to address of A
					data_toRAM_next = instructionWord[13:0];
				end
				{3'b101,1'b0}: begin //CPI // *(*B) = *A // Look at 1,940,000 ////
					//*A <- *(*B)
					addr_toRAM_next = regB;//address of B // B Request
					//nextState = `STATE6;
				end
				{3'b101,1'b1}: begin //CPIi // *(*A) = *B
					wrEn_next = 1;//*(*A) <- *B
					addr_toRAM_next = regA;
					data_toRAM_next = regB;
				end
				
				
				{3'b110,1'b0}: begin 	//BZJ //PC = (*B == 0) ? (*A) : (PC+1)
					if (regB == 1'b0) begin
						pcNext = regA; // Look For It
					end
				end
				{3'b110,1'b1}: begin 	//BZJi //PC <- (*A) + B
					pcNext = regA + instructionWord[13:0]; // Look For It
				end
				{3'b111,1'b0}: begin //MUL // *A <- (*A) * (*B)
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14]; //A
					data_toRAM_next = regA * regB;
				end
				{3'b111,1'b1}: begin //MULi // *A <- (*A) * B
					wrEn_next = 1;
					addr_toRAM_next = instructionWord[27:14]; //A
					data_toRAM_next = regA * instructionWord[13:0];
				end
				
			endcase
		  if(instructionWord[31:28] == 4'b1010 ) begin //
			nextState = `STATE6;
		  end
		  else begin
			nextState= `STATE1;
		  end
			
		end
	endcase
end

endmodule
 