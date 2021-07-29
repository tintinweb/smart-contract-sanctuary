/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract MaticGround {

    string private name;
    uint private amount;

    function setName(string memory newName) public {
        name = newName;
    }

    function getName () public view returns (string memory) {
        return name;
    }
    
    function setAmount(uint newAmount) public {
        amount = newAmount;      
    }

    function getAmount() public view returns (uint) {
        return amount;
    }
}