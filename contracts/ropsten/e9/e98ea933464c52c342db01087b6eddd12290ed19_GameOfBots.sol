pragma solidity >=0.4.0 <0.6.0;

contract GameOfBots {
    uint256 public lastBet;
    uint public lastBetBlock;
    address payable public lastBetAddress;
    
    uint public totalBets;
    uint public blocksDelay;
    
    constructor() payable public{
        lastBetBlock = 0;
        blocksDelay = 1000;
        totalBets = 0;
    }
    function addToPrize() external payable {
        require(msg.value >= 1 ether, "Please add 1 ETH or more");
        require(address(this).balance < 100 ether, "Please create new contract for playing more");
        lastBetBlock = block.number;
    }
    function () external payable {
        require(msg.sender == tx.origin, "Please use usual sender address (not contract)");
        require(msg.value > lastBet, "Please bet more");
        require(lastBetBlock == 0 || block.number - lastBetBlock <= blocksDelay, "Sorry, GameOfBots is finished");
        lastBetBlock = block.number;
        lastBet = msg.value;
        lastBetAddress = msg.sender;
        totalBets++;
        if (totalBets == 100) {
            blocksDelay = 100;
        }
        if (totalBets == 1000) {
            blocksDelay = 10;
        }
        
    }
    function sendPrize() external returns(bool) {
        require(lastBetBlock > 0 && block.number - lastBetBlock > blocksDelay, "Sorry, GameOfBots is not finished");
        selfdestruct(lastBetAddress);
    }
}