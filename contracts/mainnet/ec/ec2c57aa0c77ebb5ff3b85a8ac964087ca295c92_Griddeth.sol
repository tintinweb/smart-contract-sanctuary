pragma solidity ^0.4.18;


contract Griddeth {
    
  string public constant NAME = &quot;Griddeth&quot;;

  uint8[18000] grid8; // 180x100 display
  
  // colors = [&quot;#FFFFFF&quot;,&quot;#E4E4E4&quot;,&quot;#888888&quot;,&quot;#222222&quot;,
  // &quot;#FFA7D1&quot;,&quot;#E50000&quot;,&quot;#E59500&quot;,&quot;#A06A42&quot;,&quot;#E5D900&quot;,
  // &quot;#94E044&quot;,&quot;#02BE01&quot;,&quot;#00E5F0&quot;,&quot;#0083C7&quot;,&quot;#0000EA&quot;,
  // &quot;#E04AFF&quot;,&quot;#820080&quot;]

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