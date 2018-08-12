pragma solidity ^0.4.23;

contract Members {

    event MemberApplied(address applicantAddress, string applicantName);
    event MemberConfirmed(address memberAddress, string memberName);
    event MemberNameChanged(address memberAddress, string newMemberName);
    event MemberResigned(address memberAddress, string memberName);
    event BoardMembersChanged(address[] newBoardMemberAddresses);
    event VotingContractAddressUpdated(address newVotingContractAddress);

    address owner;

    enum MemberStatus {
          // not a member or applicant
        NONE,
        // account applied for membership
        APPLIED,
        // regular, confirmed member
        REGULAR,
        // member with board voting rights
        BOARD
    }

    struct Member {
        string name;
        MemberStatus status;
        uint entryBlock;
    }

    mapping (address => Member) public members;
    address[] public memberAddresses;

    mapping (address => address[]) confirmations;

    address public votingContractAddress;

    constructor(address[] initialMemberAddresses) public {
        for (uint index = 0; index < initialMemberAddresses.length; index++) {
            // all initial members are board members
            members[initialMemberAddresses[index]] = Member({name: "???", status: MemberStatus.BOARD, entryBlock: block.number});
            memberAddresses.push(initialMemberAddresses[index]);
        }
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVotingContract() {
        require (votingContractAddress == msg.sender);
        _;
    }

    function getNumberOfMembers() public view returns (uint) {
        return memberAddresses.length;
    }

    function applyForMembership(string memberName) public {
        require (members[msg.sender].status == MemberStatus.NONE);
        members[msg.sender] = Member({name: memberName, status: MemberStatus.APPLIED, entryBlock: 0});
        memberAddresses.push(msg.sender);
        emit MemberApplied(msg.sender, memberName);
    }

    function confirmApplication(address applicant) public {
        require (members[msg.sender].status == MemberStatus.BOARD);
        require (members[applicant].status == MemberStatus.APPLIED);
        confirmations[applicant].push(msg.sender);
        bool allBoardMembersConfirmed = true;
        for (uint index = 0; index < getNumberOfMembers(); index++) {
            address memberAddress = memberAddresses[index];
            if (members[memberAddress].status == MemberStatus.BOARD && !hasConfirmedApplicant(memberAddress, applicant)) {
                allBoardMembersConfirmed = false;
                break;
            }
        }
        if (allBoardMembersConfirmed) {
            members[applicant].status = MemberStatus.REGULAR;
            members[applicant].entryBlock = block.number;
            delete confirmations[applicant];
            emit MemberConfirmed(applicant, members[applicant].name);
        }
    }

    function hasConfirmedApplicant(address boardMember, address applicant) public view returns (bool) {
        for (uint index = 0; index < confirmations[applicant].length; index++) {
            if (confirmations[applicant][index] == boardMember)
                return true;
        }
        return false;
    }

    function changeName(string newName) public {
        members[msg.sender].name = newName;
        emit MemberNameChanged(msg.sender, newName);
    }

    function isRegularOrBoardMember(address memberAddress) public view returns (bool) {
        MemberStatus status = members[memberAddress].status;
        return status == MemberStatus.REGULAR || status == MemberStatus.BOARD;
    }

    /**
     * Resign membership - Deletes sender address from list of members 
     * (as long as it is not the last remaining member)
     */
    function resignOwnMembership() public {
        require(isRegularOrBoardMember(msg.sender));
    
        // don&#39;t allow last man standing to resign
        if (getNumberOfMembers() == 1) {
            revert();
        }

        // reset membership status
        members[msg.sender].status = MemberStatus.NONE;
        string storage memberName = members[msg.sender].name;
        
        // delete address of (ex) member from list of member addresses
        uint numberOfMembers = getNumberOfMembers();
        for (uint index = 0; index < numberOfMembers; index++) {
            address memberAddress = memberAddresses[index];
            if (memberAddress == msg.sender) {
                // delete by replacing item with last element of the array
                memberAddresses[index] = memberAddresses[numberOfMembers-1];
                memberAddresses.length--;
                break;
            }
        }

        emit MemberResigned(msg.sender, memberName);
    }

    /**
     * Instantiates new board members.
     */
    function replaceBoardMembers(address[] newBoardMembers) public onlyVotingContract {

        // this is redundant:
        // It should not even be possible to have a board member vote with no board members to be instantiated
        if (newBoardMembers.length == 0) {
            revert();
        }

        // check if new board members are already a member.
        for (uint i = 0; i != newBoardMembers.length; ++i) {
            if (isRegularOrBoardMember(newBoardMembers[i]) == false) {
                revert();
            }
        }

        // reset board members to regular members
        for (i = 0; i != memberAddresses.length; ++i) {
            Member storage member = members[memberAddresses[i]];
            if (member.status == MemberStatus.BOARD) {
                member.status = MemberStatus.REGULAR;
            }
        }   

        // instantiate new board members
        for (i = 0; i != newBoardMembers.length; ++i) {
            members[newBoardMembers[i]].status = MemberStatus.BOARD;
        }

        emit BoardMembersChanged(newBoardMembers);
    } 

    /**
     * Eligible members are members allowed to vote: board members or regular members
     */
    function getNumberOfEligibleMembers() public view returns (uint) {
        uint numberOfMembers = 0;
        for (uint i = 0; i != memberAddresses.length; ++i) {
            if (isRegularOrBoardMember(memberAddresses[i])) {
                ++numberOfMembers;
            }
        }
        return numberOfMembers;
    }

    /**
     * Initially set contract address
     */
    function setVotingContractAddress(address newAddress) public onlyOwner {
        if (votingContractAddress == address(0)) {
            votingContractAddress = newAddress;
        } else {
            revert();
        }
    }

    /**
     * Voting contract can update its address after a vote.
     */
    function updateVotingContractAddress(address newAddress) public onlyVotingContract {
        votingContractAddress = newAddress;
        emit VotingContractAddressUpdated(newAddress);
    }

    /**
     * Kill switch.
     */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}

contract Voting {

    event VoteCreated(uint voteId, uint voteType);
    event VoteCast(uint voteId, address voter);
    event VoteClosed(uint voteId, uint outcome);

    Members private membersContract;

    enum VoteStatus {
        NONE,
        OPEN,
        CLOSED
    }

    enum VoteOutcome {
        NONE,
        YES,
        NO
    }

    enum VoteType {
        NONE,
        DOCUMENT,
        BOARD_MEMBER,
        VOTING_CONTRACT_UPDATE
    }

    struct Vote {
        string name;
        VoteType voteType;
        bytes32 documentHash;
        VoteStatus status;
        mapping (address => VoteOutcome) outcome;
        address[] voters;
        address[] newBoardMembers;
        address newVotingContractAddress;
    }

    Vote[] private votes;

    modifier onlyMember {
        require(membersContract.isRegularOrBoardMember(msg.sender));
        _;
    }

    modifier onlyOpenVote(uint voteId) {
        require(votes[voteId].status == VoteStatus.OPEN);
        _;
    }

    modifier onlyClosedVote(uint voteId) {
        require(votes[voteId].status == VoteStatus.CLOSED);
        _;
    }

    // Instantiate voting contract with members contract address
    constructor(address membersContractAddress) public {
        membersContract = Members(membersContractAddress); 
    }

    function initiateBoardMemberVote(string name, bytes32 documentHash, address[] newBoardMembers) public onlyMember returns (uint) {
        if (newBoardMembers.length == 0) {
            revert();
        }

        votes.push(Vote(
            { name: name,
            voteType: VoteType.BOARD_MEMBER,
            documentHash: documentHash,
            status: VoteStatus.OPEN,
            newBoardMembers: newBoardMembers,
            newVotingContractAddress: address(0),
            voters: new address[](0)}));

        uint  voteId = votes.length - 1;
        emit VoteCreated(voteId, uint(VoteType.BOARD_MEMBER));
        return voteId;
    }

    // create a document vote
    function initiateDocumentVote(string name, bytes32 documentHash) public onlyMember returns (uint) {
        votes.push(Vote(
            { name: name,
            voteType: VoteType.DOCUMENT,
            documentHash: documentHash,
            status: VoteStatus.OPEN,
            newBoardMembers: new address[](0),
            newVotingContractAddress: address(0),
            voters: new address[](0)}));

        uint  voteId = votes.length - 1;
        emit VoteCreated(voteId, uint(VoteType.DOCUMENT));
        return voteId;
    }

    // create a contract update vote
    function initiateVotingContractUpdateVote(string name, address newContractAddress) public onlyMember returns (uint) {
        if (newContractAddress == address(0)) {
            revert();
        }
        
        votes.push(Vote(
            { name: name,
            voteType: VoteType.VOTING_CONTRACT_UPDATE,
            documentHash: 0,
            status: VoteStatus.OPEN,
            newBoardMembers: new address[](0),
            newVotingContractAddress: newContractAddress,
            voters: new address[](0)}));

        uint  voteId = votes.length - 1;
        emit VoteCreated(voteId, uint(VoteType.VOTING_CONTRACT_UPDATE));
        return voteId;
    }

    function castVote(uint voteId, bool decision) public onlyMember onlyOpenVote(voteId) {
        Vote storage vote = votes[voteId];
        require(vote.outcome[msg.sender] == VoteOutcome.NONE);
        if (decision == true) {
            vote.outcome[msg.sender] = VoteOutcome.YES;
        } else {
            vote.outcome[msg.sender] = VoteOutcome.NO;
        }
        vote.voters.push(msg.sender);

        emit VoteCast(voteId, msg.sender);
    }

    function getNumberOfVotes() public view returns (uint) {
        return votes.length;
    }

    /**
     * Returns vote details:
     *   name
     *   type (0: NONE, 1: DOCUMENT, 2: BOARD_MEMBER, 3: VOTING_CONTRACT_UPDATE)
     *   documentHash (if board member vote or contract update vote)
     *   status (0: NONE, 1: OPEN, 2: CLOSED)
     *   board member addresses (if board member vote)
     *   address of new voting contract (if contract update vote)
     *   addresses of voters
     */
    function getVoteDetails(uint voteId) public view returns (string, uint, bytes32, uint, address[], address, address[]) {
        Vote storage vote = votes[voteId];
        return (vote.name, 
            uint(vote.voteType),
            vote.documentHash,
            uint(vote.status),
            vote.newBoardMembers,
            vote.newVotingContractAddress,
            vote.voters);
    }

    /**
     * Closes vote (if result exists)
     */
    function closeVote(uint voteId) public onlyMember onlyOpenVote(voteId) { 
        Vote storage vote = votes[voteId];
        VoteOutcome outcome = computeVoteOutcome(vote);

        // only close vote if result exists
        if (outcome == VoteOutcome.NONE) {
            revert();
        }          

        vote.status = VoteStatus.CLOSED;

        // instantiate board members in case of board member vote
        if (outcome == VoteOutcome.YES && vote.voteType == VoteType.BOARD_MEMBER) {
            membersContract.replaceBoardMembers(vote.newBoardMembers);
        } 

        // set new contract address in case of contract address vote
        if (outcome == VoteOutcome.YES && vote.voteType == VoteType.VOTING_CONTRACT_UPDATE) {
            membersContract.updateVotingContractAddress(vote.newVotingContractAddress);
        }

        emit VoteClosed(voteId, uint(outcome));
    }

    function computeVoteOutcome(uint voteId) public view returns (uint) {
        VoteOutcome outcome = computeVoteOutcome(votes[voteId]);
        return uint(outcome);
    }

    /**
     * Eligible voters: E (i.e., regular or board members)
     * Positive votes: Y
     * Negative votes: N
     * Open votes: O
     * Y > E/2 --> Vote positive
     * N > E/2 --> Vote negative
     * Elsewise: Vote still open
     */
    function computeVoteOutcome(Vote storage vote) private view returns (VoteOutcome) {
        uint positiveVotes = 0;
        uint negativeVotes = 0;

        // count votes: iterate through all members
        for (uint i = 0; i != vote.voters.length; ++i) {
            VoteOutcome outcome = vote.outcome[vote.voters[i]];
            if (outcome == VoteOutcome.YES) {
                ++positiveVotes;
            } else if (outcome == VoteOutcome.NO) {
                ++negativeVotes;
            }
        }

        // process result
        uint eligibleVoters = membersContract.getNumberOfEligibleMembers();
        if (positiveVotes > eligibleVoters/2) {
            return VoteOutcome.YES;
        } else if (negativeVotes >= eligibleVoters/2) {
            return VoteOutcome.NO;
        } else {
            return VoteOutcome.NONE;
        }
    }
}