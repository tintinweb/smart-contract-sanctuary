/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MSGValueContract {
    event MsgValueData(uint256 msgValue);

    function getMsgValue() public payable returns (uint256) {
        payable(msg.sender).transfer(address(this).balance);
        emit MsgValueData(msg.value);
        return msg.value;
    }
}