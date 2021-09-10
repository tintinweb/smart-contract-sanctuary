/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

interface TheDivine {
    function testRand() external returns(uint256);
}

contract CoinFlipTest2{

    function testRand() internal returns (uint256){
       uint256 randomnumber = TheDivine(0xb8aB404B827EE39f483b26a42476d202f610A218).testRand();
       return randomnumber;
    }
    
    function CoinFlip() payable external{
        require(address(this).balance >= msg.value * 4, "Bet too high");
        address payable player =  payable(msg.sender);
        uint256 outcome = testRand() % 2;
        if(outcome == 1){
            player.transfer(msg.value*19/10);
        }
    }
    
    function TakeBackMoney() external{
        require(msg.sender == 0xc6CBDd49a933faC2188e9d5d1bEAE4f78C78c4f5, "you're not the owner");
        address payable owner =  payable(msg.sender);
            owner.transfer(address(this).balance);
    }
    
    
        receive() external payable {}
        
    
    
}