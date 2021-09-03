/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

/*
    MultiCall V1
    
                   _.===========================._
                .'`  .-  - __- - - -- --__--- -.  `'.
            __ / ,'`     _|--|_________|--|_     `'. \
          /'--| ;    _.'\ |  '         '  | /'._    ; |
         //   | |_.-' .-'.'    -  -- -    '.'-. '-._| |
        (\)   \"` _.-` /                     \ `-._ `"/
        (\)    `-`    /      .---------.      \    `-`
        (\)           |      ||1||2||3||      |
       (\)            |      ||4||5||6||      |
      (\)             |      ||7||8||9||      |
     (\)           ___|      ||*||0||#||      |
     (\)          /.--|      '---------'      |
      (\)        (\)  |\_  _  __   _   __  __/|
     (\)        (\)   |                       |
    (\)_._._.__(\)    |                       |
     (\\\\207\\\)      '.___________________.'
      '-'-'-'--'
      
    Created by Murciano207
    
    http://spookfinance.tk
    
    Spook Finance® Copyright 2021 - All Rights Reserved
    
    SPDX-License-Identifier: GPL-3.0-or-later
    */

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    // Helper functions
    function getBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}