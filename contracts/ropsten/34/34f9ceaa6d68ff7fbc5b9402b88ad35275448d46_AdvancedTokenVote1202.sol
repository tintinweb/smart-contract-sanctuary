pragma solidity ^0.4.22;

// File: contracts/BasicErc20Token.sol

contract BasicErc20Token {

    string public name = &quot;BasicErc20Token&quot;;
    string public symbol = &quot;BET&quot;;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public {
        uint256 initialSupply = 100;
        balanceOf[msg.sender] = initialSupply;
        owner = msg.sender;

        // Give the creator all initial tokens
        totalSupply = initialSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // TODO not safe for overflow
        // Check for overflows
        balanceOf[msg.sender] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);
        // Notify anyone listening that this transfer took place
    }
}

// File: contracts/advanced-version/AdvancedERC1202.sol

/**
 * - Multiple issue
 * - Multiple selection
 * - Ordered multiple result
 * Discussion:
 *   1. Each address has a weight determined by other input decided by the actual implementation
 *      which is suggested to be set upon the initialization
 *   2. Is there certain naming convention to follow?
 */
contract AdvancedERC1202 {

    // Vote with an option. The caller needs to handle success or not
    function vote(uint issueId, uint option) public returns (bool success);
    function setStatus(uint issueId, bool isOpen) public returns (bool success);

    function issueDescription(uint issueId) public view returns (string desc);
    function availableOptions(uint issueId) public view returns (uint[] options);
    function optionDescription(uint issueId, uint option) public view returns (string desc);
    function ballotOf(uint issueId, address addr) public view returns (uint option);
    function weightOf(uint issueId, address addr) public view returns (uint weight);
    function getStatus(uint issueId) public view returns (bool isOpen);
    function weightedVoteCountsOf(uint issueId, uint option) public view returns (uint count);
    function topOptions(uint issueId, uint limit) public view returns (uint[] topOptions_);

    event OnVote(uint issueId, address indexed _from, uint _value);
    event OnStatusChange(uint issueId, bool newIsOpen);
}

// File: contracts/advanced-version/AdvancedTokenVote.sol

contract AdvancedTokenVote1202 {
    mapping(uint/*issueId*/ => string/*issueDesc*/) public issueDescriptions;
    mapping(uint/*issueId*/ => uint[]/*option*/) internal options;
    mapping(uint/*issueId*/ => mapping(uint/*option*/ => string/*desc*/)) internal optionDescMap;
    mapping(uint/*issueId*/ => bool) internal isOpen;

    mapping(uint/*issueId*/ => mapping (address/*user*/ => uint256/*weight*/)) public weights;
    mapping(uint/*issueId*/ => mapping (uint => uint256)) public weightedVoteCounts;
    mapping(uint/*issueId*/ => mapping (address => uint)) public  ballots;

    constructor() public {
        // This is a hack, remove until string[] is supported for a function parameter
        optionDescMap[0][1] = &quot;No&quot;;
        optionDescMap[0][2] = &quot;Yes, 100 more&quot;;
        optionDescMap[0][3] = &quot;Yes, 200 more&quot;;

        optionDescMap[1][1] = &quot;No&quot;;
        optionDescMap[1][2] = &quot;Yes&quot;;
    }

    function createIssue(uint issueId, address _tokenAddr, uint[] options_,
        address[] qualifiedVoters_, string issueDesc_
    ) public {
        require(options_.length >= 2);
        options[issueId] = options_;
        BasicErc20Token token = BasicErc20Token(_tokenAddr);
        isOpen[issueId] = true;

        // We realize the ERC20 will need to be extended to support snapshoting the weights/balances.
        for (uint i = 0; i < qualifiedVoters_.length; i++) {
            address voter = qualifiedVoters_[i];
            weights[issueId][voter] = token.balanceOf(voter);
        }
        issueDescriptions[issueId] = issueDesc_;

    }

    function vote(uint issueId, uint option) public returns (bool success) {
        require(isOpen[issueId]);
        // TODO check if option is valid

        uint256 weight = weights[issueId][msg.sender];
        weightedVoteCounts[issueId][option] += weight;  // initial value is zero
        ballots[issueId][msg.sender] = option;
        emit OnVote(issueId, msg.sender, option);
        return true;
    }

    function setStatus(uint issueId, bool isOpen_) public returns (bool success) {
        // Should have a sense of ownership. Only Owner should be able to set the status
        isOpen[issueId] = isOpen_;
        emit OnStatusChange(issueId, isOpen_);
        return true;
    }

    function ballotOf(uint issueId, address addr) public view returns (uint option) {
        return ballots[issueId][addr];
    }

    function weightOf(uint issueId, address addr) public view returns (uint weight) {
        return weights[issueId][addr];
    }

    function getStatus(uint issueId) public view returns (bool isOpen_) {
        return isOpen[issueId];
    }

    function weightedVoteCountsOf(uint issueId, uint option) public view returns (uint count) {
        return weightedVoteCounts[issueId][option];
    }

    // TODO: changed to topOptions if determined
    function winningOption(uint issueId) public view returns (uint option) {
        uint ci = 0;
        for (uint i = 1; i < options[issueId].length; i++) {
            uint optionI = options[issueId][i];
            uint optionCi = options[issueId][ci];
            if (weightedVoteCounts[issueId][optionI] > weightedVoteCounts[issueId][optionCi]) {
                ci = i;
            } // else keep it there
        }
        return options[issueId][ci];
    }

    function issueDescription(uint issueId) public view returns (string desc) {
        return issueDescriptions[issueId];
    }

    function availableOptions(uint issueId) public view returns (uint[] options_) {
        return options[issueId];
    }

    function optionDescription(uint issueId, uint option) public view returns (string desc) {
        return optionDescMap[issueId][option];
    }

    event OnVote(uint issueId, address indexed _from, uint _value);
    event OnStatusChange(uint issueId, bool newIsOpen);

}