/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

interface TheDivine {
    function testRand() external returns(uint256);
}

contract CoinFlipTest{

    function testRand() internal returns (uint256){
       uint256 randomnumber = TheDivine(0xb8aB404B827EE39f483b26a42476d202f610A218).testRand();
       return randomnumber;
    }
    
    function CoinFlip() payable external{
        address payable player =  payable(msg.sender);
        uint256 outcome = testRand() % 2;
        if(outcome == 1){
            player.transfer(msg.value*19/10);
        }
    }
    
    function TakeBackMoney() external{
        address payable player =  payable(msg.sender);
            player.transfer(address(this).balance);
    }
    
    
        receive() external payable {}
        
    
    
}