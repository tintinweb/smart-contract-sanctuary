/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// With both call and delegatecall it’s not possible to receive 
// return values from the call due to EVM limitations.


contract Caller {
    address private _callee;

    constructor(address callee) {
        _callee = callee;
    }

    /// 0x008d3e26
    // Execute code of another contract, WITHOUT the state of the calling contract.
    function callHello() public {
        bytes memory payload = abi.encodeWithSignature("sayHello()");
        (bool success, bytes memory data) = address(_callee).call(payload);
        require(success);
    }

    /// 0x2bb3ffd8
    function callHelloFrom() public {
        bytes memory payload = abi.encodeWithSignature("sayHelloFrom(address)", msg.sender);
        (bool success, bytes memory data) = address(_callee).call(payload);
        require(success);
    }

    /// 0x5e79da22
    // Execute code of another contract, WITH the state of the calling contract.
    // Passes msg.sender, msg.value along the request, but state is recorded against this contract
    // delegatecall involves a security-risk for the calling contract, as the called 
    // contract can access/manipulate the calling contracts storage
    // useful for calling external libraries
    function delegateHello() public {
        bytes memory payload = abi.encodeWithSignature("sayHello()");
        (bool success, bytes memory data) = address(_callee).delegatecall(payload);
        require(success);
    }

    /// 0x2b99b4e1
    function delegateHelloFrom() public {
        bytes memory payload = abi.encodeWithSignature("sayHelloFrom(address)", msg.sender);
        (bool success, bytes memory data) = address(_callee).delegatecall(payload);
        require(success);
    }
}