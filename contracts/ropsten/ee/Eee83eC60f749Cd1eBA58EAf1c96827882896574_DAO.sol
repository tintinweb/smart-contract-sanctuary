pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

import "./INFTToken.sol";

contract DAO {
    uint256 public minNFTForCreateProposal = 5;
    uint256 public minNFTForApproveProposal = 5;
    uint256 public minNFTForSuccessProposal = 5;
    uint256 public minNFTForVoteOnProposal = 2;

    uint256 public numberOfVoteForApproveProposal = 2;
    uint256 public numberOfVoteForSuccessProposal = 2;

    uint256 public proposalID;

    struct Proposal{
        address owner;
        bool isAprroved;
        bool isCompleted;
        uint256 approvalVote;
        uint256 successVote;
        uint256 vote;
    }
    mapping(uint256 => Proposal) public proposal;

    INFTToken public token;
    address public owner;

    event ProposalCreated(uint256 id, address createdBy);
    event ProposalApproved(uint256 id, address approvedBy);
    event ProposalCompleted(uint256 id, address completeBy);
    event Voting(uint256 id, address voteBy);

    modifier OnlyOwner {
        require(msg.sender == owner, "Only owner can update");
        _;
    }

    constructor(address _token, uint256 _createProposal, uint256 _approveProposal, uint256 _successProposal, uint256 _voteProposal,
        uint256 _numberOfVoteForApproveProposal, uint256 _numberOfVoteForSuccessProposal){
        token = INFTToken(_token);
        owner = msg.sender;
        minNFTForCreateProposal = _createProposal;
        minNFTForApproveProposal = _approveProposal;
        minNFTForSuccessProposal = _successProposal;
        minNFTForVoteOnProposal = _voteProposal;
        numberOfVoteForApproveProposal = _numberOfVoteForApproveProposal;
        numberOfVoteForSuccessProposal = _numberOfVoteForSuccessProposal;
    }

    function setMinNFTForCreateProposal(uint256 nfts) public OnlyOwner{
        minNFTForCreateProposal = nfts;
    }

    function setMinNFTForAprroveProposal(uint256 nfts) public OnlyOwner{
        minNFTForApproveProposal = nfts;
    }

    function setMinNFTForSuccessProposal(uint256 nfts) public OnlyOwner{
        minNFTForSuccessProposal = nfts;
    }

    function setMinNFTForVoteOnProposal(uint256 nfts) public OnlyOwner{
        minNFTForVoteOnProposal = nfts;
    }

    function updateNumberOfVoteForApproveProposal(uint256 numberOfVote) public OnlyOwner {
        numberOfVoteForApproveProposal = numberOfVote;
    }

    function updateNumberOfVoteForSuccessProposal(uint256 numberOfVote) public OnlyOwner {
        numberOfVoteForSuccessProposal = numberOfVote;
    }

    function createProposal() public {
        require(token.balanceOf(msg.sender) >= minNFTForCreateProposal, "Not enough NFT in your account");
        proposalID++;
        proposal[proposalID] = Proposal({
            owner: msg.sender,
            isAprroved: false,
            isCompleted: false,
            approvalVote: 0,
            successVote: 0,
            vote: 0
        });
        emit ProposalCreated(proposalID, msg.sender);
    }

    function approveProposal(uint256 _proposalID) public {
        require(token.balanceOf(msg.sender) >= minNFTForApproveProposal, "Not enough NFT in your account");
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].owner != msg.sender, "Owner cannot approve");
        proposal[_proposalID].approvalVote = proposal[_proposalID].approvalVote + 1;
        if(proposal[_proposalID].approvalVote == numberOfVoteForApproveProposal){
            proposal[_proposalID].isAprroved = true;
        }
    }
    
    function successProposal(uint256 _proposalID) public {
        require(token.balanceOf(msg.sender) >= minNFTForSuccessProposal, "Not enough NFT in your account");
        require(proposalID >= _proposalID, "Proposal not exist");
        proposal[_proposalID].successVote = proposal[_proposalID].successVote + 1;
        if(proposal[_proposalID].successVote == numberOfVoteForSuccessProposal){
            proposal[_proposalID].isCompleted = true;
        }
    }

    function voteProposal(uint256 _proposalID) public {
        require(token.balanceOf(msg.sender) >= minNFTForVoteOnProposal, "Not enough NFT in your account");
        require(proposalID >= _proposalID, "Proposal not exist");
        require(proposal[_proposalID].isAprroved, "Proposal not approved");
        require(!proposal[_proposalID].isCompleted, "Proposal is completed");
        require(proposal[_proposalID].owner != msg.sender, "Owner cannot vote");

        proposal[_proposalID].vote = proposal[_proposalID].vote + 1;
    }

}

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface INFTToken {
    function mint() external returns(uint256 tokenID);
    function balanceOf(address owner) external returns(uint256 balance);
    function safeTransferFrom(address sender, address receiver, uint256 tokenID) external;
}