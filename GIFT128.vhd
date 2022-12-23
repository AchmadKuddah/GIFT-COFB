--initializing library
library IEEE;
use IEEE.std_logic_1164.all;
USE ieee.numeric_std.all;
--use work.type_bundle.all; --common data type used 
-- end of library

ENTITY GIFT128 IS

	PORT (P,K : in std_logic_vector(127 downto 0);
		  C : out std_logic_vector(127 downto 0);
		 flag : out std_logic;
		 reset : in std_logic;
		 clock : in std_logic
		  );
end GIFT128;

architecture GIFT128 of GIFT128 is
						 	  
--commonly used types========================================================================
subtype uint32_t is std_logic_vector(31 downto 0); -- 32 bits
subtype uint16_t is std_logic_vector (15 downto 0); -- 16 bits
subtype uint8_t is std_logic_vector(7 downto 0); -- 8 bits					 	  
type S_array is array (0 to 3) of std_logic_vector(31 downto 0);
type IO_array is array (0 to 15) of std_logic_vector(7 downto 0);
type W_array is array (0 to 7) of std_logic_vector (15 downto 0);	

					 	  						 	  
--FSM signal and type declaration ============================================================
type states is (data_loading,rounding,sub_stage1,sub_stage2,sub_stage3,sub_stage4,sub_stage5,sub_stage6,sub_stage7,sub_stage8,sub_stage9,permutation,key_process_1,key_process_2,data_out); --states
signal current_state : states; --states variable
signal count_round : integer := 0; -- counting round

-- GIFT128 ===================================================================================	
--constant data
type round_constant is array (0 to 39) of uint8_t;
constant round_constant_array : round_constant := (x"01", x"03", x"07", x"0F", x"1F", x"3E", x"3D", x"3B", x"37", x"2F",
    x"1E", x"3C", x"39", x"33", x"27", x"0E", x"1D", x"3A", x"35", x"2B",
    x"16", x"2C", x"18", x"30", x"21", x"02", x"05", x"0B", x"17", x"2E",
    x"1C", x"38", x"31", x"23", x"06", x"0D", x"1B", x"36", x"2D", x"1A");
--temporary signal for data processing =======================================================
signal T : uint32_t :=x"00000000";
signal T6,T7 : uint16_t := x"0000";
signal S : S_array;
signal W : W_array;
signal temp : IO_array;
signal temp_key : IO_array;

--ending declaration==========================================================================
						 	  
begin

--data reading================================================================================

	--data enable read
	temp(0)<= P(127 downto 120);
	temp(1)<= P(119 downto 112);
	temp(2)<= P(111 downto 104);
	temp(3)<=P(103 downto 96);
	temp(4)<=P(95 downto 88);
	temp(5)<=P(87 downto 80);
	temp(6)<=P(79 downto 72);
	temp(7)<=P(71 downto 64);
	temp(8) <= P(63 downto 56);
	temp(9) <= P(55 downto 48);
	temp(10) <= P(47 downto 40);
	temp(11) <= P(39 downto 32);
	temp(12) <= P(31 downto 24);
	temp(13) <= P(23 downto 16);
	temp(14) <= P(15 downto 8);
	temp(15) <= P(7 downto 0);
	--key data enable read
	temp_key(0)<= K(127 downto 120);
	temp_key(1)<= K(119 downto 112);
	temp_key(2)<= K(111 downto 104);
	temp_key(3)<=K(103 downto 96);
	temp_key(4)<=K(95 downto 88);
	temp_key(5)<=K(87 downto 80);
	temp_key(6)<=K(79 downto 72);
	temp_key(7)<=K(71 downto 64);
	temp_key(8) <= K(63 downto 56);
	temp_key(9) <= K(55 downto 48);
	temp_key(10) <= K(47 downto 40);
	temp_key(11) <= K(39 downto 32);
	temp_key(12) <= K(31 downto 24);
	temp_key(13) <= K(23 downto 16);
	temp_key(14) <= K(15 downto 8);
	temp_key(15) <= K(7 downto 0);	
	
--GIFT-128 stage ==================================================================================	
process(clock,reset,S(0),S(1),S(2),S(3),W(0),W(1),W(2),W(3),W(4),W(5),W(6),W(7),T,T6,T7)
				
				begin			
					if (rising_edge(clock)) then 
						if  (reset = '1') then 
							current_state <= data_loading;
							flag <= '0';
						else
							case current_state is 
