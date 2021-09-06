// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
/**
 * @title Game
 * @dev play rock paper sicissors game
 */
contract Game is Ownable {
    
    uint8 public constant totalChoice = 3;
    uint256 public maxBet = 10 * 10 ** 18;
    address public lastWinner;
    bool public prizePoolActivated = false;
    uint256 public prizePool = 0;
    uint256 public prizePoolTimeLength = 1 minutes;
    uint256 public prizePoolEndTime;
    uint256 public winningToPoolPer = 5;
    uint256 public extendPoolPer = 10;
    
    event GameOutcome(address indexed player, uint256 bet, uint8 playerChoice, uint8 randomChoice, uint8 result);
    event winPrize(address winner, uint256 prizePool);
    event poolChange(address player, uint256 amount, bool changeWinner);
    
    constructor () {}
    
    /**
     * @dev play game and get result
     * @param bet size, player choice (0 for rock, 1 for paper, 2 for sicissors)
     */
    function playGame(uint256 bet, uint8 playerChoice) public payable {
        require(bet > 0, "Cannot bet zero");
        require(bet <= maxBet, "Your bet size is too big");
        require(bet == msg.value, "Ether value not correct");
        require(playerChoice >= 0 && playerChoice <= 2, "Your choice not correct");
        
        updatePoolStatus();
        
        uint8 randomChoice = getRandomChoice();
        if(playerChoice < randomChoice) {
            playerChoice += totalChoice;
        }
        
        // 0 for tie, 1 for win, 2 for lose
        uint8 result = playerChoice - randomChoice;
        if(result == 0) {
            payable(msg.sender).transfer(bet);
        } else if(result == 1) {
            playerWin(bet);
        }
        
        emit GameOutcome(msg.sender, bet, playerChoice % totalChoice, randomChoice, result);
    }
    
    /**
     * @dev get a random choice result
     * @return 0 for rock, 1 for paper, 2 for sicissors
     */
    function getRandomChoice() public view returns (uint8) {
        //a simple but not secure way to implement, use chainlink VRF for more secure 
        uint256 result = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % uint256(totalChoice);
        return uint8(result);
    }
    
    /**
     * @dev update and send prize
     */
    function updatePoolStatus() public {
        if(prizePoolActivated == true && block.timestamp > prizePoolEndTime) {
            payable(lastWinner).transfer(prizePool);
            emit winPrize(lastWinner, prizePool);
            prizePool = 0;
            prizePoolActivated = false;
        }
    }
    
    /**
     * @dev deal player win
     * @param bet size
     */
    function playerWin(uint256 bet) internal {
        bool changeWinner = false;
        if(prizePoolActivated == false || bet > prizePool * extendPoolPer / 100) {
            prizePoolActivated = true;
            lastWinner = msg.sender;
            prizePoolEndTime = block.timestamp + prizePoolEndTime;
            changeWinner = true;
        }
        prizePool += bet * winningToPoolPer / 100;
        payable(msg.sender).transfer(bet * 2 - bet * winningToPoolPer / 100);
        emit poolChange(msg.sender, bet * winningToPoolPer / 100, changeWinner);
    }
    
    
    
    /**
     * @dev withdraw to owner
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setMaxBet(uint256 _maxBet) public onlyOwner {
        maxBet = _maxBet;
    }
    
    function setPrizePoolTimeLength(uint256 _prizePoolTimeLength) public onlyOwner {
        prizePoolTimeLength = _prizePoolTimeLength;
    }
    
    function setWinningToPoolPer(uint256 _winningToPoolPer) public onlyOwner {
        winningToPoolPer = _winningToPoolPer;
    }
    
    function setExtendPoolPer(uint256 _extendPoolPer) public onlyOwner {
        extendPoolPer = _extendPoolPer;
    }
}