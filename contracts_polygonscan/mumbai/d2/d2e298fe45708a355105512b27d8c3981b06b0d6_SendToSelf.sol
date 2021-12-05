/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract SendToSelf {
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}