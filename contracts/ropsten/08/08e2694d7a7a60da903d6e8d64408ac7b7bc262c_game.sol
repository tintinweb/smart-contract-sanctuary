/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.4.0;

 /*
 One day , the rich Scrooge McDuck felt boring.
 So the duck with so much wealth Says:
 " Let's play a game! ""
 He took out 0.00000000000000000001% of his wealth, bought some ethers.
 (With so much zero, it's still a 5 ether bouns)
 Then we have this game:
 Answer Scrooge's question, try to win the bouns!
 WoW?
 WoW.
 WoW!
 Of course, Scrooge is still Scrooge, he charges 0.5 ether as a ticket.
 So Let the game begin!
 ------------------------
 Check the question in the contract which is encoded as hexadecimal.
 Answer it with two hexadecimal coded answers.
 Oh there's a hint! But Scrooge won't tell you what's that for. 
 */
contract game {
    bytes32 private answer;
    bytes32 public hint;
    bytes public question;
    address public Scrooge;
    
    constructor() public payable {
        Scrooge = msg.sender;
    }
    
    modifier onlyScrooge {
        if (msg.sender != Scrooge) {
            revert("only Scrooge can do it :(");
        }
        _;
    }
    
    function start(bytes memory _answer1, bytes memory _answer2, bytes memory _question) public payable onlyScrooge {
        bytes32[2] answerHash;
        answerHash[0] = keccak256(_answer1);
        answerHash[1] = keccak256(_answer2);
        answer = keccak256(answerHash);
        hint = keccak256(_answer2);
        question = _question;
    }
    
    function guess(bytes memory _answer1, bytes memory _answer2) public payable {
        if (msg.value < 0.5 ether) {
            revert("need 0.5 ether to play :)");
        }
        
        bytes32[2] answerHash;
        answerHash[0] = keccak256(_answer1);
        answerHash[1] = keccak256(_answer2);
        if (keccak256(answerHash) == answer) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function stop() public onlyScrooge {
        Scrooge.transfer(this.balance);
    }
    
    function getBonus() public view returns(uint) {
        return this.balance;
    }
}