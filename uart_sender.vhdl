library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UART_Common.all;

-- I finally got the wildfire in my sock drawer under control
entity UART_Sender is
  generic (
    N_STOP_BITS : integer := 2
  );
  port (
    CLK_12MHz : in std_logic;
    UART_TX : out std_logic;

    ACTION : in Action;
    STATE : out TX_STATE;
    TXING_BYTE : in std_logic_vector (7 downto 0)
  );
end entity;

architecture uart_uwu of UART_Sender is
  signal uart_clk : std_logic := '0'; -- will tick at 115200 BAUD
  signal state_inner : TX_State := Vibing;
begin

  STATE <= state_inner;

  uart_clocker: process (CLK_12MHz)
    -- Want to downclock 12MHz to 115.200KHz
    -- Scalar of 104 + 1/6
    -- uart_ctr will count to 103
    -- extra_ctr counts to 6, then does an extra step for uart_ctr
    variable uart_ctr : integer range 0 to 104 := 0;
    variable extra_ctr : integer range 0 to 5 := 0;
  begin
    if rising_edge (CLK_12MHz) then
      if uart_ctr = 103 and extra_ctr /= 5 then
        uart_clk <= '1'; uart_ctr := 0; extra_ctr := extra_ctr + 1;
      elsif uart_ctr = 104 and extra_ctr = 5 then
        uart_clk <= '1'; uart_ctr := 0; extra_ctr := 0;
      else
        uart_clk <= '0'; uart_ctr := uart_ctr + 1;
      end if;
    end if;
  end process;

  sender : process (uart_clk)
    -- all of these are don't-care if current_state /= Sending
    type SendState is (Start, Data, Parity, Stop);
    variable send_state : SendState;

    variable parity_bit : std_logic;
    variable txing_bit_idx : integer range 0 to 7;
    variable stop_ctr : integer range 0 to N_STOP_BITS - 1;
  begin
    if rising_edge(uart_clk) then
      case action is
      when WakeUp =>
        state_inner <= Waiting;

      when StartSend =>
        send_state := Start;
        parity_bit := '0';
        txing_bit_idx := 0;
        stop_ctr := 0;
        state_inner <= Sending;

      when Nothing =>
        case state_inner is
        when Waiting | Vibing =>
          UART_TX <= '1';
        when Sending =>
          case send_state is
          when Start =>
            UART_TX <= '0';
            send_state := Data;
          when Data =>
            UART_TX <= TXING_BYTE(txing_bit_idx);
            parity_bit := parity_bit xor txing_byte(txing_bit_idx);
            if txing_bit_idx = 7 then
              send_state := Parity;
            else
              txing_bit_idx := txing_bit_idx + 1;
            end if;
          when Parity =>
            UART_TX <= parity_bit;
            send_state := Stop;
          when Stop =>
            UART_TX <= '1';
            if stop_ctr = N_STOP_BITS - 1 then
              state_inner <= Waiting;
            else
              stop_ctr := stop_ctr + 1;
            end if;
          end case;
        end case;

      when Quit =>
        state_inner <= Vibing;

      end case;
    end if;
  end process;
end architecture;

