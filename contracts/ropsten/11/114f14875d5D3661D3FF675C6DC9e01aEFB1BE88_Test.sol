/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract Test {
          uint divide ;

   function getResult(uint a,uint b) public    {
    
      divide = a/b;
   }
   function result () public view returns(uint){
return divide;
   }
}