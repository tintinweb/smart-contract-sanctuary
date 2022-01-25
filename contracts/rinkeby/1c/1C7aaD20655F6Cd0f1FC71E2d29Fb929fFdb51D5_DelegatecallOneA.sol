// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegatecallOneA {
    uint public num;
    address public sender;

    function setVars(address _contract, uint _num) public payable {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}