LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tx IS
    GENERIC (
        clock_freq : INTEGER;
        baud_rate : INTEGER
    );
    PORT (
        clk : IN STD_LOGIC;
        byte_tx : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        tx_dv : IN STD_LOGIC;
        tx_serial : OUT STD_LOGIC;
        tx_active : OUT STD_LOGIC;
        tx_done : OUT STD_LOGIC
    );
END tx;

ARCHITECTURE transmitting OF tx IS
    CONSTANT baud_freq : INTEGER := clock_freq/baud_rate - 1;

    TYPE state IS (idle, start, dataIn, stop, clean);
    SIGNAL currState : state := idle;
    SIGNAL baudCnt : INTEGER RANGE 0 TO baud_freq := 0;
    SIGNAL index : INTEGER := 1;
    SIGNAL tx_data : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL done : STD_LOGIC := '0';

BEGIN
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            CASE currState IS
                WHEN idle =>
                    tx_active <= '0';
                    tx_serial <= '1';
                    done <= '0';
                    baudCnt <= 0;
                    index <= 0;

                    IF tx_dv = '1' THEN
                        tx_data <= byte_tx;
                        currState <= start;
                    ELSE
                        currState <= idle;
                    END IF;

                WHEN start =>
                    tx_active <= '1';
                    tx_serial <= '0';

                    IF baudCnt < baud_freq - 1 THEN
                        baudCnt <= baudCnt + 1;
                        currState <= start;
                    ELSE
                        baudCnt <= 0;
                        currState <= dataIn;
                    END IF;

                WHEN dataIn =>
                    tx_serial <= tx_data(index);

                    IF baudCnt < baud_freq - 1 THEN
                        baudCnt <= baudCnt + 1;
                        currState <= dataIn;
                    ELSE
                        baudCnt <= 0;

                        IF index < 7 THEN
                            index <= index + 1;
                            currState <= dataIn;
                        ELSE
                            index <= 0;
                            currState <= stop;
                        END IF;
                    END IF;

                WHEN stop =>
                    tx_serial <= '1';

                    IF baudCnt < baud_freq - 1 THEN
                        baudCnt <= baudCnt + 1;
                        currState <= stop;
                    ELSE
                        done <= '1';
                        baudCnt <= 0;
                        currState <= clean;
                    END IF;

                WHEN clean =>
                    tx_active <= '0';
                    currState <= idle;

            END CASE;
        END IF;
    END PROCESS;
    tx_done <= done;
END transmitting;