/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

pragma solidity ^0.8.0;

contract SignMessage{
    
   bytes32 private screct ;
   
   constructor(bytes32 _screct)  {
       screct = _screct;
   }
}