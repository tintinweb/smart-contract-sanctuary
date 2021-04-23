// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import { IAMB } from "./IAMB.sol";
import { IBridgeMethods } from "./IBridgeMethods.sol";

contract KovanBridge {

    address private foreignContract;
    IAMB private amb;

    uint256 public constant DEFAULT_GAS_LIMIT = 2e6;

    event MSG_RECIEVED(string msg);
    event MSG_SEND(string msg);

    constructor(IAMB _amb) public {
        amb = _amb;
    }

    function setForeignContract(address _contract) external {
        foreignContract = _contract;
    }

    // send a message to sokol
    function sendToSokol(string memory _msg) external {
        bytes4 methodSelector = IBridgeMethods.didRecieve.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _msg);

        amb.requireToPassMessage(foreignContract, data, DEFAULT_GAS_LIMIT);

        emit MSG_SEND(_msg);
    }
    // recieve a msg from sokol and log 
    function didRecieve(string memory _msg) public {
        emit MSG_RECIEVED(_msg);
    }
}