/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract SolidityTest {
   
   using SafeMath for uint;
   
   uint public a  ;
   uint public b ;
   
   function Setter (uint _a, uint _b) public {
       a = _a;
       b = _b;
   }

   function add() public view returns(uint c) {
       return c = a.add(b);
   }
   
    function sub() public view returns(uint c) {
       return c = a.sub(b);
   } 
   
    function mul() public view returns(uint c) {
       return c = a.mul(b);
   }
   
    function div() public view returns(uint c) {
       return c = a.div(b);
   }
   

}