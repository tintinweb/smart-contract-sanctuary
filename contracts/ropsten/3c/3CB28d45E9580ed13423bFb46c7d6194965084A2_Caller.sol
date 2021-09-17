/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// With both call and delegatecall it’s not possible to receive 
// return values from the call due to EVM limitations.


contract Caller {

    /// 0x286f478e
    // Execute code of another contract, WITHOUT the state of the calling contract.
    function callHello(address addr) public {
        bytes memory payload = abi.encodeWithSignature("sayHello()");
        (bool success, bytes memory data) = address(addr).call(payload);
        require(success);
    }

    /// 0x89990ff7
    function callHelloFrom(address addr) public {
        bytes memory payload = abi.encodeWithSignature("sayHelloFrom(address)", msg.sender);
        (bool success, bytes memory data) = address(addr).call(payload);
        require(success);
    }

    /// 0xdbef889a
    // value is assigned to the callee contract
    function callHelloFromPayable(address addr) public payable {
        bytes memory payload = abi.encodeWithSignature("sayHelloFromPayable(address)", msg.sender);
        (bool success, bytes memory data) = address(addr).call{value: msg.value}(payload);
        require(success);
    }

    /// 0x1646533b
    // Execute code of another contract, WITH the state of the calling contract.
    // Passes msg.sender, msg.value along the request, but state is recorded against this contract
    // delegatecall involves a security-risk for the calling contract, as the called 
    // contract can access/manipulate the calling contracts storage
    // useful for calling external libraries
    function delegateHello(address addr) public {
        bytes memory payload = abi.encodeWithSignature("sayHello()");
        (bool success, bytes memory data) = address(addr).delegatecall(payload);
        require(success);
    }

    /// 0x2b99b4e1
    function delegateHelloFrom(address addr) public {
        bytes memory payload = abi.encodeWithSignature("sayHelloFrom(address)", msg.sender);
        (bool success, bytes memory data) = address(addr).delegatecall(payload);
        require(success);
    }

    /// 0xf5727683
    // value is assigned to this contract
    function delegateHelloFromPayable(address addr) public payable {
        bytes memory payload = abi.encodeWithSignature("sayHelloFromPayable(address)", msg.sender);
        (bool success, bytes memory data) = address(addr).delegatecall(payload);
        require(success);
    }

}