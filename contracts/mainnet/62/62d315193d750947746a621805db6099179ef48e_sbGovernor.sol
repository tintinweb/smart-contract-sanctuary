// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./sbVotesInterface.sol";

contract sbGovernor {
    event CanceledTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecutedTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueuedTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event Voted(address voter, uint256 proposalId, bool support, uint256 votes);
    event ProposalCanceled(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalExecuted(uint256 id);

    using SafeMath for uint256;

    sbVotesInterface public sbVotes;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;

    uint256 public quorumVotesInWei;
    uint256 public proposalThresholdInWei;
    uint256 public proposalMaxOperations;
    uint256 public votingDelayInBlocks;
    uint256 public votingPeriodInBlocks;
    uint256 public queuePeriodInSeconds;
    uint256 public gracePeriodInSeconds;

    uint256 public proposalCount;

    mapping(uint256 => address) public proposalProposer;
    mapping(uint256 => uint256) public proposalEta;
    mapping(uint256 => address[]) public proposalTargets;
    mapping(uint256 => uint256[]) public proposalValues;
    mapping(uint256 => string[]) public proposalSignatures;
    mapping(uint256 => bytes[]) public proposalCalldatas;
    mapping(uint256 => uint256) public proposalStartBlock;
    mapping(uint256 => uint256) public proposalEndBlock;
    mapping(uint256 => uint256) public proposalForVotes;
    mapping(uint256 => uint256) public proposalAgainstVotes;
    mapping(uint256 => bool) public proposalCanceled;
    mapping(uint256 => bool) public proposalExecuted;
    mapping(uint256 => mapping(address => bool)) public proposalVoterHasVoted;
    mapping(uint256 => mapping(address => bool)) public proposalVoterSupport;
    mapping(uint256 => mapping(address => uint96)) public proposalVoterVotes;

    mapping(address => uint256) public latestProposalIds;
    mapping(bytes32 => bool) public queuedTransactions;

    mapping(string => uint256) public possibleProposalStatesMapping;
    string[] public possibleProposalStatesArray;

    function init(
        address sbVotesAddress,
        address adminAddress,
        address superAdminAddress
    ) public {
        require(!initDone, "init done");
        sbVotes = sbVotesInterface(sbVotesAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        possibleProposalStatesMapping["Pending"] = 0;
        possibleProposalStatesArray.push("Pending");
        possibleProposalStatesMapping["Active"] = 1;
        possibleProposalStatesArray.push("Active");
        possibleProposalStatesMapping["Canceled"] = 2;
        possibleProposalStatesArray.push("Canceled");
        possibleProposalStatesMapping["Defeated"] = 3;
        possibleProposalStatesArray.push("Defeated");
        possibleProposalStatesMapping["Succeeded"] = 4;
        possibleProposalStatesArray.push("Succeeded");
        possibleProposalStatesMapping["Queued"] = 5;
        possibleProposalStatesArray.push("Queued");
        possibleProposalStatesMapping["Expired"] = 6;
        possibleProposalStatesArray.push("Expired");
        possibleProposalStatesMapping["Executed"] = 7;
        possibleProposalStatesArray.push("Executed");
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "not pendingAdmin"
        );
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(
            msg.sender == pendingSuperAdmin && msg.sender != address(0),
            "not pendingSuperAdmin"
        );
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // PARAMETERS
    // *************************************************************************************
    function updateQuorumVotesInWei(uint256 amountInWei) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInWei > 0, "zero");
        quorumVotesInWei = amountInWei;
    }

    function updateProposalThresholdInWei(uint256 amountInWei) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInWei > 0, "zero");
        proposalThresholdInWei = amountInWei;
    }

    function updateProposalMaxOperations(uint256 count) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(count > 0, "zero");
        proposalMaxOperations = count;
    }

    function updateVotingDelayInBlocks(uint256 amountInBlocks) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInBlocks > 0, "zero");
        votingDelayInBlocks = amountInBlocks;
    }

    function updateVotingPeriodInBlocks(uint256 amountInBlocks) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInBlocks > 0, "zero");
        votingPeriodInBlocks = amountInBlocks;
    }

    function updateQueuePeriodInSeconds(uint256 amountInSeconds) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInSeconds > 0, "zero");
        queuePeriodInSeconds = amountInSeconds;
    }

    function updateGracePeriodInSeconds(uint256 amountInSeconds) public {
        require(msg.sender == admin || msg.sender == superAdmin, "not admin");
        require(amountInSeconds > 0, "zero");
        gracePeriodInSeconds = amountInSeconds;
    }

    // PROPOSALS
    // *************************************************************************************
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        require(
            sbVotes.getPriorProposalVotes(msg.sender, block.number.sub(1)) >
                proposalThresholdInWei,
            "below threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "arity mismatch"
        );
        require(targets.length != 0, "missing actions");
        require(targets.length <= proposalMaxOperations, "too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            uint256 proposersLatestProposalState = state(latestProposalId);
            require(
                proposersLatestProposalState !=
                    possibleProposalStatesMapping["Active"],
                "already active proposal"
            );
            require(
                proposersLatestProposalState !=
                    possibleProposalStatesMapping["Pending"],
                "already pending proposal"
            );
        }

        uint256 startBlock = block.number.add(votingDelayInBlocks);
        uint256 endBlock = startBlock.add(votingPeriodInBlocks);

        proposalCount = proposalCount.add(1);

        proposalProposer[proposalCount] = msg.sender;
        proposalEta[proposalCount] = 0;
        proposalTargets[proposalCount] = targets;
        proposalValues[proposalCount] = values;
        proposalSignatures[proposalCount] = signatures;
        proposalCalldatas[proposalCount] = calldatas;
        proposalStartBlock[proposalCount] = startBlock;
        proposalEndBlock[proposalCount] = endBlock;
        proposalForVotes[proposalCount] = 0;
        proposalAgainstVotes[proposalCount] = 0;
        proposalCanceled[proposalCount] = false;
        proposalExecuted[proposalCount] = false;

        latestProposalIds[msg.sender] = proposalCount;

        emit ProposalCreated(
            proposalCount,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) public {
        return _vote(msg.sender, proposalId, support);
    }

    function queue(uint256 proposalId) public {
        require(
            state(proposalId) == possibleProposalStatesMapping["Succeeded"],
            "not succeeded"
        );
        uint256 eta = block.timestamp.add(queuePeriodInSeconds);
        for (uint256 i = 0; i < proposalTargets[proposalId].length; i++) {
            _queueOrRevert(
                proposalTargets[proposalId][i],
                proposalValues[proposalId][i],
                proposalSignatures[proposalId][i],
                proposalCalldatas[proposalId][i],
                eta
            );
        }
        proposalEta[proposalId] = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function cancel(uint256 proposalId) public {
        uint256 state = state(proposalId);
        require(
            state != possibleProposalStatesMapping["Executed"],
            "already executed"
        );

        require(
            msg.sender == admin ||
                msg.sender == superAdmin ||
                sbVotes.getPriorProposalVotes(
                    proposalProposer[proposalId],
                    block.number.sub(1)
                ) <
                proposalThresholdInWei,
            "below threshold"
        );

        proposalCanceled[proposalId] = true;
        for (uint256 i = 0; i < proposalTargets[proposalId].length; i++) {
            _cancelTransaction(
                proposalTargets[proposalId][i],
                proposalValues[proposalId][i],
                proposalSignatures[proposalId][i],
                proposalCalldatas[proposalId][i],
                proposalEta[proposalId]
            );
        }

        emit ProposalCanceled(proposalId);
    }

    function execute(uint256 proposalId) public payable {
        require(
            state(proposalId) == possibleProposalStatesMapping["Queued"],
            "not queued"
        );
        proposalExecuted[proposalId] = true;
        for (uint256 i = 0; i < proposalTargets[proposalId].length; i++) {
            _executeTransaction(
                proposalTargets[proposalId][i],
                proposalValues[proposalId][i],
                proposalSignatures[proposalId][i],
                proposalCalldatas[proposalId][i],
                proposalEta[proposalId]
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function getReceipt(uint256 proposalId, address voter)
        public
        view
        returns (
            bool,
            bool,
            uint96
        )
    {
        return (
            proposalVoterHasVoted[proposalId][voter],
            proposalVoterSupport[proposalId][voter],
            proposalVoterVotes[proposalId][voter]
        );
    }

    function getActions(uint256 proposalId)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            string[] memory,
            bytes[] memory
        )
    {
        return (
            proposalTargets[proposalId],
            proposalValues[proposalId],
            proposalSignatures[proposalId],
            proposalCalldatas[proposalId]
        );
    }

    function getPossibleProposalStates() public view returns (string[] memory) {
        return possibleProposalStatesArray;
    }

    function getPossibleProposalStateKey(uint256 index)
        public
        view
        returns (string memory)
    {
        require(index < possibleProposalStatesArray.length, "invalid index");
        return possibleProposalStatesArray[index];
    }

    function state(uint256 proposalId) public view returns (uint256) {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "invalid proposal id"
        );
        if (proposalCanceled[proposalId]) {
            return possibleProposalStatesMapping["Canceled"];
        } else if (block.number <= proposalStartBlock[proposalId]) {
            return possibleProposalStatesMapping["Pending"];
        } else if (block.number <= proposalEndBlock[proposalId]) {
            return possibleProposalStatesMapping["Active"];
        } else if (
            proposalForVotes[proposalId] <= proposalAgainstVotes[proposalId] ||
            proposalForVotes[proposalId] < quorumVotesInWei
        ) {
            return possibleProposalStatesMapping["Defeated"];
        } else if (proposalEta[proposalId] == 0) {
            return possibleProposalStatesMapping["Succeeded"];
        } else if (proposalExecuted[proposalId]) {
            return possibleProposalStatesMapping["Executed"];
        } else if (
            block.timestamp >= proposalEta[proposalId].add(gracePeriodInSeconds)
        ) {
            return possibleProposalStatesMapping["Expired"];
        } else {
            return possibleProposalStatesMapping["Queued"];
        }
    }

    // SUPPORT
    // *************************************************************************************
    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !queuedTransactions[keccak256(
                abi.encode(target, value, signature, data, eta)
            )],
            "already queued at eta"
        );
        _queueTransaction(target, value, signature, data, eta);
    }

    function _queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes32) {
        require(
            eta >= block.timestamp.add(queuePeriodInSeconds),
            "not satisfy queue period"
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = true;

        emit QueuedTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function _cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;
        emit CanceledTransaction(txHash, target, value, signature, data, eta);
    }

    function _executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes memory) {
        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(queuedTransactions[txHash], "not queued");
        require(block.timestamp >= eta, "not past eta");
        require(block.timestamp <= eta.add(gracePeriodInSeconds), "stale");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "execution reverted");

        emit ExecutedTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function _vote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        require(
            state(proposalId) == possibleProposalStatesMapping["Active"],
            "voting closed"
        );
        require(
            proposalVoterHasVoted[proposalId][voter] == false,
            "already voted"
        );
        uint96 votes = sbVotes.getPriorProposalVotes(
            voter,
            proposalStartBlock[proposalId]
        );

        if (support) {
            proposalForVotes[proposalId] = proposalForVotes[proposalId].add(
                votes
            );
        } else {
            proposalAgainstVotes[proposalId] = proposalAgainstVotes[proposalId]
                .add(votes);
        }

        proposalVoterHasVoted[proposalId][voter] = true;
        proposalVoterSupport[proposalId][voter] = support;
        proposalVoterVotes[proposalId][voter] = votes;

        emit Voted(voter, proposalId, support, votes);
    }
}
