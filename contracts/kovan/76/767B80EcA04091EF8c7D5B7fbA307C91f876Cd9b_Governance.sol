// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Governance {
    uint256 public useLock;
    address public giveaway;
    address public randomness;

    constructor() { useLock = 1; }

    /*
        Note: Enforces all of the requirements of verifiable fairness.
    */
    function init(address _giveaway, address _randomness) public {
        require(_randomness != address(0), "No randomness address supplied.");
        require(_giveaway != address(0), "No giveaway address given.");
        require(useLock > 0, "Use lock already empty.");
        
        useLock = useLock - 1;
        randomness = _randomness;
        giveaway = _giveaway;
    }
}