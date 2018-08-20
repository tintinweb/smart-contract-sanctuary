pragma solidity ^0.4.24;

/**
 * Taken from https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 *
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * Taken from https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/lifecycle/Pausable.sol
 *
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


/**
 * Taken from https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol
 *
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * Simple contract for asking and answering questions, in exchange for ERC20 tokens.
 * @author Austen Greene
 */
contract Magic8Ball is Pausable {

    struct Question {
        uint256 id;
        address asker;
        address tokenContract;
        uint256 bountyAmount;
        string content;
        bool alreadyAnswered;
        string answer;
    }

    event LogQuestionAsked(
        uint256 questionId,
        address indexed asker,
        string content,
        uint256 bountyAmount,
        address indexed tokenContract
    );

    event LogQuestionAnswered(
        uint256 indexed questionId,
        address indexed oracle,
        string answer
    );

    // map of questionId => Question data
    mapping (uint256 => Question) questions;

    // For every user, the mapping of what questions they are allowed to answer
    // To check if user A can answer question 3, check if oracleAllowedQuestions[A][3] == true;
    mapping (address => mapping (uint256 => bool)) oracleAllowedQuestions;

    //Helps us keep track of how many questions have been asked so far
    uint256 public nextQuestionId;

    constructor() public {
        nextQuestionId = 0;
    }

    /**
     * @dev Throws if called by any account other than the one who asked the question.
     */
    modifier onlyQuestionAsker(uint256 questionId) {
        require(msg.sender == questions[questionId].asker);
        _;
    }

    /**
     * @dev Throws if the question has already been answered
     */
    modifier onlyActiveQuestion(uint256 questionId) {
        require(!questions[questionId].alreadyAnswered);
        _;
    }


    /**
    * @dev Allows anyone to pay a bounty amount of their choosing (in the form of an ERC20 token of their choosing)
    * to ask a question, and set a list of addresses who can respond to answer the question. Before calling this
    * method the asker must have approved a token transfer of the bountyAmount with their specified ERC20 token
    * contract, otherwise the transaction will fail.
    * @param tokenContract Address of the token that will be used to pay the bounty
    * @param bountyAmount Amount of the token that will be paid out to the oracle
    * @param question The question to be answered
    * @param oracles list of addresses that are allowed to answer the question
    *
    */
    function askQuestion(address tokenContract, uint256 bountyAmount, string question, address[] oracles) public
    whenNotPaused()
    returns (uint256 questionId) {
        questionId = nextQuestionId;
        nextQuestionId++;

        questions[questionId] = Question(questionId, msg.sender, tokenContract, bountyAmount, question, false, &#39;&#39;);

        assignOracles(questionId, oracles);

        emit LogQuestionAsked(questionId, msg.sender, question, bountyAmount, tokenContract);

        //Warning Untrusted contract call!
        ERC20 untrustedToken = ERC20(tokenContract);

        bool success = untrustedToken.transferFrom(msg.sender, this, bountyAmount);
        require(success);
    }


    /**
    * @dev Allows the asker of a question to approve additional users to answer their question.  Can only be used by
    * the question asker of the specified question ID, will throw an exception for anyone else.
    * @param questionId Id of the question that the provided oracles will be allowed to answer
    * @param oracles list of addresses that are allowed to answer the question
    */
    function assignOracles(uint256 questionId, address[] oracles) public
    onlyQuestionAsker(questionId)
    onlyActiveQuestion(questionId)
    whenNotPaused()
    {
        // Warning: unbounded loop ... transaction may run out of gas and fail if the provided
        // list of allowed oracles is huge.
        // To get around this limitation askers can initially create the question with a smaller list,
        // and then call assignOracles multiple times to add the rest of the approved oracles later.
        for(uint i = 0 ; i < oracles.length ; i++) {
            oracleAllowedQuestions[oracles[i]][questionId] = true;
        }
    }

    /**
    * @dev Allows the asker of a question to remove users from the list of &#39;allowed oracles&#39; that can answer their
    * question.  Can only be used by the question asker of the specified question ID, will throw an exception for
    * anyone else.
    * @param questionId Id of the question that the provided oracles will no longer be allowed to answer
    * @param oracles list of addresses that are no longer allowed to answer the question
    */
    function removeOracles(uint256 questionId, address[] oracles) public
    onlyQuestionAsker(questionId)
    onlyActiveQuestion(questionId)
    whenNotPaused()
    {
        for(uint i = 0 ; i < oracles.length ; i++) {
            oracleAllowedQuestions[oracles[i]][questionId] = false;
        }
    }

    /**
    * @dev Allows an approved oracle to answer a question.  They will be paid out in the token provided
    * by the question asker
    * @param questionId ID of the question to be answered
    * @param answer the answer submitted
    */
    function answerQuestion(uint256 questionId, string answer) public
    onlyActiveQuestion(questionId)
    whenNotPaused()
    {
        bool approvedOracle = canUserAnswerQuestion(msg.sender, questionId);
        require(approvedOracle);

        Question storage question = questions[questionId];
        question.alreadyAnswered = true;
        question.answer = answer;

        emit LogQuestionAnswered(questionId, msg.sender, answer);

        //Warning Untrusted contract call!
        ERC20 untrustedToken = ERC20(question.tokenContract);

        bool success = untrustedToken.transfer(msg.sender, question.bountyAmount);
        require(success);
    }

    /**
    * @dev Checks the permission for the specified user on the specified question.  Returns true if they are allowed
    * to answer it, false otherwise.
    * @param user Address of the user to check permission for
    * @param questionId ID of the question to check permission for
    */
    function canUserAnswerQuestion(address user, uint256 questionId) public view returns (bool) {
        return oracleAllowedQuestions[user][questionId];
    }

    /**
    * @dev Returns stored data for the specified question:
    * @param questionId Id of the question to retrieve information about
    */
    function getQuestion(uint256 questionId) external view returns (uint256, address, uint256, string, bool, string) {
        Question storage question = questions[questionId];
        return (question.id, question.tokenContract, question.bountyAmount, question.content, question.alreadyAnswered, question.answer);
    }

}