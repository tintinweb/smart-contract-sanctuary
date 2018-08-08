pragma solidity ^0.4.18;


contract Griddeth {
    
  string public constant NAME = "Griddeth";

  uint8[18000] grid8; // 180x100 display
  
  // colors = ["#FFFFFF","#E4E4E4","#888888","#222222",
  // "#FFA7D1","#E50000","#E59500","#A06A42","#E5D900",
  // "#94E044","#02BE01","#00E5F0","#0083C7","#0000EA",
  // "#E04AFF","#820080"]

  function getGrid8() public view returns (uint8[18000]) {
      return grid8;
  }
  
  // No assertion on color < 16 since the frontend will
  // default to white otherwise.
  function setColor8(uint256 i, uint8 color) public {
      grid8[i] = color;
  }
  
  function Griddeth() public {
  }

}