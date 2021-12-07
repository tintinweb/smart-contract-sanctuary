// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BeerMe {
    address public owner = msg.sender;

    event Poured(address indexed from, uint256 timestamp, string message);

    constructor() {}

    function buy(string memory message) public payable {
        uint256 cost = 0.001 ether;
        require(msg.value >= cost, "");
        emit Poured(msg.sender, block.timestamp, message);
    }

    function release() public {
        require(msg.sender == owner, "not the owner");
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}