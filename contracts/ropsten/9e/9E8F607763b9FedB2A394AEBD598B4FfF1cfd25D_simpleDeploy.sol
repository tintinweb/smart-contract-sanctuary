/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.8.0;

//"SPDX-License-Identifier: UNLICENSED"

contract simpleDeploy {
    
    
    function deposit() public payable {
        
    }
    
    function withdraw(address a, uint amount) external {
        payable(a).transfer(amount);
    }
    
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
}