-- data loading ===================================================================================	
							when data_loading =>
									
									--load P and concatinate into S
									S(0) <= temp(0)&temp(1)&temp(2)&temp(3);
									S(1) <= temp(4)&temp(5)&temp(6)&temp(7);
									S(2) <= temp(8)&temp(9)&temp(10)&temp(11);
									S(3) <= temp(12)&temp(13)&temp(14)&temp(15);
									-- load K and concatinate into W
									W(0) <= temp_key(0)&temp_key(1);
									W(1) <= temp_key(2)&temp_key(3);
									W(2) <= temp_key(4)&temp_key(5);
									W(3) <= temp_key(6)&temp_key(7);
									W(4) <= temp_key(8)&temp_key(9);
									W(5) <= temp_key(10)&temp_key(11);
									W(6) <= temp_key(12)&temp_key(13);
									W(7) <= temp_key(14)&temp_key(15);
									
									current_state <= rounding; --initiate GIFT 128

-- check counter stage =============================================================================
							when rounding =>
							
									if (count_round < 40) then
										--subtitution stages
										current_state <= sub_stage1;
									else 
										current_state <= data_out;
										count_round <=0;
									end if;
		
--susbtitution stages (1 to 9) =====================================================================
		
							when sub_stage1 => 
										S(1) <= S(1) xor (S(0) AND S(2));
										current_state <= sub_stage2;
							when sub_stage2 => 
										S(0) <= S(0) xor (S(1) AND S(3));
										current_state <= sub_stage3;
							when sub_stage3 => 
										S(2) <= S(2) xor (S(0) OR S(1));
										current_state <= sub_stage4;
							when sub_stage4 => 
										S(3) <= S(3) xor S(2);
										current_state <= sub_stage5;
							when sub_stage5 => 
										S(1) <= S(1) xor S(3);
										current_state <= sub_stage6;
							when sub_stage6 => 
										S(3) <= NOT S(3) ;
										current_state <= sub_stage7;
							when sub_stage7 => 
										S(2) <= S(2) xor (S(0) AND S(1));
										T <= S(0);
										current_state <= sub_stage8;
							when sub_stage8 => 
										S(0) <= S(3);
										current_state <= sub_stage9;
							when sub_stage9 => 
										S(3) <= T;
										current_state <= permutation;
							
-- permutation stages =============================================================================
							when permutation =>
							
									--reconfiguring bit position as stated at the reference dociment
									S(0) <= S(0)(29)&S(0)(25)&S(0)(21)&S(0)(17)&S(0)(13)&S(0)(9)&S(0)(5)&S(0)(1)&S(0)(30)&S(0)(26)&S(0)(22)&S(0)(18)&S(0)(14)&S(0)(10)&S(0)(6)&S(0)(2)&S(0)(31)&S(0)(27)&S(0)(23)&S(0)(19)&S(0)(15)&S(0)(11)&S(0)(7)&S(0)(3)&S(0)(28)&S(0)(24)&S(0)(20)&S(0)(16)&S(0)(12)&S(0)(8)&S(0)(4)&S(0)(0);
									S(1) <= S(1)(30)&S(1)(26)&S(1)(22)&S(1)(18)&S(1)(14)&S(1)(10)&S(1)(6)&S(1)(2)&S(1)(31)&S(1)(27)&S(1)(23)&S(1)(19)&S(1)(15)&S(1)(11)&S(1)(7)&S(1)(3)&S(1)(28)&S(1)(24)&S(1)(20)&S(1)(16)&S(1)(12)&S(1)(8)&S(1)(4)&S(1)(0)&S(1)(29)&S(1)(25)&S(1)(21)&S(1)(17)&S(1)(13)&S(1)(9)&S(1)(5)&S(1)(1);
									S(2) <= S(2)(31)&S(2)(27)&S(2)(23)&S(2)(19)&S(2)(15)&S(2)(11)&S(2)(7)&S(2)(3)&S(2)(28)&S(2)(24)&S(2)(20)&S(2)(16)&S(2)(12)&S(2)(8)&S(2)(4)&S(2)(0)&S(2)(29)&S(2)(25)&S(2)(21)&S(2)(17)&S(2)(13)&S(2)(9)&S(2)(5)&S(2)(1)&S(2)(30)&S(2)(26)&S(2)(22)&S(2)(18)&S(2)(14)&S(2)(10)&S(2)(6)&S(2)(2);
									S(3) <= S(3)(28)&S(3)(24)&S(3)(20)&S(3)(16)&S(3)(12)&S(3)(8)&S(3)(4)&S(3)(0)&S(3)(29)&S(3)(25)&S(3)(21)&S(3)(17)&S(3)(13)&S(3)(9)&S(3)(5)&S(3)(1)&S(3)(30)&S(3)(26)&S(3)(22)&S(3)(18)&S(3)(14)&S(3)(10)&S(3)(6)&S(3)(2)&S(3)(31)&S(3)(27)&S(3)(23)&S(3)(19)&S(3)(15)&S(3)(11)&S(3)(7)&S(3)(3);
									
									current_state <= key_process_1;--stages movement
									
