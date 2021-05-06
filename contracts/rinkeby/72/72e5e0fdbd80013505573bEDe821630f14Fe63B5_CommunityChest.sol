/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.17;

contract CommunityChest {
    
    function withdraw(uint256 amount) payable public {
        msg.sender.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}