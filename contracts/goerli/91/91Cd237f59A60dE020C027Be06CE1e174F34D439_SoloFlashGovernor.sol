// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./FlashGovernor.sol";

contract SoloFlashGovernor is FlashGovernor {
    /**
     * @notice Upgradeable contract constructor
     * @dev Can be used instead of base governor initializer with many arguments
     */
    function soloInitialize() external initializer {
        initialize(address(0), address(0), 0, 0);
    }

    /**
     * @notice Function is called by owner to vote for some proposal
     * @param proposalId ID of the proposal to vote for
     * @param support Support of the proposal (true to support, false to reject)
     */
    function vote(uint256 proposalId, bool support)
        external
        override
        onlyOwner
    {
        if (support) {
            proposals[proposalId].forVotes++;
        } else {
            proposals[proposalId].againstVotes++;
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Function to get state of some proposal
     * @param proposalId ID of the proposal
     * @return Current proposal's state (as ProposalState enum)
     */
    function state(uint256 proposalId)
        public
        view
        override
        returns (ProposalState)
    {
        if (
            proposals[proposalId].forVotes == proposals[proposalId].againstVotes
        ) {
            return ProposalState.Active;
        } else if (
            proposals[proposalId].forVotes < proposals[proposalId].againstVotes
        ) {
            return ProposalState.Defeated;
        } else if (!proposals[proposalId].executed) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Executed;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ICPOOL.sol";
import "./interfaces/IMembershipStaking.sol";
import "./interfaces/IFlashGovernor.sol";

contract FlashGovernor is IFlashGovernor, OwnableUpgradeable {
    struct Receipt {
        bool hasVoted;
        bool support;
    }

    struct Proposal {
        bool executed;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => Receipt) receipts;
    }

    /// @notice Mapping of IDs to proposals
    mapping(uint256 => Proposal) public proposals;

    /// @notice Mapping from addresses to flags if they are allowed to propose (no direct proposals from users to FlashGovernor)
    mapping(address => bool) public allowedProposers;

    /// @notice Minimal number of votes to reach quorum
    uint256 public quorumVotes;

    /// @notice Period of voting for proposal (in blocks)
    uint256 public votingPeriod;

    /// @notice CPOOL token contract (as primary votes source)
    ICPOOL public cpool;

    /// @notice Membership staking contract (as staked votes source)
    IMembershipStaking public staking;

    /// @notice ID of last created proposal
    uint256 public lastProposalId;

    // EVENTS

    /// @notice Event emitted when new proposal is created
    event ProposalCreated(uint256 indexed proposalId);

    /// @notice Event emitted when vote is case for some proposal
    event VoteCast(uint256 indexed proposalId, address voter, bool support);

    /// @notice Event emitted when proposal is executed
    event ProposalExecuted(uint256 indexed proposalId);

    /// @notice Event emitted when new quorum votes value is set
    event QuorumVotesSet(uint256 votes);

    /// @notice Event emitted when new voting period is set
    event VotingPeriodSet(uint256 period);

    /// @notice Event emitted when state of address as allowed proposer is changed
    event AllowedProposerSet(address proposer, bool allowed);

    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param cpool_ The address of the CPOOL contract
     * @param staking_ The address of the MembershipStaking contract
     * @param quorumVotes_ Minimal number of votes to reach quorum
     * @param votingPeriod_ Period of voting for proposal (in blocks)
     */
    function initialize(
        address cpool_,
        address staking_,
        uint256 quorumVotes_,
        uint256 votingPeriod_
    ) public initializer {
        __Ownable_init();
        cpool = ICPOOL(cpool_);
        staking = IMembershipStaking(staking_);
        quorumVotes = quorumVotes_;
        votingPeriod = votingPeriod_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Function is called by allowed proposer to create new proposal
     * @return ID of the created proposal
     */
    function propose() external returns (uint256) {
        require(allowedProposers[msg.sender], "PNA");

        lastProposalId++;
        proposals[lastProposalId].startBlock = block.number + 1;
        proposals[lastProposalId].endBlock = block.number + votingPeriod;

        emit ProposalCreated(lastProposalId);
        return lastProposalId;
    }

    /**
     * @notice Function is called by CPOOL delegate to vote for some proposal
     * @param proposalId ID of the proposal to vote for
     * @param support Support of the proposal (true to support, false to reject)
     */
    function vote(uint256 proposalId, bool support) external virtual {
        require(state(proposalId) == ProposalState.Active, "PWS");
        require(!proposals[proposalId].receipts[msg.sender].hasVoted, "HWA");

        proposals[proposalId].receipts[msg.sender].hasVoted = true;
        proposals[proposalId].receipts[msg.sender].support = support;
        uint256 votes = getVotesAtBlock(
            msg.sender,
            proposals[proposalId].startBlock
        );
        if (support) {
            proposals[proposalId].forVotes += votes;
        } else {
            proposals[proposalId].againstVotes += votes;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Function is called by allowed proposer to mark succeeded proposal as executed
     * @param proposalId ID of the proposal to mark
     */
    function execute(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "PWS");
        require(allowedProposers[msg.sender], "APE");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function is called by contract owner to set quorum votes
     * @param quorumVotes_ New value for quorum votes
     */
    function setQuorumVotes(uint256 quorumVotes_) external onlyOwner {
        quorumVotes = quorumVotes_;
        emit QuorumVotesSet(quorumVotes_);
    }

    /**
     * @notice Function is called by contract owner to set voting period
     * @param votingPeriod_ New value for voting period
     */
    function setVotingPeriod(uint256 votingPeriod_) external onlyOwner {
        require(votingPeriod_ > 0, "VPZ");
        votingPeriod = votingPeriod_;
        emit VotingPeriodSet(votingPeriod_);
    }

    /**
     * @notice Function is called by contract owner to allow or forbid some proposer
     * @param proposer Address of the proposer to allow or forbid
     * @param allowed Allowance (true to allow, false to forbid)
     */
    function setAllowedProposer(address proposer, bool allowed)
        external
        onlyOwner
    {
        allowedProposers[proposer] = allowed;
        emit AllowedProposerSet(proposer, allowed);
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function to get state of some proposal
     * @param proposalId ID of the proposal
     * @return Current proposal's state (as ProposalState enum)
     */
    function state(uint256 proposalId)
        public
        view
        virtual
        returns (ProposalState)
    {
        if (block.number <= proposals[proposalId].startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposals[proposalId].endBlock) {
            return ProposalState.Active;
        } else if (
            proposals[proposalId].forVotes <=
            proposals[proposalId].againstVotes ||
            proposals[proposalId].forVotes +
                proposals[proposalId].againstVotes <
            quorumVotes
        ) {
            return ProposalState.Defeated;
        } else if (!proposals[proposalId].executed) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Executed;
        }
    }

    /**
     * @notice Function to get voting end block of some proposal
     * @param proposalId ID of the proposal
     * @return Proposal's voting end block
     */
    function proposalEndBlock(uint256 proposalId)
        external
        view
        returns (uint256)
    {
        return proposals[proposalId].endBlock;
    }

    /**
     * @notice Function returns given account votes at given block
     * @param account Account to get votes for
     * @param blockNumber Block number to get votes at
     * @return Number of votes
     */
    function getVotesAtBlock(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        return (uint256(cpool.getPriorVotes(account, blockNumber)) +
            staking.getPriorVotes(account, blockNumber));
    }

    /**
     * @notice Function to determine if sender has voted for given proposal
     * @param proposalId ID of the proposal
     * @return Receipt struct with voting information
     */
    function hasVoted(uint256 proposalId)
        external
        view
        returns (Receipt memory)
    {
        return proposals[proposalId].receipts[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICPOOL {
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMembershipStaking {
    function managerMinimalStake() external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    function lockStake(address account) external returns (uint256);

    function unlockStake(address account, uint256 amount) external;

    function transferStake(
        address account,
        uint256 amount,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFlashGovernor {
    function proposalEndBlock(uint256 proposalId)
        external
        view
        returns (uint256);

    function propose() external returns (uint256);

    function execute(uint256 proposalId) external;

    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed
    }

    function state(uint256 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}