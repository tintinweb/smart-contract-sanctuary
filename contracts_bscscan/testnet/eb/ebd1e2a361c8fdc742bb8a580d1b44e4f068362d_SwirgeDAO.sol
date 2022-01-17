/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenLocker {
    
    address public owner;

    ERC20 public token;

    /**
     * @dev Create a new TokenLocker contract
     * @param tokenAddr ERC20 token this contract will be used to lock
     */
    function TokenLocker (ERC20 tokenAddr) public {
        owner = msg.sender;
        token = tokenAddr;
    }

    /** 
     *  @dev Call the ERC20 `transfer` function on the underlying token contract
     *  @param dest Token destination
     *  @param amount Amount of tokens to be transferred
     */
    function transfer(address dest, uint amount) public returns (bool) {
        require(msg.sender == owner);
        return token.transfer(dest, amount);
    }

}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function () payable public {
        ReceivedEther(msg.sender, msg.value);
    }
}

contract DelegatedShareholderAssociation is TokenRecipient {

    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
    ERC20 public sharesTokenAddress;

    /* Delegate addresses by delegator. */
    mapping (address => address) public delegatesByDelegator;

    /* Locked tokens by delegator. */
    mapping (address => uint) public lockedDelegatingTokens;

    /* Delegated votes by delegate. */
    mapping (address => uint) public delegatedAmountsByDelegate;
    
    /* Tokens currently locked by vote delegation. */
    uint public totalLockedTokens;

    /* Threshold for the ability to create proposals. */
    uint public requiredSharesToBeBoardMember;

    /* Token Locker contract. */
    TokenLocker public tokenLocker;

    /* Events for all state changes. */

    event ProposalAdded(uint proposalID, address recipient, uint amount, bytes metadataHash);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint yea, uint nay, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, address newSharesTokenAddress);
    event TokensDelegated(address indexed delegator, uint numberOfTokens, address indexed delegate);
    event TokensUndelegated(address indexed delegator, uint numberOfTokens, address indexed delegate);

    struct Proposal {
        address recipient;
        uint amount;
        bytes metadataHash;
        uint timeCreated;
        uint votingDeadline;
        bool finalized;
        bool proposalPassed;
        uint numberOfVotes;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    /* Only shareholders can execute a function with this modifier. */
    modifier onlyShareholders {
        require(ERC20(sharesTokenAddress).balanceOf(msg.sender) > 0);
        _;
    }

    /* Only the DAO itself (via an approved proposal) can execute a function with this modifier. */
    modifier onlySelf {
        require(msg.sender == address(this));
        _;
    }

    /* Any account except the DAO itself can execute a function with this modifier. */
    modifier notSelf {
        require(msg.sender != address(this));
        _;
    }

    /* Only a shareholder who has *not* delegated his vote can execute a function with this modifier. */
    modifier onlyUndelegated {
        require(delegatesByDelegator[msg.sender] == address(0));
        _;
    }

    /* Only boardmembers (shareholders above a certain threshold) can execute a function with this modifier. */
    modifier onlyBoardMembers {
        require(ERC20(sharesTokenAddress).balanceOf(msg.sender) >= requiredSharesToBeBoardMember);
        _;
    }

    /* Only a shareholder who has delegated his vote can execute a function with this modifier. */
    modifier onlyDelegated {
        require(delegatesByDelegator[msg.sender] != address(0));
        _;
    }

    /**
      * Delegate an amount of tokens
      * 
      * @notice Set the delegate address for a specified number of tokens belonging to the sending address, locking the tokens.
      * @dev An address holding tokens (shares) may only delegate some portion of their vote to one delegate at any one time
      * @param tokensToLock number of tokens to be locked (sending address must have at least this many tokens)
      * @param delegate the address to which votes equal to the number of tokens locked will be delegated
      */
    function setDelegateAndLockTokens(uint tokensToLock, address delegate)
        public
        onlyShareholders
        onlyUndelegated
        notSelf
    {
        lockedDelegatingTokens[msg.sender] = tokensToLock;
        delegatedAmountsByDelegate[delegate] = SafeMath.add(delegatedAmountsByDelegate[delegate], tokensToLock);
        totalLockedTokens = SafeMath.add(totalLockedTokens, tokensToLock);
        delegatesByDelegator[msg.sender] = delegate;
        require(sharesTokenAddress.transferFrom(msg.sender, tokenLocker, tokensToLock));
        require(sharesTokenAddress.balanceOf(tokenLocker) == totalLockedTokens);
        TokensDelegated(msg.sender, tokensToLock, delegate);
    }

    /** 
     * Undelegate all delegated tokens
     * 
     * @notice Clear the delegate address for all tokens delegated by the sending address, unlocking the locked tokens.
     * @dev Can only be called by a sending address currently delegating tokens, will transfer all locked tokens back to the sender
     * @return The number of tokens previously locked, now released
     */
    function clearDelegateAndUnlockTokens()
        public
        onlyDelegated
        notSelf
        returns (uint lockedTokens)
    {
        address delegate = delegatesByDelegator[msg.sender];
        lockedTokens = lockedDelegatingTokens[msg.sender];
        lockedDelegatingTokens[msg.sender] = 0;
        delegatedAmountsByDelegate[delegate] = SafeMath.sub(delegatedAmountsByDelegate[delegate], lockedTokens);
        totalLockedTokens = SafeMath.sub(totalLockedTokens, lockedTokens);
        delete delegatesByDelegator[msg.sender];
        require(tokenLocker.transfer(msg.sender, lockedTokens));
        require(sharesTokenAddress.balanceOf(tokenLocker) == totalLockedTokens);
        TokensUndelegated(msg.sender, lockedTokens, delegate);
        return lockedTokens;
    }

    /**
     * Change voting rules
     *
     * Make so that proposals need tobe discussed for at least `minutesForDebate/60` hours
     * and all voters combined must own more than `minimumSharesToPassAVote` shares of token `sharesAddress` to be executed
     * and a shareholder needs `sharesToBeBoardMember` shares to create a transaction proposal
     *
     * @param minimumSharesToPassAVote proposal can vote only if the sum of shares held by all voters exceed this number
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     * @param sharesToBeBoardMember the minimum number of shares required to create proposals
     */
    function changeVotingRules(uint minimumSharesToPassAVote, uint minutesForDebate, uint sharesToBeBoardMember)
        public
        onlySelf
    {
        if (minimumSharesToPassAVote == 0 ) {
            minimumSharesToPassAVote = 1;
        }
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriodInMinutes = minutesForDebate;
        requiredSharesToBeBoardMember = sharesToBeBoardMember;
        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, sharesTokenAddress);
    }

    /**
     * Add Proposal
     *
     * Propose to send `weiAmount / 1e18` ether to `beneficiary` for `jobMetadataHash`. `transactionBytecode ? Contains : Does not contain` code.
     *
     * @dev Submit proposal for the DAO to execute a particular transaction. Submitter should check that the `beneficiary` account exists, unless the intent is to burn Ether.
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send, in wei
     * @param jobMetadataHash Hash of job metadata (IPFS)
     * @param transactionBytecode bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint weiAmount,
        bytes jobMetadataHash,
        bytes transactionBytecode
    )
        public
        onlyBoardMembers
        notSelf
        returns (uint proposalID)
    {
        /* Proposals cannot be directed to the token locking contract. */
        require(beneficiary != address(tokenLocker));
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.metadataHash = jobMetadataHash;
        p.proposalHash = keccak256(beneficiary, weiAmount, transactionBytecode);
        p.timeCreated = now;
        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.finalized = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        ProposalAdded(proposalID, beneficiary, weiAmount, jobMetadataHash);
        numProposals = proposalID+1;
        return proposalID;
    }

    /**
     * Check if a proposal code matches
     *
     * @param proposalNumber ID number of the proposal to query
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send
     * @param transactionBytecode bytecode of transaction
     */
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint weiAmount,
        bytes transactionBytecode
    )
        public
        view
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(beneficiary, weiAmount, transactionBytecode);
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @dev Vote in favor or against an existing proposal. Voter should check that the proposal destination account exists, unless the intent is to burn Ether.
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     */
    function vote(
        uint proposalNumber,
        bool supportsProposal
    )
        public
        onlyShareholders
        notSelf
        returns (uint voteID)
    {
        Proposal storage p = proposals[proposalNumber];
        require(p.voted[msg.sender] != true);
        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID + 1;
        Voted(proposalNumber, supportsProposal, msg.sender);
        return voteID;
    }

    /**
     * Return whether a particular shareholder has voted on a particular proposal (convenience function)
     * @param proposalNumber proposal number
     * @param shareholder address to query
     * @return whether or not the specified address has cast a vote on the specified proposal
     */
    function hasVoted(uint proposalNumber, address shareholder) public view returns (bool) {
        Proposal storage p = proposals[proposalNumber];
        return p.voted[shareholder];
    }

    /**
     * Count the votes, including delegated votes, in support of, against, and in total for a particular proposal
     * @param proposalNumber proposal number
     * @return yea votes, nay votes, quorum (total votes)
     */
    function countVotes(uint proposalNumber) public view returns (uint yea, uint nay, uint quorum) {
        Proposal storage p = proposals[proposalNumber];
        yea = 0;
        nay = 0;
        quorum = 0;
        for (uint i = 0; i < p.votes.length; ++i) {
            Vote storage v = p.votes[i];
            uint voteWeight = SafeMath.add(sharesTokenAddress.balanceOf(v.voter), delegatedAmountsByDelegate[v.voter]);
            quorum = SafeMath.add(quorum, voteWeight);
            if (v.inSupport) {
                yea = SafeMath.add(yea, voteWeight);
            } else {
                nay = SafeMath.add(nay, voteWeight);
            }
        }
    }

    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
     */
    function executeProposal(uint proposalNumber, bytes transactionBytecode)
        public
        notSelf
    {
        Proposal storage p = proposals[proposalNumber];

        /* If at or past deadline, not already finalized, and code is correct, keep going. */
        require((now >= p.votingDeadline) && !p.finalized && p.proposalHash == keccak256(p.recipient, p.amount, transactionBytecode));

        /* Count the votes. */
        var ( yea, nay, quorum ) = countVotes(proposalNumber);

        /* Assert that a minimum quorum has been reached. */
        require(quorum >= minimumQuorum);
        
        /* Mark proposal as finalized. */   
        p.finalized = true;

        if (yea > nay) {
            /* Mark proposal as passed. */
            p.proposalPassed = true;

            /* Execute the function. */
            require(p.recipient.call.value(p.amount)(transactionBytecode));

        } else {
            /* Proposal failed. */
            p.proposalPassed = false;
        }

        /* Log event. */
        ProposalTallied(proposalNumber, yea, nay, quorum, p.proposalPassed);
    }
}

contract SwirgeDAO is DelegatedShareholderAssociation {

    string public constant name = "Project Swirge DAO";

    uint public constant TOKEN_DECIMALS                     = 18;
    uint public constant REQUIRED_SHARES_TO_BE_BOARD_MEMBER = 8000 * (10 ** TOKEN_DECIMALS); // set to ~ 0.1% of supply
    uint public constant MINIMUM_QUORUM                     = 800000 * (10 ** TOKEN_DECIMALS); // set to 10% of supply
    uint public constant DEBATE_PERIOD_MINUTES              = 60 * 24 * 3; // set to 3 days

    function SwirgeDAO (ERC20 sharesAddress) public {
        sharesTokenAddress = sharesAddress;
        requiredSharesToBeBoardMember = REQUIRED_SHARES_TO_BE_BOARD_MEMBER;
        minimumQuorum = MINIMUM_QUORUM;
        debatingPeriodInMinutes = DEBATE_PERIOD_MINUTES;
        tokenLocker = new TokenLocker(sharesAddress);
    }

}