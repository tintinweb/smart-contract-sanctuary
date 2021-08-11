/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.8.4;



contract A {

  struct TStruct {
    int x;
    int y;
  }  
  

  
  function SetStruct (TStruct memory sin, uint a) public returns (int) {
    TStruct memory s;
    s.x = sin.x;
    s.y = sin.y;
    return s.x;
  }
}