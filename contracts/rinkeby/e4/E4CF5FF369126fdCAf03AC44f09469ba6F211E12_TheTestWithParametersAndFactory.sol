/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// File: contracts/test-with-parameters-and-factory.sol

pragma solidity ^0.5.7;
contract TheTestWithParametersAndFactory {
    address manager;
    uint256 initialAmount;
    constructor(address _manager, uint256 _initialAmount) public {
        manager = _manager;
        initialAmount = _initialAmount;
    }
    function dotest() public pure returns (uint dt) {
        return 20;
    }
}

contract TestFactory {
    function createContract(uint256 _initialAmount) public payable {
        new TheTestWithParametersAndFactory(msg.sender, _initialAmount);
    }
}