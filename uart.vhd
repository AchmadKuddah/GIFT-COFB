LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart IS
    GENERIC (
        clock_freq : INTEGER := 50_000_000;
        baud_rate : INTEGER := 9600
    );
    PORT (
        clk : IN STD_LOGIC;
        UART_RXD : IN STD_LOGIC;
        UART_TXD : OUT STD_LOGIC;
        en_seg : OUT STD_LOGIC;
        seg : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END uart;

ARCHITECTURE testing OF uart IS
    SIGNAL w_rx_dv : STD_LOGIC;
    SIGNAL temp_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL temp_key : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL temp_pt : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL temp_c : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL temp_c_8 : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL flag_gift : STD_LOGIC;
    SIGNAL done : STD_LOGIC;
    SIGNAL w_tx_active : STD_LOGIC;
    SIGNAL w_tx_serial : STD_LOGIC;

    COMPONENT rx
        GENERIC (
            clock_freq : INTEGER := clock_freq;
            baud_rate : INTEGER := baud_rate
        );
        PORT (
            clk : IN STD_LOGIC;
            rx_serial : IN STD_LOGIC;
            rx_dv : OUT STD_LOGIC;
            byte_rx : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT rx;

    COMPONENT tx
        GENERIC (
            clock_freq : INTEGER := clock_freq;
            baud_rate : INTEGER := baud_rate
        );
        PORT (
            clk : IN STD_LOGIC;
            byte_tx : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            tx_dv : IN STD_LOGIC;
            tx_serial : OUT STD_LOGIC;
            tx_active : OUT STD_LOGIC;
            tx_done : OUT STD_LOGIC
        );
    END COMPONENT tx;

    COMPONENT GIFT128 IS
        PORT (
            P, K : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
            C : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
            flag : OUT STD_LOGIC;
            -- reset : IN STD_LOGIC;
            clock : IN STD_LOGIC

        );
    END COMPONENT;

    TYPE state IS (dataIn, crypting, dataOut, clean);
    SIGNAL currState : state := dataIn;
    SIGNAL index : INTEGER := 0;
    SIGNAL increment_bit : INTEGER := 0;
    SIGNAL key_or_pt : STD_LOGIC := '0';--0 key / 1 pt
    SIGNAL cnt : INTEGER;
    SIGNAL i : INTEGER;

BEGIN
    en_seg <= '0';
    receive : rx PORT MAP(clk, UART_RXD, w_rx_dv, temp_data);
    transmit : tx PORT MAP(clk, temp_c_8, w_rx_dv, w_tx_serial, w_tx_active, done);
    gift : GIFT128 PORT MAP(temp_pt, temp_key, temp_c, flag_gift, clk);

    UART_TXD <= w_tx_serial WHEN w_tx_active = '1' ELSE
        '1';
    -- ketika receiving
    PROCESS (w_rx_dv)
    BEGIN
        IF falling_edge(w_rx_dv) THEN
            IF cnt = 25_000_000 THEN
                --buat fsm disini
                CASE currState IS
                    WHEN dataIn =>
                        --buat untuk masukin data ke 128 bit
                        IF increment_bit < 15 THEN
                            IF index < 7 THEN
                                IF key_or_pt = '0' THEN
                                    --masukin data ke key
                                    temp_key((8 * increment_bit) + index) <= temp_data(index);
                                ELSE
                                    --masukin data ke pt
                                    temp_pt((8 * increment_bit) + index) <= temp_data(index);
                                END IF;
                                index <= index + 1;
                            END IF;
                            increment_bit <= increment_bit + 1;
                        ELSE
                            IF key_or_pt = '1' THEN
                                currState <= crypting;
                            END IF;
                        END IF;
                        key_or_pt <= '1';
                        index <= 0;
                        increment_bit <= 0;
                        currState <= dataIn;
                    WHEN crypting =>
                        --masukin code untuk ngenahan untuk ga ngeluarin datanya
                        IF flag_gift = '1' THEN
                            currState <= dataOut;
                        ELSE
                            currState <= crypting;
                        END IF;
                    WHEN dataOut =>
                        -- code untuk nge assign setiap byte nya di tx
                        IF increment_bit < 15 THEN
                            IF index < 7 THEN
                                temp_key((8 * increment_bit) + index) <= temp_data(index);
                                index <= index + 1;
                            END IF;
                            increment_bit <= increment_bit + 1;
                        ELSE
                            IF done = '1' THEN
                                currState <= clean;
                            END IF;
                        END IF;
                        index <= 0;
                        increment_bit <= 0;
                        currState <= dataOut;
                    WHEN clean =>
                        index <= 0;
                        increment_bit <= 0;
                        currState <= dataIn;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF cnt < 25_000_001 THEN
                cnt <= cnt + 1;
            ELSE
                cnt <= 0;
            END IF;
        END IF;
    END PROCESS;

END testing;