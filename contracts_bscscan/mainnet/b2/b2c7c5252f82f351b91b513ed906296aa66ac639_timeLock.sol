/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

contract timeLock {
    struct accountData
    {
        uint balance;
        uint releaseTime;
    }

    mapping (address => accountData) accounts;

    function payIn(uint _lockTimeS) public payable {
        uint amount = msg.value;
        payOut();
        if (accounts[msg.sender].balance > 0)
            msg.sender.transfer(msg.value);
        else
        {
            accounts[msg.sender].balance = amount;
            accounts[msg.sender].releaseTime = now + _lockTimeS;
        }
    }

    function payOut() public {
        if (accounts[msg.sender].balance != 0 && accounts[msg.sender].releaseTime < now)
        {
            msg.sender.transfer(accounts[msg.sender].balance);
            accounts[msg.sender].balance = 0;
            accounts[msg.sender].releaseTime = 0;
        }
    }

    function getMyLockedFunds() view public returns (uint x)
    {
        return accounts[msg.sender].balance;
    }

    function getMyLockedFundsReleaseTime() view public returns (uint x)
    {
        return accounts[msg.sender].releaseTime;
    }

    function getNow() view public returns (uint x)
    {
        return now;
    }
}