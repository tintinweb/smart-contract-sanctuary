/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.17;

contract CommunityChest {
    
    function withdraw( uint amount ) payable public {
        msg.sender.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}