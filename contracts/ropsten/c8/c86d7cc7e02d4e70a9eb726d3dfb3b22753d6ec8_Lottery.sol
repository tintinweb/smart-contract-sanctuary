pragma solidity ^0.4.8;

contract Lottery {
    
    mapping (uint256 => address[]) playersByNumber ;
    
    address owner;
    
    constructor() public{
        owner = msg.sender;
        state = LotteryState.Accepting;
    }
    
    enum LotteryState { Accepting, Finished }
    
    LotteryState state; 
    
    function enter(uint256 number) public payable {
        require(state == LotteryState.Accepting);
        require(msg.value > .001 ether);
        playersByNumber[number].push(msg.sender);
    }
    
    function determineWinner() public {
        require(msg.sender == owner);
        state = LotteryState.Finished;
        uint256 winningNumber = random();
        distributeFunds(winningNumber);
        selfdestruct(owner);
    }
    
    function distributeFunds(uint256 winningNumber) private constant returns(uint256) {
        uint256 winnerCount = playersByNumber[winningNumber].length;
                require(winnerCount == 1);
        if (winnerCount == 1) {
            uint256 balanceToDistribute = address(this).balance/(2*winnerCount);
        }
        
        return balanceToDistribute;
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now))); 
    //    return uint(keccak256(block.difficulty, now, players));
    }
}