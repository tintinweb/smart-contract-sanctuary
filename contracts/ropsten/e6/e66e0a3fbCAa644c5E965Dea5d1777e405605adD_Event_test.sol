// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Event_test {

    uint256 currentBlockNumber = block.number;
    uint256 finalBlockNumber;

    
    function test(uint256 _finalBlockNumber) public returns(bool){
        require(_finalBlockNumber < currentBlockNumber);
        return true;
    }


}