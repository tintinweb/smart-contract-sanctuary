/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HashLast {
    enum Status {
    Open,
    Closed,
    Claimable
  }
    struct SaladBet {
    uint8 bet;
    uint8 bet2;
    uint256 value;
  }

  struct SaladBowl {
    uint256[6] total;
    mapping(address => SaladBet) bets;
    uint256 maxBet;
    address maxBetter;
    uint256 createdOn;
    uint256 expiry;
    Status status;
    uint8 result;
    bool jackpot;
  }

  mapping(uint64 => SaladBowl) public salads;
  mapping(address => mapping(uint64 => uint256[6])) public bets;

  mapping(address => address) public referrers;
  
    mapping(uint256 => mapping(uint256 => address)) test;
    bytes32 constant public zero = bytes32(0);
    
    function hashLast(uint256 n) public view returns (uint8) {
        return uint8(blockhash(n)[31]) % 16;
    }
    
    function hash(uint256 n) public view returns (bytes32) {
        return blockhash(n);
    }
    
    function isOldHash(uint256 n) public view returns (bool) {
        return blockhash(n) == zero;
    }
}