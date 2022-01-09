/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract WriteFirstContract
{
    string _message;

    constructor(string memory msg)
    {
        _message = msg;
    }

    function getMessage() public view returns(string memory)
    {
        return _message;
    }
}