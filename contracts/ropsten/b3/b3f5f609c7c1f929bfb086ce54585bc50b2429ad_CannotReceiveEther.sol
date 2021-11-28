/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CannotReceiveEther {

    mapping (address => bool) public winners;

    receive() external payable {
        revert("you can't send ether to me!");
    }

    fallback() external payable {
        revert("you can't send ether to me!");
    }

    function impossible() external {
        require(address(this).balance > 0, "I have no ether");
        winners[msg.sender] = true;
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

}