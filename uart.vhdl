library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
    port (
        CLK_12MHz : in std_logic;
        LED1 : out std_logic;
        BTN1 : in std_logic;
        UART_RX : in std_logic;
        UART_TX : out std_logic
    );
end entity;

architecture uart_uwu of uart is
  signal uart_clk : std_logic; -- we want 115 200 BAUD
begin

  uart_clocker: process (CLK_12MHz)
    -- Want to downclock 12MHz to 115.200KHz
    -- Scalar of 104 + 1/6
    -- uart_ctr will count to 103
    -- extra_ctr counts to 6, then does an extra step for uart_ctr
    variable uart_ctr : integer range 0 to 104;
    variable extra_ctr : integer range 0 to 5;
  begin
    if rising_edge (CLK_12MHz) then
      if uart_ctr = 103 and extra_ctr /= 5 then
        uart_clk <= '1';
        uart_ctr := 0;
        extra_ctr := extra_ctr + 1;
      elsif uart_ctr = 104 and extra_ctr = 5 then
        uart_clk <= '1';
        uart_ctr := 0;
        extra_ctr := 0;
      else
        uart_clk <= '0';
        uart_ctr := uart_ctr + 1;
      end if;
    end if;
  end process;

  process (uart_clk)
    variable tx_byte : std_logic_vector (7 downto 0) := "00000000";
    -- 0 = idle (high)
    -- 1 = start bit (0)
    -- 2 - 9 = data bits
    -- 10 = parity bit
    -- 11,12 = stop bit
    variable bit_state : integer range 0 to 12 := 0;

    type State is range -2 to 10;
    -- state = -2 = wait for button low
    -- state = -1 = wait for button high
    -- state > 0 = send data
    -- constant NDATA : State := 4;
    constant NDATA : State := 5;
    variable cstate : State := -2;
  begin
    if rising_edge (uart_clk) then
      case cstate is
      -- when 0 => tx_byte := "01000101"; -- E
      -- when 1 => tx_byte := "01010100"; -- T
      -- when 2 => tx_byte := "01000001"; -- A
      -- when 3 => tx_byte := "00100000"; -- space
      -- when others => tx_byte := "00000000"; -- \n
      when 0 => tx_byte := "01101101"; -- m
      when 1 => tx_byte := "01101010"; -- j
      when 2 => tx_byte := "01100001"; -- a
      when 3 => tx_byte := "01110101"; -- u
      when 4 => tx_byte := "00100000"; -- space
      when others => tx_byte := "00000000"; -- \n
      end case;

      case cstate is
      when -2 =>
        if BTN1 = '0' then
          cstate := -1;
        end if;
      when -1 =>
        if BTN1 = '1' then
          cstate := 0;
        end if;
      when others =>
        case bit_state is
        when 0 => -- idle
          UART_TX <= '1';
          bit_state := 1;
        when 1 => -- start bit
          UART_TX <= '0';
          bit_state := 2;
        -- data
        when 2 => UART_TX <= tx_byte(0); bit_state := 3;
        when 3 => UART_TX <= tx_byte(1); bit_state := 4;
        when 4 => UART_TX <= tx_byte(2); bit_state := 5;
        when 5 => UART_TX <= tx_byte(3); bit_state := 6;
        when 6 => UART_TX <= tx_byte(4); bit_state := 7;
        when 7 => UART_TX <= tx_byte(5); bit_state := 8;
        when 8 => UART_TX <= tx_byte(6); bit_state := 9;
        when 9 => UART_TX <= tx_byte(7); bit_state := 10;
        when 10 => -- parity bit
          UART_TX <= tx_byte(0) xor tx_byte(1) xor tx_byte(2) xor tx_byte(3) xor tx_byte(4) xor tx_byte(5) xor tx_byte(6) xor tx_byte(7);
          bit_state := 11;
        when 11 => -- stop bit 1
          UART_TX <= '1';
          bit_state := 12;
        when 12 => -- stop bit 2
          UART_TX <= '1';
          bit_state := 0;
          -- next state
          if cstate /= NDATA then
            cstate := cstate + 1;
          else
            cstate := -2;
          end if;
        end case;
      end case;
    end if;
  end process;
end architecture;
