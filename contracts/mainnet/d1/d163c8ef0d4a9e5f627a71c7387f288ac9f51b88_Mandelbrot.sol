/**
 *Submitted for verification at Etherscan.io on 2020-06-02
*/

pragma solidity ^0.6.0;

contract Mandelbrot {
  int xMin = -8601;
  int xMax = 2867;
  int yMin = -4915;
  int yMax = 4915;
  int maxI = 30;
  int dx = (xMax - xMin) / 36;
  int dy = (yMax - yMin) / 12;
  int CY = yMax;
  string ascii = '$ .,[email protected]*?&()%+=';
  string[] mandel;

  function generator() public payable returns (bool) {
    require(mandel.length < 13, "Already yeeted.");
    int yeet = 1;
    int cy = CY;
    for (cy; cy>=xMin; cy-=dy) {
      int byteChar = 0;
      string memory sL = new string(100);
      bytes memory scanLine = bytes(sL);
      int cx = xMin;
      for (cx; cx<=xMax; cx+=dx) {
        int x = 0; int y = 0; int x2 = 0; int y2 = 0;
        int i = 0;
        for (i; i < maxI && x2 + y2 <= 16384; i++) {
            y = ((x * y) / 2**11) + cy;
            x = x2 - y2 + cx;
            x2 = (x * x) / 2**12;
            y2= (y * y) / 2**12;
        }

        bytes memory char = bytes(ascii);
        scanLine[uint(byteChar)] = char[uint(i%15)];
        byteChar++;
      }
      mandel.push(string(abi.encodePacked(string(scanLine), '\n')));
      CY -= dy;
      if (yeet == 6 || mandel.length == 13) {
        return true; 
      }
      yeet++;
    }
    return true;
  }

  function viewer() public view returns (string memory) {
    string memory mandelbro = string(abi.encodePacked(mandel[0]));
    for (uint iter = 1; iter < mandel.length; iter++) {
      mandelbro = string(abi.encodePacked(mandelbro, mandel[iter]));
    }
    return mandelbro;
  }
}