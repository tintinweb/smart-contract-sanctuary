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