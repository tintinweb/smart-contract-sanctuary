pragma solidity >=0.4.0 <0.6.0;

contract GameOfBots {
    uint256 public lastBet;
    uint public lastBetBlock;
    address payable public lastBetAddress;
    
    constructor() payable public{
        lastBetBlock = 0;
    }
    function addToPrize() external payable {
        require(msg.value >= 1 ether, "Please add 1 ETH or more");
        require(address(this).balance < 100 ether, "Please create new contract for playing more");
        lastBetBlock = block.number;
    }
    function () external payable {
        require(msg.sender == tx.origin, "Please use usual sender address (not contract)");
        require(msg.value > lastBet, "Please bet more");
        require(lastBetBlock == 0 || block.number - lastBetBlock <= 10, "Sorry, GameOfBots is finished");
        lastBetBlock = block.number;
        lastBet = msg.value;
        lastBetAddress = msg.sender;
    }
    function sendPrize() external returns(bool) {
        require(lastBetBlock > 0 && block.number - lastBetBlock > 10, "Sorry, GameOfBots is not finished");
        selfdestruct(lastBetAddress);
    }
}