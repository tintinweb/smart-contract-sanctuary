pragma solidity ^0.4.22;

contract VotingService {

    address public owner ;
    string  public pollName ;

    struct Proposal {
        string name ;
        uint   votes ;
    }

    Proposal[] public proposals ;
    mapping(address => bool) public voters ;

    modifier ownerOnly() {
        if (msg.sender == owner) _;
    }

    constructor(string _pollName) public {
        owner = msg.sender ;
        pollName = _pollName ;
    }

    function proposalPresent(string _proposalName) private view returns(bool) {
        for (uint i = 0; i < proposals.length; i++) {
            // Note need to call abi.encodePacked as part of removing varargs
            // from hash functions
            // https://github.com/ethereum/solidity/issues/3955
            if (keccak256(abi.encodePacked(proposals[i].name)) ==
                keccak256(abi.encodePacked(_proposalName))) {
                return true ;
            }
        }
        return false ;
    }

    function addProposal(string _proposalName) public ownerOnly {
        if (!proposalPresent(_proposalName)) {
            proposals.push(Proposal(_proposalName, 0)) ;
        }
    }

    function numberOfProposals() public view returns(uint) {
        return proposals.length ;
    }

    function castVote(uint _proposalIdx) public {
        require(!voters[msg.sender]);
        voters[msg.sender] = true ;
        proposals[_proposalIdx].votes += 1 ;
    }

    function chosenProposal() public view returns(uint) {
        uint maxVotes = 0 ;
        uint chosenProposalIdx ;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].votes > maxVotes) {
                maxVotes = proposals[i].votes ;
                chosenProposalIdx = i ;
            }
        }
        return chosenProposalIdx ;
    }

    function numberOfVotesCast() public view returns(uint) {
        uint total = 0 ;
        for (uint i = 0; i < proposals.length; i++) {
            total += proposals[i].votes ;
        }
        return total ;
    }
}