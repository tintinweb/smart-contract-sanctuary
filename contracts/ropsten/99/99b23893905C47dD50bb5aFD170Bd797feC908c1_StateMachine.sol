/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity >=0.4.22 <0.9.0;

contract StateMachine {
   
   
   uint256    kk;
   
   
    event ff(address indexed addr,uint256 indexed amount);
    event ff1(address  addr,uint256  amount);
   
   function cetes(uint256 val) payable external {
       
       
       emit ff(msg.sender,val);
       
   }
    function cetes1(uint256 val)  external {
       
       
       emit ff1(msg.sender,val);
       
   }
   
   
}