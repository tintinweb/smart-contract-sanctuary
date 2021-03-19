/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.4.24;

contract Riddle {
    bytes32 private answerHash;
    bool public isActive;
    string public riddle;
    string public answer;

    address private riddler;

    function () payable public {}
    
    constructor (string _riddle, bytes32 _answerHash) public payable {
        riddler = msg.sender;
        riddle = _riddle;
        answerHash = _answerHash;
        isActive = true;
    }
    
    function verifyAnswer(string guess) public view returns(bool) {
        if (keccak256(guess) == answerHash) {
           return true;
        }

    }

    function play(string guess) public {
        require(isActive);
        require(bytes(guess).length > 0);
        
        if (keccak256(guess) == answerHash) {
            answer = guess;
            isActive = false;
            msg.sender.transfer(this.balance);
        }
    }
    
    function end(string _answer) public {
        require(msg.sender == riddler);
        answer = _answer;
        isActive = false;
        msg.sender.transfer(this.balance);
    }
}