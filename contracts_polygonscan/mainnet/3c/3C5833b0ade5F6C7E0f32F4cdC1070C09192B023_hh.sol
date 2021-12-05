/**
 *Submitted for verification at polygonscan.com on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract hh {
    event Whatever(address indexed caller, uint256 value);
    function whatever() public payable returns(uint256){
        emit Whatever(msg.sender, msg.value);
        return(msg.value);
    }
}