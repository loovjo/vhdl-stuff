package UART_Common is

  type Action is (
    Nothing, WakeUp, StartSend, Quit
  );

  type TX_State is (
    Sending, -- txing_byte is being sent
    Waiting, -- txing_byte has been sent - caller should either go back to SendStart or to vibing
    Vibing -- switched to after QUIT has been received
  );

end UART_Common;
