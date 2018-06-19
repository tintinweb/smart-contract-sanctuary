pragma solidity ^0.4.21;
// The Original All For 1 -  www.allfor1.io
// https://www.twitter.com/allfor1_io


contract AllForOne {
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping (address => uint) private playerKey;
    mapping (address => uint) public playerCount;
    mapping (address => uint) public currentGame;
    mapping (address => uint) public currentPlayersRequired;
    
    mapping (address => uint) private playerRegistrationStatus;
    mapping (address => uint) private playerNumber;
    mapping (uint => address) private numberToAddress;
    
    uint public currentBet = 0.005 ether;
    address public contractAddress;
    address public owner;
    address public lastWinner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    modifier noPendingBets {
        require(playerCount[contractAddress] == 0);
        _;
    }
    
    function changeBet(uint _newBet) public noPendingBets onlyOwner {
        currentBet = _newBet;
    }
    
    function AllForOne() {
        contractAddress = this;
        currentGame[contractAddress]++;
        currentPlayersRequired[contractAddress] = 100;
        owner = msg.sender;
        currentBet = 0.005 ether;
        lastWinner = msg.sender;
    }
    
    function canBet() view public returns (uint, uint, address) {
        uint _status = 0;
        uint _playerCount = playerCount[contractAddress];
        address _lastWinner = lastWinner;
        if (playerRegistrationStatus[msg.sender] < currentGame[contractAddress]) {
        _status = 1;
        }
        return (_status, _playerCount, _lastWinner);
    }
    
    modifier betCondition(uint _input) {
        require (playerRegistrationStatus[msg.sender] < currentGame[contractAddress]);
        require (playerCount[contractAddress] < 100);
        require (msg.value == currentBet);
        require (_input > 0 && _input != 0);
        _;
    }
    
    function placeBet (uint _input) payable betCondition(_input) {
        playerNumber[msg.sender] = 0;
        playerCount[contractAddress]++;
        playerRegistrationStatus[msg.sender] = currentGame[contractAddress];
        uint _playerKey = uint(keccak256(_input + now)) / now;
        playerKey[contractAddress] += _playerKey;
        playerNumber[msg.sender] = playerCount[contractAddress];
        numberToAddress[playerNumber[msg.sender]] = msg.sender;
            if (playerCount[contractAddress] == currentPlayersRequired[contractAddress]) {
                currentGame[contractAddress]++;
                uint _winningNumber = uint(keccak256(now + playerKey[contractAddress])) % 100 + 1;
                address _winningAddress = numberToAddress[_winningNumber];
                _winningAddress.transfer(currentBet * 99);
                owner.transfer(currentBet * 1);
                lastWinner = _winningAddress;
                playerKey[contractAddress] = 0;
                playerCount[contractAddress] = 0;
            }
        }
}