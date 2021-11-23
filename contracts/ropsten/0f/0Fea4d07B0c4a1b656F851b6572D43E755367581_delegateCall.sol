/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract delegateCall {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}