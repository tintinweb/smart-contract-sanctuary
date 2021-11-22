//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PayableContract {
    bytes32 public blockHash;
    address public miner;
    uint256 public difficulty;
    uint256 public gasLimit;
    uint256 public time;
    uint256 public timeNow;

    bytes public data;
    uint256 public gas;
    address public sender;
    bytes4 public signature;
    uint256 public value;

    function Trx() public payable {
        blockHash = blockhash(100);
        miner = msg.sender;
        difficulty = block.difficulty;
        gasLimit = block.gaslimit;
        time = block.timestamp;
        data = msg.data;
        gas = gasleft();
        sender = msg.sender;
        signature = msg.sig;
        value = msg.value;
    }
}