//SourceUnit: test.sol

pragma solidity ^0.4.25;

contract Skam {
    address public owner;
    uint balance;

    modifier onlyOwner() {
        require(msg.sender == owner, "Go fuck yourself");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function hehehe() external payable {
        balance += msg.value;
    }

    function getAllMoney() external onlyOwner {
        msg.sender.transfer(balance);
    }
}