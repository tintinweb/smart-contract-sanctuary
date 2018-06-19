pragma solidity ^0.4.21;
// The Original All For 1 -  www.allfor1.io
// https://www.twitter.com/allfor1_io
// https://www.reddit.com/user/allfor1_io

contract AllForOne {
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping (address => uint) private playerRegistrationStatus;
    mapping (address => uint) private confirmedWinners;
    mapping (uint => address) private numberToAddress;
    uint private currentPlayersRequired;
    uint private currentBet;
    uint private playerCount;
    uint private jackpot;
    uint private revealBlock;
    uint private currentGame;
    address private contractAddress;
    address private owner;
    address private lastWinner;
    
    function AllForOne () {
        contractAddress = this;
        currentGame++;
        currentPlayersRequired = 25;
        owner = msg.sender;
        currentBet = 0.005 ether;
        lastWinner = msg.sender;
    }
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    modifier changeBetConditions () {
        require (playerCount == 0);
        require (contractAddress.balance == 0 ether);
        _;
    }
    modifier betConditions () {
        require (playerRegistrationStatus[msg.sender] < currentGame);
        require (playerCount < currentPlayersRequired);
        require (msg.value == currentBet);
        require (confirmedWinners[msg.sender] == 0);
        _;
    }
    modifier revealConditions () {
        require (playerCount == currentPlayersRequired);
        require (block.blockhash(revealBlock) != 0);
        _;
    }
    modifier winnerWithdrawConditions () {
        require (confirmedWinners[msg.sender] == 1);
        _;
    }
    function transferOwnership (address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function changeBet (uint _newBet) external changeBetConditions onlyOwner {
        currentBet = _newBet;
    }
    function canBet () view public returns (uint, uint, address) {
        uint _status = 0;
        uint _playerCount = playerCount;
        address _lastWinner = lastWinner;
        if (playerRegistrationStatus[msg.sender] < currentGame) {
        _status = 1;
        }
        return (_status, _playerCount, _lastWinner);
    }
    function placeBet () payable betConditions {
        playerCount++;
        playerRegistrationStatus[msg.sender] = currentGame;
        numberToAddress[playerCount] = msg.sender;
        if (playerCount == currentPlayersRequired) {
            revealBlock = block.number;
        }
        }
    function revealWinner () external revealConditions {
        uint _thisBlock = block.number;
        if (_thisBlock - revealBlock <= 255) {
            playerCount = 0;
            currentGame++;
            uint _winningNumber = uint(block.blockhash(revealBlock)) % currentPlayersRequired + 1;
            address _winningAddress = numberToAddress[_winningNumber];
            confirmedWinners[_winningAddress] = 1;
            lastWinner = _winningAddress;
            msg.sender.transfer(currentBet);
        } else {
            revealBlock = block.number;       
        }
    }
    function winnerWithdraw () external winnerWithdrawConditions {
        confirmedWinners[msg.sender] = 0;
        jackpot = (currentBet * (currentPlayersRequired - 1));
        msg.sender.transfer(jackpot);
    }
}