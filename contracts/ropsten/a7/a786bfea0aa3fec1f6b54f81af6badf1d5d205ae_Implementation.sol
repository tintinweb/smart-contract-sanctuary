/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

contract Implementation {

    uint public x;
    bool public isBase;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR");

        _;
    }
    
    constructor() {
        isBase = true;
    }

    function initialize(address _owner) external {
        require( isBase == false);

        require(owner == address(0), "ERROR");
        owner = _owner;
    }

    function setX(uint _newX) external onlyOwner {
        x = _newX;
    }

}