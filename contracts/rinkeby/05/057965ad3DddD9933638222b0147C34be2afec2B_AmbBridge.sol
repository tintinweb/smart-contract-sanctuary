// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AmbBridge {
    struct Withdraw {
        address fromAddress;
        address toAddress;
        uint amount;
    }

    Withdraw[] queue;
    uint eventNumber = 0;

    event Test(uint eventNumber, Withdraw[] withdraws);

    constructor() {}


    function withdraw(address toAddr, uint amount) public {
        queue.push(Withdraw(msg.sender, toAddr, amount));
    }


    function eventTest() public {
//        emit Test(keccak256(abi.encode(queue)), queue);
        eventNumber++;
        emit Test(eventNumber, queue);
        delete queue;
    }
}