/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity 0.8.1;

contract Blackhole {
    
    address public previousWinner;
    address public feeTo;
    address public currentLeader;
    uint256 public currentBet;//amount of current bet in wei
    uint256 public lastBet;//time of last bet in seconds
    bool public currentGame;

    event NewBet(uint256 amount, address newLeader);
    event NewGameStarted(uint256 amount, address creator);
    event Winrar(uint256 amount, address winner);
    constructor() {
        previousWinner = msg.sender;
        feeTo = msg.sender;
    }

    modifier onlyPreviousWinner() {
        require(msg.sender == previousWinner, "You aren't the previous winner");
        _;
    }

    function setFeeTo(address destination) public onlyPreviousWinner {
        feeTo = destination;
    }

    function nextMinimumBet() public view returns(uint256) {
        if (currentGame) {
            return (currentBet / 10) + currentBet;
        } else {
            return 100;
        }
    }

    function bet() public payable {
        require(msg.value >= nextMinimumBet(), "bet more");
        if (!currentGame) {
            currentGame = true;
            emit NewGameStarted(msg.value, msg.sender);
        } else {
            payable(feeTo).transfer(msg.value / 1000);
        }
        currentBet = msg.value;
        lastBet = block.timestamp;
        currentLeader = msg.sender;
        emit NewBet(msg.value, msg.sender);
    }

    function win() public {
        require(block.timestamp >= lastBet + 2 days, "must be leader for 48 hours to collect");
        require(msg.sender == currentLeader);
        emit Winrar(address(this).balance, msg.sender);
        payable(msg.sender).transfer(address(this).balance);
        currentGame = false;
        currentBet = 0;
        previousWinner = msg.sender;
        feeTo = msg.sender;
    }
    

}