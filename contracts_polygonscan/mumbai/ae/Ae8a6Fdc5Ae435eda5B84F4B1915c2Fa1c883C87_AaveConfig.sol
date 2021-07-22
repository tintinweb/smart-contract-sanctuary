// SPDX-License-Identifier: MIT

pragma solidity ^0.6.9;

contract AaveConfig {
    address public lendingPool;

    address public governance;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    constructor(address _lendingPool) public {
        lendingPool = _lendingPool;
    }

    function setGovernance(address newGov) public onlyGovernance {
        governance = newGov;
    }
}