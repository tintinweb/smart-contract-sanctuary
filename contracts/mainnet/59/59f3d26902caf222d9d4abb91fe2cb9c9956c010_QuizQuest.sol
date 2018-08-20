pragma solidity ^0.4.24;

contract QuizQuest {
    bytes32 private answerHash;
    bool private isActive;
    Guess[] public PreviousGuesses;
    string public Riddle;
    string public Answer;

    struct Guess { address player; string guess; }
    address private riddler;

    function () payable public {}
    
    function Quiz(string _riddle, string _answer) public payable {
        if (riddler == 0x0) {
            riddler = msg.sender;
            Riddle = _riddle;
            answerHash = keccak256(_answer);
            isActive = true;
        }
    }

    function Play(string guess) public payable {
        require(isActive && msg.value >= 0.5 ether);
        if (bytes(guess).length == 0) return;
        
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
    
    function End(string _answer) public {
        require(msg.sender == riddler);
        Answer = _answer;
        isActive = false;
        msg.sender.transfer(this.balance);
    }
}