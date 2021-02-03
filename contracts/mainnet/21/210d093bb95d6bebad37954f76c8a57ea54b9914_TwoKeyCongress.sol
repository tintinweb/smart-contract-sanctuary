/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract TwoKeyCongress {

    event ReceivedEther(address sender, uint amount);

    using SafeMath for uint;

    //Period length for voting
    uint256 public debatingPeriodInMinutes;
    //Array of proposals
    Proposal[] public proposals;
    //Number of proposals
    uint public numProposals;

    TwoKeyCongressMembersRegistry public twoKeyCongressMembersRegistry;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, uint quorum, bool active);
    event ChangeOfRules(uint256 _newDebatingPeriodInMinutes);

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint minExecutionDate;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        uint againstProposalTotal;
        uint supportingProposalTotal;
        bytes32 proposalHash;
        bytes transactionBytecode;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }


    /**
     * @notice Modifier to check if the msg.sender is member of the congress
     */
    modifier onlyMembers() {
        require(twoKeyCongressMembersRegistry.isMember(msg.sender) == true);
        _;
    }

    /**
     * @param _minutesForDebate is the number of minutes debate length
     */
    constructor(
        uint256 _minutesForDebate
    )
    payable
    public
    {
        changeVotingRules(_minutesForDebate);
    }

    /**
     * @notice Function which will be called only once immediately after contract is deployed
     * @param _twoKeyCongressMembers is the address of already deployed contract
     */
    function setTwoKeyCongressMembersContract(
        address _twoKeyCongressMembers
    )
    public
    {
        require(address(twoKeyCongressMembersRegistry) == address(0));
        twoKeyCongressMembersRegistry = TwoKeyCongressMembersRegistry(_twoKeyCongressMembers);
    }


    /**
     * Change voting rules
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     */
    function changeVotingRules(
        uint256 minutesForDebate
    )
    internal
    {
        debatingPeriodInMinutes = minutesForDebate;
        emit ChangeOfRules(minutesForDebate);
    }

    /**
     * Add Proposal
     *
     * Propose to send `weiAmount / 1e18` ether to `beneficiary` for `jobDescription`. `transactionBytecode ? Contains : Does not contain` code.
     *
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send, in wei
     * @param jobDescription Description of job
     * @param transactionBytecode bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint weiAmount,
        string jobDescription,
        bytes transactionBytecode)
    public
    payable
    onlyMembers
    {
        uint proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = jobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
        p.transactionBytecode = transactionBytecode;
        p.minExecutionDate = block.timestamp + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.againstProposalTotal = 0;
        p.supportingProposalTotal = 0;
        emit ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numProposals = proposalID+1;
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
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     * @param justificationText optional justification text
     */
    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string justificationText
    )
    public
    onlyMembers
    returns (uint256 voteID)
    {
        Proposal storage p = proposals[proposalNumber]; // Get the proposal
        require(block.timestamp <= p.minExecutionDate);
        require(!p.voted[msg.sender]);                  // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;
        voteID = p.numberOfVotes;                     // Increase the number of votes
        p.votes.push(Vote({ inSupport: supportsProposal, voter: msg.sender, justification: justificationText }));
        uint votingPower = twoKeyCongressMembersRegistry.getMemberVotingPower(msg.sender);
        if (supportsProposal) {                         // If they support the proposal
            p.supportingProposalTotal += votingPower; // Increase score
        } else {                                        // If they don't
            p.againstProposalTotal += votingPower;                          // Decrease the score
        }
        // Create a log of this event
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return voteID;
    }

    function getVoteCount(
        uint256 proposalNumber
    )
    onlyMembers
    public
    view
    returns(uint256 numberOfVotes, uint256 supportingProposalTotal, uint256 againstProposalTotal, string description)
    {
        require(proposals[proposalNumber].proposalHash != 0);
        numberOfVotes = proposals[proposalNumber].numberOfVotes;
        supportingProposalTotal = proposals[proposalNumber].supportingProposalTotal;
        againstProposalTotal = proposals[proposalNumber].againstProposalTotal;
        description = proposals[proposalNumber].description;
    }


    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
     */
    function executeProposal(
        uint proposalNumber,
        bytes transactionBytecode
    )
    public
    onlyMembers
    {
        Proposal storage p = proposals[proposalNumber];
        uint minimumQuorum = twoKeyCongressMembersRegistry.minimumQuorum();
        uint maxVotingPower = twoKeyCongressMembersRegistry.maxVotingPower();
        require(
//            block.timestamp > p.minExecutionDate  &&                             // If it is past the voting deadline
             !p.executed                                                         // and it has not already been executed
            && p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode))  // and the supplied code matches the proposal
            && p.numberOfVotes >= minimumQuorum.sub(1) // and a minimum quorum has been reached...
            && uint(p.supportingProposalTotal) >= maxVotingPower.mul(51).div(100) // Total support should be >= than 51%
        );

        // ...then execute result
        p.executed = true; // Avoid recursive calling
        p.proposalPassed = true;

        // Fire Events
        emit ProposalTallied(proposalNumber, p.numberOfVotes, p.proposalPassed);

//         Call external function
        require(p.recipient.call.value(p.amount)(transactionBytecode));
    }


    /// @notice Function to get major proposal data
    /// @param proposalId is the id of proposal
    /// @return tuple containing all the data for proposal
    function getProposalData(
        uint proposalId
    )
    public
    view
    returns (uint,string,uint,bool,uint,uint,uint,bytes)
    {
        Proposal memory p = proposals[proposalId];
        return (p.amount, p.description, p.minExecutionDate, p.executed, p.numberOfVotes, p.supportingProposalTotal, p.againstProposalTotal, p.transactionBytecode);
    }


    /// @notice Fallback function
    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

