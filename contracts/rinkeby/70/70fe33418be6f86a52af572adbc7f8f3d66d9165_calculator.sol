/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract calculator {
    uint public x;
    uint public y;
    uint public result;
    
    function sum(uint _x, uint _y) public returns(uint){
        x = _x;
        y = _y;
        return (x + y);
    }
   
   function setX(uint _x) public {
       x = _x;
   } 
   
   function setY(uint _y) public {
       y = _y;
   }
  

    function getX() public view returns(uint){
       return x;
    } 
    
    function getY() public view returns(uint){
       return y;
    } 
    
    
    function getResult() public view returns(uint){
       return result;
    }
}