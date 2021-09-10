/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

interface RandomNumberGenerator {
    function rand() external returns(uint256);
}

contract SimpleCasino{
    address payable private bank = payable(0xc6CBDd49a933faC2188e9d5d1bEAE4f78C78c4f5);
    uint256 public lastGame;
    address private RNG;
    address private manager = 0xc6CBDd49a933faC2188e9d5d1bEAE4f78C78c4f5;


function setRNGAddress(address _RNGaddy) external {
        require(msg.sender == manager, "you're not the owner");
    RNG = _RNGaddy;
}

    function randomnumberRequest() internal returns (uint256){
       uint256 randomnumber = RandomNumberGenerator(RNG).rand();
       return randomnumber;
    }
    
    function DoubleYourMoney() payable external{
        require(address(this).balance >= msg.value * 4, "Bet too high");
        require(lastGame < block.timestamp - 3, "You're playing too quickly");
        address payable player =  payable(msg.sender);
        uint256 outcome = randomnumberRequest() % 2;
        if(outcome == 1){
            player.transfer(msg.value*19/10);
            bank.transfer(msg.value*1/20);
        }
        lastGame = block.timestamp;
    }
    
        function TripleYourMoney() payable external{
        require(address(this).balance >= msg.value * 6, "Bet too high");
        require(lastGame < block.timestamp - 3, "You're playing too quickly");
        address payable player =  payable(msg.sender);
        uint256 outcome = randomnumberRequest() % 3;
        if(outcome == 1){
        player.transfer(msg.value*28/10);
        bank.transfer(msg.value*1/10);
       
        }
        lastGame = block.timestamp;
    }
    
    
    
    function TakeBackMoney() external{
        require(msg.sender == manager, "you're not the owner");
        address payable owner =  payable(msg.sender);
            owner.transfer(address(this).balance);
    }
    
    
        receive() external payable {}
        
    
    
}