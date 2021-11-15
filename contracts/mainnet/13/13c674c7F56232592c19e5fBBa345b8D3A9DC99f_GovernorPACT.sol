// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./vendors/contracts/AbstractGovernor.sol";
import "./vendors/contracts/access/GovernanceOwnable.sol";
import "./vendors/libraries/SafeMath.sol";

contract GovernorPACT is AbstractGovernor, GovernanceOwnable {
    enum VotingSettingsKeys {
        DefaultPropose,
        FastPropose,
        MultiExecutable
    }

    // etherium - block_generation_frequency_ ~ 15s
    // binance smart chain - block_generation_frequency_ ~ 4s
    constructor(
        address pact_,
        uint256 block_generation_frequency_
    ) AbstractGovernor("Governor PACT", pact_) GovernanceOwnable(address(this)) public {
        _addAllowedTarget(address(this));
        _addAllowedTarget(pact_);

        _setVotingSettings(
            uint(VotingSettingsKeys.DefaultPropose), // votingSettingsId
            SafeMath.div(3 days, block_generation_frequency_),// votingPeriod
            SafeMath.div(15 days, block_generation_frequency_),// expirationPeriod
            10,// proposalMaxOperations
            25,// quorumVotesDelimiter 4% of total PACTs
            100// proposalThresholdDelimiter 1% of total PACTs
        );
        _setVotingSettings(
            uint(VotingSettingsKeys.FastPropose), // votingSettingsId
            SafeMath.div(1 hours, block_generation_frequency_),// votingPeriod
            SafeMath.div(2 hours, block_generation_frequency_),// expirationPeriod
            40,// proposalMaxOperations
            5,// quorumVotesDelimiter 20% of total PACTs
            20// proposalThresholdDelimiter 5% of total PACTs
        );
        _setVotingSettings(
            uint(VotingSettingsKeys.MultiExecutable), // votingSettingsId
            SafeMath.div(1 hours, block_generation_frequency_),// votingPeriod
            SafeMath.div(365 days, block_generation_frequency_),// expirationPeriod
            2,// proposalMaxOperations
            5,// quorumVotesDelimiter 20% of total PACTs
            20// proposalThresholdDelimiter 5% of total PACTs
        );
    }

    function createDefaultPropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createFastPropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.DefaultPropose),
            targets,
            values,
            signatures,
            calldatas,
            description,
            false
        );
    }

    function createFastPropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createFastPropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.FastPropose),
            targets,
            values,
            signatures,
            calldatas,
            description,
            false
        );
    }

    function createMultiExecutablePropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createMultiExecutablePropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.MultiExecutable),
            targets,
            values,
            signatures,
            calldatas,
            description,
            true
        );
    }

    address[] internal allowedTargetsList;
    mapping (address => bool) public allowedTargets;

    function addAllowedTarget(address target) public onlyGovernance {
        _addAllowedTarget(target);
    }
    function _addAllowedTarget(address target) internal {
        if (allowedTargets[target] == false) {
            allowedTargets[target] = true;
            allowedTargetsList.push(target);
        }
    }

    function getAllowedTargets() public view returns(address[] memory) {
        return allowedTargetsList;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IDelegableERC20.sol";
import "./utils/Context.sol";

import "../libraries/SafeMath.sol";

// Copied and modified from Compound code:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
abstract contract AbstractGovernor is Context {
    using SafeMath for uint256;

    string _name;
    IDelegableERC20 public _token;

    constructor(
        string memory name_,
        address token_
    ) public {
        _name = name_;
        _token = IDelegableERC20(token_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice all VotingSettings
    mapping (uint => VotingSettings) public _votingSettings;

    /// @notice votingPeriod - The duration of voting on a proposal, in blocks
    /// @notice expirationPeriod - The duration of execution on a proposal after voting, in blocks
    /// @notice proposalMaxOperations - The maximum number of actions that can be included in a proposal
    /// @notice quorumVotesDelimiter - Number for calculate count of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    /// @notice proposalThresholdDelimiter - Number for calculate count of votes required in order for a voter to become a proposer
    struct VotingSettings {
        bool isValue;
        uint256 votingPeriod;
        uint256 expirationPeriod;
        uint256 proposalMaxOperations;
        uint256 quorumVotesDelimiter;
        uint256 proposalThresholdDelimiter;
    }

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes(uint256 votingSettingsId) public view returns (uint) {
        VotingSettings storage votingSettings = _votingSettings[votingSettingsId];
        require(votingSettings.isValue, "Governor::quorumVotes: incorrect votingSettingsId");
        return _token.totalSupply() / votingSettings.quorumVotesDelimiter;
    }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold(uint256 votingSettingsId) public view returns (uint) {
        VotingSettings storage votingSettings = _votingSettings[votingSettingsId];
        require(votingSettings.isValue, "Governor::proposalThreshold: incorrect votingSettingsId");
        return _token.totalSupply() / votingSettings.proposalThresholdDelimiter;
    }

    /// @notice The delay before voting on a proposal may take place, once proposed
    function _setVotingSettings(
        uint256 votingSettingsId,
        uint256 votingPeriod,
        uint256 expirationPeriod,
        uint256 proposalMaxOperations,
        uint256 quorumVotesDelimiter,
        uint256 proposalThresholdDelimiter
    ) internal {
        VotingSettings storage votingSettings = _votingSettings[votingSettingsId];
        require(votingSettings.isValue == false, "Governor::setVotingSettings: incorrect votingSettingsId");

        require(votingPeriod > 0, "Governor::setVotingSettings: shoud be more then 0");
        require(expirationPeriod > 0, "Governor::setVotingSettings: shoud be more then 0");
        require(proposalMaxOperations > 0, "Governor::setVotingSettings: shoud be more then 0");
        require(quorumVotesDelimiter > 0, "Governor::setVotingSettings: shoud be more then 0");
        require(proposalThresholdDelimiter > 0, "Governor::setVotingSettings: shoud be more then 0");

        VotingSettings memory newVotingSettings = VotingSettings({
            isValue: true,
            votingPeriod: votingPeriod,
            expirationPeriod: expirationPeriod,
            proposalMaxOperations: proposalMaxOperations,
            quorumVotesDelimiter: quorumVotesDelimiter,
            proposalThresholdDelimiter: proposalThresholdDelimiter
        });

        _votingSettings[votingSettingsId] = newVotingSettings;
    }

    function getVotingSettings(uint256 votingSettingsId) public view returns (VotingSettings memory) {
        return _votingSettings[votingSettingsId];
    }

    /// @notice The total number of proposals
    uint public _proposalCount;

    /// @notice id -  Unique id for looking up a proposal
    /// @notice proposer -  Creator of the proposal
    /// @notice targets -  the ordered list of target addresses for calls to be made
    /// @notice values -  The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    /// @notice signatures -  The ordered list of function signatures to be called
    /// @notice calldatas -  The ordered list of calldata to be passed to each call
    /// @notice startBlock -  The block at which voting begins: holders must delegate their votes prior to this block
    /// @notice endBlock -  The block at which voting ends: votes must be cast prior to this block
    /// @notice expiredBlock -  The block at which successful, but not executed transactions is expired
    /// @notice forVotes -  Current number of votes in favor of this proposal
    /// @notice againstVotes -  Current number of votes in opposition to this proposal
    /// @notice canceled -  Flag marking whether the proposal has been canceled
    /// @notice executed -  Flag marking whether the proposal has been executed
    /// @notice receipts -  Receipts of ballots for the entire set of voters
    struct Proposal {
        uint256 votingSettingsId;
        uint id;
        address proposer;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint expiredBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
        bool isMultiExecutable;
    }

    /// @notice Ballot receipt record for a voter
    /// @notice hasVoted - Whether or not a vote has been cast
    /// @notice support - Whether or not the voter supports the proposal
    /// @notice votes - The number of votes the voter had, which were cast
    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public _proposals;
    /// @notice The official records of all proposals executions
    mapping (uint => uint[]) public _proposalsExecutionBlocks;
    /// @notice The latest proposal for each proposer
    mapping (address => uint) public _latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint id);

    /// @notice An event emitted when a some proposals transaction has been executed
    event ExecuteTransaction(address indexed target, uint value, string signature, bytes data);

    /// @notice The delay before voting on a proposal may take place, once proposed
    function _propose(
        uint256 votingSettingsId,
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        bool isMultiExecutable
    ) internal returns (uint) {
        VotingSettings storage votingSettings = _votingSettings[votingSettingsId];
        require(votingSettings.isValue, "Governor::propose: incorrect votingSettingsId");

        require(
            _token.getPriorVotes(
                _msgSender(),
                block.number.sub(1, "Governor::propose: block.number - Underflow")
            ) > proposalThreshold(votingSettingsId),
            "Governor::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            "Governor::propose: proposal function information arity mismatch"
        );
        require(
            targets.length != 0,
            "Governor::propose: must provide actions"
        );
        require(
            targets.length <= votingSettings.proposalMaxOperations,
            "Governor::propose: too many actions"
        );

        uint startBlock = block.number;
        uint endBlock = startBlock.add(votingSettings.votingPeriod, "Governor::propose: endBlock - Add Overflow");

        _proposalCount++;
        Proposal memory newProposal = Proposal({
            votingSettingsId: votingSettingsId,
            id: _proposalCount,
            proposer: _msgSender(),
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            expiredBlock: endBlock.add(votingSettings.expirationPeriod, "Governor::propose: expiredBlock - Add Overflow"),
            //forVotes: _token.getPriorVotes(_msgSender(), 0),
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false,
            isMultiExecutable: isMultiExecutable
        });

        _proposals[newProposal.id] = newProposal;
        _latestProposalIds[newProposal.proposer] = newProposal.id;
        _castVote(newProposal.proposer, newProposal.id, true);

        emit ProposalCreated(newProposal.id, _msgSender(), targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function execute(uint proposalId) public payable {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "Governor::execute: proposal can only be executed if it is Succeeded"
        );
        Proposal storage proposal = _proposals[proposalId];
        _proposalsExecutionBlocks[proposalId].push(block.number);
        if (!proposal.isMultiExecutable) {
            proposal.executed = true;
        }

        for (uint i = 0; i < proposal.targets.length; i++) {
            _executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i]
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function _executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data
    ) internal returns (
        bytes memory
    ) {
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Governor::_executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }

    function cancel(uint proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "Governor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = _proposals[proposalId];

        require(
            _token.getPriorVotes(
                proposal.proposer,
                block.number.sub(1, "Governor::cancel: block.number - Underflow")
            ) < proposalThreshold(proposal.votingSettingsId),
            "Governor::cancel: proposer above threshold"
        );

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    function getActions(
        uint proposalId
    ) public view returns (
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = _proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return _proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(
            _proposalCount >= proposalId && proposalId > 0,
            "Governor::state: invalid proposal id"
        );
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes(proposal.votingSettingsId)) {
            return ProposalState.Defeated;
        } else if (block.number < proposal.expiredBlock) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Expired;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(_msgSender(), proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = _proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint256 votes = _token.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes, "Governor::_castVote: votes - Add Overflow");
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes, "Governor::_castVote: votes - Add Overflow");
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../interfaces/IGovernanceOwnable.sol";

abstract contract GovernanceOwnable is IGovernanceOwnable {
    address private _governanceAddress;

    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    constructor (address governance_) public {
        require(governance_ != address(0), "Governance address should be not null");
        _governanceAddress = governance_;
        emit GovernanceSetTransferred(address(0), governance_);
    }

    /**
     * @dev Returns the address of the current governanceAddress.
     */
    function governance() public view override returns (address) {
        return _governanceAddress;
    }

    /**
     * @dev Throws if called by any account other than the governanceAddress.
     */
    modifier onlyGovernance() {
        require(_governanceAddress == msg.sender, "Governance: caller is not the governance");
        _;
    }

    /**
     * @dev SetGovernance of the contract to a new account (`newGovernance`).
     * Can only be called by the current onlyGovernance.
     */
    function setGovernance(address newGovernance) public virtual override onlyGovernance {
        require(newGovernance != address(0), "GovernanceOwnable: new governance is the zero address");
        emit GovernanceSetTransferred(_governanceAddress, newGovernance);
        _governanceAddress = newGovernance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Copied from OpenZeppelin code:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IDelegable {
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IDelegable.sol";
import "./IERC20WithMaxTotalSupply.sol";

interface IDelegableERC20 is IDelegable, IERC20WithMaxTotalSupply {}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IERC20WithMaxTotalSupply is IERC20 {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address indexed account, uint tokens);
    event Burn(address indexed account, uint tokens);
    function maxTotalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGovernanceOwnable {
    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    function governance() external view returns (address);
    function setGovernance(address newGovernance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