contract TwoKeyCongressMembersRegistry {
    /**
     * This contract will serve as accountant for Members inside TwoKeyCongress
     * contract. Only contract eligible to mutate state of this contract is TwoKeyCongress
     * TwoKeyCongress will check for it's members from this contract.
     */

    using SafeMath for uint;

    event MembershipChanged(address member, bool isMember);

    address public TWO_KEY_CONGRESS;

    // The maximum voting power containing sum of voting powers of all active members
    uint256 public maxVotingPower;
    //The minimum number of voting members that must be in attendance
    uint256 public minimumQuorum;

    // Mapping to check if the member is belonging to congress
    mapping (address => bool) public isMemberInCongress;
    // Mapping address to memberId
    mapping(address => Member) public address2Member;
    // Mapping to store all members addresses
    address[] public allMembers;

    struct Member {
        address memberAddress;
        bytes32 name;
        uint votingPower;
        uint memberSince;
    }

    modifier onlyTwoKeyCongress () {
        require(msg.sender == TWO_KEY_CONGRESS);
        _;
    }

    /**
     * @param initialCongressMembers is the array containing addresses of initial members
     * @param memberVotingPowers is the array of unassigned integers containing voting powers respectively
     * @dev initialMembers.length must be equal votingPowers.length
     */
    constructor(
        address[] initialCongressMembers,
        bytes32[] initialCongressMemberNames,
        uint[] memberVotingPowers,
        address _twoKeyCongress
    )
    public
    {
        uint length = initialCongressMembers.length;
        for(uint i=0; i<length; i++) {
            addMemberInternal(
                initialCongressMembers[i],
                initialCongressMemberNames[i],
                memberVotingPowers[i]
            );
        }
        TWO_KEY_CONGRESS = _twoKeyCongress;
    }

    /**
     * Add member
     *
     * Make `targetMember` a member named `memberName`
     *
     * @param targetMember ethereum address to be added
     * @param memberName public name for that member
     */
    function addMember(
        address targetMember,
        bytes32 memberName,
        uint _votingPower
    )
    public
    onlyTwoKeyCongress
    {
        addMemberInternal(targetMember, memberName, _votingPower);
    }

    function addMemberInternal(
        address targetMember,
        bytes32 memberName,
        uint _votingPower
    )
    internal
    {
        //Require that this member is not already a member of congress
        require(isMemberInCongress[targetMember] == false);
        minimumQuorum = allMembers.length;
        maxVotingPower = maxVotingPower.add(_votingPower);
        address2Member[targetMember] = Member(
            {
            memberAddress: targetMember,
            memberSince: block.timestamp,
            votingPower: _votingPower,
            name: memberName
            }
        );
        allMembers.push(targetMember);
        isMemberInCongress[targetMember] = true;
        emit MembershipChanged(targetMember, true);
    }

    /**
     * Remove member
     *
     * @notice Remove membership from `targetMember`
     *
     * @param targetMember ethereum address to be removed
     */
    function removeMember(
        address targetMember
    )
    public
    onlyTwoKeyCongress
    {
        require(isMemberInCongress[targetMember] == true);

        //Remove member voting power from max voting power
        uint votingPower = getMemberVotingPower(targetMember);
        maxVotingPower-= votingPower;

        uint length = allMembers.length;
        uint i=0;
        //Find selected member
        while(allMembers[i] != targetMember) {
            if(i == length) {
                revert();
            }
            i++;
        }

        // Move the lest member to this place
        allMembers[i] = allMembers[length-1];

        //After reduce array size
        delete allMembers[allMembers.length-1];

        uint newLength = allMembers.length.sub(1);
        allMembers.length = newLength;

        //Remove him from state mapping
        isMemberInCongress[targetMember] = false;

        //Remove his state to empty member
        address2Member[targetMember] = Member(
            {
                memberAddress: address(0),
                memberSince: block.timestamp,
                votingPower: 0,
                name: "0x0"
            }
        );
        //Reduce 1 member from quorum
        minimumQuorum = minimumQuorum.sub(1);
    }

    /// @notice Function getter for voting power for specific member
    /// @param _memberAddress is the address of the member
    /// @return integer representing voting power
    function getMemberVotingPower(
        address _memberAddress
    )
    public
    view
    returns (uint)
    {
        Member memory _member = address2Member[_memberAddress];
        return _member.votingPower;
    }

    /**
     * @notice Function which will be exposed and congress will use it as "modifier"
     * @param _address is the address we're willing to check if it belongs to congress
     * @return true/false depending if it is either a member or not
     */
    function isMember(
        address _address
    )
    public
    view
    returns (bool)
    {
        return isMemberInCongress[_address];
    }

    /// @notice Getter for length for how many members are currently
    /// @return length of members
    function getMembersLength()
    public
    view
    returns (uint)
    {
        return allMembers.length;
    }

    /// @notice Function to get addresses of all members in congress
    /// @return array of addresses
    function getAllMemberAddresses()
    public
    view
    returns (address[])
    {
        return allMembers;
    }

    /// Basic getter function
    function getMemberInfo()
    public
    view
    returns (address, bytes32, uint, uint)
    {
        Member memory member = address2Member[msg.sender];
        return (member.memberAddress, member.name, member.votingPower, member.memberSince);
    }
}