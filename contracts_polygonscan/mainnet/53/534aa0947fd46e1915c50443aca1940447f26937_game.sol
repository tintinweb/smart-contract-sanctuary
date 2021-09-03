/**
 *Submitted for verification at polygonscan.com on 2021-09-03
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
 */
contract game { 
    bytes32 private answer;
    bytes32 private hint;
    address private Scrooge;
    string private question;
    uint private index;
    uint private deadline;
    mapping(uint => comment) comments;
    
    event bingo(address winner, string answer1, string answer2, uint bouns);
    
    struct comment {
        address sender;
        string message;
        uint128 timestamp;
        uint128 tip;
    }
    
    constructor() public payable {
        Scrooge = msg.sender;
    }
    
    modifier onlyScrooge {
        if (msg.sender != Scrooge) {
            revert("only Scrooge can do it :(");
        }
        _;
    }
    
    modifier beforeDeadline {
        if (block.timestamp >= deadline) {
            revert("There is no ongoing question!");
        }
        _;
    }
    
    function start(string _answer1, string _answer2, string _question, uint period) public payable onlyScrooge {
        bytes32[2] answerHash;
        answerHash[0] = keccak256(_answer1);
        answerHash[1] = keccak256(_answer2);
        answer = keccak256(answerHash);
        hint = keccak256(_answer2);
        question = _question;
        deadline = block.timestamp + period;
    }
    
    function stop() public onlyScrooge {
        Scrooge.transfer(this.balance);
        deadline = block.timestamp;
    }
    
    // guess _answer1 && _answer2
    // need 0.5 ether to play
    // get all the money if correct
    function guess(string _answer1, string _answer2) public payable beforeDeadline {
        if (msg.value < 0.5 ether) {
            revert("need 0.5 ether to play :)");
        }
        
        bytes32[2] answerHash;
        answerHash[0] = keccak256(_answer1);
        answerHash[1] = keccak256(_answer2);
        if (keccak256(answerHash) == answer) {
            bingo(msg.sender, _answer1, _answer2, this.balance);
            msg.sender.transfer(this.balance);
            deadline = block.timestamp;
        }
    }
    
    // guess _answer1 
    // need 0.1 ether to play
    // get your ether back if you are right
    // verify your answers before the FINAL GUESS
    function guessTheFirstAnswer(string _answer1) public payable beforeDeadline {
        if (msg.value < 0.1 ether) {
            revert("need 0.1 ether to play :)");
        }
        
        bytes32 answerOneHash = keccak256(_answer1);
        if (keccak256(answerOneHash,hint) == answer) {
            msg.sender.transfer(msg.value);
            bingo(msg.sender, _answer1, "", msg.value);
        }
    }
    
    // guess _answer2 
    // ......
    function guessTheSecondAnswer(string _answer2) public payable beforeDeadline {
        if (msg.value < 0.1 ether) {
            revert("need 0.1 ether to play :)");
        }
        
        if (keccak256(_answer2) == hint) {
            msg.sender.transfer(msg.value);
            bingo(msg.sender, "", _answer2, msg.value);
        }
    }
    
    // leave comments or give tips here
    function leaveComment(string content, uint128 timestamp) public payable {
        comment c;
        c.sender = msg.sender;
        c.message = content;
        c.tip = uint128(msg.value);
        c.timestamp = timestamp;
        comments[index++] = c;
    }
    
    function getTime() public view returns(uint _now, uint _deadline, uint _countDown) {
        if (deadline < block.timestamp) {
            return (block.timestamp ,deadline ,0);
        }
        return (block.timestamp ,deadline ,deadline-block.timestamp);
    }
    
    function getBonus() public view returns(uint _wei, uint _ether) {
        return (this.balance, this.balance/10**18);
    }
    
    function readQuestion() public view beforeDeadline returns(string) {
        return question;
    }
    
    function readComment(uint _index) public view returns(address sender ,uint128 timestamp, uint128 tip, string content) {
        if (_index >= index) {
            revert("no such comment");
        }
        comment c = comments[_index];
        return(c.sender, c.tip, c.timestamp, c.message);
    }
    
    function() public payable {}
}