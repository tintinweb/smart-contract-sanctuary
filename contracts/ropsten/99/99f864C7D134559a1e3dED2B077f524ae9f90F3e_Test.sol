// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test{

    uint[] counters = [1,5,9]; 
    function addNewCardCounter(uint _counter) external {
        require(counters[counters.length] < _counter,"PlayingCard: not a valid counter");
        counters.push(_counter);
    }
    function riturn() external view returns(uint){
        return counters[counters.length];
    }
}