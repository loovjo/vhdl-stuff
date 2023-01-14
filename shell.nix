let pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  name = "icebreaker-testing";
  buildInputs = with pkgs; [
    usbutils icestorm
    yosys yosys-ghdl arachne-pnr nextpnrWithGui
    minicom
  ];
}
