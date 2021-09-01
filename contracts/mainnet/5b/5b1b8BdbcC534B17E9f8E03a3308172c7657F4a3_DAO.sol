//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
This contract implements a DAO, it's been loosely based on Compound's
GovernorAlpha. It supports multiple options per proposal and multiple actions
per option. It leverages the `Voters` contract for snapshots of voting power.
It supports gasless voting with voteBySig / EIP-712.
*/

import './interfaces/IVoters.sol';

contract DAO {
    struct Proposal {
        uint id;
        address proposer;
        string title;
        string description;
        string[] optionsNames;
        bytes[][] optionsActions;
        uint[] optionsVotes;
        uint startAt;
        uint endAt;
        uint executableAt;
        uint executedAt;
        uint snapshotId;
        uint votersSupply;
        bool cancelled;
    }

    event Proposed(uint indexed proposalId);
    event Voted(uint indexed proposalId, address indexed voter, uint optionId);
    event Executed(address indexed to, uint value, bytes data);
    event ExecutedProposal(uint indexed proposalId, uint optionId, address executer);

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint optionId)");
    uint public minBalanceToPropose;
    uint public minPercentQuorum;
    uint public minVotingTime;
    uint public minExecutionDelay;
    IVoters public voters;
    uint public proposalsCount;
    mapping(uint => Proposal) private proposals;
    mapping(uint => mapping(address => uint)) public proposalVotes;
    mapping (address => uint) private latestProposalIds;

    constructor(
      address _voters,
      uint _minBalanceToPropose,
      uint _minPercentQuorum,
      uint _minVotingTime,
      uint _minExecutionDelay
    ) {
        voters = IVoters(_voters);
        minBalanceToPropose = _minBalanceToPropose;
        minPercentQuorum = _minPercentQuorum;
        minVotingTime = _minVotingTime;
        minExecutionDelay = _minExecutionDelay;
    }

    function proposal(uint index) public view returns (uint, address, string memory, uint, uint, uint, uint, bool) {
        Proposal storage p = proposals[index];
        return (
          p.id,
          p.proposer,
          p.title,
          p.startAt,
          p.endAt,
          p.executableAt,
          p.executedAt,
          p.cancelled
        );
    }

    function proposalDetails(uint index) public view returns (string memory, uint, uint, string[] memory, bytes[][] memory, uint[] memory) {
        return (
          proposals[index].description,
          proposals[index].snapshotId,
          proposals[index].votersSupply,
          proposals[index].optionsNames,
          proposals[index].optionsActions,
          proposals[index].optionsVotes
        );
    }

    function propose(string calldata title, string calldata description, uint votingTime, uint executionDelay, string[] calldata optionNames, bytes[][] memory optionActions) external returns (uint) {
        uint snapshotId = voters.snapshot();
        require(voters.votesAt(msg.sender, snapshotId) >= minBalanceToPropose, "<balance");
        require(optionNames.length == optionActions.length && optionNames.length > 0 && optionNames.length <= 100, "option len match or count");
        require(optionActions[optionActions.length - 1].length == 0, "last option, no action");
        require(votingTime >= minVotingTime, "<voting time");
        require(executionDelay >= minExecutionDelay, "<exec delay");

        // Check the proposing address doesn't have an other active proposal
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            require(block.timestamp > proposals[latestProposalId].endAt, "1 live proposal max");
        }

        // Add new proposal
        proposalsCount += 1;
        Proposal storage newProposal = proposals[proposalsCount];
        newProposal.id = proposalsCount;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.startAt = block.timestamp + 86400;
        newProposal.endAt = block.timestamp + 86400 + votingTime;
        newProposal.executableAt = block.timestamp + 86400 + votingTime + executionDelay;
        newProposal.snapshotId = snapshotId;
        newProposal.votersSupply = voters.totalSupplyAt(snapshotId);
        newProposal.optionsNames = new string[](optionNames.length);
        newProposal.optionsVotes = new uint[](optionNames.length);
        newProposal.optionsActions = optionActions;

        for (uint i = 0; i < optionNames.length; i++) {
            require(optionActions[i].length <= 10, "actions length > 10");
            newProposal.optionsNames[i] = optionNames[i];
        }

        latestProposalIds[msg.sender] = newProposal.id;
        emit Proposed(newProposal.id);
        return newProposal.id;
    }

    function proposeCancel(uint proposalId, string memory title, string memory description) external returns (uint) {
        uint snapshotId = voters.snapshot();
        require(voters.votesAt(msg.sender, snapshotId) >= minBalanceToPropose, "<balance");

        // Check the proposing address doesn't have an other active proposal
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            require(block.timestamp > proposals[latestProposalId].endAt, "1 live proposal max");
        }

        // Add new proposal
        proposalsCount += 1;
        Proposal storage newProposal = proposals[proposalsCount];
        newProposal.id = proposalsCount;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.startAt = block.timestamp;
        newProposal.endAt = block.timestamp + 86400; // 24 hours
        newProposal.executableAt = block.timestamp + 86400; // Executable immediately
        newProposal.snapshotId = snapshotId;
        newProposal.votersSupply = voters.totalSupplyAt(snapshotId);
        newProposal.optionsNames = new string[](2);
        newProposal.optionsVotes = new uint[](2);
        newProposal.optionsActions = new bytes[][](2);

        newProposal.optionsNames[0] = "Cancel Proposal";
        newProposal.optionsNames[1] = "Do Nothing";
        newProposal.optionsActions[0] = new bytes[](1);
        newProposal.optionsActions[1] = new bytes[](0);
        newProposal.optionsActions[0][0] = abi.encode(
            address(this), 0,
            abi.encodeWithSignature("cancel(uint256)", proposalId)
        );

        latestProposalIds[msg.sender] = newProposal.id;
        emit Proposed(newProposal.id);
        return newProposal.id;
    }

    function vote(uint proposalId, uint optionId) external {
        _vote(msg.sender, proposalId, optionId);
    }

    function voteBySig(uint proposalId, uint optionId, uint8 v, bytes32 r, bytes32 s) external {
        uint chainId;
        assembly { chainId := chainid() }
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("Thorstarter DAO")), chainId, address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, optionId));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address voter = ecrecover(digest, v, r, s);
        require(voter != address(0), "invalid signature");
        _vote(voter, proposalId, optionId);
    }

    function _vote(address voter, uint proposalId, uint optionId) private {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.endAt, "voting ended");
        require(proposalVotes[proposalId][voter] == 0, "already voted");
        p.optionsVotes[optionId] = p.optionsVotes[optionId] + voters.votesAt(voter, p.snapshotId);
        proposalVotes[proposalId][voter] = optionId + 1;
        emit Voted(proposalId, voter, optionId);
    }

    // Executes an un-executed, with quorum, ready to be executed proposal
    // If the pre-conditions are met, anybody can call this
    // Part of this is establishing which option "won" and if quorum was reached
    function execute(uint proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.executedAt == 0, "already executed");
        require(block.timestamp > p.executableAt, "not yet executable");
        require(!p.cancelled, "proposal cancelled");
        require(p.optionsVotes.length >= 2, "not a proposal");
        p.executedAt = block.timestamp; // Mark as executed now to prevent re-entrancy

        // Pick the winning option (the one with the most votes, defaulting to the "Against" (last) option
        uint votesTotal;
        uint winningOptionIndex = p.optionsNames.length - 1; // Default to "Against"
        uint winningOptionVotes = 0;
        for (int i = int(p.optionsVotes.length) - 1; i >= 0; i--) {
            uint votes = p.optionsVotes[uint(i)];
            votesTotal = votesTotal + votes;
            // Use greater than (not equal) to avoid a proposal with 0 votes
            // to default to the 1st option
            if (votes > winningOptionVotes) {
                winningOptionIndex = uint(i);
                winningOptionVotes = votes;
            }
        }

        require((votesTotal * 1e12) / p.votersSupply > minPercentQuorum, "not at quorum");

        // Run all actions attached to the winning option
        for (uint i = 0; i < p.optionsActions[winningOptionIndex].length; i++) {
            (address to, uint value, bytes memory data) = abi.decode(
              p.optionsActions[winningOptionIndex][i],
              (address, uint, bytes)
            );
            (bool success,) = to.call{value: value}(data);
            require(success, "action reverted");
            emit Executed(to, value, data);
        }

        emit ExecutedProposal(proposalId, winningOptionIndex, msg.sender);
    }

    function setMinBalanceToPropose(uint value) external {
        require(msg.sender == address(this), "!DAO");
        minBalanceToPropose = value;
    }

    function setMinPercentQuorum(uint value) external {
        require(msg.sender == address(this), "!DAO");
        minPercentQuorum = value;
    }

    function setMinVotingTime(uint value) external {
        require(msg.sender == address(this), "!DAO");
        minVotingTime = value;
    }

    function setMinExecutionDelay(uint value) external {
        require(msg.sender == address(this), "!DAO");
        minExecutionDelay = value;
    }

    function setVoters(address newVoters) external {
        require(msg.sender == address(this), "!DAO");
        voters = IVoters(newVoters);
    }

    function cancel(uint proposalId) external {
        require(msg.sender == address(this), "!DAO");
        Proposal storage p = proposals[proposalId];
        require(p.executedAt == 0 && !p.cancelled, "already executed or cancelled");
        p.cancelled = true;
    }

    fallback() external payable { }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoters {
  function snapshot() external returns (uint);
  function totalSupplyAt(uint snapshotId) external view returns (uint);
  function votesAt(address account, uint snapshotId) external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function balanceOfAt(address account, uint snapshotId) external view returns (uint);
  function donate(uint amount) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}