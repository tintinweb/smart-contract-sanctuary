/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

interface TheDivine {
    function rand() external returns(uint256);
}

contract TestTheDivine{
    event Log(uint256 indexed _value);

    function testRand() public returns (uint256){
        uint256 randomnumber = TheDivine(0xF52a83a3B7d918B66BD9ae117519ddC436A82031).rand();
        
        emit Log(TheDivine(0xF52a83a3B7d918B66BD9ae117519ddC436A82031).rand());
        
        return randomnumber;
    }
}