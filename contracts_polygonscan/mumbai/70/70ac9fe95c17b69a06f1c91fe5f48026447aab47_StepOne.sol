/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract StepOne {

    string public Message;

    constructor(string memory initVal){
        Message = initVal;
    }

    function Update(string memory newVal) public 
        
        {
            Message = newVal;
        }
}