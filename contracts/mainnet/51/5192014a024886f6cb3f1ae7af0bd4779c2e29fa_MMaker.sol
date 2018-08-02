pragma solidity ^0.4.21;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract MMaker is owned {
    
    mapping (uint8 => address) players;
    
    
    
    function MMaker() public {
        state = LotteryState.Accepting;
    }
    
    uint8 number;
    
    enum LotteryState { Accepting, Finished }
    
    LotteryState state; 
    uint8 public maxnumber  = 55;
    uint public minAmount = 20000000000000000;
    
    
    function enroll() public payable {
        require(state == LotteryState.Accepting);
        require(msg.value >= minAmount);
        number += 1;
        require(number<=maxnumber);
        players[number] = (msg.sender);
        if (number == maxnumber){
            state = LotteryState.Finished;
        }
    }
    
    function setMaxNumber(uint8 newNumber) public onlyOwner {
        maxnumber = newNumber;
    }
    
    function setMinAmount(uint newAmount) public onlyOwner {
        minAmount = newAmount;
    }

    function lastPlayer() public view returns (uint8 _number, address _Player){
        _Player = players[number];
        _number = number;
    }
    
    function determineWinner() public onlyOwner {
        
        
        uint8 winningNumber = randomtest();
        
        distributeFunds(winningNumber);
    }
    function startOver() public onlyOwner{
      
      for (uint8 i=1; i<number; i++){
        delete (players[i]);
        }
        number = 0;
        state = LotteryState.Accepting;
        
    }
    
    function distributeFunds(uint8 winningNumber) private {
        owner.transfer(this.balance/10);
        players[winningNumber].transfer(this.balance);
    
    }
    
    
    function randomtest() internal returns(uint8){
        uint8 inter =  uint8(uint256(keccak256(block.timestamp))%number);
        //return inter;
        return uint8(uint256(keccak256(players[inter]))%number);
    }
    
    
}