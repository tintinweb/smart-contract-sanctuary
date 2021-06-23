/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthManager {

    function send(address payable _receiver) payable public {
        _receiver.send(msg.value);
    }

}