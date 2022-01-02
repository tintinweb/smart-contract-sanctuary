/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract RopstenTest {

    address public constant DEV = 0x0E596bAefcD8FEf491a93dDF79b73e7153bEE22B;
    address public constant MOD = 0xAa0fF7e8A2361BeF4139e1e6D24ed5950Ac3cA42;

    bool public hasStarted;
    uint256 public timestamp;

    uint256 public price = 0.002 ether;
    mapping(address => uint32) public amountOf;

    function mint(uint8 amount) public payable {
        require(hasStarted, "Sale hasn't started");
        _mint(amount, msg.sender);
    }

    function mintWithValue(uint8 amount) public payable {
        require(hasStarted, "Sale hasn't started");
        require(amount*price == msg.value, "Insufficient value");
        _mint(amount, msg.sender);
    }

    function mintTimestamp(uint8 amount) public payable {
        require(block.timestamp >= timestamp, "Sale hasn't started");
        _mint(amount, msg.sender);
    }

    function mintMultiInput(uint8 amount, address to) public payable {
        _mint(amount, to);
    }

    function mintNoInput() public payable {
        _mint(1, msg.sender);
    }

    function _mint(uint8 amount, address to) internal {
        require(amount <= 2, "Insufficient amount");
        require(to != address(0));
        amountOf[to] += amount;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == DEV || msg.sender == MOD, "You are not allowed to withdraw");
        payable(msg.sender).transfer(amount);
    }

    function changePrice(uint256 _price) public {
        price = _price;
    }

    function changeTimestamp(uint256 _timestamp) public {
        timestamp = _timestamp;
    }
    
    function changeStatus() public {
        hasStarted = !hasStarted;
    }
}