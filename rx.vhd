LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rx IS
    GENERIC (
        clock_freq : INTEGER;
        baud_rate : INTEGER
    );
    PORT (
        clk : IN STD_LOGIC;
        rx_serial : IN STD_LOGIC;
        rx_dv : OUT STD_LOGIC;
        byte_rx : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END rx;

ARCHITECTURE receiving OF rx IS
    CONSTANT baud_freq : INTEGER := clock_freq/baud_rate - 1;

    TYPE state IS (idle, start, dataIn, stop, clean);
    SIGNAL currState : state := idle;
    SIGNAL baudCnt : INTEGER RANGE 0 TO baud_freq := 0;
    SIGNAL index : INTEGER := 0;
    SIGNAL rx_data : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL receive : STD_LOGIC := '0';

BEGIN
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            CASE currState IS
                WHEN idle =>
                    baudCnt <= 0;
                    index <= 0;
                    receive <= '0';

                    IF rx_serial = '0' THEN
                        currState <= start;
                    ELSE
                        currState <= idle;
                    END IF;

                WHEN start =>
                    IF baudCnt = baud_freq/2 THEN
                        IF rx_serial = '0' THEN
                            baudCnt <= 0;
                            currState <= dataIn;
                        ELSE
                            currState <= idle;
                        END IF;
                    ELSE
                        baudCnt <= baudCnt + 1;
                        currState <= start;
                    END IF;

                WHEN dataIn =>
                    IF baudCnt < baud_freq THEN
                        baudCnt <= baudCnt + 1;
                        currState <= dataIn;
                    ELSE
                        baudCnt <= 0;
                        rx_data(index) <= rx_serial;

                        IF index < 7 THEN
                            index <= index + 1;
                            currState <= dataIn;
                        ELSE
                            index <= 1;
                            currState <= stop;
                        END IF;
                    END IF;

                WHEN stop =>
                    IF baudCnt < baud_freq THEN
                        baudCnt <= baudCnt + 1;
                        currState <= stop;
                    ELSE
                        receive <= '1';
                        baudCnt <= 0;
                        currState <= clean;
                    END IF;
                WHEN clean =>
                    receive <= '0';
                    currState <= idle;
            END CASE;
        END IF;
    END PROCESS;
    byte_rx <= rx_data;
    rx_dv <= receive;
END receiving;