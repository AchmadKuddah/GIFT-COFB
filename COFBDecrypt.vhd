LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY COFBDecrypt IS
    PORT (
        clk : IN STD_LOGIC;
        k, n, m, ad : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        c : BUFFER STD_LOGIC_VECTOR (127 DOWNTO 0);
        t : OUT STD_LOGIC_VECTOR (127 DOWNTO 0)
    );
END COFBDecrypt;

ARCHITECTURE yes OF COFBDecrypt IS
    COMPONENT GIFT128 IS
        PORT (
            P, K : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
            C : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
            flag : OUT STD_LOGIC;
            reset : IN STD_LOGIC;
            clock : IN STD_LOGIC
        );
    END COMPONENT;

    SIGNAL y : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL L : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL x, out1, temp : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL ns, flag : STD_LOGIC := '0';
    SIGNAL en1 : STD_LOGIC := '1';
    SIGNAL tes : STD_LOGIC_VECTOR (127 DOWNTO 0);

BEGIN
    main : GIFT128 PORT MAP(P => x, K => k, C => out1, flag => flag, reset => en1, clock => clk);
    PROCESS (y, L, x, en1, k, n, m, ad, clk, temp, tes, flag)
        VARIABLE count : INTEGER := 0;
        VARIABLE y1, y2 : STD_LOGIC_VECTOR (63 DOWNTO 0);
    BEGIN
        ------ CLOCK COUNTER ------
        IF clk'event AND clk = '1' THEN
            IF ns = '1' THEN
                count := count + 1;
            END IF;
        END IF;
        IF clk'event AND clk = '0' THEN
            ns <= '0';
        END IF;

        IF count = 0 THEN
            IF flag = '0' THEN
                en1 <= '0';
                x <= n;

            ELSE
                y <= out1;
                ns <= '1';
                L <= y(63 DOWNTO 0);
            END IF;
        END IF;

        IF count = 1 THEN
            en1 <= '1';
            ns <= '1';
            IF falling_edge(clk) THEN
                tes <= STD_LOGIC_VECTOR(unsigned(L) * 3);
            END IF;
        ELSIF count = 2 THEN
            L <= tes(63 DOWNTO 0);
            y1 := Y(63 DOWNTO 0);
            y2 := Y(126 DOWNTO 64) & Y(127);
            ns <= '1';

        ELSIF count = 3 THEN
            y <= AD XOR (y1 & y2) XOR (L & X"0000000000000000");
            ns <= '1';

        ELSIF count = 4 THEN
            IF flag = '0' THEN
                en1 <= '0';
                x <= y;

            ELSE
                ns <= '1';
                temp <= out1;
            END IF;

        ELSIF count = 5 THEN
            en1 <= '1';
            ns <= '1';
            IF rising_edge(clk) THEN
                tes <= STD_LOGIC_VECTOR(unsigned(L) * 3);
            END IF;
        ELSIF count = 6 THEN
            L <= tes(63 DOWNTO 0);
            C <= M XOR temp;
            Y <= temp;
            ns <= '1';

        ELSIF count = 7 THEN
            y1 := Y(63 DOWNTO 0);
            y2 := Y(126 DOWNTO 64) & Y(127);
            ns <= '1';

        ELSIF count = 8 THEN
            Y <= c XOR (y1 & y2) XOR (L & X"0000000000000000");
            ns <= '1';

        ELSIF count = 9 THEN
            IF flag = '0' THEN
                en1 <= '0';
                x <= y;

            ELSE
                ns <= '1';
                T <= out1;
            END IF;

        ELSIF count = 10 THEN
            ns <= '1';
            en1 <= '1';
        END IF;
    END PROCESS;
END yes;