/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity 0.6.1;

contract BusdAccepet {
    
    address payable Owner;
   constructor() public {
    Owner = msg.sender;
  } 
    
     receive() external payable {
         Owner.transfer(msg.value);
     }
}