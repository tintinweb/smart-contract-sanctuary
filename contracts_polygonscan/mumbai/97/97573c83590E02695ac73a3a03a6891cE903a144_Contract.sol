/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Contract {

    event MyEvent(string indexed info);

    function emitEvent() public {
        emit MyEvent("emiting an event");
    }
}