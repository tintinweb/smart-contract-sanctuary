/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract piggy_bank{
    uint public a;

    constructor (uint goal){
        a=goal;
    }
    function getbalance() public view returns(uint){
        return address(this).balance;
    }

    function claim() public {
        if (getbalance() > a) {
            selfdestruct(msg.sender);
        }
    } 
    receive() external payable {}    
}