-- key update (2 stages)===========================================================================	
							when  key_process_1 =>
							
									S(2) <= S(2) xor (W(2)&W(3)); -- update 
									S(1) <= S(1) xor (W(6)&W(7));
									S(3) <= S(3) xor (x"800000" & round_constant_array(count_round)); -- add round constant
									T6 <= std_logic_vector(shift_right(unsigned(W(6)),2) OR (shift_left(unsigned(W(6)),14)));
									T7 <= std_logic_vector(shift_right(unsigned(W(7)),12) OR (shift_left(unsigned(W(7)),4)));
									
									current_state <= key_process_2; --stages movement
									
							when key_process_2 =>
					
									W(7) <= W(5); --updating key
									W(6) <= W(4);
									W(5) <= W(3);
									W(4) <= W(2);
									W(3) <= W(1);
									W(2) <= W(0);
									W(1) <= T7;
									W(0) <= T6;
						
									current_state <= rounding; --stages movement
									count_round <= count_round +1; --incrementing counter
									
-- finalizing data stages(output)=====================================================================
									
							when data_out =>
							
									-- final data is converted from 4 sets of 32 bits into single set with 128 bit length
								    C(127 downto 120) <=  S(0)(31)&S(0)(30)&S(0)(29)&S(0)(28)&S(0)(27)&S(0)(26)&S(0)(25)&S(0)(24);
									C(119 downto 112) <= S(0)(23)&S(0)(22)&S(0)(21)&S(0)(20)&S(0)(19)&S(0)(18)&S(0)(17)&S(0)(16);
									C(111 downto 104) <= S(0)(15)&S(0)(14)&S(0)(13)&S(0)(12)&S(0)(11)&S(0)(10)&S(0)(9)&S(0)(8);
									C(103 downto 96) <=  S(0)(7)&S(0)(6)&S(0)(5)&S(0)(4)&S(0)(3)&S(0)(2)&S(0)(1)&S(0)(0);
									C(95 downto 88) <= S(1)(31)&S(1)(30)&S(1)(29)&S(1)(28)&S(1)(27)&S(1)(26)&S(1)(25)&S(1)(24);
									C(87 downto 80) <= S(1)(23)&S(1)(22)&S(1)(21)&S(1)(20)&S(1)(19)&S(1)(18)&S(1)(17)&S(1)(16);
									C(79 downto 72) <= S(1)(15)&S(1)(14)&S(1)(13)&S(1)(12)&S(1)(11)&S(1)(10)&S(1)(9)&S(1)(8);
									C(71 downto 64) <= S(1)(7)&S(1)(6)&S(1)(5)&S(1)(4)&S(1)(3)&S(1)(2)&S(1)(1)&S(1)(0);
									C(63 downto 56) <= S(2)(31)&S(2)(30)&S(2)(29)&S(2)(28)&S(2)(27)&S(2)(26)&S(2)(25)&S(2)(24);
									C(55 downto 48) <= S(2)(23)&S(2)(22)&S(2)(21)&S(2)(20)&S(2)(19)&S(2)(18)&S(2)(17)&S(2)(16);
									C(47 downto 40) <= S(2)(15)&S(2)(14)&S(2)(13)&S(2)(12)&S(2)(11)&S(2)(10)&S(2)(9)&S(2)(8);
									C(39 downto 32) <= S(2)(7)&S(2)(6)&S(2)(5)&S(2)(4)&S(2)(3)&S(2)(2)&S(2)(1)&S(2)(0);
									C(31 downto 24) <= S(3)(31)&S(3)(30)&S(3)(29)&S(3)(28)&S(3)(27)&S(3)(26)&S(3)(25)&S(3)(24);
									C(23 downto 16) <= S(3)(23)&S(3)(22)&S(3)(21)&S(3)(20)&S(3)(19)&S(3)(18)&S(3)(17)&S(3)(16);
									C(15 downto 8) <= S(3)(15)&S(3)(14)&S(3)(13)&S(3)(12)&S(3)(11)&S(3)(10)&S(3)(9)&S(3)(8);
									C(7 downto 0) <= S(3)(7)&S(3)(6)&S(3)(5)&S(3)(4)&S(3)(3)&S(3)(2)&S(3)(1)&S(3)(0);
									count_round <=0; --reseting count for next use
									flag <= '1'; --finished processing
								
							end case;
						end if;
						end if;
					end process;
--end of stages ======================================================================================
end GIFT128;
