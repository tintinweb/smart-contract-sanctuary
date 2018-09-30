pragma solidity ^0.4.23;

contract WhatDoesNadiaThink_1 {
    address public owner;

    string public question;
    string public questionType;
    string public answerHash;
    bytes32[] public responses;
    uint256 public timeout;
    bool public isQuestionOpen;
    
    event AddressandAnswer(address indexed _from, uint256 indexed _result, uint _value );

    constructor(string _question, bytes32[] _responses, string _questionType, string _answerHash, uint256 timeoutDelay)
        public
    {
        owner = msg.sender;
        question = _question;
        responses = _responses;
        timeout = now + timeoutDelay;
        questionType = _questionType; // Categories are art, fact, and opinion.
        answerHash = _answerHash; // Hash of correct answer to verify integrity.
        isQuestionOpen = true; // Lets frontend check if the question is open for answers.

    }

    enum States { Open, Closed, Resolved, Cancelled }
    States state = States.Open;

    mapping(address => mapping(uint256 => uint256)) public answerAmount;
    mapping(uint256 => uint256) public totalPerResponse;
    uint256 public total;

    uint256 winningResponse;

    function answer(uint256 result) public payable {
        require(state == States.Open);

        answerAmount[msg.sender][result] += msg.value;
        totalPerResponse[result] += msg.value;
        total += msg.value;
        require(total < 2 ** 128);   // Avoid overflow possibility.
        
        emit AddressandAnswer(msg.sender, result, msg.value);
    }

    function close() public {
        require(state == States.Open);
        require(msg.sender == owner);
        isQuestionOpen = false;
        state = States.Closed;
    }

    function resolve(uint256 _winningResponse) public {
        require(state == States.Closed);
        require(msg.sender == owner);

        winningResponse = _winningResponse;
        state = States.Resolved;
    }

    function claim() public {
        require(state == States.Resolved);

        uint256 amount = answerAmount[msg.sender][winningResponse] * total
            / totalPerResponse[winningResponse];
        answerAmount[msg.sender][winningResponse] = 0;
        msg.sender.transfer(amount);
    }

    function cancel() public {
        require(state != States.Resolved);
        require(msg.sender == owner || now > timeout);
        isQuestionOpen = false;

        state = States.Cancelled;
    }

    function refund(uint256 result) public {
        require(state == States.Cancelled);

        uint256 amount = answerAmount[msg.sender][result];
        answerAmount[msg.sender][result] = 0;
        msg.sender.transfer(amount);
    }
}