library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UART_Common.all;

entity UART_User is
  port (
    CLK_12MHz : in std_logic;
    UART_TX : out std_logic;

    LED1, LED2, LED3 : out std_logic;
    BTN1 : in std_logic
  );
end entity;

-- default sender - sends 'meow ' over uart when BTN1 is pressed
architecture send_sample of UART_User is
  signal UART_action : Action := Nothing;
  signal UART_state : TX_State;
  signal UART_txing_byte : std_logic_vector (7 downto 0);

  type SupplierState is (WaitingUp, WaitingDown, Sending);
  signal supplier_state : SupplierState := WaitingUp;

  component UART_Sender is
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
  end component;
begin
  uart_sub : UART_Sender
    generic map (N_STOP_BITS => 2)
    port map (
      CLK_12MHz => CLK_12MHz,
      UART_TX => UART_TX,
      ACTION => UART_action,
      STATE => UART_state,
      TXING_BYTE => UART_txing_byte
    );

  with UART_state select LED1 <=
    '0' when Vibing,
    '1' when others;

  with supplier_state select LED2 <=
    '1' when WaitingUp,
    '0' when others;

  with supplier_state select LED3 <=
    '1' when WaitingDown,
    '0' when others;

  supplier : process (CLK_12MHz)
    constant SEND_AMOUNT : integer := 5;
    type SendText is array (0 to SEND_AMOUNT - 1) of std_logic_vector (7 downto 0);
    constant DATA : SendText :=
      (
        "01101101",
        "01101010",
        "01100001",
        "01110101",
        "00100000"
      );
    variable text_idx : integer range 0 to SEND_AMOUNT;
  begin
    if rising_edge(CLK_12MHz) then
      case supplier_state is
      when WaitingUp =>
        if BTN1 = '0' then
          supplier_state <= WaitingDown;
        end if;

      when WaitingDown =>
        if BTN1 = '1' then
          -- Start sending
          supplier_state <= Sending;
          text_idx := 0;
        end if;

      when Sending =>
        case UART_state is
        when Vibing =>
          if text_idx = 0 then
            UART_action <= WakeUp;
          else
            supplier_state <= WaitingUp;
          end if;

        when Waiting =>
          if UART_action = Nothing or UART_action = WakeUp then
            if text_idx = SEND_AMOUNT then
              UART_action <= Quit;
            else
              UART_txing_byte <= DATA(text_idx);
              UART_action <= StartSend;
              text_idx := text_idx + 1;
            end if;
          end if;
        when others =>
          UART_action <= Nothing;

        end case;
      end case;
    end if;
  end process;
end architecture;
