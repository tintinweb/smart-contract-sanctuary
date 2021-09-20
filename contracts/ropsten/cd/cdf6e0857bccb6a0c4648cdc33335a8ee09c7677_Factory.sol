/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Factory {
    address public forwardTo;

    constructor() {
        forwardTo = msg.sender;
    }

    function deploy(bytes32 salt) public returns (address addr) {
        return address(new Forwarder{salt: salt}(forwardTo));
    }
}


contract Forwarder {
    address payable public _forwardTo;

    constructor(address forwardTo) {
        _forwardTo = payable(forwardTo);
    }
}