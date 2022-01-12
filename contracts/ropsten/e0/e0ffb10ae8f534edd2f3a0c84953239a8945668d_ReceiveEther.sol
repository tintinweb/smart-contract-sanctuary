/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ReceiveEther {
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */
    event log(string message);
    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit log("receive");
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        emit log("fallback");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}