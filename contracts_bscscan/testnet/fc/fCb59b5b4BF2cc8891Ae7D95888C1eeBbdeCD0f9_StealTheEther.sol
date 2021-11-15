// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StealTheEther {
    mapping(address => uint256) public balanceOf;

    constructor() payable {
        require(msg.value == 1 ether, "StealTheEther: Need value");
    }

    function guess(bytes32 blockhashGuess) external {
        require(blockhashGuess == blockhash(block.number), "Wrong guess");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "StealTheEther: Transfer failed");
    }
}

