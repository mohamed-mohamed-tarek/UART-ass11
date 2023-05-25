`include "CONFIG_MACROS.v"

module UART_RX_TB ();
    reg CLK_tb;
    reg RST_tb;
    reg RX_IN_tb;
    reg PAR_EN_tb;
    reg PAR_TYP_tb;
    reg [4:0] Prescale_tb;
    
    wire Data_Valid_tb;
    wire [`WIDTH-1:0] P_DATA_tb;
    
    integer PreScale_Value;

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////// Tests ////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    initial begin
        
        INIT_CLK ();
        Go_IDLE ();

        Config_PreScale (5'd16);

        // ------------------------------------------------------------------------------------------------------------ //
        // -------------------------------------------- Single Frame Tests -------------------------------------------- //
        // ------------------------------------------------------------------------------------------------------------ //

        $display ("\nThe Single Frame Tests ...\n");

        $display ("\nChecking DataValid and P_DATA = 0 After Reset");
        Config_ParityEnable_And_Type (1, `ODD_PARITY_CONFIG);
        RST_And_Wait_At_IDLE ();
        Check_DataValid_And_PDATA (0,0);

        $display ("\nChecking DataValid = 1 and P_DATA = 0111_1111 In Case The Frame Is Correct");
        Apply_RX_Sequence ('b10011111110, 11); // The Second Number is the Number of Bits

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (1,'b0111_1111);

        $display ("\nChecking DataValid = 0 and P_DATA = 0111_1111 In Case The Parity Bit (ODD) is Wrong");
        Apply_RX_Sequence ('b11011111110, 11); // The Second Number is the Number of Bits

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (0,'b0111_1111);

        $display ("\nChecking DataValid = 0 and P_DATA = 0111_1111 In Case The Stop Bit And The Parity Bit (ODD) are Wrong");
        Apply_RX_Sequence ('b01011111110, 11); // The Second Number is the Number of Bits

        Go_IDLE();

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (0,'b0111_1111);

        $display ("\nChecking DataValid = 0 and P_DATA = 0111_1111 In Case The Parity Bit (EVEN) is Wrong");
        Config_ParityEnable_And_Type (1, `EVEN_PARITY_CONFIG);
        Apply_RX_Sequence ('b10011111110, 11); // The Second Number is the Number of Bits

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (0,'b0111_1111);

        $display ("\nChecking DataValid = 0 and P_DATA = 0111_1111 In Case The Stop Bit And The Parity Bit (EVEN) are Wrong");
        Apply_RX_Sequence ('b00011111110, 11); // The Second Number is the Number of Bits

        Go_IDLE();

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (0,'b0111_1111);


        $display ("\nChecking DataValid = 1 and P_DATA = 0111_1111 In Case The Frame Is Correct (par_en = 0)");
        Config_ParityEnable_And_Type (0, `EVEN_PARITY_CONFIG);
        Apply_RX_Sequence ('b1011111110, 10); // The Second Number is the Number of Bits

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (1,'b0111_1111);

        $display ("\nChecking DataValid = 0 and P_DATA = 0111_1111 In Case The Stop Bit Is Wrong (par_en = 0)");
        Config_ParityEnable_And_Type (0, `EVEN_PARITY_CONFIG);
        Apply_RX_Sequence ('b0011111110, 10); // The Second Number is the Number of Bits

        @(posedge CLK_tb);

        Check_DataValid_And_PDATA (0,'b0111_1111);

        // ------------------------------------------------------------------------------------------------------------ //
        // ------------------------------------------ Consequent Frames Tests ----------------------------------------- //
        // ------------------------------------------------------------------------------------------------------------ //

        $display ("\nThe Consequent Frames Tests ...\n");

        // Testing 2 Correct Frames
                $display ("\nTesting 2 Correct Frames:");

        Config_ParityEnable_And_Type (1, `ODD_PARITY_CONFIG);
        Apply_RX_Sequence ('b10011111110, 11); // The Second Number is the Number of Bits

        // Now We Have To Clear RX_IN To Generate the Start Bit of the New Frame
        CLEAR_RX ();

        @(posedge CLK_tb);
        $display ("The First Frame Should be Correct...");
                Check_DataValid_And_PDATA (1,'b0111_1111);

        repeat(PreScale_Value-1) @(posedge CLK_tb);

        // Now We should apply the second frame sequence
        Apply_RX_Sequence ('b1001111111, 10); // The Second Number is the Number of Bits

        @(posedge CLK_tb);
        $display ("The Second Frame Should be Correct...");
                Check_DataValid_And_PDATA (1,'b0111_1111);

        // Testing Correct Frame Folllowed By a Wrong One
                $display ("\nTesting Correct Frame Folllowed By a Wrong One:");

        Config_ParityEnable_And_Type (1, `ODD_PARITY_CONFIG);
        Apply_RX_Sequence ('b10011111110, 11); // The Second Number is the Number of Bits

        // Now We Have To Clear RX_IN To Generate the Start Bit of the New Frame
        CLEAR_RX ();

        @(posedge CLK_tb);
        $display ("The First Frame Should be Correct...");
                Check_DataValid_And_PDATA (1,'b0111_1111);

        repeat(PreScale_Value-1) @(posedge CLK_tb);

        // Now We should apply the second frame sequence
        Apply_RX_Sequence ('b1101111111, 10); // The Second Number is the Number of Bits

        @(posedge CLK_tb);
        $display ("The Second Frame Should be Wrong (Par_err = 1)...");
                Check_DataValid_And_PDATA (0,'b0111_1111);

        // Testing a Wrong Frame Followed by a Correct One
                $display ("\nTesting a Wrong Frame Followed by a Correct One:");

        Config_ParityEnable_And_Type (1, `ODD_PARITY_CONFIG);
        Apply_RX_Sequence ('b11011111110, 11); // The Second Number is the Number of Bits

        // Now We Have To Clear RX_IN To Generate the Start Bit of the New Frame
        CLEAR_RX ();

        @(posedge CLK_tb);
        $display ("The First Frame Should be Wrong(par_err = 1)...");
                Check_DataValid_And_PDATA (0,'b0111_1111);

        repeat(PreScale_Value-1) @(posedge CLK_tb);

        // Now We should apply the second frame sequence
        Apply_RX_Sequence ('b1001111111, 10); // The Second Number is the Number of Bits

        @(posedge CLK_tb);
        $display ("The Second Frame Should be Correct...");
                Check_DataValid_And_PDATA (1,'b0111_1111);


        #100 $finish();
        
    end
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////// Tasks ////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    task INIT_CLK ();
        // No Inputs Or Outputs
        begin
            CLK_tb = 1'b1;
        end
    endtask
    
    task Go_IDLE ();
        // No Inputs Or Outputs
        begin
            RX_IN_tb = 1'b1;
        end
    endtask

    task CLEAR_RX ();
        // No Inputs Or Outputs
        begin
            RX_IN_tb = 1'b0;
        end
    endtask
    
    task Config_PreScale (
        input [4:0] PreScale_In
        );
        begin
            Prescale_tb = PreScale_In;
            PreScale_Value = PreScale_In;
        end
    endtask
    
    task Config_ParityEnable_And_Type (
        input PAR_EN_in,
        input PAR_TYP_in
        );
        begin
            PAR_EN_tb  = PAR_EN_in;
            PAR_TYP_tb = PAR_TYP_in;
        end
    endtask

    task Check_DataValid_And_PDATA (
        input DataValid_Check,
        input [`WIDTH-1:0] P_DATA_Check
        );
        begin
                if (Data_Valid_tb == DataValid_Check && P_DATA_tb == P_DATA_Check)
                    $display ("Data Valid = %d (par_err = %d, stp_err = %d) and P_DATA = %b Specified Passed", DataValid_Check, DUT.par_err_int, DUT.stp_err_int, P_DATA_Check);
                else
                    $display ("Data Valid = %d and P_DATA = %b Specified Failed", DataValid_Check, P_DATA_Check);
        end
    endtask
    
    task Apply_RX_Sequence (
        input [10:0] Input_Seq,
        input integer NUM_BITS
    ); 

    integer i;

    begin

        for ( i = 0 ; i < NUM_BITS ; i = i+1 ) begin
            RX_IN_tb = Input_Seq [i];
            repeat(PreScale_Value) @(posedge CLK_tb);
        end

    end
    endtask

    task RST_And_Wait_At_IDLE ();
        
        begin
            RST_tb                          = 1'b1;
            @(negedge CLK_tb) RST_tb = 1'b0;
            @(negedge CLK_tb) RST_tb = 1'b1;
            repeat (2) @(posedge CLK_tb);
        end
        
    endtask
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////// CLK GEN. ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   

    `timescale 1ns/100ps
    
    always #2.5 CLK_tb = ~ CLK_tb;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////// DUT Inst. //////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    UART_RX DUT (
    .CLK(CLK_tb),
    .RST(RST_tb),
    .RX_IN(RX_IN_tb),
    .PAR_EN(PAR_EN_tb),
    .PAR_TYP(PAR_TYP_tb),
    .Prescale(Prescale_tb),
    
    .Data_Valid(Data_Valid_tb),
    .P_DATA(P_DATA_tb)
    );
    
endmodule
