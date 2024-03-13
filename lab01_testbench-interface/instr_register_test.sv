/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;

  parameter WRITE_NR = 50;
  parameter READ_NR = 50;

  parameter WRITE_ORDER = 2; // 0 - Incremental
                             // 1 - Decremental
                             // 2 - RANDOM

  parameter READ_ORDER = 2; // 0 - Incremental
                            // 1 - Decremental
                            // 2 - RANDOM
  
  instruction_t iw_reg_test[0:31];
  logic [31:0] pass_counter;

  int seed = 555;

  initial begin
    $display("\n\n***********************************************************");
    $display(  "***         THIS IS  A SELF-CHECKING TESTBENCH          ***");
    $display(  "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    // repeat (3) begin     Andrei Visoiu - Modificare - 06.03.2024
    repeat (WRITE_NR) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    // for (int i=0; i<=2; i++) begin Andrei Visoiu - Modificare - 06.03.2024
    for (int i=0; i<READ_NR; i++) begin 
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk) case (READ_ORDER)
        0 : read_pointer = i % 32;
        1 : read_pointer = 31 - (i % 32);
        2 : read_pointer = $random($random) % 32;
      endcase
      
      @(negedge clk) print_results;
      check_results;

      $display("Final results: %0d\n", pass_counter);
    end


    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***         THIS IS  A SELF-CHECKING TESTBENCH          ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp_i = 0;
    static int temp_d = 31;

    operand_a     = $random(seed)%16;                 // between -15 and 15
    operand_b     = $unsigned($random)%16;            // between 0 and 15
    opcode        = opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type
    
    case (WRITE_ORDER)
      0 : write_pointer = temp_i++;
      1 : write_pointer = temp_d--;
      2 : write_pointer = $random($random)%32;
    endcase

    $display("At write_pointer = %0d, timp %0t:", write_pointer, $time);
    $display("  opcode = %0d", opcode);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
    iw_reg_test[write_pointer] = '{opcode,operand_a,operand_b,0};
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d", operand_b);
    $display("  result = %0d\n", instruction_word.result);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.result);
  endfunction: print_results

  function void check_results;
  result_t local_result;
  logic [4-1:0] pass_flags;

  if(instruction_word.op_a == iw_reg_test[read_pointer].op_a) begin
    $display("PASS OP_A!");
    pass_flags[0] = 1'b1;
  end
  else begin
    $display("FAIL OP_A!"); 
    pass_flags[0] = 1'b0;
  end

  if(instruction_word.op_b == iw_reg_test[read_pointer].op_b) begin
    $display("PASS OP_B!");
    pass_flags[1] = 1'b1;
  end
  else begin
    $display("FAIL OP_B!"); 
    pass_flags[1] = 1'b0;
  end
  
  if(instruction_word.opc == iw_reg_test[read_pointer].opc) begin
    $display("PASS OPC!");
    pass_flags[2] = 1'b1;
  end
  else begin
    $display("FAIL OPC!");
    pass_flags[2] = 1'b0;
  end 


  case (iw_reg_test[read_pointer].opc)
        ZERO: local_result = 0;
        PASSA: local_result = iw_reg_test[read_pointer].op_a;
        PASSB: local_result = iw_reg_test[read_pointer].op_b;
        ADD: local_result = iw_reg_test[read_pointer].op_a + iw_reg_test[read_pointer].op_b;
        SUB: local_result = iw_reg_test[read_pointer].op_a - iw_reg_test[read_pointer].op_b;
        MULT: local_result = iw_reg_test[read_pointer].op_a * iw_reg_test[read_pointer].op_b;
        DIV: if(iw_reg_test[read_pointer].op_b == 0)
              local_result = 0;
            else
              local_result = iw_reg_test[read_pointer].op_a / iw_reg_test[read_pointer].op_b;
        MOD: local_result = iw_reg_test[read_pointer].op_a % iw_reg_test[read_pointer].op_b;
        default: local_result = 63'bx;
      endcase

  if (local_result === instruction_word.result) begin
      $display("PASS RESULT!\n");
      pass_flags[3] = 1'b1;
  end
    else begin
      $display("FAIL RESULT!\n");    
      pass_flags[3] = 1'b0;
    end
  
  if(&pass_flags)
    pass_counter = pass_counter + 1;

  endfunction: check_results


endmodule: instr_register_test
