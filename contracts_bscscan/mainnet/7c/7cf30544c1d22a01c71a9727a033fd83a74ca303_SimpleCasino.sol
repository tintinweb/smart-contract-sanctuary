/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

interface RandomNumberGenerator {
    function rand() external returns(uint256);
}

contract SimpleCasino{
    address private manager = 0xc6CBDd49a933faC2188e9d5d1bEAE4f78C78c4f5;

    event Winner(address player, uint256 win);
    event Loser(address player);


    function randomnumberRequest() internal returns (uint256){
       uint256 randomnumber = RandomNumberGenerator(0xb8aB404B827EE39f483b26a42476d202f610A218).rand();
       return randomnumber;
    }
    
    function DoubleYourMoney() payable external{
        require(address(this).balance >= msg.value * 4, "Bet too high");
        address payable player =  payable(msg.sender);
        uint256 outcome = randomnumberRequest() % 2;
        if(outcome == 1){
            player.transfer(msg.value*19/10);
            emit Winner(msg.sender,msg.value*19/20);
        }
        if(outcome != 1){
            emit Loser(msg.sender);
        }
      
    }
    
        function TripleYourMoney() payable external{
        require(address(this).balance >= msg.value * 6, "Bet too high");
        address payable player =  payable(msg.sender);
        uint256 outcome = randomnumberRequest() % 3;
        if(outcome == 1){
        player.transfer(msg.value*28/10);
        emit Winner(msg.sender,msg.value*28/20);
        }
        if(outcome != 1){
            emit Loser(msg.sender);
        }
    }
    
    
    
    function TakeBackMoney() external{
        require(msg.sender == manager, "you're not the owner");
        address payable owner =  payable(msg.sender);
            owner.transfer(address(this).balance);
    }
    
    
        receive() external payable {}
        
    
    
}