pragma solidity ^0.4.24;

// This contract is a fork of Dr. Todd Proebsting&#39;s parimutuel contract. https://programtheblockchain.com/posts/2018/05/08/writing-a-parimutuel-wager-contract/
// Additional gas guzzling shitcoding by Woody Deck.

contract WhatDoesNadiaThink {
    address public owner;
    string public question;
    string public questionType;
    string public answerHash;
    bytes32[] public responses;
    uint256 public marketClosureTime;
    uint256 public timeout;
    uint256 public integrityFee;
    uint256 public integrityPercentage;
    uint256 public winningAnswer;
    uint256 public total;
    
    event AddressandAnswer(address indexed _from, uint256 indexed _result, uint _value);

    constructor(string _question, bytes32[] _responses, string _questionType, string _answerHash, uint256 _timeQuestionIsOpen)
        public payable
    {
        owner = msg.sender;
        question = _question;
        responses = _responses;
        marketClosureTime = now + _timeQuestionIsOpen; // The time in seconds that the market is open. After this time, the answer() function will revert all incoming transactions 
        // until close() is executed by the owner. The frontend of the Dapp will check if the question is open for answer by seeing if the closure time has passed. Transacting 
        // manually outside of the Dapp will mean you need to calculate this time yourself.
        timeout = now + _timeQuestionIsOpen + 1209600; // The contract function cancel() can be executed by anyone after 14 days after market closure (1,209,600 seconds is 14 days).
        // This is to allow for refunds if the answer is not posted in a timely manner. The market can still be resolved normally if the contract owner posts the result after 
        // 14 days, but before anyone calls cancel().
        questionType = _questionType; // Categories are art, fact, and opinion.
        answerHash = _answerHash; // Hash of correct answer to verify integrity of the posted answer.
        integrityPercentage = 5; // The market integrity fee (5% of the total) goes to the contract owner. It is to strongly encourage answer secrecy and fair play. The amount is about double what could be realistically stolen via insider trading without being easily detected forensically.  
        winningAnswer = 1234; // Set initially to 1234 (all possible answers) so the frontend can recognize when the market is closed, but not yet resolved with an answer. The variable winningAnswer is purely statistical in nature.
        total = msg.value; // This contract version is payable so the market can be seeded with free Ether to incentivize answers.
    }

    enum States { Open, Resolved, Cancelled }
    States state = States.Open;

    mapping(address => mapping(uint256 => uint256)) public answerAmount;
    mapping(uint256 => uint256) public totalPerResponse;


    uint256 winningResponse;

    function answer(uint256 result) public payable {
        
        if (now > marketClosureTime) {
            revert(); // Prevents answers after the market closes.
        }
        
        require(state == States.Open);

        answerAmount[msg.sender][result] += msg.value;
        totalPerResponse[result] += msg.value;
        total += msg.value;
        require(total < 2 ** 128);   // Avoid overflow possibility.
        
        emit AddressandAnswer(msg.sender, result, msg.value);
    }

    function resolve(uint256 _winningResponse) public {
        require(now > marketClosureTime && state == States.Open); // States of smart contracts are updated only when someone transacts with them. The answer function looks up the Unix time that is converted on the front end to see if the market is still open. The state doesn&#39;t change until resolved, so both cases must be true in order to use the resolve() function, otherwise the owner could resolve early or change the answer after. &#39;
        require(msg.sender == owner);

        winningResponse = _winningResponse; // This is the internally used integer, as arrays in Solidity start from 0.
        winningAnswer = winningResponse + 1; // Publically posts the correct answer. The &#39;+ 1&#39; addition is for the frontend and to avoid layman confusion with arrays that start from zero.
        
        if (totalPerResponse[winningResponse] == 0) {
            state = States.Cancelled; // If nobody bet on the winning answer, the market is cancelled, else it is resolved. Losing bets will be refunded. 
        } else {
            state = States.Resolved;
            integrityFee = total * integrityPercentage/100; // Only collect the integrityFee if the market resolves. It would be a mess to take upfront in case of cancel() being executed.
            msg.sender.transfer(integrityFee); // The integrityFee goes to the owner.
        }
        
    }

    function claim() public {
        require(state == States.Resolved);

        uint256 amount = answerAmount[msg.sender][winningResponse] * (total - integrityFee) / totalPerResponse[winningResponse]; // Subtract the integrityFee from the total before paying out winners.
        answerAmount[msg.sender][winningResponse] = 0;
        msg.sender.transfer(amount);
    }

    function cancel() public {
        require(state != States.Resolved);
        require(msg.sender == owner || now > timeout);

        state = States.Cancelled;
    }

    function refund(uint256 result) public {
        require(state == States.Cancelled);

        uint256 amount = answerAmount[msg.sender][result]; // You have to manually choose which answer you bet on because every answer is now entitled to a refund. Please when manually requesting a refund outside of the Dapp that Answer 1 is 0, Answer 2 is 1, Answer is 3, and Answer 4 is 3 as arrays start from 0. There is nothing bad that happens if you screw this up except a waste of gas. 
        answerAmount[msg.sender][result] = 0;
        msg.sender.transfer(amount);
    }
}