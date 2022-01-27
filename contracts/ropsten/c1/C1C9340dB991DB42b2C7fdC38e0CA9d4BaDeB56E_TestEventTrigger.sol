//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestEventTrigger {

    event TestEvent(
        string message
    );

    function triggerEvent() public {
        emit TestEvent("Test Events");
    }

}