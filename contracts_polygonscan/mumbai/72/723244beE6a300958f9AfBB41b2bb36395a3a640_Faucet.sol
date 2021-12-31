//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Faucet {
    receive() external payable {}
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function withdraw (address payable recepient, uint256 amount) external {
        require(msg.sender == owner, "!owner");
        require(amount <= 0.01 ether, "incorrect amount");
        recepient.transfer(amount);
    }
}