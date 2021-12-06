/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PiggyBank {
    uint public goal;
    
    constructor(uint _goal) {
        goal = _goal;
    }
    
    receive() external payable {}

    function GetBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        if (GetBalance() > goal) {
            selfdestruct(payable(msg.sender));
        }
    }


}