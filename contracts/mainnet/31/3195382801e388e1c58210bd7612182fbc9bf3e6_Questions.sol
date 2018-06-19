pragma solidity ^0.4.19;

contract Questions {
    struct Question {
        address creator;
        uint paymentForAnswer;
        uint8 maxAnswers;
        uint8 answerCount;
        int minVoteWeight;
    }
    
    struct Answer {
        bool placed;
        int rating;
        uint8 votes;
    }
    
    address public owner;
    uint private ownerBalance;
    
    uint public minPaymentForAnswer = 1 finney;
    uint public votesForAnswer = 5;
    int public maxAbsKindness = 25;
    uint public resetVoteKindnessEvery = 5000;
    uint public minVoteWeightK = 1 finney;
    
    mapping (uint => Question) public questions;
    uint public currentQuestionId = 0;
    
    // questionId => creator => rating
    mapping (uint => mapping (address => Answer)) public answers;
    
    // questionId => creator => voter => true
    mapping (uint => mapping (address => mapping (address => bool))) public votes;
    
    // voter => kindness
    mapping (address => int8) public voteKindness;
    
    // user => vote kindness reset
    mapping (address => uint) public voteKindnessReset;
    
    // user => vote weight
    mapping (address => int) public voteWeight;
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    event PlaceQuestion(
        uint indexed questionId,
        address indexed creator,
        uint paymentForAnswer,
        uint8 maxAnswers,
        uint minVoteWeight,
        string text
    );
    event PlaceAnswer(
        uint indexed questionId,
        address indexed creator,
        string text
    );
    event Vote(uint indexed questionId, address indexed creator, int ratingDelta);
    event VoteWeightChange(address indexed user, int weight);

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    function setMinPaymentForAnswer(uint value) external onlyOwner {
        require(value < minPaymentForAnswer);
        minPaymentForAnswer = value;
    }
    
    function setMaxAbsKindness(int value) external onlyOwner {
        require(value > 0);
        maxAbsKindness = value;
    }
    
    function setResetVoteKindnessEvery(uint value) external onlyOwner {
        resetVoteKindnessEvery = value;
    }
    
    function setMinVoteWeightK(uint value) external onlyOwner {
        minVoteWeightK = value;
    }
    
    function Questions() public {
        owner = msg.sender;
    }
    
    function safeAdd(uint a, uint b) private pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint a, uint b) private pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeMul(uint a, uint b) private pure returns (uint) {
        if (a == 0) {
          return 0;
        }
        
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function changeVoteWeight(address user, int delta) internal {
        voteWeight[user] += delta;
        VoteWeightChange(user, voteWeight[user]);
    }
    
    function placeQuestion(uint paymentForAnswer, uint8 maxAnswers, uint minVoteWeight, string text) external payable {
        require(maxAnswers > 0 && maxAnswers <= 32);
        require(msg.value == safeMul(paymentForAnswer, safeAdd(maxAnswers, 1)));
        require(paymentForAnswer >= safeAdd(minPaymentForAnswer, safeMul(minVoteWeight, minVoteWeightK)));
        uint len = bytes(text).length;
        require(len > 0 && len <= 1024);
        
        uint realPaymentForAnswer = paymentForAnswer / 2;
        uint realPaymentForVote = realPaymentForAnswer / votesForAnswer;
        
        int minVoteWeightI = int(minVoteWeight);
        require(minVoteWeightI >= 0);
        
        questions[currentQuestionId] = Question({
            creator: msg.sender,
            paymentForAnswer: realPaymentForAnswer,
            maxAnswers: maxAnswers,
            answerCount: 0,
            minVoteWeight: minVoteWeightI
        });
        PlaceQuestion(currentQuestionId, msg.sender, realPaymentForAnswer, maxAnswers, minVoteWeight, text);
        currentQuestionId++;
        
        changeVoteWeight(msg.sender, 1);
        
        ownerBalance += msg.value - (realPaymentForAnswer + realPaymentForVote * votesForAnswer) * maxAnswers;
        
        FundTransfer(msg.sender, msg.value, true);
    }
    
    function placeAnswer(uint questionId, string text) external {
        require(questions[questionId].creator != 0x0);
        require(questions[questionId].creator != msg.sender);
        require(!answers[questionId][msg.sender].placed);
        uint len = bytes(text).length;
        require(len > 0 && len <= 1024);
        require(questions[questionId].answerCount < questions[questionId].maxAnswers);
        require(voteWeight[msg.sender] >= questions[questionId].minVoteWeight);
        
        questions[questionId].answerCount++;
        answers[questionId][msg.sender] = Answer({
            placed: true,
            rating: 0,
            votes: 0
        });
        PlaceAnswer(questionId, msg.sender, text);
    }
    
    function voteForAnswer(uint questionId, address creator, bool isSpam) external {
        require(questions[questionId].creator != msg.sender);
        require(creator != msg.sender);
        require(answers[questionId][creator].placed);
        require(answers[questionId][creator].votes < votesForAnswer);
        require(!votes[questionId][creator][msg.sender]);
        require(voteWeight[msg.sender] > 0);
        require(voteWeight[msg.sender] >= questions[questionId].minVoteWeight);
        
        if (voteKindnessReset[msg.sender] + resetVoteKindnessEvery <= block.number) {
            voteKindness[msg.sender] = 0;
            voteKindnessReset[msg.sender] = block.number;
        }
        
        if (isSpam) {
            require(voteKindness[msg.sender] > -maxAbsKindness);
            voteKindness[msg.sender]--;
        } else {
            require(voteKindness[msg.sender] < maxAbsKindness);
            voteKindness[msg.sender]++;
        }
        
        int ratingDelta = isSpam ? -voteWeight[msg.sender] : voteWeight[msg.sender];
        votes[questionId][creator][msg.sender] = true;
        answers[questionId][creator].votes++;
        answers[questionId][creator].rating += ratingDelta;
        Vote(questionId, creator, ratingDelta);
        
        uint payment = questions[questionId].paymentForAnswer / votesForAnswer;
        msg.sender.transfer(payment);
        FundTransfer(msg.sender, payment, false);
        
        if (answers[questionId][creator].votes == votesForAnswer) {
            if (answers[questionId][creator].rating > 0) {
                creator.transfer(questions[questionId].paymentForAnswer);
                FundTransfer(creator, questions[questionId].paymentForAnswer, false);
                
                changeVoteWeight(creator, 5);
            } else {
                questions[questionId].creator.transfer(questions[questionId].paymentForAnswer);
                FundTransfer(questions[questionId].creator, questions[questionId].paymentForAnswer, false);
                
                changeVoteWeight(creator, -5);
            }
        }
    }
    
    function withdrawEther() external onlyOwner {
        owner.transfer(ownerBalance);
        ownerBalance = 0;
    }
}