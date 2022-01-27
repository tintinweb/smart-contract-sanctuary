/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RibonVoteToken {
    // nobdy can have more than x tokens at a time and everybody gets 4 tokens per week
    uint token_max = 4;
    uint limit_block = (60 * 60 * 24 * 7);
    struct TokenRecord {
        mapping(uint => uint) token;
    }
    mapping(address => TokenRecord) records;

    // variables
    address owner;
    uint public supply;
    uint public decimals;
    string public name;
    string public symbol;
    mapping(address => uint) balances;


    constructor() {
        owner = msg.sender;
        supply = 100000;
        decimals = 0;
        name = "Ribon Voting Token Test";
        symbol = "RBVT1";
    }

    function receiveTokens() public payable {
        uint i = 0;
        uint date = block.timestamp;
        // subtract 1 week from 
        uint week_ago = block.timestamp - limit_block;
        uint add_amount = 0;

        // loop through the max tokens and add a token to the balance if the last token is more than a week ago
        for(i = 0; i < token_max; i++) {
            if (records[msg.sender].token[i] <= week_ago) {
                add_amount += 1;
                records[msg.sender].token[i] = date;
            }
        }

        balances[msg.sender] += add_amount;
        supply -= add_amount;
    }

    function useVoteToken(address user) public {
        // we subtract a token from the current user
        // you can only user one token at a time
        balances[user] -= 1;
    }

    /* Events related to the protocol */
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // necessary ERC20 functions and events
    function totalSupply() public view returns (uint) {
        return supply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        require(spender == owner, "Only owner can spend other tokens");
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can transfer extra tokens");

        balances[to] += tokens;
        supply -= tokens;

        return true;
    }

    function approve(address spender, uint tokens) public view returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can approve extra tokens");

        require(balances[spender] >= tokens, "Balance insufficient");

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // in this case only the owner can send tokens
        require(msg.sender == owner, "Only owner can transfer extra tokens");

        balances[to] += tokens;
        balances[from] -= tokens;

        return true;
    }
}

contract Evaluation {
    address owner;
    address token_address;

    // question and question mapping
    struct Question {
        uint id;
        string question;
        uint status;
        uint yes;
        uint no;
        uint na;
    }
    mapping(uint => Question) questions;

    // nested mapping of evaluated users and their question values
    struct Rating {
        uint ratings;
        uint rating_value;
    }
    struct Evaluee {
        mapping(uint => Rating) ratings;
    }
    mapping(uint => Evaluee) evaluees;

    // evaluators
    struct Evaluator {
        uint id;
        uint level;
        string email;
    }
    mapping(address => Evaluator) evaluators;

    // evaluation count and limit
    struct EvaluationRecord {
        uint id;
        address evaluatator;
        uint evaluee;
        uint timestamp;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /**
     * Evaluator levels
     * 1 - Basic
     * 2 - Mid level admin
     * 3 - High level admin
     * 4 - Top Tier admin
     */
    modifier isAdmin {
        uint level = evaluators[msg.sender].level;
        require(level > 1 || msg.sender == owner);
        _;
    }

    modifier isModerator {
        uint level = evaluators[msg.sender].level;
        require(level > 2 || msg.sender == owner);
        _;
    }

    modifier isChief {
        uint level = evaluators[msg.sender].level;
        require(level > 3 || msg.sender == owner);
        _;
    }

    /**
     * Question Functions
     */
    function registerQuestion(uint _id, string memory _question, uint _yes, uint _no, uint _na) external isChief {
        questions[_id] = Question(_id, _question, 1, _yes, _no, _na);
    }

    function testTokenBalance() external view returns (uint balance) {
        RibonVoteToken _token = RibonVoteToken(token_address);
        uint user_balance = _token.balanceOf(msg.sender);
        require(user_balance < 1, "Insufficient voting tokens");

        return user_balance;
    }

    function evaluateQuestions(uint[] memory _ids, string[] memory _questions, uint[] memory _values, uint _userid) external payable returns (uint[] memory _eval) {
        // we have to make sure that the account can evaluate
        require(evaluators[msg.sender].level > 0, "Invalid Evaluator");

        // lets make sure this user has enough vote tokens to vote
        RibonVoteToken _token = RibonVoteToken(token_address);
        uint user_balance = _token.balanceOf(msg.sender);
        require(user_balance < 1, "Insufficient voting tokens");

        uint ids_length = _ids.length;
        uint questions_length = _questions.length;
        uint values_length = _values.length;

        // all lengths have to be the same size
        require(ids_length == questions_length && questions_length == values_length, "invalid inputs");

        // first we have to loop through all the ids and make sure that they're all valid
        uint i = 0;
        for(i = 0; i < ids_length; i++) {
            // we have to validate the question and id
            require(keccak256(abi.encodePacked((questions[_ids[i]].question))) == keccak256(abi.encodePacked((_questions[i]))), "Invalid Question");

            require(questions[_ids[i]].status == 1, "Invalid Question Status");
        }

        // once we know all the questions are valid we make the evaluation loop
        uint j = 0;
        uint[] memory evaluations;
        for(j = 0; j < ids_length; j++) {
            // we're going to save the evaluated value in a struct so we can get the values later
            evaluees[_userid].ratings[_ids[j]].ratings += 1;
            evaluees[_userid].ratings[_ids[j]].rating_value += _values[j];

            if (_values[j] == 1) evaluations[j] = questions[_ids[j]].yes;
            if (_values[j] == 2) evaluations[j] = questions[_ids[j]].no;
            if (_values[j] == 0) evaluations[j] = questions[_ids[j]].na;
        }

        // now that everything is ok, lets burn a vote token
        _token.useVoteToken(msg.sender);

        return evaluations;    
    }

    function showQuestion(uint _id) external view returns (uint id, string memory question) {
        return (questions[_id].id, questions[_id].question);
    }

    function showFullQuestion(uint _id) external view isChief returns (uint id, string memory question, uint yes, uint no, uint na) {
        return (questions[_id].id, questions[_id].question, questions[_id].yes, questions[_id].no, questions[_id].na);
    }

    function questionStatus(uint _id, uint _status) external isChief {
        questions[_id].status = _status;
    }

    /**
     * Evaluator functions
     */
    function registerSelfEvaluator(uint _id, string memory _email) external payable {
        // when you register an evaluator it automatically starts as a level 1
        // and mid tier admin can register an evaluator
        evaluators[msg.sender] = Evaluator(_id, 1, _email);
    }

    function registerEvaluator(address _address, uint _id, uint _level, string memory _email) external payable isModerator {
        // max level
        uint max = evaluators[msg.sender].level;

        // validate level
        require(_level > 0 && _level <= max, "Invalid Level");
        // when you register an evaluator it automatically starts as a level 1
        // and mid tier admin can register an evaluator
        evaluators[_address] = Evaluator(_id, 1, _email);
    }

    function changeEvaluatorLevel(address _address, uint _level) external payable {
        // max level
        uint max = evaluators[msg.sender].level;
        if (msg.sender == owner) max = 4;

        // you can only change the level to whatever your current level is
        require(_level > 0 && _level <= max, "Invalid Level");
        evaluators[_address].level = _level;
    }

    /**
     * Scoring and data of evaluation functions
     */
    function getEvaluationValue(uint _questionId, uint _userid) external view returns (uint _evaluations, uint _value) {
        return (evaluees[_userid].ratings[_questionId].ratings, evaluees[_userid].ratings[_questionId].rating_value);
    }

    function setTokenAddress(address _token) external payable onlyOwner {
        token_address = _token;
    }

    // kill contract if necessary
    function destroySmartContract(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}