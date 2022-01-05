// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Variables {
    // State variables are stored on the blockchain.
    string public text = "Horsing around, said the pony";
    uint public num = 123;

    function doSomething() public {
        // Local variables are not saved to the blockchain.
        uint i = 456;

        // Here are some global variables
        uint timestamp = block.timestamp; // Current block timestamp
        address sender = msg.sender; // address of the caller
    }
}