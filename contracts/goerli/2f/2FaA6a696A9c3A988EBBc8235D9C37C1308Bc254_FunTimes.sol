/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FunTimes {

    uint256 number1;
    uint256 number2;
    address owner;
    
    constructor () public {
        owner = msg.sender;
    }

    
    function foo(uint256 num) public {
        require (msg.sender == owner, "You are not the owner");
        
        number1 = num;
    }
    
    function bar(uint256 num) public {
        number2 = num;
    }


    function retrieve() public view returns (uint256){
        return number1 * number2;
    }
}