pragma solidity ^0.4.25;

contract ProposalContract {
    enum Status { CreatedByA, ApprovedByA, RejectedByA, ApprovedByB, RejectedByB, ApprovedByC, RejectedByC }
    enum Party { A, B, C }

    mapping(address => uint) public balanceOf;
    
    struct Proposal {
        string title;
        string content;
        Status status;
        address partyAOwner;
        address partyBOwner;
        address partyCOwner;
    }

    struct User {
        string name;
        Party party;
    }

    Proposal[] public proposals;
    mapping(address => User) public users;
    address[] public addresses;

    event CreateAProposal(address who, uint256 proposalId);
    event ApproveAProposal(address who, uint256 proposalId);
    event DisapproveAProposal(address who, uint256 proposalId);

    function getProposalsCount() public view returns(uint) {
        return proposals.length;
    }

    function getAddressesCount() public view returns(uint) {
        return addresses.length;
    }

    function register(string name, Party party) public {
        users[msg.sender] = User(name, party);
        addresses.push(msg.sender);
    }

    function create(string title, string content) public {
        uint256 proposalId = proposals.length;
        require(users[msg.sender].party == Party.A, "Only Party A members can create proposal.");
        proposals.push(Proposal(title, content, Status.ApprovedByA, msg.sender, address(0), address(0)));
        balanceOf[msg.sender] += 1;
        emit CreateAProposal(msg.sender, proposalId);
        emit ApproveAProposal(msg.sender, proposalId);
    }

    function approve(uint256 proposalId, string content) public {
        Proposal storage proposal = proposals[proposalId];
        
        // party A
        if (proposal.status == Status.RejectedByB && proposal.partyAOwner == msg.sender) {
            proposal.status = Status.ApprovedByA;
        }
        
        // party B
        else if ((proposal.status == Status.ApprovedByA || proposal.status == Status.RejectedByC)
                && (proposal.partyBOwner == address(0) || proposal.partyBOwner == msg.sender)) 
        {
            if (proposal.partyBOwner == address(0)) {
                proposal.partyBOwner == msg.sender;
            }
            proposal.status = Status.ApprovedByB;
        }
        
        // party C
        else if (proposal.status == Status.ApprovedByB
                && (proposal.partyCOwner == address(0) || proposal.partyCOwner == msg.sender)) 
        {
            if (proposal.partyCOwner == address(0)) {
                proposal.partyCOwner == msg.sender;
            }
            proposal.status = Status.ApprovedByC;
        }

        proposal.content = content;
        proposals[proposalId] = proposal;
        balanceOf[msg.sender] += 1;

        emit ApproveAProposal(msg.sender, proposalId);
    }

    function disapprove(uint256 proposalId, string content) public {
        Proposal storage proposal = proposals[proposalId];
        
        // party A
        if (proposal.status == Status.RejectedByB && proposal.partyAOwner == msg.sender) {
            proposal.status = Status.RejectedByA;
        }
        
        // party B
        else if (proposal.status == Status.RejectedByC
                && (proposal.partyBOwner == address(0) || proposal.partyBOwner == msg.sender)) 
        {
            if (proposal.partyBOwner == address(0)) {
                proposal.partyBOwner == msg.sender;
            }
            proposal.status = Status.RejectedByB;
        }
        
        // party C
        else if (proposal.status == Status.ApprovedByB
                && (proposal.partyCOwner == address(0) || proposal.partyCOwner == msg.sender)) 
        {
            if (proposal.partyCOwner == address(0)) {
                proposal.partyCOwner == msg.sender;
            }
            proposal.status = Status.RejectedByC;
        }

        proposal.content = content;
        proposals[proposalId] = proposal;
        if (balanceOf[msg.sender] > 0) {
            balanceOf[msg.sender] -= 1;
        }

        emit DisapproveAProposal(msg.sender, proposalId);
    }
}