/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.5.0 < 0.7.0;

contract SimpleCounter {
    int counter;
    int counterLimit;
    address private _owner;
    mapping(int => address) public winners;

    modifier onlyOwner() {
      require(msg.sender == _owner, 'Caller is not the contract owner.');
      _;
    }

    constructor() public {
      counter = 0;
      counterLimit = 0;
      _owner = msg.sender;
    }

    function getCounter() public view returns (int){
      return counter;
    }

    function increment() public {
      require(counter < counterLimit, 'The current counter has already been claimed');
      counter += 1;
      winners[counter] = msg.sender;
    }

    function releaseNextIncrement() public onlyOwner {
      require(counter == counterLimit, 'The counter needs to be incremented first');
      counterLimit += 1;
    }
}