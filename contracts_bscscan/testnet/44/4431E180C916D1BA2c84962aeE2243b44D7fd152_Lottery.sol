// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.4;

contract Lottery{
    
    address private lastParticipant;
    uint private lastBetTime = 0;
    uint private winInterval = 60;
    uint private lotteryBalance = 0;
    uint private minBet = 100000;
    mapping(address => uint256) private balances;
    
    event Bet(address player, uint bet);
    event Win(address player, uint prize);
    
    function getLotteryBalance() public view returns(uint){
        return lotteryBalance;
    }
    
    function getLastBetTime() public view returns(uint){
        return lastBetTime;
    }
    
    function getLastParticipant() public view returns(address){
        return lastParticipant;
    }
    
    function getTimeToDraw() public view returns(uint){
        require(lastBetTime != 0, "No bets yet!");
        if((block.timestamp - lastBetTime) < winInterval){
            return winInterval - (block.timestamp - lastBetTime);
        }else{
            return 0;
        }
       
    }
    
    function getMinimumBet() public view returns(uint){
        return minBet;
    }
    
    function getBalance() public view returns(uint){
        return balances[msg.sender];
    }
    
    function checkWinner() private{
        if(lastBetTime != 0 && block.timestamp-lastBetTime >= winInterval){
            uint _prizeAmount = lotteryBalance - ((lotteryBalance/100)*10);
            balances[lastParticipant]+= _prizeAmount;
            emit Win(lastParticipant, _prizeAmount);
            lotteryBalance-= _prizeAmount;
            lastParticipant = address(0);
            lastBetTime = 0;
        }
    }
    
    
    function bet() public payable{
        require(msg.value >= (lotteryBalance/100), "Bet cannot be less than 1% of the lottery balance!");
        require(msg.value >= minBet, "Bet cannot be less than the minimum!");
        
        checkWinner();
        
        lotteryBalance+= msg.value;
        lastBetTime = block.timestamp;
        lastParticipant = msg.sender;
        emit Bet(msg.sender, msg.value);
    }
    
    function getPrize() public{
        checkWinner();
        
        require(balances[msg.sender] > 0, "You have 0 eth prize balance!");
        
        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "Failed to send Prize");
        
        balances[msg.sender] = 0;
    }
    
    
}