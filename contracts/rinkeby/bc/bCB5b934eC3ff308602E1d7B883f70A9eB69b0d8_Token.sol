// SPDX-license-identifier: MIT

pragma solidity ^0.8.4;

contract Token {
    address public owner;
    uint256 public totalSupply = 1000;

    modifier onlyOwner() {
        require(owner == msg.sender, "Invalid caller");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addToken(uint256 _amount) onlyOwner() public {
        totalSupply += _amount;
    }
}

