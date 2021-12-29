/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract faucet {
    address public owner; 

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw(uint256 amount) public payable {
        require(amount <= 1000000000000000000);
        
        payable(msg.sender).transfer(amount);
        
    }

    // function () public payable {}
    fallback() external payable {}

    receive() external payable {}

}