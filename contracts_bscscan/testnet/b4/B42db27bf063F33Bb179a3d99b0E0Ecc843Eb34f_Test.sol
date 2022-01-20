/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.0;

interface lanuch{
    function lanuchAt() external returns(uint);
}

contract Test{
    uint public lanuchAt;
    address testaddress = address(0x9F40bdb811b34933c8667158937F128E8315b4F0);
    function getLanuch() public{
        lanuchAt = lanuch(testaddress).lanuchAt();
    }
}