/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma  solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector {  //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    address public owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance= balance + msg.value;
    }

}