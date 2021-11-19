pragma solidity ^0.8.10;

import "./Proposal.sol";

contract VotingFactory {
    address private owner;

    Proposal[] private proposals;
    uint256 private proposalCount;

    mapping(address => uint256[]) private proposalsByAddress;
    mapping(address => uint256) private proposalCountByAddress;

    event ProposalCreated(Proposal proposal);

    constructor() {
        owner = msg.sender;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _durationInBlocks,
        uint256 _unixDeployed,
        uint256 _unixDeadline
    ) public {
        uint256 newId = proposalCount++;
        Proposal proposal = new Proposal(
            _title,
            _description,
            newId,
            _durationInBlocks,
            _unixDeployed,
            _unixDeadline,
            msg.sender
        );
        proposals.push(proposal);
        proposalCount++;
        emit ProposalCreated(proposal);

        proposalsByAddress[msg.sender].push(newId);
        proposalCountByAddress[msg.sender]++;
    }

    function getProposal(uint256 _index) public view returns (Proposal) {
        return proposals[_index];
    }

    function getProposalsByAddress() public view returns (Proposal[] memory) {
        Proposal[] memory foundProposals;

        for (
            uint256 index = 0;
            index < proposalCountByAddress[msg.sender];
            index++
        ) {
            foundProposals[index] = proposals[
                proposalsByAddress[msg.sender][index]
            ];
        }

        return foundProposals;
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCount;
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}