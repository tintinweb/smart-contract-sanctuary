/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract popWallet {
    
    uint256 public satoshiTotal = 0;
    
    uint256 public satoshiIn = 0;
    
    uint256 public satoshiOut = 0;
    
    address internal Moderator;
    
    mapping(string => uint256) public accounts;

    // Contract name
    string public name = "POP Wallet";
    // Contract symbol
    string public symbol = "POPW";
    
    event satohiIn(string btcAddr, uint256 amount);
    event withdrawal(string btcAddr, uint256 amount);
    event Transfer(string from, string to, uint256 amount);

    constructor() {
        Moderator = msg.sender;
    }
    
    function addSatoshi(string memory btcAddr, uint256 amount) public onlyModerator {
        satoshiIn += amount;
        satoshiTotal += amount;
        accounts[btcAddr] += amount;
        emit satohiIn(btcAddr, amount);
    }

    function withdrawSatoshi(string memory btcAddr, uint256 amount) public onlyModerator {
        require(accounts[btcAddr] >= amount,"Insufficient Satoshi in balance");
        satoshiOut += amount;
        satoshiTotal -= amount;
        accounts[btcAddr] -= amount;
        emit withdrawal(btcAddr, amount);
    }

    function transferSatoshi(string memory from, string memory to, uint256 amount) public onlyModerator {
        require(accounts[from] >= amount,"Insufficient Satoshi in balance");
        accounts[from] -= amount;
        accounts[to] += amount;
        emit Transfer(from, to, amount);
    }

    function withdraw() public payable onlyModerator{
        require(payable(msg.sender).send(address(this).balance));
    }

    modifier onlyModerator {
        require(msg.sender == Moderator, "Only Moderator function");
        _;
    }

}