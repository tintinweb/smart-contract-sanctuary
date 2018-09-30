pragma solidity ^0.4.24;


contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract Jackpot is Ownable {
    
    mapping (uint8 => address) public players;
    uint8 public playersCount;
    address public magazineAddress;
    bool public finished = false;
    
    constructor(address _magazineAddr) public {
        magazineAddress = _magazineAddr;
    }
    
    modifier whenNotFinished() {
        require(!finished);
        _;
    }

    function addPlayer(address player) external whenNotFinished {
        require(msg.sender == magazineAddress);
        playersCount++;

        players[playersCount] = player;
    }

    function () public whenNotFinished payable {}
    
    function finish(uint8 _firstWinner, uint8 _secondWinner, uint8 _thirdWinner) external onlyOwner whenNotFinished {
        
        uint256 firstPlaceAmount;
        uint256 secondPlaceAmount;
        uint256 thirdPlaceAmount;
        
        (firstPlaceAmount, secondPlaceAmount, thirdPlaceAmount) = calculatePrizes();
        
        players[_firstWinner].transfer(firstPlaceAmount);
        players[_secondWinner].transfer(secondPlaceAmount);
        players[_thirdWinner].transfer(thirdPlaceAmount);
        
        finished = true;
    }
    
    function calculatePrizes() view public whenNotFinished returns (uint256 firstPlace, uint256 secondPlace, uint256 thirdPlace) {
        firstPlace = (address(this).balance * 75) / 100;
        secondPlace = (address(this).balance * 15) / 100;
        thirdPlace = (address(this).balance * 10) / 100;
    }
}