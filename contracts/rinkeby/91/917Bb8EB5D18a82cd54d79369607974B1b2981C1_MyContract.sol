// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyContract {
    address public owner;

    event Buy(address indexed buyer, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    function buy() external payable {
        require(msg.sender.balance > msg.value, "Insufficient amount");
        require(msg.value > 10 ** 10, "Not enough value");

        payable(owner).transfer(msg.value);
        owner = msg.sender;
        
        emit Buy(msg.sender, msg.value);
    }
}