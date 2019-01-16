pragma solidity ^0.4.8;

contract Lottery {
    
    mapping (uint8 => address[]) playersByNumber ;
    
    address owner;
    
    constructor() public{
        owner = msg.sender;
        state = LotteryState.Accepting;
    }
    
    enum LotteryState { Accepting, Finished }
    
    LotteryState state; 
    
    function enter(uint8 number) public payable {
        require(state == LotteryState.Accepting);
        require(msg.value > .001 ether);
        playersByNumber[number].push(msg.sender);
    }
    
    function determineWinner() public {
        require(msg.sender == owner);
        state = LotteryState.Finished;
        uint8 winningNumber = random();
        distributeFunds(winningNumber);
        selfdestruct(owner);
    }
    
    function distributeFunds(uint8 winningNumber) private returns(uint256) {
        uint256 winnerCount = playersByNumber[winningNumber].length;
                require(winnerCount == 1);
        if (winnerCount == 1) {
            uint256 balanceToDistribute = address(this).balance/(2*winnerCount);
        }
        
        return address(this).balance;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(sha256(abi.encodePacked(block.timestamp, block.difficulty)))%251);
    }
}