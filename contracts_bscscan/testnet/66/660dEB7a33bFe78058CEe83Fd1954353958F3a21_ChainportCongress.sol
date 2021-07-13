/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/interfaces/ICongressMembersRegistry.sol

pragma solidity ^0.6.12;

/**
 * ICongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 21.3.21.
 * Github: madjarevicn
 */
interface ICongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}


// File contracts/governance/ChainportCongress.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * ChainportCongress contract.
 * @author Nikola Madjarevic
 * Date created: 18.3.21.
 * Github: madjarevicn
 */
contract ChainportCongress {
    /// @notice The name of this contract
    string public constant name = "ChainportCongress";

    // Members registry contract
    ICongressMembersRegistry membersRegistry;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        // Unique id for looking up a proposal
        uint id;

        // Creator of the proposal
        address proposer;

        // the ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Timestamp when proposal is created
        uint timestamp;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint id);

    /// @notice An event emitted everytime ether is received
    event ReceivedEther(address sender, uint amount);

    /// @notice Event which will fire every time transaction is executed
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);

    modifier onlyMember {
        require(membersRegistry.isMember(msg.sender) == true, "Only ChainportCongress member can call this function");
        _;
    }

    /// One time call function to set members registry contract
    function setMembersRegistry(
        address _membersRegistry
    )
    external
    {
        require(address(membersRegistry) == address(0x0), "ChainportCongress:setMembersRegistry: membersRegistry is already set");
        membersRegistry = ICongressMembersRegistry(_membersRegistry);
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    )
    external
    onlyMember
    returns (uint)
    {
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "ChainportCongress::propose: proposal function information arity mismatch"
        );

        require(targets.length != 0, "ChainportCongress::propose: must provide actions");

        proposalCount++;

        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false,
            timestamp: block.timestamp
        });

        proposals[newProposal.id] = newProposal;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, description);
        return newProposal.id;
    }


    function castVote(
        uint proposalId,
        bool support
    )
    external
    onlyMember
    {
        return _castVote(msg.sender, proposalId, support);
    }


    function execute(
        uint proposalId
    )
    external
    onlyMember
    payable
    {
        // load the proposal
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(proposal.executed == false && proposal.canceled == false);
        // Mark that proposal is executed
        proposal.executed = true;
        // Require that votes in favor of proposal are greater or equal to minimalQuorum
        require(proposal.forVotes >= membersRegistry.getMinimalQuorum());

        for (uint i = 0; i < proposal.targets.length; i++) {
            bytes memory callData;

            if (bytes(proposal.signatures[i]).length == 0) {
                callData = proposal.calldatas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            }

            // solium-disable-next-line security/no-call-value
            (bool success,) = proposal.targets[i].call{value:proposal.values[i]}(callData);

            // Require that transaction went through
            require(success, "ChainportCongress::executeTransaction: Transaction execution reverted.");

            // Emit event that transaction is being executed
            emit ExecuteTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }

        // Emit event that proposal executed
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) external onlyMember {
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(proposal.executed == false && proposal.canceled == false, "ChainportCongress:cancel: Proposal already executed or canceled");
        // 3 days after proposal can get cancelled
        require(block.timestamp >= proposal.timestamp + 259200, "ChainportCongress:cancel: Time lock hasn't ended yet");
        // Proposal with reached minimalQuorum cant be cancelled
        require(proposal.forVotes < membersRegistry.getMinimalQuorum(), "ChainportCongress:cancel: Proposal already reached quorum");
        // Set that proposal is cancelled
        proposal.canceled = true;
        // Emit event
        emit ProposalCanceled(proposalId);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "ChainportCongress::_castVote: voter already voted");

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, 1);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, 1);
        }

        receipt.hasVoted = true;
        receipt.support = support;

        emit VoteCast(voter, proposalId, support);
    }

    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getMembersRegistry()
    external
    view
    returns (address)
    {
        return address(membersRegistry);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}