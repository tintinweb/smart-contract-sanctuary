/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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

    // Function to receive Ether. msg.data must be empty
    //receive() external payable {}

    // Fallback function is called when msg.data is not empty
    //fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}