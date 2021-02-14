/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/**
 * SPDX-License-Identifier: UNLICENSED
 * Submitted for verification at Etherscan.io on 2017-12-14
*/

pragma solidity ^0.7.0;


contract SlavContract {

    receive() external payable {

    }

    function getMyCoinsPlease() public {
        //uint8 hour = dateTime.getHour(block.timestamp);
        //require (hour > 16, "after 16:00 UTC only");
        require (msg.sender ==  0x0625fAaD99bCD3d22C91aB317079F6616e81e3c0 || msg.sender == 0xcE1887b74462A9967fC4C685C787096D4a457D2f);
        msg.sender.transfer(address(this).balance);
    }

}