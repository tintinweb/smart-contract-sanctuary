/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// SPDX-License-Identifier: MIT
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
    function proposalThreshold() external view returns (uint);
    function timelock() external view returns (TimeLockInterface);
    function votingDelay() external pure returns (uint);
    function votingPeriod() external view returns (uint);
    function proposalMaxOperations() external view returns (uint);
    function name() external view returns (string memory);
}

interface TokenInterface {
    function mintingAllowedAfter() external pure returns (uint);
    function minimumTimeBetweenMints() external pure returns (uint);
    function mintCap() external pure returns (uint);
    function totalSupply() external view returns (uint);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function minter() external view returns (address);
}
interface TimeLockInterface {
    function admin() external view returns (address);
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}


contract Resolver {
    struct ProposalState {
        uint forVotes;
        uint againstVotes;
        bool isFailed;
        bool isEnded;
        GoveranceInterface.ProposalState currentState;
    }

    struct GovernanceData {
        address governanceAddress;
        address timelockAddress;
        uint quorumVotes;
        uint proposalThreshold;
        uint votingDelay;
        uint votingPeriod;
        uint proposalMaxOperations;
        uint proposalCount;
        uint timelock_gracePeriod;
        uint timelock_delay;
        string name;
    }

    struct TokenData {
        address tokenAddress;
        // uint mintingAllowedAfter;
        // uint minimumTimeBetweenMints;
        // uint mintCap;
        uint totalSupply;
        string symbol;
        string name;
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

    function getGovernanceData(address[] memory govAddress) public view returns (GovernanceData[] memory) {
        GovernanceData[] memory governanceDatas = new GovernanceData[](govAddress.length);
        for (uint i = 0; i < govAddress.length; i++) {
            GoveranceInterface govContract = GoveranceInterface(govAddress[i]);
            TimeLockInterface timelockContract = govContract.timelock();
            governanceDatas[i] = GovernanceData({
                governanceAddress: govAddress[i],
                timelockAddress: address(timelockContract),
                quorumVotes: govContract.quorumVotes(),
                proposalThreshold: govContract.proposalThreshold(),
                votingDelay: govContract.votingDelay(),
                votingPeriod: govContract.votingPeriod(),
                proposalMaxOperations: govContract.proposalMaxOperations(),
                proposalCount: govContract.proposalCount(),
                timelock_gracePeriod: timelockContract.GRACE_PERIOD(),
                timelock_delay: timelockContract.delay(),
                name: govContract.name()
            });
        }
        return governanceDatas;
    }

    function getTokenData(address[] memory tokens) public view returns (TokenData[] memory) {
        TokenData[] memory tokenDatas = new TokenData[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            TokenInterface tokenContract = TokenInterface(tokens[i]);
            tokenDatas[i] = TokenData({
                tokenAddress: tokens[i],
                // mintingAllowedAfter: tokenContract.mintingAllowedAfter(),
                // minimumTimeBetweenMints: tokenContract.minimumTimeBetweenMints(),
                // mintCap: tokenContract.mintCap(),
                totalSupply: tokenContract.totalSupply(),
                symbol: tokenContract.symbol(),
                name: tokenContract.name()
            });
        }
        return tokenDatas;
    }

    function getDaoData(address[] memory tokens, address[] memory govAddress) public view returns (TokenData[] memory, GovernanceData[] memory) {
        address[] memory _govAddr = new address[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            if (govAddress[i] == address(0)) {
                _govAddr[i] = TimeLockInterface(TokenInterface(tokens[i]).minter()).admin();
            } else {
                _govAddr[i] = govAddress[i];
            }
        }
        return (getTokenData(tokens), getGovernanceData(_govAddr));
    }
}

contract AtlasGovResolver is Resolver {

    string public constant name = "Atlas-Governance-Resolver-v1.2";
    
}