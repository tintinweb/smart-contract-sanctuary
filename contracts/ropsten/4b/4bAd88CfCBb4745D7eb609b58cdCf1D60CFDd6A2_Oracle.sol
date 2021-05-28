/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle {
    address public provider;
    address public owner;
    address public pool;

    uint256 public winRate;
    uint256 public equalRate;
    uint256 public lostRate;
    event BetRate(address indexed pool, uint256 indexed timestamp, uint256 winRate, uint256 equalRate, uint256 lostRate);

    constructor(address _owner) {
        pool = msg.sender;
        owner = _owner; 
        provider = _owner;
    }

    function setOwner(address _to) public {
        require(msg.sender == owner, "!non owner");
        owner = _to;
    }
    function setProvider(address _to) public {
        require(msg.sender == owner || msg.sender == provider, "!provider addr");
        provider = _to;
    }

    function uploadData(uint256 _winRate, uint256 _equalRate, uint256 _lostRate) public {
        //require(msg.sender == provider, "!provider addr");
        winRate = _winRate;
        equalRate = _equalRate;
        lostRate = _lostRate;
        emit BetRate(pool, block.timestamp, _winRate, _equalRate, _lostRate);
    }

    function getLastestBetRate() public view returns (uint256, uint256, uint256) {
        return (winRate, equalRate, lostRate);
    }
}