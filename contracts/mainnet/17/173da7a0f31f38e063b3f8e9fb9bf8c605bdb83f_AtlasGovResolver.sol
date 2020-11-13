pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface GoveranceInterface {

       struct Proposal {
        uint id;
        address proposer;
        uint eta;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

     enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    function proposals(uint) external view returns (Proposal memory);
    function proposalCount() external view returns (uint);

    function state(uint) external view returns (ProposalState);

    function quorumVotes() external view returns (uint) ;
    function getProposalThreshold() external view returns (uint);
    function proposalMaxOperations() external pure returns (uint);
    function getVotingDelay() external view returns (uint);
    function getVotingPeriod() external view returns (uint);
}


contract Resolver {
    struct ProposalState {
        uint forVotes;
        uint againstVotes;
        bool isFailed;
        bool isEnded;
        GoveranceInterface.ProposalState currentState;
    }

    function getProposalStates(address govAddr, uint256[] memory ids) public view returns (ProposalState[] memory) {
        ProposalState[] memory proposalStates = new ProposalState[](ids.length);
        GoveranceInterface govContract = GoveranceInterface(govAddr);
        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];
            GoveranceInterface.Proposal memory proposal = govContract.proposals(id);
            bool isEnded = proposal.endBlock <= block.number;
            bool isFailed = proposal.forVotes <= proposal.againstVotes || proposal.forVotes < govContract.quorumVotes();
            proposalStates[i] = ProposalState({
                forVotes: proposal.forVotes,
                againstVotes: proposal.againstVotes,
                isFailed: isEnded && isFailed,
                isEnded: isEnded,
                currentState: govContract.state(id)
            });
        }
        return proposalStates;
    }
}

contract AtlasGovResolver is Resolver {

    string public constant name = "Atlas-Governance-Resolver-v1.0";
    
}