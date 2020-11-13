pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function delegates(address) external view returns (address);
    function getCurrentVotes(address) external view returns (uint96);
}

library GovernaceTypes {
   struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
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
     
}

interface GoveranceInterface {
    function proposals(uint) external view returns (GovernaceTypes.Proposal memory);
    function proposalCount() external view returns (uint);

    function state(uint) external view returns (GovernaceTypes.ProposalState);

    function getQuorumVotes() external view returns (uint) ;
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
        GovernaceTypes.ProposalState currentState;
    }

    function getProposalStates(address govAddr, uint256[] memory ids) public view returns (ProposalState[] memory) {
        ProposalState[] memory proposalStates = new ProposalState[](ids.length);
        GoveranceInterface govContract = GoveranceInterface(govAddr);
        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];
            GovernaceTypes.Proposal memory proposal = govContract.proposals(id);
            bool isEnded = proposal.endBlock <= block.number;
            bool isFailed = proposal.forVotes <= proposal.againstVotes || proposal.forVotes < govContract.getQuorumVotes();
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