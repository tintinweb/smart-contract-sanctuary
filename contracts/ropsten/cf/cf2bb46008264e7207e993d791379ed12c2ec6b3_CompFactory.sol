pragma solidity ^0.4.25;

contract CompFactory {
    address[] public contracts;
    
    function getContractCount() public constant returns(uint contractCount){
        return contracts.length;
    }
    
    function newComp(uint8 _numRounds) public payable returns(address newContract) {
        Comp c = new Comp(_numRounds);
        contracts.push(c);
        return c;
    }
}

contract Comp {
    address public playerA;
    address public playerB;
    uint8 public numRounds;
    uint8 public round;
    uint256 public punt;
    mapping (uint8=>uint8) public results;
    bool public begun;
    bool public finished;
    
    constructor(uint8 _numRounds) public payable {
        require(msg.value > 0);
        require(_numRounds > 0);
        require((_numRounds % 2) == 1);
        playerA = msg.sender;
        numRounds = _numRounds;
        round = 0;
        punt = msg.value;
        begun = false;
        finished = false;
    }
    
    function () public {
        
    }
    
    modifier inLobby {
        require(!begun);
        _;
    }
    
    function readyUp() payable public inLobby {
        require(msg.sender != playerA);
        require(msg.value >= punt);
        playerB = msg.sender;
        playerB.transfer(msg.value-punt);
        begun = true;
    }
    
    modifier isPlayer {
        require(msg.sender == playerA || msg.sender == playerB);
        _;
    }
    
    function claimLoss() public isPlayer {
        require(begun);
        require(!finished);
        uint8 player;
        if (msg.sender == playerA) {
            player = 1;
        } else {
            player = 2;
        }
        results[round] = player;
        round++;
        if (round==numRounds) {
            finished = true;
            payWinner();
        }
    }
    
    function payWinner() private {
        int8 score = 0;
        for (uint8 i=0 ; i < numRounds ; i++){
            if (results[i]==1){
                score++;
            } else {
                score--;
            }
        }
        
        if (score>0) {
            playerA.transfer(address(this).balance);
        } else {
            playerB.transfer(address(this).balance);
        }
    }
}