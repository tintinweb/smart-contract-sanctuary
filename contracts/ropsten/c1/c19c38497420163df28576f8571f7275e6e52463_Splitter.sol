/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Splitter {
    address payable constant public first = payable(0xc4b7dBC93bC18Dd1Ba2FA467ff182ddFb1C87ED6);
    address payable constant public second = payable(0x56026474e23AB091AD2A8781A9e7D4aA3f03ee1f);

    receive() external payable {
        first.transfer(msg.value / 2);
        second.transfer(msg.value / 2);
    }
}