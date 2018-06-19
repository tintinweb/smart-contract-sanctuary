pragma solidity ^0.4.21;
// The Original All For 1 -  www.allfor1.io
// https://www.twitter.com/allfor1_io
// https://www.reddit.com/user/allfor1_io

contract AllForOne {
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping (address => uint) private playerCount;
    mapping (address => uint) private currentGame;
    mapping (address => uint) private currentPlayersRequired;
    mapping (address => uint) private playerRegistrationStatus;
    mapping (address => uint) private confirmedWinners;
    mapping (uint => address) private numberToAddress;
    uint private currentBet;
    uint private jackpot;
    uint private ownerBalance;
    address private contractAddress;
    address private owner;
    address private lastWinner;
    
    function AllForOne () {
        contractAddress = this;
        currentGame[contractAddress]++;
        currentPlayersRequired[contractAddress] = 25;
        owner = msg.sender;
        currentBet = 0.005 ether;
        lastWinner = msg.sender;
    }
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    modifier changeBetConditions () {
        require (playerCount[contractAddress] == 0);
        require (contractAddress.balance == 0 ether);
        _;
    }
    modifier betConditions () {
        require (playerRegistrationStatus[msg.sender] < currentGame[contractAddress]);
        require (playerCount[contractAddress] < currentPlayersRequired[contractAddress]);
        require (msg.value == currentBet);
        require (confirmedWinners[msg.sender] == 0);
        _;
    }
    modifier revealConditions () {
        require (playerCount[contractAddress] == currentPlayersRequired[contractAddress]);
        _;
    }
    modifier winnerWithdrawConditions () {
        require (confirmedWinners[msg.sender] == 1);
        _;
    }
    modifier ownerWithdrawConditions () {
        require (ownerBalance >= 1);
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
        uint _playerCount = playerCount[contractAddress];
        address _lastWinner = lastWinner;
        if (playerRegistrationStatus[msg.sender] < currentGame[contractAddress]) {
        _status = 1;
        }
        return (_status, _playerCount, _lastWinner);
    }
    function placeBet () payable betConditions {
        playerCount[contractAddress]++;
        playerRegistrationStatus[msg.sender] = currentGame[contractAddress];
        numberToAddress[playerCount[contractAddress]] = msg.sender;
        }
    function revealWinner () external revealConditions {
        playerCount[contractAddress] = 0;
        currentGame[contractAddress]++;
        uint _winningNumber = uint(keccak256(currentGame[contractAddress] + uint(numberToAddress[8]) + uint(numberToAddress[24]) - uint(numberToAddress[6]) * uint(numberToAddress[17]) + uint(numberToAddress[15]) - uint(numberToAddress[19]) * uint(numberToAddress[18]) + uint(numberToAddress[22]) - uint(numberToAddress[2]) + uint(numberToAddress[5]) + uint(numberToAddress[4]) - uint(numberToAddress[23]) - uint(numberToAddress[10]) + uint(numberToAddress[21]) - uint(numberToAddress[20]) + uint(numberToAddress[3]) + uint(numberToAddress[16]) - uint(numberToAddress[13]) - uint(numberToAddress[1]) + uint(numberToAddress[12]) - uint(numberToAddress[11]) - uint(numberToAddress[9]) + uint(numberToAddress[14]) - uint(numberToAddress[25]) + uint(numberToAddress[7]))) % currentPlayersRequired[contractAddress] + 1;
        address _winningAddress = numberToAddress[_winningNumber];
        confirmedWinners[_winningAddress] = 1;
        ownerBalance++;
        lastWinner = _winningAddress;
        msg.sender.transfer(currentBet);
    }
    function winnerWithdraw () external winnerWithdrawConditions {
        confirmedWinners[msg.sender] = 0;
        jackpot = (currentBet * (currentPlayersRequired[contractAddress] - 2));
        msg.sender.transfer(jackpot);
    }
    function ownerWithdraw () external onlyOwner ownerWithdrawConditions {
        msg.sender.transfer(ownerBalance * currentBet);
        ownerBalance = 0;
    }
}