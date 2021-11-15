// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant alphabet = '0123456789abcdef';

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0x00';
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = alphabet[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import './IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { AccessControl } from '../dependencies/open-zeppelin/AccessControl.sol';
import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';
import { IDydxGovernor } from '../interfaces/IDydxGovernor.sol';
import { IExecutorWithTimelock } from '../interfaces/IExecutorWithTimelock.sol';
import { IGovernanceStrategy } from '../interfaces/IGovernanceStrategy.sol';
import { IProposalValidator } from '../interfaces/IProposalValidator.sol';
import { IVotingStrategy } from '../interfaces/IVotingStrategy.sol';
import { isContract, getChainId } from '../misc/Helpers.sol';

/**
 * @title dYdX governor contract.
 * @author dYdX
 *
 * @notice Main point of interaction for dYdX governance. Holds governance proposals. Delegates to
 *  the governance strategy contract to determine how voting and proposing powers are counted. The
 *  content of a proposal is a sequence of function calls. These function calls must be made
 *  through authorized executor contracts.
 *
 *  Functionality includes:
 *    - Create a proposal
 *    - Cancel a proposal
 *    - Queue a proposal
 *    - Execute a proposal
 *    - Submit a vote to a proposal
 *
 *  Proposal state transitions in success case:
 *
 *    Pending => Active => Succeeded => Queued => Executed
 *
 *  Proposal state transitions in failure cases:
 *
 *    Pending => Active => Failed
 *    Pending => Active => Succeeded => Queued => Expired
 *    Pending => Canceled
 *    Pending => Active => Canceled
 *    Pending => Active => Succeeded => Canceled
 *    Pending => Active => Succeeded => Queued => Canceled
 **/
contract DydxGovernor is
  AccessControl,
  IDydxGovernor
{
  using SafeMath for uint256;

  // ============ Constants ============

  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant ADD_EXECUTOR_ROLE = keccak256('ADD_EXECUTOR_ROLE');

  // ============ Storage ============

  address private _governanceStrategy;
  uint256 private _votingDelay;
  uint256 private _proposalsCount;
  mapping(uint256 => Proposal) private _proposals;
  mapping(address => bool) private _authorizedExecutors;

  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    'EIP712Domain(string name,uint256 chainId,address verifyingContract)'
  );
  bytes32 public constant VOTE_EMITTED_TYPEHASH = keccak256(
    'VoteEmitted(uint256 id,bool support)'
  );
  string public constant EIP712_DOMAIN_NAME = 'dYdX Governance';

  constructor(
    address governanceStrategy,
    uint256 votingDelay,
    address addExecutorAdmin
  ) {
    _setGovernanceStrategy(governanceStrategy);
    _setVotingDelay(votingDelay);

    // Assign roles.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(ADD_EXECUTOR_ROLE, addExecutorAdmin);

    // Set OWNER_ROLE as the admin for all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(ADD_EXECUTOR_ROLE, OWNER_ROLE);
  }

  struct CreateVars {
    uint256 startBlock;
    uint256 endBlock;
    uint256 previousProposalsCount;
  }

  /**
   * @notice Creates a Proposal (needs to be validated by the Proposal Validator)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param ipfsHash IPFS hash of the proposal
   **/
  function create(
    IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash
  ) external override returns (uint256) {
    require(targets.length != 0, 'INVALID_EMPTY_TARGETS');
    require(
      targets.length == values.length &&
        targets.length == signatures.length &&
        targets.length == calldatas.length &&
        targets.length == withDelegatecalls.length,
      'INCONSISTENT_PARAMS_LENGTH'
    );

    require(isExecutorAuthorized(address(executor)), 'EXECUTOR_NOT_AUTHORIZED');

    require(
      IProposalValidator(address(executor)).validateCreatorOfProposal(
        this,
        msg.sender,
        block.number - 1
      ),
      'PROPOSITION_CREATION_INVALID'
    );

    CreateVars memory vars;

    vars.startBlock = block.number.add(_votingDelay);
    vars.endBlock = vars.startBlock.add(IProposalValidator(address(executor)).VOTING_DURATION());

    vars.previousProposalsCount = _proposalsCount;

    Proposal storage newProposal = _proposals[vars.previousProposalsCount];
    newProposal.id = vars.previousProposalsCount;
    newProposal.creator = msg.sender;
    newProposal.executor = executor;
    newProposal.targets = targets;
    newProposal.values = values;
    newProposal.signatures = signatures;
    newProposal.calldatas = calldatas;
    newProposal.withDelegatecalls = withDelegatecalls;
    newProposal.startBlock = vars.startBlock;
    newProposal.endBlock = vars.endBlock;
    newProposal.strategy = _governanceStrategy;
    newProposal.ipfsHash = ipfsHash;
    _proposalsCount = vars.previousProposalsCount + 1;

    emit ProposalCreated(
      vars.previousProposalsCount,
      msg.sender,
      executor,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      vars.startBlock,
      vars.endBlock,
      _governanceStrategy,
      ipfsHash
    );

    return newProposal.id;
  }

  /**
   * @dev Cancels a Proposal. Callable by anyone if the conditions on the executor are fulfilled.
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external override {
    ProposalState state = getProposalState(proposalId);
    require(
      state != ProposalState.Canceled &&
        state != ProposalState.Failed &&
        state != ProposalState.Expired &&
        state != ProposalState.Executed,
      'ONLY_BEFORE_EXECUTED'
    );

    Proposal storage proposal = _proposals[proposalId];
    require(
      IProposalValidator(address(proposal.executor)).validateProposalCancellation(
        this,
        proposal.creator,
        block.number - 1
      ),
      'PROPOSITION_CANCELLATION_INVALID'
    );
    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      proposal.executor.cancelTransaction(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.executionTime,
        proposal.withDelegatecalls[i]
      );
    }

    emit ProposalCanceled(proposalId);
  }

  /**
   * @dev Queue the proposal. Requires that the proposal succeeded.
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external override {
    require(getProposalState(proposalId) == ProposalState.Succeeded, 'INVALID_STATE_FOR_QUEUE');
    Proposal storage proposal = _proposals[proposalId];
    uint256 executionTime = block.timestamp.add(proposal.executor.getDelay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(
        proposal.executor,
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    proposal.executionTime = executionTime;

    emit ProposalQueued(proposalId, executionTime, msg.sender);
  }

  /**
   * @dev Execute the proposal. Requires that the proposal is queued.
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable override {
    require(getProposalState(proposalId) == ProposalState.Queued, 'ONLY_QUEUED_PROPOSALS');
    Proposal storage proposal = _proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      proposal.executor.executeTransaction{value: proposal.values[i]}(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.executionTime,
        proposal.withDelegatecalls[i]
      );
    }
    emit ProposalExecuted(proposalId, msg.sender);
  }

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   **/
  function submitVote(uint256 proposalId, bool support) external override {
    return _submitVote(msg.sender, proposalId, support);
  }

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        keccak256(
          abi.encode(
            DOMAIN_TYPEHASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            getChainId(),
            address(this)
          )
        ),
        keccak256(abi.encode(VOTE_EMITTED_TYPEHASH, proposalId, support))
      )
    );
    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0), 'INVALID_SIGNATURE');
    return _submitVote(signer, proposalId, support);
  }

  /**
   * @dev Set new GovernanceStrategy
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param governanceStrategy new Address of the GovernanceStrategy contract
   **/
  function setGovernanceStrategy(address governanceStrategy)
    external
    override
    onlyRole(OWNER_ROLE)
  {
    _setGovernanceStrategy(governanceStrategy);
  }

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in terms of blocks
   **/
  function setVotingDelay(uint256 votingDelay)
    external
    override
    onlyRole(OWNER_ROLE)
  {
    _setVotingDelay(votingDelay);
  }

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors)
    public
    override
    onlyRole(ADD_EXECUTOR_ROLE)
  {
    for (uint256 i = 0; i < executors.length; i++) {
      _authorizeExecutor(executors[i]);
    }
  }

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors)
    public
    override
    onlyRole(OWNER_ROLE)
  {
    for (uint256 i = 0; i < executors.length; i++) {
      _unauthorizeExecutor(executors[i]);
    }
  }

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
  function getGovernanceStrategy() external view override returns (address) {
    return _governanceStrategy;
  }

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in number of blocks
   **/
  function getVotingDelay() external view override returns (uint256) {
    return _votingDelay;
  }

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) public view override returns (bool) {
    return _authorizedExecutors[executor];
  }

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view override returns (uint256) {
    return _proposalsCount;
  }

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
  function getProposalById(uint256 proposalId)
    external
    view
    override
    returns (ProposalWithoutVotes memory)
  {
    Proposal storage proposal = _proposals[proposalId];
    ProposalWithoutVotes memory proposalWithoutVotes = ProposalWithoutVotes({
      id: proposal.id,
      creator: proposal.creator,
      executor: proposal.executor,
      targets: proposal.targets,
      values: proposal.values,
      signatures: proposal.signatures,
      calldatas: proposal.calldatas,
      withDelegatecalls: proposal.withDelegatecalls,
      startBlock: proposal.startBlock,
      endBlock: proposal.endBlock,
      executionTime: proposal.executionTime,
      forVotes: proposal.forVotes,
      againstVotes: proposal.againstVotes,
      executed: proposal.executed,
      canceled: proposal.canceled,
      strategy: proposal.strategy,
      ipfsHash: proposal.ipfsHash
    });

    return proposalWithoutVotes;
  }

  /**
   * @notice Get information about a voter's vote on a proposal.
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    override
    returns (Vote memory)
  {
    return _proposals[proposalId].votes[voter];
  }

  /**
   * @notice Get the current state of a proposal.
   * @param proposalId id of the proposal
   * @return The current state of the proposal
   **/
  function getProposalState(uint256 proposalId) public view override returns (ProposalState) {
    require(_proposalsCount > proposalId, 'INVALID_PROPOSAL_ID');
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (!IProposalValidator(address(proposal.executor)).isProposalPassed(this, proposalId)) {
      return ProposalState.Failed;
    } else if (proposal.executionTime == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (proposal.executor.isProposalOverGracePeriod(this, proposalId)) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function _queueOrRevert(
    IExecutorWithTimelock executor,
    address target,
    uint256 value,
    string memory signature,
    bytes memory callData,
    uint256 executionTime,
    bool withDelegatecall
  ) internal {
    require(
      !executor.isActionQueued(
        keccak256(abi.encode(target, value, signature, callData, executionTime, withDelegatecall))
      ),
      'DUPLICATED_ACTION'
    );
    executor.queueTransaction(target, value, signature, callData, executionTime, withDelegatecall);
  }

  function _submitVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal {
    require(getProposalState(proposalId) == ProposalState.Active, 'VOTING_CLOSED');
    Proposal storage proposal = _proposals[proposalId];
    Vote storage vote = proposal.votes[voter];

    require(vote.votingPower == 0, 'VOTE_ALREADY_SUBMITTED');

    uint256 votingPower = IVotingStrategy(proposal.strategy).getVotingPowerAt(
      voter,
      proposal.startBlock
    );

    if (support) {
      proposal.forVotes = proposal.forVotes.add(votingPower);
    } else {
      proposal.againstVotes = proposal.againstVotes.add(votingPower);
    }

    vote.support = support;
    vote.votingPower = uint248(votingPower);

    emit VoteEmitted(proposalId, voter, support, votingPower);
  }

  function _setGovernanceStrategy(address governanceStrategy) internal {
    _governanceStrategy = governanceStrategy;

    emit GovernanceStrategyChanged(governanceStrategy, msg.sender);
  }

  function _setVotingDelay(uint256 votingDelay) internal {
    _votingDelay = votingDelay;

    emit VotingDelayChanged(votingDelay, msg.sender);
  }

  function _authorizeExecutor(address executor) internal {
    _authorizedExecutors[executor] = true;
    emit ExecutorAuthorized(executor);
  }

  function _unauthorizeExecutor(address executor) internal {
    _authorizedExecutors[executor] = false;
    emit ExecutorUnauthorized(executor);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IExecutorWithTimelock } from './IExecutorWithTimelock.sol';

interface IDydxGovernor {

  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  struct Vote {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
    mapping(address => Vote) votes;
  }

  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev emitted when a new proposal is created
   * @param id Id of the proposal
   * @param creator address of the creator
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param startBlock block number when vote starts
   * @param endBlock block number when vote ends
   * @param strategy address of the governanceStrategy contract
   * @param ipfsHash IPFS hash of the proposal
   **/
  event ProposalCreated(
    uint256 id,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startBlock,
    uint256 endBlock,
    address strategy,
    bytes32 ipfsHash
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param id Id of the proposal
   **/
  event ProposalCanceled(uint256 id);

  /**
   * @dev emitted when a proposal is queued
   * @param id Id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(uint256 id, uint256 executionTime, address indexed initiatorQueueing);
  /**
   * @dev emitted when a proposal is executed
   * @param id Id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 id, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param id Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(uint256 id, address indexed voter, bool support, uint256 votingPower);

  event GovernanceStrategyChanged(address indexed newStrategy, address indexed initiatorChange);

  event VotingDelayChanged(uint256 newVotingDelay, address indexed initiatorChange);

  event ExecutorAuthorized(address executor);

  event ExecutorUnauthorized(address executor);

  /**
   * @dev Creates a Proposal (needs Proposition Power of creator > Threshold)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls if true, transaction delegatecalls the taget, else calls the target
   * @param ipfsHash IPFS hash of the proposal
   **/
  function create(
    IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev Cancels a Proposal, when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   **/
  function submitVote(uint256 proposalId, bool support) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Set new GovernanceStrategy
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param governanceStrategy new Address of the GovernanceStrategy contract
   **/
  function setGovernanceStrategy(address governanceStrategy) external;

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
  function getGovernanceStrategy() external view returns (address);

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVotes memory);

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter) external view returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IDydxGovernor } from './IDydxGovernor.sol';

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IDydxGovernor governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IGovernanceStrategy {

  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IDydxGovernor } from './IDydxGovernor.sol';

interface IProposalValidator {

  /**
   * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be created
   **/
  function validateCreatorOfProposal(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns whether a user has enough Proposition Power to make a proposal.
   * @param governance Governance Contract
   * @param user Address of the user to be challenged.
   * @param blockNumber Block Number against which to make the challenge.
   * @return true if user has enough power
   **/
  function isPropositionPowerEnough(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns the minimum Proposition Power needed to create a proposition.
   * @param governance Governance Contract
   * @param blockNumber Blocknumber at which to evaluate
   * @return minimum Proposition Power needed
   **/
  function getMinimumPropositionPowerNeeded(IDydxGovernor governance, uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns whether a proposal passed or not
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isProposalPassed(IDydxGovernor governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
   * Here quorum is not to understand as number of votes reached, but number of for-votes reached
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IDydxGovernor governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IDydxGovernor governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
   * @param votingSupply Total number of oustanding voting tokens
   * @return voting power needed for a proposal to pass
   **/
  function getMinimumVotingPowerNeeded(uint256 votingSupply) external view returns (uint256);

  /**
   * @dev Get proposition threshold constant value
   * @return the proposition threshold value (100 <=> 1%)
   **/
  function PROPOSITION_THRESHOLD() external view returns (uint256);

  /**
   * @dev Get voting duration constant value
   * @return the voting duration value in seconds
   **/
  function VOTING_DURATION() external view returns (uint256);

  /**
   * @dev Get the vote differential threshold constant value
   * to compare with % of for votes/total supply - % of against votes/total supply
   * @return the vote differential threshold value (100 <=> 1%)
   **/
  function VOTE_DIFFERENTIAL() external view returns (uint256);

  /**
   * @dev Get quorum threshold constant value
   * to compare with % of for votes/total supply
   * @return the quorum threshold value (100 <=> 1%)
   **/
  function MINIMUM_QUORUM() external view returns (uint256);

  /**
   * @dev precision helper: 100% = 10000
   * @return one hundred percents with our chosen precision
   **/
  function ONE_HUNDRED_WITH_PRECISION() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

interface IVotingStrategy {
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

function getChainId() pure returns (uint256) {
  uint256 chainId;
  assembly {
    chainId := chainid()
  }
  return chainId;
}

function isContract(address account) view returns (bool) {
  // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
  // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
  // for accounts without code, i.e. `keccak256('')`
  bytes32 codehash;
  bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
  // solhint-disable-next-line no-inline-assembly
  assembly {
    codehash := extcodehash(account)
  }
  return (codehash != accountHash && codehash != 0x0);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { IDydxGovernor } from '../../interfaces/IDydxGovernor.sol';
import { IGovernanceStrategy } from '../../interfaces/IGovernanceStrategy.sol';
import { IProposalValidator } from '../../interfaces/IProposalValidator.sol';

/**
 * @title Proposal validator contract mixin, inherited the governance executor contract.
 * @dev Validates/Invalidations propositions state modifications.
 * Proposition Power functions: Validates proposition creations/ cancellation
 * Voting Power functions: Validates success of propositions.
 * @author dYdX
 **/
contract ProposalValidatorMixin is IProposalValidator {
  using SafeMath for uint256;

  uint256 public immutable override PROPOSITION_THRESHOLD;
  uint256 public immutable override VOTING_DURATION;
  uint256 public immutable override VOTE_DIFFERENTIAL;
  uint256 public immutable override MINIMUM_QUORUM;
  uint256 public constant override ONE_HUNDRED_WITH_PRECISION = 10000; // Represents 100%.

  /**
   * @dev Constructor
   * @param propositionThreshold minimum percentage of supply needed to submit a proposal
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param votingDuration duration in blocks of the voting period
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   **/
  constructor(
    uint256 propositionThreshold,
    uint256 votingDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum
  ) {
    PROPOSITION_THRESHOLD = propositionThreshold;
    VOTING_DURATION = votingDuration;
    VOTE_DIFFERENTIAL = voteDifferential;
    MINIMUM_QUORUM = minimumQuorum;
  }

  /**
   * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be created
   **/
  function validateCreatorOfProposal(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) external view override returns (bool) {
    return isPropositionPowerEnough(governance, user, blockNumber);
  }

  /**
   * @dev Called to validate the cancellation of a proposal
   * Needs to creator to have lost proposition power threashold
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) external view override returns (bool) {
    return !isPropositionPowerEnough(governance, user, blockNumber);
  }

  /**
   * @dev Returns whether a user has enough Proposition Power to make a proposal.
   * @param governance Governance Contract
   * @param user Address of the user to be challenged.
   * @param blockNumber Block Number against which to make the challenge.
   * @return true if user has enough power
   **/
  function isPropositionPowerEnough(
    IDydxGovernor governance,
    address user,
    uint256 blockNumber
  ) public view override returns (bool) {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy.getPropositionPowerAt(user, blockNumber) >=
      getMinimumPropositionPowerNeeded(governance, blockNumber);
  }

  /**
   * @dev Returns the minimum Proposition Power needed to create a proposition.
   * @param governance Governance Contract
   * @param blockNumber Blocknumber at which to evaluate
   * @return minimum Proposition Power needed
   **/
  function getMinimumPropositionPowerNeeded(IDydxGovernor governance, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy
        .getTotalPropositionSupplyAt(blockNumber)
        .mul(PROPOSITION_THRESHOLD)
        .div(ONE_HUNDRED_WITH_PRECISION);
  }

  /**
   * @dev Returns whether a proposal passed or not
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isProposalPassed(IDydxGovernor governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /**
   * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
   * @param votingSupply Total number of oustanding voting tokens
   * @return voting power needed for a proposal to pass
   **/
  function getMinimumVotingPowerNeeded(uint256 votingSupply)
    public
    view
    override
    returns (uint256)
  {
    return votingSupply.mul(MINIMUM_QUORUM).div(ONE_HUNDRED_WITH_PRECISION);
  }

  /**
   * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
   * Here quorum is not to understand as number of votes reached, but number of for-votes reached
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IDydxGovernor governance, uint256 proposalId)
    public
    view
    override
    returns (bool)
  {
    IDydxGovernor.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
  }

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IDydxGovernor governance, uint256 proposalId)
    public
    view
    override
    returns (bool)
  {
    IDydxGovernor.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return (proposal.forVotes.mul(ONE_HUNDRED_WITH_PRECISION).div(votingSupply) >
      proposal.againstVotes.mul(ONE_HUNDRED_WITH_PRECISION).div(votingSupply).add(
        VOTE_DIFFERENTIAL
      ));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { PriorityTimelockExecutorMixin } from './PriorityTimelockExecutorMixin.sol';
import { ProposalValidatorMixin } from './ProposalValidatorMixin.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations / cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author dYdX
 **/
contract PriorityExecutor is PriorityTimelockExecutorMixin, ProposalValidatorMixin {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 priorityPeriod,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum,
    address priorityExecutor
  )
    PriorityTimelockExecutorMixin(
      admin,
      delay,
      gracePeriod,
      minimumDelay,
      maximumDelay,
      priorityPeriod,
      priorityExecutor
    )
    ProposalValidatorMixin(
      propositionThreshold,
      voteDuration,
      voteDifferential,
      minimumQuorum
    )
  {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { IPriorityTimelockExecutor } from '../../interfaces/IPriorityTimelockExecutor.sol';
import { IDydxGovernor } from '../../interfaces/IDydxGovernor.sol';

/**
 * @title Time-locked executor contract mixin, inherited the governance executor contract.
 * @dev Contract that can queue, execute, cancel transactions voted by Governance
 * Queued transactions can be executed after a delay and until
 * Grace period is not over.
 * @author dYdX
 **/
contract PriorityTimelockExecutorMixin is IPriorityTimelockExecutor {
  using SafeMath for uint256;

  uint256 public immutable override GRACE_PERIOD;
  uint256 public immutable override MINIMUM_DELAY;
  uint256 public immutable override MAXIMUM_DELAY;

  address private _admin;
  address private _pendingAdmin;
  mapping(address => bool) private _isPriorityController;

  uint256 private _delay;
  uint256 private _priorityPeriod;

  mapping(bytes32 => bool) private _queuedTransactions;
  mapping(bytes32 => bool) private _priorityUnlockedTransactions;

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal
   * @param gracePeriod time after `delay` while a proposal can be executed
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threhold of `delay`, in seconds
   * @param priorityPeriod time at end of delay period during which a priority controller may “unlock”
   * @param priorityController address which may execute proposals during the priority window
   *  the proposal for early execution
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 priorityPeriod,
    address priorityController
  ) {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _validatePriorityPeriod(delay, priorityPeriod);
    _delay = delay;
    _priorityPeriod = priorityPeriod;
    _admin = admin;

    GRACE_PERIOD = gracePeriod;
    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewPriorityPeriod(priorityPeriod);
    emit NewAdmin(admin);

    _updatePriorityController(priorityController, true);
  }

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == address(this), 'ONLY_BY_THIS_TIMELOCK');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  modifier onlyPriorityController() {
    require(_isPriorityController[msg.sender], 'ONLY_BY_PRIORITY_CONTROLLER');
    _;
  }

  /**
   * @dev Set the delay
   * @param delay delay between queue and execution of proposal
   **/
  function setDelay(uint256 delay) public onlyTimelock {
    _validateDelay(delay);
    _validatePriorityPeriod(delay, _priorityPeriod);
    _delay = delay;

    emit NewDelay(delay);
  }

  /**
   * @dev Set the priority period
   * @param priorityPeriod time at end of delay period during which a priority controller may “unlock”
   *  the proposal for early execution
   **/
  function setPriorityPeriod(uint256 priorityPeriod) public onlyTimelock {
    _validatePriorityPeriod(_delay, priorityPeriod);
    _priorityPeriod = priorityPeriod;

    emit NewPriorityPeriod(priorityPeriod);
  }

  /**
   * @dev Function enabling pending admin to become admin
   **/
  function acceptAdmin() public onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /**
   * @dev Add or remove a priority controller.
   */
  function updatePriorityController(address account, bool isPriorityController) public onlyTimelock {
    _updatePriorityController(account, isPriorityController);
  }

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp.add(_delay), 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash of the canceled tx
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the callData executed as memory bytes
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public payable override onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp <= executionTime.add(GRACE_PERIOD), 'GRACE_PERIOD_FINISHED');

    // Require either that:
    //  - the timelock elapsed; or
    //  - the transaction was unlocked by a priority controller, and we are in the priority
    //    execution window.
    if (_priorityUnlockedTransactions[actionHash]) {
      require(block.timestamp >= executionTime.sub(_priorityPeriod), 'NOT_IN_PRIORITY_WINDOW');
    } else {
      require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    }

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, "NOT_ENOUGH_MSG_VALUE");
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /**
   * @dev Function, called by a priority controller, to lock or unlock a proposal for execution
   *  during the priority period.
   * @param actionHash hash of the action
   * @param isUnlockedForExecution whether the proposal is executable during the priority period
   */
  function setTransactionPriorityStatus(
    bytes32 actionHash,
    bool isUnlockedForExecution
  ) public onlyPriorityController {
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    _priorityUnlockedTransactions[actionHash] = isUnlockedForExecution;
    emit UpdatedActionPriorityStatus(actionHash, isUnlockedForExecution);
  }

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view override returns (address) {
    return _admin;
  }

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view override returns (address) {
    return _pendingAdmin;
  }

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /**
   * @dev Getter of the priority period, which is amount of time before mandatory
   * timelock delay that a proposal can be executed early only by a priority controller.
   * @return The priority period in seconds.
   **/
  function getPriorityPeriod() external view returns (uint256) {
    return _priorityPeriod;
  }

  /**
   * @dev Getter for whether an address is a priority controller.
   * @param account address to check for being a priority controller
   * @return True if `account` is a priority controller, false if not.
   **/
  function isPriorityController(address account) external view returns (bool) {
    return _isPriorityController[account];
  }

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view override returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /**
   * @dev Returns whether an action (via actionHash) has priority status
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function hasPriorityStatus(bytes32 actionHash) external view returns (bool) {
    return _priorityUnlockedTransactions[actionHash];
  }

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IDydxGovernor governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    IDydxGovernor.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime.add(GRACE_PERIOD));
  }

  function _updatePriorityController(address account, bool isPriorityController) internal {
    _isPriorityController[account] = isPriorityController;
    emit PriorityControllerUpdated(account, isPriorityController);
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  function _validatePriorityPeriod(uint256 delay, uint256 priorityPeriod) internal view {
    require(priorityPeriod <= delay, 'PRIORITY_PERIOD_LONGER_THAN_DELAY');
  }

  receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IDydxGovernor } from './IDydxGovernor.sol';
import { IExecutorWithTimelock } from './IExecutorWithTimelock.sol';

interface IPriorityTimelockExecutor is IExecutorWithTimelock {

  /**
   * @dev emitted when a priority controller is added or removed
   * @param account address added or removed
   * @param isPriorityController whether the account is now a priority controller
   */
  event PriorityControllerUpdated(address account, bool isPriorityController);


  /**
   * @dev emitted when a new priority period is set
   * @param priorityPeriod new priority period
   **/
  event NewPriorityPeriod(uint256 priorityPeriod);

  /**
   * @dev emitted when an action is locked or unlocked for execution by a priority controller
   * @param actionHash hash of the action
   * @param isUnlockedForExecution whether the proposal is executable during the priority period
   */
  event UpdatedActionPriorityStatus(bytes32 actionHash, bool isUnlockedForExecution);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IDydxGovernor } from '../interfaces/IDydxGovernor.sol';
import { IERC20 } from '../interfaces/IERC20.sol';
import { IExecutorWithTimelock } from '../interfaces/IExecutorWithTimelock.sol';

contract FlashAttacks {

  IERC20 internal immutable TOKEN;
  address internal immutable MINTER;
  IDydxGovernor internal immutable GOV;

  constructor(address _token, address _MINTER, address _governance) {
    TOKEN = IERC20(_token);
    MINTER = _MINTER;
    GOV = IDydxGovernor(_governance);
  }

  function flashVote(uint256 votePower, uint256 proposalId, bool support) external {
    TOKEN.transferFrom(MINTER,address(this), votePower);
    GOV.submitVote(proposalId, support);
    TOKEN.transfer(MINTER, votePower);
  }

  function flashVotePermit(uint256 votePower, uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s) external {
    TOKEN.transferFrom(MINTER, address(this), votePower);
    GOV.submitVoteBySignature(proposalId, support, v, r, s);
    TOKEN.transfer(MINTER, votePower);
  }

  function flashProposal(uint256 proposalPower, IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash) external {
    TOKEN.transferFrom(MINTER, address(this),proposalPower);
    GOV.create(executor, targets, values, signatures, calldatas, withDelegatecalls, ipfsHash);
    TOKEN.transfer(MINTER, proposalPower);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { IExecutorWithTimelock } from '../../interfaces/IExecutorWithTimelock.sol';
import { IDydxGovernor } from '../../interfaces/IDydxGovernor.sol';

/**
 * @title Time-locked executor contract mixin, inherited the governance executor contract.
 * @dev Contract that can queue, execute, cancel transactions voted by Governance
 * Queued transactions can be executed after a delay and until
 * Grace period is not over.
 * @author dYdX
 **/
contract ExecutorWithTimelockMixin is IExecutorWithTimelock {
  using SafeMath for uint256;

  uint256 public immutable override GRACE_PERIOD;
  uint256 public immutable override MINIMUM_DELAY;
  uint256 public immutable override MAXIMUM_DELAY;

  address private _admin;
  address private _pendingAdmin;
  uint256 private _delay;

  mapping(bytes32 => bool) private _queuedTransactions;

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal
   * @param gracePeriod time after `delay` while a proposal can be executed
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threhold of `delay`, in seconds
   **/
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay
  ) {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _admin = admin;

    GRACE_PERIOD = gracePeriod;
    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewAdmin(admin);
  }

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyTimelock() {
    require(msg.sender == address(this), 'ONLY_BY_THIS_TIMELOCK');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  /**
   * @dev Set the delay
   * @param delay delay between queue and execution of proposal
   **/
  function setDelay(uint256 delay) public onlyTimelock {
    _validateDelay(delay);
    _delay = delay;

    emit NewDelay(delay);
  }

  /**
   * @dev Function enabling pending admin to become admin
   **/
  function acceptAdmin() public onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /**
   * @dev Function, called by Governance, that queues a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp.add(_delay), 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the action Hash of the canceled tx
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public override onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /**
   * @dev Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return the callData executed as memory bytes
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) public payable override onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    require(block.timestamp <= executionTime.add(GRACE_PERIOD), 'GRACE_PERIOD_FINISHED');

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, "NOT_ENOUGH_MSG_VALUE");
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view override returns (address) {
    return _admin;
  }

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view override returns (address) {
    return _pendingAdmin;
  }

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view override returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(IDydxGovernor governance, uint256 proposalId)
    external
    view
    override
    returns (bool)
  {
    IDydxGovernor.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime.add(GRACE_PERIOD));
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

/**
 * @title Math
 * @author dYdX
 *
 * @dev Library for non-standard Math functions.
 */
library Math {
  using SafeMath for uint256;

  // ============ Library Functions ============

  /**
   * @dev Return `ceil(numerator / denominator)`.
   */
  function divRoundUp(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
    if (numerator == 0) {
      // SafeMath will check for zero denominator
      return SafeMath.div(0, denominator);
    }
    return numerator.sub(1).div(denominator).add(1);
  }

  /**
   * @dev Returns the minimum between a and b.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the maximum between a and b.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}

pragma solidity 0.7.5;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

contract TreasuryVester {
    using SafeMath for uint256;

    address public dydx;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address dydx_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) {
        require(vestingBegin_ >= block.timestamp, 'VESTING_BEGIN_TOO_EARLY');
        require(vestingCliff_ >= vestingBegin_, 'VESTING_CLIFF_BEFORE_BEGIN');
        require(vestingEnd_ > vestingCliff_, 'VESTING_END_BEFORE_CLIFF');

        dydx = dydx_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'SET_RECIPIENT_UNAUTHORIZED');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'CLAIM_TOO_EARLY');
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IDydx(dydx).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IDydx(dydx).transfer(recipient, amount);
    }
}

interface IDydx {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address dst, uint256 rawAmount) external returns (bool);
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

interface ISafetyModuleV1 {
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    returns (uint256);
}

interface ILiquidityStakingV1 {
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    returns (uint256);
}

interface IMerkleDistributorV1 {
  function claimRewardsFor(
    address user,
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256);
}

interface ITreasuryVester {
  function claim() external;
}

/**
 * @title ClaimsProxy
 * @author dYdX
 *
 * @notice Contract which claims DYDX rewards from multiple contracts on behalf of a user.
 *
 *  Requires the following permissions:
 *    - Set as the CLAIMS_PROXY on the SafetyModuleV1 contract.
 *    - Has role CLAIM_OPERATOR_ROLE on the LiquidityStakingV1 contract.
 *    - Has role CLAIM_OPERATOR_ROLE on the MerkleDistributorV1 contract.
 */
contract ClaimsProxy {
  using SafeMath for uint256;

  // ============ Constants ============

  ISafetyModuleV1 public immutable SAFETY_MODULE;
  ILiquidityStakingV1 public immutable LIQUIDITY_STAKING;
  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;
  ITreasuryVester public immutable REWARDS_TREASURY_VESTER;

  // ============ Constructor ============

  constructor(
    ISafetyModuleV1 safetyModule,
    ILiquidityStakingV1 liquidityStaking,
    IMerkleDistributorV1 merkleDistributor,
    ITreasuryVester rewardsTreasuryVester
  ) {
    SAFETY_MODULE = safetyModule;
    LIQUIDITY_STAKING = liquidityStaking;
    MERKLE_DISTRIBUTOR = merkleDistributor;
    REWARDS_TREASURY_VESTER = rewardsTreasuryVester;
  }

  // ============ External Functions ============

  /**
   * @notice Claim rewards from zero or more rewards contracts. All rewards are sent directly to
   *  the sender's address.
   *
   * @param  claimSafetyRewards       Whether or not to claim rewards from SafetyModuleV1.
   * @param  claimLiquidityRewards    Whether or not to claim rewards from LiquidityStakingV1.
   * @param  merkleCumulativeAmount   The cumulative rewards amount for the user in the
   *                                  MerkleDistributorV1 rewards Merkle tree, or zero to skip
   *                                  claiming from this contract.
   * @param  merkleProof              The Merkle proof for the user's cumulative rewards.
   * @param  vestFromTreasuryVester   Whether or not to vest rewards from the rewards treasury
   *                                  vester to the rewards treasury (e.g. set to true if rewards
   *                                  treasury has insufficient funds for users, and false otherwise).
   *
   * @return The total number of rewards claimed.
   */
  function claimRewards(
    bool claimSafetyRewards,
    bool claimLiquidityRewards,
    uint256 merkleCumulativeAmount,
    bytes32[] calldata merkleProof,
    bool vestFromTreasuryVester
  )
    external
    returns (uint256)
  {
    if (vestFromTreasuryVester) {
      // call rewards treasury vester so that rewards treasury has sufficient rewards
      REWARDS_TREASURY_VESTER.claim();
    }

    address user = msg.sender;

    uint256 amount1 = 0;
    uint256 amount2 = 0;
    uint256 amount3 = 0;

    if (claimSafetyRewards) {
      amount1 = SAFETY_MODULE.claimRewardsFor(user, user);
    }
    if (claimLiquidityRewards) {
      amount2 = LIQUIDITY_STAKING.claimRewardsFor(user, user);
    }
    if (merkleCumulativeAmount != 0) {
      amount3 = MERKLE_DISTRIBUTOR.claimRewardsFor(user, merkleCumulativeAmount, merkleProof);
    }

    return amount1.add(amount2).add(amount3);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { Ownable } from '../../dependencies/open-zeppelin/Ownable.sol';
import { MerkleProof } from '../../dependencies/open-zeppelin/MerkleProof.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { IRewardsOracle } from '../../interfaces/IRewardsOracle.sol';
import { MD1Claims } from './impl/MD1Claims.sol';
import { MD1RootUpdates } from './impl/MD1RootUpdates.sol';
import { MD1Configuration } from './impl/MD1Configuration.sol';
import { MD1Getters } from './impl/MD1Getters.sol';

/**
 * @title MerkleDistributorV1
 * @author dYdX
 *
 * @notice Distributes DYDX token rewards according to a Merkle tree of balances. The tree can be
 *  updated periodially with each user's cumulative rewards balance, allowing new rewards to be
 *  distributed to users over time.
 *
 *  An update is performed by setting the proposed Merkle root to the latest value returned by
 *  the oracle contract. The proposed Merkle root can be made active after a waiting period has
 *  elapsed. During the waiting period, dYdX governance has the opportunity to freeze the Merkle
 *  root, in case the proposed root is incorrect or malicious.
 */
contract MerkleDistributorV1 is
  MD1RootUpdates,
  MD1Claims,
  MD1Configuration,
  MD1Getters
{
  // ============ Constructor ============

  constructor(
    address rewardsToken,
    address rewardsTreasury
  )
    MD1Claims(rewardsToken, rewardsTreasury)
    {}

  // ============ External Functions ============

  function initialize(
    address rewardsOracle,
    string calldata ipnsName,
    uint256 ipfsUpdatePeriod,
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha,
    uint256 epochInterval,
    uint256 epochOffset
  )
    external
    initializer
  {
    __MD1Roles_init();
    __MD1Configuration_init(
      rewardsOracle,
      ipnsName,
      ipfsUpdatePeriod,
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
    __MD1EpochSchedule_init(epochInterval, epochOffset);
  }

  // ============ Internal Functions ============

  /**
   * @dev Returns the revision of the implementation contract. Used by VersionedInitializable.
   *
   * @return The revision number.
   */
  function getRevision()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IRewardsOracle {

  /**
   * @notice Returns the oracle value, agreed upon by all oracle signers. If the signers have not
   *  agreed upon a value, should return zero for all return values.
   *
   * @return  merkleRoot  The Merkle root for the next Merkle distributor update.
   * @return  epoch       The epoch number corresponding to the new Merkle root.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function read()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MerkleProof } from '../../../dependencies/open-zeppelin/MerkleProof.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Roles } from './MD1Roles.sol';

/**
 * @title MD1Claims
 * @author dYdX
 *
 * @notice Allows rewards to be claimed by providing a Merkle proof of the rewards amount.
 */
abstract contract MD1Claims is
  MD1Roles
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The token distributed as rewards.
  IERC20 public immutable REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public immutable REWARDS_TREASURY;

  // ============ Events ============

  /// @notice Emitted when a user claims rewards.
  event RewardsClaimed(
    address account,
    uint256 amount
  );

  /// @notice Emitted when a user opts into or out of the claim-for allowlist.
  event AlwaysAllowClaimForUpdated(
    address user,
    bool allow
  );

  // ============ Constructor ============

  constructor(
    address rewardsToken,
    address rewardsTreasury
  ) {
    REWARDS_TOKEN = IERC20(rewardsToken);
    REWARDS_TREASURY = rewardsTreasury;
  }

  // ============ External Functions ============

  /**
   * @notice Claim the remaining unclaimed rewards for the sender.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _claimRewards(msg.sender, cumulativeAmount, merkleProof);
  }

  /**
   * @notice Claim the remaining unclaimed rewards for a user, and send them to that user.
   *
   *  The caller must be authorized with CLAIM_OPERATOR_ROLE unless the specified user has opted
   *  into the claim-for allowlist. In any case, rewards are transfered to the original user
   *  specified in the Merkle tree.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  user              Address of the user on whose behalf to trigger a claim.
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address user,
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    nonReentrant
    returns (uint256)
  {
    require(
      (
        hasRole(CLAIM_OPERATOR_ROLE, msg.sender) ||
        _ALWAYS_ALLOW_CLAIMS_FOR_[user]
      ),
      'MD1Claims: Do not have permission to claim for this user'
    );
    return _claimRewards(user, cumulativeAmount, merkleProof);
  }

  /**
   * @notice Opt into allowing anyone to claim on the sender's behalf.
   *
   *  Note that this does not affect who receives the funds. The user specified in the Merkle tree
   *  receives those rewards regardless of who issues the claim.
   *
   *  Note that addresses with the CLAIM_OPERATOR_ROLE ignore this allowlist when triggering claims.
   *
   * @param  allow  Whether or not to allow claims on the sender's behalf.
   */
  function setAlwaysAllowClaimsFor(
    bool allow
  )
    external
    nonReentrant
  {
    _ALWAYS_ALLOW_CLAIMS_FOR_[msg.sender] = allow;
    emit AlwaysAllowClaimForUpdated(msg.sender, allow);
  }

  // ============ Internal Functions ============

  /**
   * @notice Claim the remaining unclaimed rewards for a user, and send them to that user.
   *
   *  Reverts if the provided Merkle proof is invalid.
   *
   * @param  user              Address of the user.
   * @param  cumulativeAmount  The total all-time rewards this user has earned.
   * @param  merkleProof       The Merkle proof for the user and cumulative amount.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    internal
    returns (uint256)
  {
    // Get the active Merkle root.
    bytes32 merkleRoot = _ACTIVE_ROOT_.merkleRoot;

    // Verify the Merkle proof.
    bytes32 node = keccak256(abi.encodePacked(user, cumulativeAmount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MD1Claims: Invalid Merkle proof');

    // Get the claimable amount.
    //
    // Note: If this reverts, then there was an error in the Merkle tree, since the cumulative
    // amount for a given user should never decrease over time.
    uint256 claimable = cumulativeAmount.sub(_CLAIMED_[user]);

    if (claimable == 0) {
      return 0;
    }

    // Mark the user as having claimed the full amount.
    _CLAIMED_[user] = cumulativeAmount;

    // Send the user the claimable amount.
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, user, claimable);

    emit RewardsClaimed(user, claimable);

    return claimable;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MerkleProof } from '../../../dependencies/open-zeppelin/MerkleProof.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Pausable } from './MD1Pausable.sol';

/**
 * @title MD1RootUpdates
 * @author dYdX
 *
 * @notice Handles updates to the Merkle root.
 */
abstract contract MD1RootUpdates is
  MD1Pausable
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The waiting period before a proposed Merkle root can become active, in seconds.
  uint256 public constant WAITING_PERIOD = 7 days;

  // ============ Events ============

  /// @notice Emitted when a new Merkle root is proposed and the waiting period begins.
  event RootProposed(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid,
    uint256 waitingPeriodEnd
  );

  /// @notice Emitted when a new Merkle root becomes active.
  event RootUpdated(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid
  );

  // ============ External Functions ============

  /**
   * @notice Set the proposed root parameters to the values returned by the oracle, and start the
   *  waiting period. Anyone may call this function.
   *
   *  Reverts if the oracle root is bytes32(0).
   *  Reverts if the oracle root parameters are equal to the proposed root parameters.
   *  Reverts if the oracle root epoch is not equal to the next root epoch.
   */
  function proposeRoot()
    external
    nonReentrant
  {
    // Read the latest values from the oracle.
    (
      bytes32 merkleRoot,
      uint256 epoch,
      bytes memory ipfsCid
    ) = _REWARDS_ORACLE_.read();

    require(merkleRoot != bytes32(0), 'MD1RootUpdates: Oracle root is zero (unset)');
    require(
      (
        merkleRoot != _PROPOSED_ROOT_.merkleRoot ||
        epoch != _PROPOSED_ROOT_.epoch ||
        keccak256(ipfsCid) != keccak256(_PROPOSED_ROOT_.ipfsCid)
      ),
      'MD1RootUpdates: Oracle root was already proposed'
    );
    require(epoch == getNextRootEpoch(), 'MD1RootUpdates: Oracle epoch is not next root epoch');

    // Set the proposed root and the waiting period for the proposed root to become active.
    _PROPOSED_ROOT_ = MD1Types.MerkleRoot({
      merkleRoot: merkleRoot,
      epoch: epoch,
      ipfsCid: ipfsCid
    });
    uint256 waitingPeriodEnd = block.timestamp.add(WAITING_PERIOD);
    _WAITING_PERIOD_END_ = waitingPeriodEnd;

    emit RootProposed(merkleRoot, epoch, ipfsCid, waitingPeriodEnd);
  }

  /**
   * @notice Set the active root parameters to the proposed root parameters.
   *
   *  Reverts if root updates are paused.
   *  Reverts if the proposed root is bytes32(0).
   *  Reverts if the proposed root epoch is not equal to the next root epoch.
   *  Reverts if the waiting period for the proposed root has not elapsed.
   */
  function updateRoot()
    external
    nonReentrant
    whenNotPaused
  {
    // Get the proposed root parameters.
    bytes32 merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    uint256 epoch = _PROPOSED_ROOT_.epoch;
    bytes memory ipfsCid = _PROPOSED_ROOT_.ipfsCid;

    require(merkleRoot != bytes32(0), 'MD1RootUpdates: Proposed root is zero (unset)');
    require(epoch == getNextRootEpoch(), 'MD1RootUpdates: Proposed epoch is not next root epoch');
    require(
      block.timestamp >= _WAITING_PERIOD_END_,
      'MD1RootUpdates: Waiting period has not elapsed'
    );

    // Set the active root.
    _ACTIVE_ROOT_.merkleRoot = merkleRoot;
    _ACTIVE_ROOT_.epoch = epoch;
    _ACTIVE_ROOT_.ipfsCid = ipfsCid;

    emit RootUpdated(merkleRoot, epoch, ipfsCid);
  }

  /**
   * @notice Returns true if there is a proposed root waiting to become active, the waiting period
   *  for that root has elapsed, and root updates are not paused.
   *
   * @return Boolean `true` if the active root can be updated to the proposed root, else `false`.
   */
  function canUpdateRoot()
    external
    view
    returns (bool)
  {
    return (
      hasPendingRoot() &&
      block.timestamp >= _WAITING_PERIOD_END_ &&
      !_ARE_ROOT_UPDATES_PAUSED_
    );
  }

  // ============ Public Functions ============

  /**
   * @notice Returns true if there is a proposed root waiting to become active. This is the case if
   *  and only if the proposed root is not zero and the proposed root epoch is equal to the next
   *  root epoch.
   */
  function hasPendingRoot()
    public
    view
    returns (bool)
  {
    // Get the proposed parameters.
    bytes32 merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    uint256 epoch = _PROPOSED_ROOT_.epoch;

    if (merkleRoot == bytes32(0)) {
      return false;
    }
    return epoch == getNextRootEpoch();
  }

  /**
   * @notice Get the next root epoch. If the active root is zero, then the next root epoch is zero,
   *  otherwise, it is equal to the active root epoch plus one.
   */
  function getNextRootEpoch()
    public
    view
    returns (uint256)
  {
    bytes32 merkleRoot = _ACTIVE_ROOT_.merkleRoot;

    if (merkleRoot == bytes32(0)) {
      return 0;
    }

    return _ACTIVE_ROOT_.epoch.add(1);
  }
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1EpochSchedule } from './MD1EpochSchedule.sol';
import { MD1Roles } from './MD1Roles.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1Configuration
 * @author dYdX
 *
 * @notice Functions for modifying the Merkle distributor rewards configuration.
 *
 *  The more sensitive configuration values, which potentially give full control over the contents
 *  of the Merkle tree, may only be updated by the OWNER_ROLE. Other values may be configured by
 *  the CONFIG_UPDATER_ROLE.
 *
 *  Note that these configuration values are made available externally but are not used internally
 *  within this contract, with the exception of the IPFS update period which is used by
 *  the getIpfsEpoch() function.
 */
abstract contract MD1Configuration is
  MD1EpochSchedule,
  MD1Roles
{
  // ============ Constants ============

  uint256 public constant TRADER_SCORE_ALPHA_BASE = 10 ** 18;

  // ============ Events ============

  event RewardsOracleChanged(
    address rewardsOracle
  );

  event IpnsNameUpdated(
    string ipnsName
  );

  event IpfsUpdatePeriodUpdated(
    uint256 ipfsUpdatePeriod
  );

  event RewardsParametersUpdated(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  );

  // ============ Initializer ============

  function __MD1Configuration_init(
    address rewardsOracle,
    string calldata ipnsName,
    uint256 ipfsUpdatePeriod,
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    internal
  {
    _setRewardsOracle(rewardsOracle);
    _setIpnsName(ipnsName);
    _setIpfsUpdatePeriod(ipfsUpdatePeriod);
    _setRewardsParameters(
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
  }

  // ============ External Functions ============

  /**
   * @notice Set the address of the oracle which provides Merkle root updates.
   *
   * @param  rewardsOracle  The new oracle address.
   */
  function setRewardsOracle(
    address rewardsOracle
  )
    external
    onlyRole(OWNER_ROLE)
    nonReentrant
  {
    _setRewardsOracle(rewardsOracle);
  }

  /**
   * @notice Set the IPNS name to which trader and market maker exchange statistics are published.
   *
   * @param  ipnsName  The new IPNS name.
   */
  function setIpnsName(
    string calldata ipnsName
  )
    external
    onlyRole(OWNER_ROLE)
    nonReentrant
  {
    _setIpnsName(ipnsName);
  }

  /**
   * @notice Set the period of time after the epoch end after which the new epoch exchange
   *  statistics should be available on IPFS via the IPNS name.
   *
   *  This can be used as a trigger for “keepers” who are incentivized to call the proposeRoot()
   *  and updateRoot() functions as needed.
   *
   * @param  ipfsUpdatePeriod  The new IPFS update period, in seconds.
   */
  function setIpfsUpdatePeriod(
    uint256 ipfsUpdatePeriod
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setIpfsUpdatePeriod(ipfsUpdatePeriod);
  }

  /**
   * @notice Set the rewards formula parameters.
   *
   * @param  marketMakerRewardsAmount  Max rewards distributed per epoch as market maker incentives.
   * @param  traderRewardsAmount       Max rewards distributed per epoch as trader incentives.
   * @param  traderScoreAlpha          The alpha parameter between 0 and 1, in units out of 10^18.
   */
  function setRewardsParameters(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setRewardsParameters(marketMakerRewardsAmount, traderRewardsAmount, traderScoreAlpha);
  }

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   * @param  interval  The length of an epoch, in seconds.
   * @param  offset    The start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(CONFIG_UPDATER_ROLE)
    nonReentrant
  {
    _setEpochParameters(interval, offset);
  }

  // ============ Internal Functions ============

  function _setRewardsOracle(
    address rewardsOracle
  )
    internal
  {
    _REWARDS_ORACLE_ = IRewardsOracle(rewardsOracle);
    emit RewardsOracleChanged(rewardsOracle);
  }

  function _setIpnsName(
    string calldata ipnsName
  )
    internal
  {
    _IPNS_NAME_ = ipnsName;
    emit IpnsNameUpdated(ipnsName);
  }

  function _setIpfsUpdatePeriod(
    uint256 ipfsUpdatePeriod
  )
    internal
  {
    _IPFS_UPDATE_PERIOD_ = ipfsUpdatePeriod;
    emit IpfsUpdatePeriodUpdated(ipfsUpdatePeriod);
  }

  function _setRewardsParameters(
    uint256 marketMakerRewardsAmount,
    uint256 traderRewardsAmount,
    uint256 traderScoreAlpha
  )
    internal
  {
    require(
      traderScoreAlpha <= TRADER_SCORE_ALPHA_BASE,
      'MD1Configuration: Invalid traderScoreAlpha'
    );

    _MARKET_MAKER_REWARDS_AMOUNT_ = marketMakerRewardsAmount;
    _TRADER_REWARDS_AMOUNT_ = traderRewardsAmount;
    _TRADER_SCORE_ALPHA_ = traderScoreAlpha;

    emit RewardsParametersUpdated(
      marketMakerRewardsAmount,
      traderRewardsAmount,
      traderScoreAlpha
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1Getters
 * @author dYdX
 *
 * @notice Simple getter functions.
 */
abstract contract MD1Getters is
  MD1Storage
{
  /**
   * @notice Get the address of the oracle which provides Merkle root updates.
   *
   * @return The address of the oracle.
   */
  function getRewardsOracle()
    external
    view
    returns (IRewardsOracle)
  {
    return _REWARDS_ORACLE_;
  }

  /**
   * @notice Get the IPNS name to which trader and market maker exchange statistics are published.
   *
   * @return The IPNS name.
   */
  function getIpnsName()
    external
    view
    returns (string memory)
  {
    return _IPNS_NAME_;
  }

  /**
   * @notice Get the period of time after the epoch end after which the new epoch exchange
   *  statistics should be available on IPFS via the IPNS name.
   *
   * @return The IPFS update period, in seconds.
   */
  function getIpfsUpdatePeriod()
    external
    view
    returns (uint256)
  {
    return _IPFS_UPDATE_PERIOD_;
  }

  /**
   * @notice Get the rewards formula parameters.
   *
   * @return Max rewards distributed per epoch as market maker incentives.
   * @return Max rewards distributed per epoch as trader incentives.
   * @return The alpha parameter between 0 and 1, in units out of 10^18.
   */
  function getRewardsParameters()
    external
    view
    returns (uint256, uint256, uint256)
  {
    return (
      _MARKET_MAKER_REWARDS_AMOUNT_,
      _TRADER_REWARDS_AMOUNT_,
      _TRADER_SCORE_ALPHA_
    );
  }

  /**
   * @notice Get the parameters specifying the function from timestamp to epoch number.
   *
   * @return The parameters struct with `interval` and `offset` fields.
   */
  function getEpochParameters()
    external
    view
    returns (MD1Types.EpochParameters memory)
  {
    return _EPOCH_PARAMETERS_;
  }

  /**
   * @notice Get the active Merkle root and associated parameters.
   *
   * @return  merkleRoot  The active Merkle root.
   * @return  epoch       The epoch number corresponding to this Merkle tree.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function getActiveRoot()
    external
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _ACTIVE_ROOT_.merkleRoot;
    epoch = _ACTIVE_ROOT_.epoch;
    ipfsCid = _ACTIVE_ROOT_.ipfsCid;
  }

  /**
   * @notice Get the proposed Merkle root and associated parameters.
   *
   * @return  merkleRoot  The active Merkle root.
   * @return  epoch       The epoch number corresponding to this Merkle tree.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function getProposedRoot()
    external
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _PROPOSED_ROOT_.merkleRoot;
    epoch = _PROPOSED_ROOT_.epoch;
    ipfsCid = _PROPOSED_ROOT_.ipfsCid;
  }

  /**
   * @notice Get the time at which the proposed root may become active.
   *
   * @return The time at which the proposed root may become active, in epoch seconds.
   */
  function getWaitingPeriodEnd()
    external
    view
    returns (uint256)
  {
    return _WAITING_PERIOD_END_;
  }

  /**
   * @notice Check whether root updates are currently paused.
   *
   * @return Boolean `true` if root updates are currently paused, otherwise, `false`.
   */
  function getAreRootUpdatesPaused()
    external
    view
    returns (bool)
  {
    return _ARE_ROOT_UPDATES_PAUSED_;
  }

  /**
   * @notice Get the tokens claimed so far by a given user.
   *
   * @param  user  The address of the user.
   *
   * @return The tokens claimed so far by that user.
   */
  function getClaimed(address user)
    external
    view
    returns (uint256)
  {
    return _CLAIMED_[user];
  }

  /**
   * @notice Check whether the user opted into allowing anyone to trigger a claim on their behalf.
   *
   * @param  user  The address of the user.
   *
   * @return Boolean `true` if any address may trigger claims for the user, otherwise `false`.
   */
  function getAlwaysAllowClaimsFor(address user)
    external
    view
    returns (bool)
  {
    return _ALWAYS_ALLOW_CLAIMS_FOR_[user];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library MD1Types {

  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev The parameters related to a certain version of the Merkle root.
   */
  struct MerkleRoot {
    bytes32 merkleRoot;
    uint256 epoch;
    bytes ipfsCid;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1Roles
 * @author dYdX
 *
 * @notice Defines roles used in the MerkleDistributorV1 contract. The hierarchy of roles and
 *  powers of each role are described below.
 *
 *  Roles:
 *
 *    OWNER_ROLE
 *      | -> May add or remove addresses from any of the below roles it manages.
 *      | -> May update the rewards oracle address.
 *      | -> May update the IPNS name.
 *      |
 *      +-- CONFIG_UPDATER_ROLE
 *      |     -> May update parameters affecting the formulae used to calculate rewards.
 *      |     -> May update the epoch schedule.
 *      |     -> May update the IPFS update period.
 *      |
 *      +-- PAUSER_ROLE
 *      |     -> May pause updates to the Merkle root.
 *      |
 *      +-- UNPAUSER_ROLE
 *      |     -> May unpause updates to the Merkle root.
 *      |
 *      +-- CLAIM_OPERATOR_ROLE
 *            -> May trigger a claim on behalf of a user (but the recipient is always the user).
 */
abstract contract MD1Roles is
  MD1Storage
{
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant CONFIG_UPDATER_ROLE = keccak256('CONFIG_UPDATER_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant UNPAUSER_ROLE = keccak256('UNPAUSER_ROLE');
  bytes32 public constant CLAIM_OPERATOR_ROLE = keccak256('CLAIM_OPERATOR_ROLE');

  function __MD1Roles_init()
    internal
  {
    // Assign the OWNER_ROLE to the sender.
    _setupRole(OWNER_ROLE, msg.sender);

    // Set OWNER_ROLE as the admin of all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(CONFIG_UPDATER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(UNPAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(CLAIM_OPERATOR_ROLE, OWNER_ROLE);
  }
}

pragma solidity 0.7.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {
  AccessControlUpgradeable
} from '../../../dependencies/open-zeppelin/AccessControlUpgradeable.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { ReentrancyGuard } from '../../../utils/ReentrancyGuard.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1Storage
 * @author dYdX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract MD1Storage is
  AccessControlUpgradeable,
  ReentrancyGuard,
  VersionedInitializable
{
  // ============ Configuration ============

  /// @dev The oracle which provides Merkle root updates.
  IRewardsOracle internal _REWARDS_ORACLE_;

  /// @dev The IPNS name to which trader and market maker exchange statistics are published.
  string internal _IPNS_NAME_;

  /// @dev Period of time after the epoch end after which the new epoch exchange statistics should
  ///  be available on IPFS via the IPNS name. This can be used as a trigger for “keepers” who are
  ///  incentivized to call the proposeRoot() and updateRoot() functions as needed.
  uint256 internal _IPFS_UPDATE_PERIOD_;

  /// @dev Max rewards distributed per epoch as market maker incentives.
  uint256 internal _MARKET_MAKER_REWARDS_AMOUNT_;

  /// @dev Max rewards distributed per epoch as trader incentives.
  uint256 internal _TRADER_REWARDS_AMOUNT_;

  /// @dev Parameter affecting the calculation of trader rewards. This is a value
  ///  between 0 and 1, represented here in units out of 10^18.
  uint256 internal _TRADER_SCORE_ALPHA_;

  // ============ Epoch Schedule ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  MD1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  // ============ Root Updates ============

  /// @dev The active Merkle root and associated parameters.
  MD1Types.MerkleRoot internal _ACTIVE_ROOT_;

  /// @dev The proposed Merkle root and associated parameters.
  MD1Types.MerkleRoot internal _PROPOSED_ROOT_;

  /// @dev The time at which the proposed root may become active.
  uint256 internal _WAITING_PERIOD_END_;

  /// @dev Whether root updates are currently paused.
  bool internal _ARE_ROOT_UPDATES_PAUSED_;

  // ============ Claims ============

  /// @dev Mapping of (user address) => (number of tokens claimed).
  mapping(address => uint256) internal _CLAIMED_;

  /// @dev Whether the user has opted into allowing anyone to trigger a claim on their behalf.
  mapping(address => bool) internal _ALWAYS_ALLOW_CLAIMS_FOR_;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import './Context.sol';
import './Strings.sol';
import './ERC165.sol';

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Context, IAccessControlUpgradeable, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role, _msgSender());
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControlUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
   */
  function _checkRole(bytes32 role, address account) internal view {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            'AccessControl: account ',
            Strings.toHexString(uint160(account), 20),
            ' is missing role ',
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title ReentrancyGuard
 * @author dYdX
 *
 * @dev Updated ReentrancyGuard library designed to be used with Proxy Contracts.
 */
abstract contract ReentrancyGuard {
  uint256 private constant NOT_ENTERED = 1;
  uint256 private constant ENTERED = uint256(int256(-1));

  uint256 private _STATUS_;

  constructor() internal {
    _STATUS_ = NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_STATUS_ != ENTERED, 'ReentrancyGuard: reentrant call');
    _STATUS_ = ENTERED;
    _;
    _STATUS_ = NOT_ENTERED;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author dYdX, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { MD1Roles } from './MD1Roles.sol';

/**
 * @title MD1Pausable
 * @author dYdX
 *
 * @notice Allows authorized addresses to pause updates to the Merkle root.
 *
 *  For the Merkle root to be updated, the root must first be set on the oracle contract, then
 *  proposed on this contract, at which point the waiting period begins. During the waiting period,
 *  the root should be verified, and updates should be paused by the PAUSER_ROLE if the root is
 *  found to be incorrect.
 */
abstract contract MD1Pausable is
  MD1Roles
{
  // ============ Events ============

  /// @notice Emitted when root updates are paused.
  event RootUpdatesPaused();

  /// @notice Emitted when root updates are unpaused.
  event RootUpdatesUnpaused();

  // ============ Modifiers ============

  /**
   * @dev Enforce that a function may be called only while root updates are not paused.
   */
  modifier whenNotPaused() {
    require(!_ARE_ROOT_UPDATES_PAUSED_, 'MD1Pausable: Updates paused');
    _;
  }

  /**
   * @dev Enforce that a function may be called only while root updates are paused.
   */
  modifier whenPaused() {
    require(_ARE_ROOT_UPDATES_PAUSED_, 'MD1Pausable: Updates not paused');
    _;
  }

  // ============ External Functions ============

  /**
   * @dev Called by PAUSER_ROLE to prevent proposed Merkle roots from becoming active.
   */
  function pauseRootUpdates()
    onlyRole(PAUSER_ROLE)
    whenNotPaused
    nonReentrant
    external
  {
    _ARE_ROOT_UPDATES_PAUSED_ = true;
    emit RootUpdatesPaused();
  }

  /**
   * @dev Called by UNPAUSER_ROLE to resume allowing proposed Merkle roots to become active.
   */
  function unpauseRootUpdates()
    onlyRole(UNPAUSER_ROLE)
    whenPaused
    nonReentrant
    external
  {
    _ARE_ROOT_UPDATES_PAUSED_ = false;
    emit RootUpdatesUnpaused();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { MD1Types } from '../lib/MD1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { MD1Storage } from './MD1Storage.sol';

/**
 * @title MD1EpochSchedule
 * @author dYdX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  Note that the current and IPFS epoch numbers are made available externally but are not used
 *  internally within this contract.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 */
abstract contract MD1EpochSchedule is
  MD1Storage
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Events ============

  event EpochScheduleUpdated(
    MD1Types.EpochParameters epochParameters
  );

  // ============ Initializer ============

  function __MD1EpochSchedule_init(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    _setEpochParameters(interval, offset);
  }

  // ============ External Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    external
    view
    returns (uint256)
  {
    return _getEpochAtTimestamp(
      block.timestamp,
      'MD1EpochSchedule: Epoch zero has not started'
    );
  }

  /**
   * @notice Get the latest epoch number for which we expect to have data available on IPFS.
   *  This is equal to the current epoch number, delayed by the IPFS update period.
   *
   *  Reverts if epoch zero did not begin at least `_IPFS_UPDATE_PERIOD_` seconds ago.
   *
   * @return The latest epoch number for which we expect to have data available on IPFS.
   */
  function getIpfsEpoch()
    external
    view
    returns (uint256)
  {
    return _getEpochAtTimestamp(
      block.timestamp.sub(_IPFS_UPDATE_PERIOD_),
      'MD1EpochSchedule: IPFS epoch zero has not started'
    );
  }

  // ============ Internal Functions ============

  function _getEpochAtTimestamp(
    uint256 timestamp,
    string memory revertReason
  )
    internal
    view
    returns (uint256)
  {
    MD1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;

    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(timestamp >= offset, revertReason);

    return timestamp.sub(offset).div(interval);
  }

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    require(interval != 0, 'MD1EpochSchedule: Interval cannot be zero');

    MD1Types.EpochParameters memory epochParameters = MD1Types.EpochParameters({
      interval: interval.toUint128(),
      offset: offset.toUint128()
    });

    _EPOCH_PARAMETERS_ = epochParameters;

    emit EpochScheduleUpdated(epochParameters);
  }
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @dev Methods for downcasting unsigned integers, reverting on overflow.
 */
library SafeCast {

  /**
   * @dev Downcast to a uint128, reverting on overflow.
   */
  function toUint128(uint256 a) internal pure returns (uint128) {
    uint128 b = uint128(a);
    require(uint256(b) == a, 'SafeCast: toUint128 overflow');
    return b;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {
  ChainlinkClient,
  Chainlink
} from '@chainlink/contracts/src/v0.7/ChainlinkClient.sol';

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IMerkleDistributorV1 } from '../../../interfaces/IMerkleDistributorV1.sol';
import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1ChainlinkAdapter
 * @author dYdX
 *
 * @notice Chainlink oracle adapter to be read by the MerkleDistributorV1 contract.
 */
contract MD1ChainlinkAdapter is
  ChainlinkClient,
  IRewardsOracle
{
  using Chainlink for Chainlink.Request;
  using SafeERC20 for IERC20;

  // ============ Events ============

  /// @notice Emitted when the oracle data is updated.
  event OracleRootUpdated(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid
  );

  // ============ Constants ============

  /// @notice Address of the LINK token, used to pay for requests for oracle data.
  IERC20 public immutable CHAINLINK_TOKEN;

  /// @notice The address of the Merkle distributor contract, which determines rewards parameters.
  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;

  /// @notice The address to which the Chainlink request is sent.
  address public immutable ORACLE_CONTRACT;

  /// @notice The address which will call writeOracleData().
  address public immutable ORACLE_EXTERNAL_ADAPTER;

  /// @notice Chainlink ID for the job.
  bytes32 public immutable JOB_ID;

  // ============ Storage ============

  /// @dev Mapping from Chainlink request ID to the address that initated the request.
  mapping(bytes32 => address) internal _OPEN_REQUESTS_;

  /// @dev The latest oracle data.
  MD1Types.MerkleRoot internal _ORACLE_ROOT_;

  // ============ Constructor ============

  constructor(
    address chainlinkToken,
    address merkleDistributor,
    address oracleContract,
    address oracleExternalAdapter,
    bytes32 jobId
  ) {
    setChainlinkToken(chainlinkToken);
    CHAINLINK_TOKEN = IERC20(chainlinkToken);
    MERKLE_DISTRIBUTOR = IMerkleDistributorV1(merkleDistributor);
    ORACLE_CONTRACT = oracleContract;
    ORACLE_EXTERNAL_ADAPTER = oracleExternalAdapter;
    JOB_ID = jobId;
  }

  // ============ External Functions ============

  /**
   * @notice Helper function which transfers the fee and makes a request in a single transaction.
   *
   * @param  fee  The LINK amount to pay for the request.
   */
  function transferAndRequestOracleData(
    uint256 fee
  )
    external
  {
    CHAINLINK_TOKEN.safeTransferFrom(msg.sender, address(this), fee);
    requestOracleData(fee);
  }

  /**
   * @notice Called by the oracle external adapter to write data in response to a request.
   *
   *  This should be called before fulfillRequest() is called.
   *
   * @param  merkleRoot  Root hash of the Merkle tree for this epoch's rewards distribution.
   * @param  epoch       The epoch number for this rewards distribution.
   * @param  ipfsCid     The IPFS CID with the full Merkle tree data.
   */
  function writeOracleData(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes calldata ipfsCid
  )
    external
  {
    require(
      msg.sender == ORACLE_EXTERNAL_ADAPTER,
      'MD1ChainlinkAdapter: Sender must be the oracle external adapter'
    );

    _ORACLE_ROOT_ = MD1Types.MerkleRoot({
      merkleRoot: merkleRoot,
      epoch: epoch,
      ipfsCid: ipfsCid
    });

    emit OracleRootUpdated(merkleRoot, epoch, ipfsCid);
  }

  /**
   * @notice Callback function for the oracle to record fulfillment of a request.
   */
  function fulfillRequest(
    bytes32 requestId
  )
    external
    recordChainlinkFulfillment(requestId)
  {
    delete _OPEN_REQUESTS_[requestId];
  }

  /**
   * @notice Allow the initiator of a request to cancel that request. The request must have expired.
   *
   *  The LINK fee for the request will be refunded back to this contract.
   */
  function cancelRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    external
  {
    require(
      msg.sender == _OPEN_REQUESTS_[requestId],
      'Request is not open or sender was not the initiator'
    );
    cancelChainlinkRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Read the latest data written by the oracle. This will be called by MerkleDistributorV1.
   *
   * @return  merkleRoot  The Merkle root for the next Merkle distributor update.
   * @return  epoch       The epoch number corresponding to the new Merkle root.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function read()
    external
    override
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _ORACLE_ROOT_.merkleRoot;
    epoch = _ORACLE_ROOT_.epoch;
    ipfsCid = _ORACLE_ROOT_.ipfsCid;
  }

  /**
   * @notice If a request with the specified ID is open, returns the address that initiated it.
   *
   * @param  requestId  The Chainlink request ID.
   *
   * @return The address that initiated request, or the zero address if the request is not open.
   */
  function getOpenRequest(
    bytes32 requestId
  )
    external
    view
    returns (address)
  {
    return _OPEN_REQUESTS_[requestId];
  }

  // ============ Public Functions ============

  /**
   * @notice Request the latest oracle data.
   *
   *  In response to this request, if sufficient fee is provided, the Chainlink node is expected to
   *  call the writeOracleData() function, followed by the fulfillRequest() function.
   *
   *  Reverts if this contract does not have LINK to pay the fee.
   *
   *  If the fee is less than the amount agreed to by the external (off-chain) oracle adapter, then
   *  the external adapter may ignore the request.
   *
   * @param  fee  The LINK amount to pay for the request.
   */
  function requestOracleData(
    uint256 fee
  )
    public
  {
    // Read parameters from the Merkle distributor contract.
    string memory ipnsName = MERKLE_DISTRIBUTOR.getIpnsName();
    (
      uint256 marketMakerRewardsAmount,
      uint256 traderRewardsAmount,
      uint256 traderScoreAlpha
    ) = MERKLE_DISTRIBUTOR.getRewardsParameters();
    (, , bytes memory activeRootIpfsCid) = MERKLE_DISTRIBUTOR.getActiveRoot();
    uint256 newEpoch = MERKLE_DISTRIBUTOR.getNextRootEpoch();

    // Build the Chainlink request.
    Chainlink.Request memory req = buildChainlinkRequest(
      JOB_ID,
      address(this),
      this.fulfillRequest.selector
    );
    req.addBytes('callbackAddress', abi.encodePacked(address(this)));
    req.add('ipnsName', ipnsName);
    req.addUint('marketMakerRewardsAmount', marketMakerRewardsAmount);
    req.addUint('traderRewardsAmount', traderRewardsAmount);
    req.addUint('traderScoreAlpha', traderScoreAlpha);
    req.addBytes('activeRootIpfsCid', activeRootIpfsCid);
    req.addUint('newEpoch', newEpoch);

    // Send the Chainlink request.
    //
    // Note: This emits ChainlinkRequested(bytes32 indexed id);
    bytes32 requestId = sendChainlinkRequestTo(ORACLE_CONTRACT, req, fee);

    // Store the address that initiated the request. This address may cancel the request.
    _OPEN_REQUESTS_[requestId] = msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK_DIVISIBILITY = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ORACLE_ARGS_VERSION = 1;
  uint256 constant private OPERATOR_ARGS_VERSION = 2;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  OperatorInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(
    bytes32 indexed id
  );
  event ChainlinkFulfilled(
    bytes32 indexed id
  );
  event ChainlinkCancelled(
    bytes32 indexed id
  );

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddress The callback address that the response will be sent to
   * @param callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionSignature
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddress, callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return sendChainlinkRequestTo(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, ORACLE_ARGS_VERSION, oracle.oracleRequest.selector);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `requestOracleDataFrom` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleData(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return requestOracleDataFrom(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleDataFrom(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, OPERATOR_ARGS_VERSION, oracle.requestOracleData.selector);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @param argsVersion The version of data support (single word, multi word)
   * @return requestId The request ID
   */
  function rawRequest(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment,
    uint256 argsVersion,
    bytes4 funcSelector
  )
    private
    returns (
      bytes32 requestId
    )
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    req.nonce = requestCount;
    pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    bytes memory encodedData = abi.encodeWithSelector(
      funcSelector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress,
      req.callbackFunctionId,
      req.nonce,
      argsVersion,
      req.buf.buf);
    require(link.transferAndCall(oracleAddress, payment, encodedData), "unable to transferAndCall to oracle");
    requestCount += 1;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    internal
  {
    OperatorInterface requested = OperatorInterface(pendingRequests[requestId]);
    delete pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(
    address oracleAddress
  )
    internal
  {
    oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(
    address linkAddress
  )
    internal
  {
    link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() 
    internal
  {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(
    address oracleAddress,
    bytes32 requestId
  )
    internal
    notPendingRequest(requestId)
  {
    pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(
    address ensAddress,
    bytes32 node
  )
    internal
  {
    ens = ENSInterface(ensAddress);
    ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(
    bytes32 requestId
  )
    internal
    recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(
    bytes32 requestId
  )
  {
    require(msg.sender == pendingRequests[requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(
    bytes32 requestId
  )
  {
    require(pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title IMerkleDistributorV1
 * @author dYdX
 *
 * @notice Partial interface for the MerkleDistributorV1 contract.
 */
interface IMerkleDistributorV1 {

  function getIpnsName()
    external
    virtual
    view
    returns (string memory);

  function getRewardsParameters()
    external
    virtual
    view
    returns (uint256, uint256, uint256);

  function getActiveRoot()
    external
    virtual
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid);

  function getNextRootEpoch()
    external
    virtual
    view
    returns (uint256);

  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { CBORChainlink } from "./vendor/CBORChainlink.sol";
import { BufferChainlink } from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(
    Request memory self,
    bytes memory data
  )
    internal
    pure
  {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(
    bytes32 indexed node,
    address owner
  );

  // Logged when the resolver for a node changes.
  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  // Logged when the TTL of a node changes
  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );


  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(
    bytes32 node,
    address resolver
  ) external;

  function setOwner(
    bytes32 node,
    address owner
  ) external;

  function setTTL(
    bytes32 node,
    uint64 ttl
  ) external;

  function owner(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function resolver(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function ttl(
    bytes32 node
  )
    external
    view
    returns (
      uint64
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ChainlinkRequestInterface.sol";
import "./OracleInterface.sol";

interface OperatorInterface is
  ChainlinkRequestInterface,
  OracleInterface
{

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface PointerInterface {
  
  function getAddress()
    external
    view
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ENSResolver {
  function addr(
    bytes32 node
  )
    public
    view
    virtual
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.19;

import { BufferChainlink } from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeType(
    BufferChainlink.buffer memory buf,
    uint8 major,
    uint value
  )
    private
    pure
  {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(
    BufferChainlink.buffer memory buf,
    uint8 major
  )
    private
    pure
  {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(
    BufferChainlink.buffer memory buf,
    uint value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(
    BufferChainlink.buffer memory buf,
    bytes memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeBigNum(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(value)));
  }

  function encodeSignedBigNum(
    BufferChainlink.buffer memory buf,
    int input
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(-1 - input)));
  }

  function encodeString(
    BufferChainlink.buffer memory buf,
    string memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(
    buffer memory buf,
    uint capacity
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(
    bytes memory b
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(
    buffer memory buf,
    uint capacity
  )
    private
    pure
  {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(
    uint a,
    uint b
  )
    private
    pure
    returns(
      uint
    )
  {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(
    buffer memory buf
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(
    buffer memory buf,
    uint off,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(
    buffer memory buf,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes32 data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(
    buffer memory buf,
    uint off,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(
    buffer memory buf,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(
    buffer memory buf,
    bytes32 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(
    buffer memory buf,
    uint off,
    uint data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(
    buffer memory buf,
    uint data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { IRewardsOracle } from '../interfaces/IRewardsOracle.sol';

contract MockRewardsOracle is IRewardsOracle {

  bytes32 _MERKLE_ROOT_;
  uint256 _EPOCH_;
  bytes _IPFS_CID_;

  function read()
    external
    override
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    return (_MERKLE_ROOT_, _EPOCH_, _IPFS_CID_);
  }

  function setMockValue(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes calldata ipfsCid
  )
    external
  {
    _MERKLE_ROOT_ = merkleRoot;
    _EPOCH_ = epoch;
    _IPFS_CID_ = ipfsCid;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { OwnableUpgradeable } from '../dependencies/open-zeppelin/OwnableUpgradeable.sol';
import { SafeERC20 } from '../dependencies/open-zeppelin/SafeERC20.sol';
import { VersionedInitializable } from '../utils/VersionedInitializable.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

/**
 * @title Treasury 
 * @notice Stores DYDX kept for incentives, just giving approval to the different
 * systems that will pull DYDX funds for their specific use case.
 * @author dYdX
 **/
contract Treasury is
OwnableUpgradeable,
VersionedInitializable
{
  using SafeERC20 for IERC20;

  uint256 public constant REVISION = 1;

  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize() external initializer {
    __Ownable_init();
  }

  function approve(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    // SafeERC20 safeApprove requires setting to zero first.
    IERC20(token).safeApprove(recipient, 0);
    IERC20(token).safeApprove(recipient, amount);
  }

  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).safeTransfer(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./Context.sol";

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
abstract contract OwnableUpgradeable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { SafeERC20 } from '../dependencies/open-zeppelin/SafeERC20.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

interface IMerkleDistributorV1 {
  function claimRewards(
    uint256 cumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256);
}

/**
 * @title  TreasuryMerkleClaimProxy
 * @author dYdX
 *
 * @notice Contract which claims DYDX rewards from the merkle distributor and immediately
 *         transfers the rewards to the community treasury.
 *
 *         This contract is meant to be used for transferring all unclaimed epoch zero retroactive
 *         mining rewards to the community treasury. 
 */
contract TreasuryMerkleClaimProxy {
  using SafeERC20 for IERC20;

  // ============ Constants ============

  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;
  /// @notice Address to send claimed merkle rewards to.
  address public immutable COMMUNITY_TREASURY;
  IERC20 public immutable REWARDS_TOKEN;

  // ============ Constructor ============

  constructor(IMerkleDistributorV1 merkleDistributor, address communityTreasury, IERC20 rewardsToken) {
    MERKLE_DISTRIBUTOR = merkleDistributor;
    COMMUNITY_TREASURY = communityTreasury;
    REWARDS_TOKEN = rewardsToken;
  }

  // ============ External Functions ============

  /**
   * @notice Claims rewards from merkle distributor and forwards them to the community treasury.
   *
   * @param  merkleCumulativeAmount   The cumulative rewards amount owned by this proxy on behalf of the treasury,
   *                                  in the MerkleDistributorV1 rewards tree.
   * @param  merkleProof              The Merkle proof to claim rewards for this proxy on behalf of the treasury.
   *
   * @return The total number of rewards claimed and transferred to the community treasury.
   */
  function claimRewards(
    uint256 merkleCumulativeAmount,
    bytes32[] calldata merkleProof
  )
    external
    returns (uint256)
  {
    uint256 claimedRewards = MERKLE_DISTRIBUTOR.claimRewards(merkleCumulativeAmount, merkleProof);

    REWARDS_TOKEN.safeTransfer(COMMUNITY_TREASURY, claimedRewards);

    return claimedRewards;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() virtual public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() virtual public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() virtual public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { ERC20 } from '../../dependencies/open-zeppelin/ERC20.sol';

/**
 * @title MintableErc20
 * @author dYdX
 *
 * @notice Test ERC20 token that allows anyone to mint.
 */
contract MintableErc20 is
  ERC20
{
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  )
    ERC20(name, symbol)
  {
    _setupDecimals(decimals);
  }

  /**
   * @notice Mint tokens to the specified account.
   *
   * @param  account  The account to receive minted tokens.
   * @param  value    The amount of tokens to mint.
   */
  function mint(
    address account,
    uint256 value
  )
    external
  {
    _mint(account, value);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import { MintableErc20 } from './MintableErc20.sol';

/**
 * @title MockChainlinkToken
 * @author dYdX
 *
 * @notice Mock Chainlink token.
 */
contract MockChainlinkToken is
  MintableErc20
{
  address public _CALLED_WITH_TO_;
  uint256 public _CALLED_WITH_VALUE_;
  bytes public _CALLED_WITH_DATA_;

  constructor()
    MintableErc20('Mock Chainlink Token', 'LINK', 18)
  {}

  function transferAndCall(
    address to,
    uint256 value,
    bytes memory data
  )
    external
    returns (bool success)
  {
    _CALLED_WITH_TO_ = to;
    _CALLED_WITH_VALUE_ = value;
    _CALLED_WITH_DATA_ = data;
    return true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { ERC20 } from '../../dependencies/open-zeppelin/ERC20.sol';
import { Ownable } from '../../dependencies/open-zeppelin/Ownable.sol';
import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import { GovernancePowerDelegationERC20Mixin } from './GovernancePowerDelegationERC20Mixin.sol';

/**
 * @title DydxToken
 * @author dYdX
 *
 * @notice The dYdX governance token.
 */
contract DydxToken is
  GovernancePowerDelegationERC20Mixin,
  Ownable
{
  using SafeMath for uint256;

  // ============ Events ============

  /**
   * @dev Emitted when an address has been added to or removed from the token transfer allowlist.
   *
   * @param  account    Address that was added to or removed from the token transfer allowlist.
   * @param  isAllowed  True if the address was added to the allowlist, false if removed.
   */
  event TransferAllowlistUpdated(address account, bool isAllowed);

  /**
   * @dev Emitted when the transfer restriction timestamp is reassigned.
   *
   * @param  transfersRestrictedBefore  The new timestamp on and after which non-allowlisted transfers may occur.
   */
  event TransfersRestrictedBeforeUpdated(uint256 transfersRestrictedBefore);

  // ============ Constants ============

  string internal constant NAME = 'dYdX';
  string internal constant SYMBOL = 'DYDX';

  uint256 public constant INITIAL_SUPPLY = 1_000_000_000 ether;

  bytes32 public immutable DOMAIN_SEPARATOR;
  bytes public constant EIP712_VERSION = '1';
  bytes32 public constant EIP712_DOMAIN = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
  );
  bytes32 public constant PERMIT_TYPEHASH = keccak256(
    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
  );

  /// @notice Minimum time between mints.
  uint256 public constant MINT_MIN_INTERVAL = 365 days;

  /// @notice Cap on the percentage of the total supply that can be minted at each mint.
  ///  Denominated in percentage points (units out of 100).
  uint256 public immutable MINT_MAX_PERCENT;

  /// @notice The timestamp on and after which the transfer restriction must be lifted.
  uint256 public immutable TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN;

  // ============ Storage ============

  /// @dev Mapping from (owner) => (next valid nonce) for EIP-712 signatures.
  mapping(address => uint256) internal _nonces;

  mapping(address => mapping(uint256 => Snapshot)) public _votingSnapshots;
  mapping(address => uint256) public _votingSnapshotsCounts;
  mapping(address => address) public _votingDelegates;

  mapping(address => mapping(uint256 => Snapshot)) public _propositionPowerSnapshots;
  mapping(address => uint256) public _propositionPowerSnapshotsCounts;
  mapping(address => address) public _propositionPowerDelegates;

  /// @notice Snapshots of the token total supply, at each block where the total supply has changed.
  mapping(uint256 => Snapshot) public _totalSupplySnapshots;

  /// @notice Number of snapshots of the token total supply.
  uint256 public _totalSupplySnapshotsCount;

  /// @notice Allowlist of addresses which may send or receive tokens while transfers are
  ///  otherwise restricted.
  mapping(address => bool) public _tokenTransferAllowlist;

  /// @notice The timestamp on and after which minting may occur.
  uint256 public _mintingRestrictedBefore;

  /// @notice The timestamp on and after which non-allowlisted transfers may occur.
  uint256 public _transfersRestrictedBefore;

  // ============ Constructor ============

  /**
   * @notice Constructor.
   *
   * @param  distributor                           The address which will receive the initial supply of tokens.
   * @param  transfersRestrictedBefore             Timestamp, before which transfers are restricted unless the
   *                                               origin or destination address is in the allowlist.
   * @param  transferRestrictionLiftedNoLaterThan  Timestamp, which is the maximum timestamp that transfer
   *                                               restrictions can be extended to.
   * @param  mintingRestrictedBefore               Timestamp, before which minting is not allowed.
   * @param  mintMaxPercent                        Cap on the percentage of the total supply that can be minted at
   *                                               each mint.
   */
  constructor(
    address distributor,
    uint256 transfersRestrictedBefore,
    uint256 transferRestrictionLiftedNoLaterThan,
    uint256 mintingRestrictedBefore,
    uint256 mintMaxPercent
  )
    ERC20(NAME, SYMBOL)
  {
    uint256 chainId;

    // solium-disable-next-line
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(NAME)),
        keccak256(bytes(EIP712_VERSION)),
        chainId,
        address(this)
      )
    );

    // Validate and set parameters.
    require(transfersRestrictedBefore > block.timestamp, 'TRANSFERS_RESTRICTED_BEFORE_TOO_EARLY');
    require(transfersRestrictedBefore <= transferRestrictionLiftedNoLaterThan, 'MAX_TRANSFER_RESTRICTION_TOO_EARLY');
    require(mintingRestrictedBefore > block.timestamp, 'MINTING_RESTRICTED_BEFORE_TOO_EARLY');
    _transfersRestrictedBefore = transfersRestrictedBefore;
    TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN = transferRestrictionLiftedNoLaterThan;
    _mintingRestrictedBefore = mintingRestrictedBefore;
    MINT_MAX_PERCENT = mintMaxPercent;

    // Mint the initial supply.
    _mint(distributor, INITIAL_SUPPLY);

    emit TransfersRestrictedBeforeUpdated(transfersRestrictedBefore);
  }

  // ============ Other Functions ============

  /**
   * @notice Adds addresses to the token transfer allowlist. Reverts if any of the addresses
   *  already exist in the allowlist. Only callable by owner.
   *
   * @param  addressesToAdd  Addresses to add to the token transfer allowlist.
   */
  function addToTokenTransferAllowlist(address[] calldata addressesToAdd)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addressesToAdd.length; i++) {
      require(
        !_tokenTransferAllowlist[addressesToAdd[i]],
        'ADDRESS_EXISTS_IN_TRANSFER_ALLOWLIST'
      );
      _tokenTransferAllowlist[addressesToAdd[i]] = true;
      emit TransferAllowlistUpdated(addressesToAdd[i], true);
    }
  }

  /**
   * @notice Removes addresses from the token transfer allowlist. Reverts if any of the addresses
   *  don't exist in the allowlist. Only callable by owner.
   *
   * @param  addressesToRemove  Addresses to remove from the token transfer allowlist.
   */
  function removeFromTokenTransferAllowlist(address[] calldata addressesToRemove)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addressesToRemove.length; i++) {
      require(
        _tokenTransferAllowlist[addressesToRemove[i]],
        'ADDRESS_DOES_NOT_EXIST_IN_TRANSFER_ALLOWLIST'
      );
      _tokenTransferAllowlist[addressesToRemove[i]] = false;
      emit TransferAllowlistUpdated(addressesToRemove[i], false);
    }
  }

  /**
   * @notice Updates the transfer restriction. Reverts if the transfer restriction has already passed,
   *  the new transfer restriction is earlier than the previous one, or the new transfer restriction is
   *  after the maximum transfer restriction.
   *
   * @param  transfersRestrictedBefore  The timestamp on and after which non-allowlisted transfers may occur.
   */
  function updateTransfersRestrictedBefore(uint256 transfersRestrictedBefore)
    external
    onlyOwner
  {
    uint256 previousTransfersRestrictedBefore = _transfersRestrictedBefore;
    require(block.timestamp < previousTransfersRestrictedBefore, 'TRANSFER_RESTRICTION_ENDED');
    require(previousTransfersRestrictedBefore <= transfersRestrictedBefore, 'NEW_TRANSFER_RESTRICTION_TOO_EARLY');
    require(transfersRestrictedBefore <= TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN, 'AFTER_MAX_TRANSFER_RESTRICTION');

    _transfersRestrictedBefore = transfersRestrictedBefore;

    emit TransfersRestrictedBeforeUpdated(transfersRestrictedBefore);
  }

  /**
   * @notice Mint new tokens. Only callable by owner after the required time period has elapsed.
   *
   * @param  recipient  The address to receive minted tokens.
   * @param  amount     The number of tokens to mint.
   */
  function mint(address recipient, uint256 amount)
    external
    onlyOwner
  {
    require(block.timestamp >= _mintingRestrictedBefore, 'MINT_TOO_EARLY');
    require(amount <= totalSupply().mul(MINT_MAX_PERCENT).div(100), 'MAX_MINT_EXCEEDED');

    // Update the next allowed minting time.
    _mintingRestrictedBefore = block.timestamp.add(MINT_MIN_INTERVAL);

    // Mint the amount.
    _mint(recipient, amount);
  }

  /**
   * @notice Implements the permit function as specified in EIP-2612.
   *
   * @param  owner     Address of the token owner.
   * @param  spender   Address of the spender.
   * @param  value     Amount of allowance.
   * @param  deadline  Expiration timestamp for the signature.
   * @param  v         Signature param.
   * @param  r         Signature param.
   * @param  s         Signature param.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    require(owner != address(0), 'INVALID_OWNER');
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  /**
   * @notice Get the next valid nonce for EIP-712 signatures.
   *
   *  This nonce should be used when signing for any of the following functions:
   *   - permit()
   *   - delegateByTypeBySig()
   *   - delegateBySig()
   */
  function nonces(address owner)
    external
    view
    returns (uint256)
  {
    return _nonces[owner];
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _requireTransferAllowed(_msgSender(), recipient);
    return super.transfer(recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _requireTransferAllowed(sender, recipient);
    return super.transferFrom(sender, recipient, amount);
  }

  /**
   * @dev Override _mint() to write a snapshot whenever the total supply changes.
   *
   *  These snapshots are intended to be used by the governance strategy.
   *
   *  Note that the ERC20 _burn() function is never used. If desired, an official burn mechanism
   *  could be implemented external to this contract, and accounted for in the governance strategy.
   */
  function _mint(address account, uint256 amount)
    internal
    override
  {
    super._mint(account, amount);

    uint256 snapshotsCount = _totalSupplySnapshotsCount;
    uint128 currentBlock = uint128(block.number);
    uint128 newValue = uint128(totalSupply());

    // Note: There is no special case for the total supply being updated multiple times in the same
    // block. That should never occur.
    _totalSupplySnapshots[snapshotsCount] = Snapshot(currentBlock, newValue);
    _totalSupplySnapshotsCount = snapshotsCount.add(1);
  }

  function _requireTransferAllowed(address sender, address recipient)
    view
    internal
  {
    // Compare against the constant `TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN` first
    // to avoid additional gas costs from reading from storage.
    if (
      block.timestamp < TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN &&
      block.timestamp < _transfersRestrictedBefore
    ) {
      // While transfers are restricted, a transfer is permitted if either the sender or the
      // recipient is on the allowlist.
      require(
        _tokenTransferAllowlist[sender] || _tokenTransferAllowlist[recipient],
        'NON_ALLOWLIST_TRANSFERS_DISABLED'
      );
    }
  }

  /**
   * @dev Writes a snapshot before any transfer operation, including: _transfer, _mint and _burn.
   *  - On _transfer, it writes snapshots for both 'from' and 'to'.
   *  - On _mint, only for `to`.
   *  - On _burn, only for `from`.
   *
   * @param  from    The sender.
   * @param  to      The recipient.
   * @param  amount  The amount being transfered.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  )
    internal
    override
  {
    address votingFromDelegatee = _getDelegatee(from, _votingDelegates);
    address votingToDelegatee = _getDelegatee(to, _votingDelegates);

    _moveDelegatesByType(
      votingFromDelegatee,
      votingToDelegatee,
      amount,
      DelegationType.VOTING_POWER
    );

    address propPowerFromDelegatee = _getDelegatee(from, _propositionPowerDelegates);
    address propPowerToDelegatee = _getDelegatee(to, _propositionPowerDelegates);

    _moveDelegatesByType(
      propPowerFromDelegatee,
      propPowerToDelegatee,
      amount,
      DelegationType.PROPOSITION_POWER
    );
  }

  function _getDelegationDataByType(DelegationType delegationType)
    internal
    override
    view
    returns (
      mapping(address => mapping(uint256 => Snapshot)) storage, // snapshots
      mapping(address => uint256) storage, // snapshots count
      mapping(address => address) storage // delegatees list
    )
  {
    if (delegationType == DelegationType.VOTING_POWER) {
      return (_votingSnapshots, _votingSnapshotsCounts, _votingDelegates);
    } else {
      return (
        _propositionPowerSnapshots,
        _propositionPowerSnapshotsCounts,
        _propositionPowerDelegates
      );
    }
  }

  /**
   * @dev Delegates specific governance power from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee       The address to delegate votes to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   * @param  nonce           The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry          Expiration timestamp for the signature.
   * @param  v               Signature param.
   * @param  r               Signature param.
   * @param  s               Signature param.
   */
  function delegateByTypeBySig(
    address delegatee,
    DelegationType delegationType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_BY_TYPE_TYPEHASH, delegatee, uint256(delegationType), nonce, expiry)
    );
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0), 'INVALID_SIGNATURE');
    require(nonce == _nonces[signer]++, 'INVALID_NONCE');
    require(block.timestamp <= expiry, 'INVALID_EXPIRATION');
    _delegateByType(signer, delegatee, delegationType);
  }

  /**
   * @dev Delegates both governance powers from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee  The address to delegate votes to.
   * @param  nonce      The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry     Expiration timestamp for the signature.
   * @param  v          Signature param.
   * @param  r          Signature param.
   * @param  s          Signature param.
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
    bytes32 structHash = keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0), 'INVALID_SIGNATURE');
    require(nonce == _nonces[signer]++, 'INVALID_NONCE');
    require(block.timestamp <= expiry, 'INVALID_EXPIRATION');
    _delegateByType(signer, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(signer, delegatee, DelegationType.PROPOSITION_POWER);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { ERC20 } from '../../dependencies/open-zeppelin/ERC20.sol';
import { SafeMath } from '../../dependencies/open-zeppelin/SafeMath.sol';
import {
  IGovernancePowerDelegationERC20
} from '../../interfaces/IGovernancePowerDelegationERC20.sol';

/**
 * @title GovernancePowerDelegationERC20Mixin
 * @author dYdX
 *
 * @notice Provides support for two types of governance powers, both endowed by the governance
 *  token, and separately delegatable. Provides functions for delegation and for querying a user's
 *  power at a certain block number.
 */
abstract contract GovernancePowerDelegationERC20Mixin is
  ERC20,
  IGovernancePowerDelegationERC20
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice EIP-712 typehash for delegation by signature of a specific governance power type.
  bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH = keccak256(
    'DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
  );

  /// @notice EIP-712 typehash for delegation by signature of all governance powers.
  bytes32 public constant DELEGATE_TYPEHASH = keccak256(
    'Delegate(address delegatee,uint256 nonce,uint256 expiry)'
  );

  // ============ Structs ============

  /// @dev Snapshot of a value on a specific block, used to track voting power for proposals.
  struct Snapshot {
    uint128 blockNumber;
    uint128 value;
  }

  // ============ External Functions ============

  /**
   * @notice Delegates a specific governance power to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(address delegatee, DelegationType delegationType)
    external
    override
  {
    _delegateByType(msg.sender, delegatee, delegationType);
  }

  /**
   * @notice Delegates all governance powers to a delegatee.
   *
   * @param  delegatee  The address to delegate power to.
   */
  function delegate(address delegatee)
    external
    override
  {
    _delegateByType(msg.sender, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(msg.sender, delegatee, DelegationType.PROPOSITION_POWER);
  }

  /**
   * @notice Returns the delegatee of a user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(address delegator, DelegationType delegationType)
    external
    override
    view
    returns (address)
  {
    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

    return _getDelegatee(delegator, delegates);
  }

  /**
   * @notice Returns the current power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(address user, DelegationType delegationType)
    external
    override
    view
    returns (uint256)
  {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    return _searchByBlockNumber(snapshots, snapshotsCounts, user, block.number);
  }

  /**
   * @notice Returns the power of a user at a certain block.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  ) external override view returns (uint256) {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    return _searchByBlockNumber(snapshots, snapshotsCounts, user, blockNumber);
  }

  // ============ Internal Functions ============

  /**
   * @dev Delegates one specific power to a delegatee.
   *
   * @param  delegator       The user whose power to delegate.
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _delegateByType(
    address delegator,
    address delegatee,
    DelegationType delegationType
  ) internal {
    require(delegatee != address(0), 'INVALID_DELEGATEE');

    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

    uint256 delegatorBalance = balanceOf(delegator);

    address previousDelegatee = _getDelegatee(delegator, delegates);

    delegates[delegator] = delegatee;

    _moveDelegatesByType(previousDelegatee, delegatee, delegatorBalance, delegationType);
    emit DelegateChanged(delegator, delegatee, delegationType);
  }

  /**
   * @dev Moves power from one user to another.
   *
   * @param  from            The user from which delegated power is moved.
   * @param  to              The user that will receive the delegated power.
   * @param  amount          The amount of power to be moved.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _moveDelegatesByType(
    address from,
    address to,
    uint256 amount,
    DelegationType delegationType
  ) internal {
    if (from == to) {
      return;
    }

    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    if (from != address(0)) {
      uint256 previous = 0;
      uint256 fromSnapshotsCount = snapshotsCounts[from];

      if (fromSnapshotsCount != 0) {
        previous = snapshots[from][fromSnapshotsCount - 1].value;
      } else {
        previous = balanceOf(from);
      }

      uint256 newAmount = previous.sub(amount);
      _writeSnapshot(
        snapshots,
        snapshotsCounts,
        from,
        uint128(newAmount)
      );

      emit DelegatedPowerChanged(from, newAmount, delegationType);
    }

    if (to != address(0)) {
      uint256 previous = 0;
      uint256 toSnapshotsCount = snapshotsCounts[to];
      if (toSnapshotsCount != 0) {
        previous = snapshots[to][toSnapshotsCount - 1].value;
      } else {
        previous = balanceOf(to);
      }

      uint256 newAmount = previous.add(amount);
      _writeSnapshot(
        snapshots,
        snapshotsCounts,
        to,
        uint128(newAmount)
      );

      emit DelegatedPowerChanged(to, newAmount, delegationType);
    }
  }

  /**
   * @dev Searches for a balance snapshot by block number using binary search.
   *
   * @param  snapshots        The mapping of snapshots by user.
   * @param  snapshotsCounts  The mapping of the number of snapshots by user.
   * @param  user             The user for which the snapshot is being searched.
   * @param  blockNumber      The block number being searched.
   */
  function _searchByBlockNumber(
    mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
    mapping(address => uint256) storage snapshotsCounts,
    address user,
    uint256 blockNumber
  ) internal view returns (uint256) {
    require(blockNumber <= block.number, 'INVALID_BLOCK_NUMBER');

    uint256 snapshotsCount = snapshotsCounts[user];

    if (snapshotsCount == 0) {
      return balanceOf(user);
    }

    // First check most recent balance
    if (snapshots[user][snapshotsCount - 1].blockNumber <= blockNumber) {
      return snapshots[user][snapshotsCount - 1].value;
    }

    // Next check implicit zero balance
    if (snapshots[user][0].blockNumber > blockNumber) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = snapshotsCount - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Snapshot memory snapshot = snapshots[user][center];
      if (snapshot.blockNumber == blockNumber) {
        return snapshot.value;
      } else if (snapshot.blockNumber < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return snapshots[user][lower].value;
  }

  /**
   * @dev Returns delegation data (snapshot, snapshotsCount, delegates) by delegation type.
   *
   *  Note: This mixin contract does not itself define any storage, and we require the inheriting
   *  contract to implement this method to provide access to the relevant mappings in storage.
   *  This pattern was implemented by Aave for legacy reasons and we have decided not to change it.
   *
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _getDelegationDataByType(DelegationType delegationType)
    internal
    virtual
    view
    returns (
      mapping(address => mapping(uint256 => Snapshot)) storage, // snapshots
      mapping(address => uint256) storage, // snapshotsCount
      mapping(address => address) storage // delegates
    );

  /**
   * @dev Writes a snapshot of a user's token/power balance.
   *
   * @param  snapshots        The mapping of snapshots by user.
   * @param  snapshotsCounts  The mapping of the number of snapshots by user.
   * @param  owner            The user whose power to snapshot.
   * @param  newValue         The new balance to snapshot at the current block.
   */
  function _writeSnapshot(
    mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
    mapping(address => uint256) storage snapshotsCounts,
    address owner,
    uint128 newValue
  ) internal {
    uint128 currentBlock = uint128(block.number);

    uint256 ownerSnapshotsCount = snapshotsCounts[owner];
    mapping(uint256 => Snapshot) storage ownerSnapshots = snapshots[owner];

    if (
      ownerSnapshotsCount != 0 &&
      ownerSnapshots[ownerSnapshotsCount - 1].blockNumber == currentBlock
    ) {
      // Doing multiple operations in the same block
      ownerSnapshots[ownerSnapshotsCount - 1].value = newValue;
    } else {
      ownerSnapshots[ownerSnapshotsCount] = Snapshot(currentBlock, newValue);
      snapshotsCounts[owner] = ownerSnapshotsCount + 1;
    }
  }

  /**
   * @dev Returns the delegatee of a user. If a user never performed any delegation, their
   *  delegated address will be 0x0, in which case we return the user's own address.
   *
   * @param  delegator  The address of the user for which return the delegatee.
   * @param  delegates  The mapping of delegates for a particular type of delegation.
   */
  function _getDelegatee(
    address delegator,
    mapping(address => address) storage delegates
  )
    internal
    view
    returns (address)
  {
    address previousDelegatee = delegates[delegator];

    if (previousDelegatee == address(0)) {
      return delegator;
    }

    return previousDelegatee;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IGovernancePowerDelegationERC20 {

  enum DelegationType {
    VOTING_POWER,
    PROPOSITION_POWER
  }

  /**
   * @dev Emitted when a user delegates governance power to another user.
   *
   * @param  delegator       The delegator.
   * @param  delegatee       The delegatee.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegateChanged(
    address indexed delegator,
    address indexed delegatee,
    DelegationType delegationType
  );

  /**
   * @dev Emitted when an action changes the delegated power of a user.
   *
   * @param  user            The user whose delegated power has changed.
   * @param  amount          The new amount of delegated power for the user.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegatedPowerChanged(address indexed user, uint256 amount, DelegationType delegationType);

  /**
   * @dev Delegates a specific governance power to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(address delegatee, DelegationType delegationType) external virtual;

  /**
   * @dev Delegates all governance powers to a delegatee.
   *
   * @param  delegatee  The user to which the power will be delegated.
   */
  function delegate(address delegatee) external virtual;

  /**
   * @dev Returns the delegatee of an user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(address delegator, DelegationType delegationType)
    external
    view
    virtual
    returns (address);

  /**
   * @dev Returns the current delegated power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(address user, DelegationType delegationType)
    external
    view
    virtual
    returns (uint256);

  /**
   * @dev Returns the delegated power of a user at a certain block.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  )
    external
    view
    virtual
    returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { IGovernanceStrategy } from '../interfaces/IGovernanceStrategy.sol';
import { IGovernancePowerDelegationERC20 } from '../interfaces/IGovernancePowerDelegationERC20.sol';
import { GovernancePowerDelegationERC20Mixin } from './token/GovernancePowerDelegationERC20Mixin.sol';

interface IDydxToken {
  function _totalSupplySnapshots(uint256) external view returns (GovernancePowerDelegationERC20Mixin.Snapshot memory);
  function _totalSupplySnapshotsCount() external view returns (uint256);
}

/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from DYDX token + User Power from staked-DYDX token.
 * User Power from Token = Token Power + Token Power as Delegatee [- Token Power if user has delegated]
 * Two wrapper functions linked to DYDX tokens's GovernancePowerDelegationERC20Mixin.sol implementation
 * - getPropositionPowerAt: fetching a user Proposition Power at a specified block
 * - getVotingPowerAt: fetching a user Voting Power at a specified block
 * @author dYdX
 **/
contract GovernanceStrategy is IGovernanceStrategy {
  address public immutable DYDX_TOKEN;
  address public immutable STAKED_DYDX_TOKEN;

  /**
   * @dev Constructor, register tokens used for Voting and Proposition Powers.
   * @param dydxToken The address of the DYDX token contract.
   * @param stakedDydxToken The address of the staked-DYDX token Contract
   **/
  constructor(address dydxToken, address stakedDydxToken) {
    DYDX_TOKEN = dydxToken;
    STAKED_DYDX_TOKEN = stakedDydxToken;
  }

  /**
   * @dev Get the supply of proposition power, for the purpose of determining if a proposing
   *  threshold was reached.
   * @param blockNumber Block number at which to evaluate
   * @return Returns token supply at blockNumber.
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return _getTotalSupplyAt(blockNumber);
  }

  /**
   * @dev Get the supply of voting power, for the purpose of determining if quorum or vote
   *  differential tresholds were reached.
   * @param blockNumber Block number at which to evaluate
   * @return Returns token supply at blockNumber.
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return _getTotalSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return
      _getPowerByTypeAt(user, blockNumber, IGovernancePowerDelegationERC20.DelegationType.PROPOSITION_POWER);
  }

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return _getPowerByTypeAt(user, blockNumber, IGovernancePowerDelegationERC20.DelegationType.VOTING_POWER);
  }

  function _getPowerByTypeAt(
    address user,
    uint256 blockNumber,
    IGovernancePowerDelegationERC20.DelegationType powerType
  ) internal view returns (uint256) {
    return
      IGovernancePowerDelegationERC20(DYDX_TOKEN).getPowerAtBlock(user, blockNumber, powerType) +
      IGovernancePowerDelegationERC20(STAKED_DYDX_TOKEN).getPowerAtBlock(user, blockNumber, powerType);
  }

  /**
   * @dev Returns the total supply of DYDX token at a specific block number.
   * @param blockNumber Blocknumber at which to fetch DYDX token supply.
   * @return Total DYDX token supply at block number.
   **/
  function _getTotalSupplyAt(uint256 blockNumber) internal view returns (uint256) {
    IDydxToken dydxToken = IDydxToken(DYDX_TOKEN);
    uint256 snapshotsCount = dydxToken._totalSupplySnapshotsCount();

    // Iterate in reverse over the total supply snapshots, up to index 1.
    for (uint256 i = snapshotsCount - 1; i != 0; i--) {
      GovernancePowerDelegationERC20Mixin.Snapshot memory snapshot = dydxToken._totalSupplySnapshots(i);
      if (snapshot.blockNumber <= blockNumber) {
        return snapshot.value;
      }
    }

    // If blockNumber was on or after the first snapshot, then return the initial supply.
    // Else, blockNumber is before token launch so return 0.
    GovernancePowerDelegationERC20Mixin.Snapshot memory firstSnapshot = dydxToken._totalSupplySnapshots(0);
    if (firstSnapshot.blockNumber <= blockNumber) {
      return firstSnapshot.value;
    } else {
      return 0;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { ERC20 } from '../dependencies/open-zeppelin/ERC20.sol';
import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';
import { GovernancePowerDelegationERC20Mixin } from './token/GovernancePowerDelegationERC20Mixin.sol';

/**
 * @title GovernancePowerWithSnapshot
 * @notice ERC20 including snapshots of balances on transfer-related actions
 * @author dYdX
 **/
abstract contract GovernancePowerWithSnapshot is GovernancePowerDelegationERC20Mixin {
  using SafeMath for uint256;

  /**
   * @dev The following storage layout points to the prior StakedToken.sol implementation:
   * _snapshots => _votingSnapshots
   * _snapshotsCounts =>  _votingSnapshotsCounts
   */
  mapping(address => mapping(uint256 => Snapshot)) public _votingSnapshots;
  mapping(address => uint256) public _votingSnapshotsCounts;
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { Ownable } from '../dependencies/open-zeppelin/Ownable.sol';
import { IStarkPerpetual } from '../interfaces/IStarkPerpetual.sol';

/**
 * @title StarkExRemoverGovernorV2
 * @author dYdX
 *
 * @notice This is a StarkEx governor contract whose sole purpose is to remove other governors.
 *
 *  This contract can be nominated by a StarkEx governor in order to allow themselves to be removed
 *  “automatically” from the governor role. The governor should nominate this contract to the main
 *  and proxy governor roles, while ensuring that the MAIN_GOVERNORS_TO_REMOVE and
 *  PROXY_GOVERNORS_TO_REMOVE values are correctly set.
 */
contract StarkExRemoverGovernorV2 is
  Ownable
{
  IStarkPerpetual public immutable STARK_PERPETUAL;
  address[] public MAIN_GOVERNORS_TO_REMOVE;
  address[] public PROXY_GOVERNORS_TO_REMOVE;

  constructor(
    address starkPerpetual,
    address[] memory mainGovernorsToRemove,
    address[] memory proxyGovernorsToRemove
  ) {
    STARK_PERPETUAL = IStarkPerpetual(starkPerpetual);
    MAIN_GOVERNORS_TO_REMOVE = mainGovernorsToRemove;
    PROXY_GOVERNORS_TO_REMOVE = proxyGovernorsToRemove;
  }

  function mainAcceptGovernance()
    external
    onlyOwner
  {
    STARK_PERPETUAL.mainAcceptGovernance();
  }

  function proxyAcceptGovernance()
    external
    onlyOwner
  {
    STARK_PERPETUAL.proxyAcceptGovernance();
  }

  function mainRemoveGovernor(
    uint256 i
  )
    external
    onlyOwner
  {
    STARK_PERPETUAL.mainRemoveGovernor(MAIN_GOVERNORS_TO_REMOVE[i]);
  }

  function proxyRemoveGovernor(
    uint256 i
  )
    external
    onlyOwner
  {
    STARK_PERPETUAL.proxyRemoveGovernor(PROXY_GOVERNORS_TO_REMOVE[i]);
  }

  function numMainGovernorsToRemove()
    external
    view
    returns (uint256)
  {
    return MAIN_GOVERNORS_TO_REMOVE.length;
  }

  function numProxyGovernorsToRemove()
    external
    view
    returns (uint256)
  {
    return PROXY_GOVERNORS_TO_REMOVE.length;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title IStarkPerpetual
 * @author dYdX
 *
 * @notice Partial interface for the StarkPerpetual contract, for accessing the dYdX L2 exchange.
 * @dev See https://github.com/starkware-libs/starkex-contracts
 */
interface IStarkPerpetual {

  function registerUser(
    address ethKey,
    uint256 starkKey,
    bytes calldata signature
  ) external;

  function deposit(
    uint256 starkKey,
    uint256 assetType,
    uint256 vaultId,
    uint256 quantizedAmount
  ) external;

  function withdraw(uint256 starkKey, uint256 assetType) external;

  function forcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost
  ) external;

  function forcedTradeRequest(
    uint256 starkKeyA,
    uint256 starkKeyB,
    uint256 vaultIdA,
    uint256 vaultIdB,
    uint256 collateralAssetId,
    uint256 syntheticAssetId,
    uint256 amountCollateral,
    uint256 amountSynthetic,
    bool aIsBuyingSynthetic,
    uint256 submissionExpirationTime,
    uint256 nonce,
    bytes calldata signature,
    bool premiumCost
  ) external;

  function mainAcceptGovernance() external;
  function proxyAcceptGovernance() external;

  function mainRemoveGovernor(address governorForRemoval) external;
  function proxyRemoveGovernor(address governorForRemoval) external;

  function registerAssetConfigurationChange(uint256 assetId, bytes32 configHash) external;
  function applyAssetConfigurationChange(uint256 assetId, bytes32 configHash) external;

  function registerGlobalConfigurationChange(bytes32 configHash) external;
  function applyGlobalConfigurationChange(bytes32 configHash) external;

  function getEthKey(uint256 starkKey) external view returns (address);
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { Ownable } from '../dependencies/open-zeppelin/Ownable.sol';
import { IStarkPerpetual } from '../interfaces/IStarkPerpetual.sol';

/**
 * @title StarkExRemoverGovernor
 * @author dYdX
 *
 * @notice This is a StarkEx governor contract whose sole purpose is to remove another governor.
 *
 *  This contract can be nominated by a StarkEx governor in order to allow themselves to be removed
 *  “automatically” from the governor role. The governor should nominate this contract to the main
 *  and proxy governor roles, while ensuring that the GOVERNOR_TO_REMOVE address is correctly set
 *  to their own address.
 */
contract StarkExRemoverGovernor is
  Ownable
{
  IStarkPerpetual public immutable STARK_PERPETUAL;
  address public immutable GOVERNOR_TO_REMOVE;

  constructor(
    address starkPerpetual,
    address governorToRemove
  ) {
    STARK_PERPETUAL = IStarkPerpetual(starkPerpetual);
    GOVERNOR_TO_REMOVE = governorToRemove;
  }

  function mainAcceptGovernance()
    external
    onlyOwner
  {
    STARK_PERPETUAL.mainAcceptGovernance();
  }

  function proxyAcceptGovernance()
    external
    onlyOwner
  {
    STARK_PERPETUAL.proxyAcceptGovernance();
  }

  function mainRemoveGovernor()
    external
    onlyOwner
  {
    STARK_PERPETUAL.mainRemoveGovernor(GOVERNOR_TO_REMOVE);
  }

  function proxyRemoveGovernor()
    external
    onlyOwner
  {
    STARK_PERPETUAL.proxyRemoveGovernor(GOVERNOR_TO_REMOVE);
  }
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { Ownable } from '../dependencies/open-zeppelin/Ownable.sol';
import { IStarkPerpetual } from '../interfaces/IStarkPerpetual.sol';

/**
 * @title StarkExHelperGovernor
 * @author dYdX
 *
 * @notice This is a StarkEx governor which can be used by the owner to execute config changes.
 */
contract StarkExHelperGovernor is
  Ownable
{
  IStarkPerpetual public immutable STARK_PERPETUAL;

  constructor(
    address starkPerpetual
  ) {
    STARK_PERPETUAL = IStarkPerpetual(starkPerpetual);
  }

  function mainAcceptGovernance()
    external
    onlyOwner
  {
    STARK_PERPETUAL.mainAcceptGovernance();
  }

  /**
   * @notice Helper function to register and apply multiple asset configuration changes.
   *
   *  Requires that there is no timelock set on the StarkEx contract.
   *
   * @param  assetIds      Array of asset IDs for the assets to be configured.
   * @param  configHashes  Array of hashes of the asset configurations.
   */
  function executeAssetConfigurationChanges(
    uint256[] calldata assetIds,
    bytes32[] calldata configHashes
  )
    external
    onlyOwner
  {
    require(
      assetIds.length == configHashes.length,
      'StarkExHelperGovernor: Input params must have the same length'
    );
    for (uint256 i = 0; i < assetIds.length; i++) {
      STARK_PERPETUAL.registerAssetConfigurationChange(assetIds[i], configHashes[i]);
      STARK_PERPETUAL.applyAssetConfigurationChange(assetIds[i], configHashes[i]);
    }
  }

  /**
   * @notice Helper function to register and apply a global configuration change.
   *
   *  Requires that there is no timelock set on the StarkEx contract.
   *
   * @param  configHash  The hash of the global configuration.
   */
  function executeGlobalConfigurationChange(
    bytes32 configHash
  )
    external
    onlyOwner
  {
    STARK_PERPETUAL.registerGlobalConfigurationChange(configHash);
    STARK_PERPETUAL.applyGlobalConfigurationChange(configHash);
  }
}

pragma solidity ^0.7.5;

import "./Ownable.sol";
import "./AdminUpgradeabilityProxy.sol";

/**
 * @title ProxyAdmin
 * @dev This contract is the admin of a proxy, and is in charge
 * of upgrading it as well as transferring it to another admin.
 */
contract ProxyAdmin is Ownable {
  
  /**
   * @dev Returns the current implementation of a proxy.
   * This is needed because only the proxy admin can query it.
   * @return The address of the current implementation of the proxy.
   */
  function getProxyImplementation(AdminUpgradeabilityProxy proxy) public view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("implementation()")) == 0x5c60da1b
    (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
    require(success);
    return abi.decode(returndata, (address));
  }

  /**
   * @dev Returns the admin of a proxy. Only the admin can query it.
   * @return The address of the current admin of the proxy.
   */
  function getProxyAdmin(AdminUpgradeabilityProxy proxy) public view returns (address) {
    // We need to manually run the static call since the getter cannot be flagged as view
    // bytes4(keccak256("admin()")) == 0xf851a440
    (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
    require(success);
    return abi.decode(returndata, (address));
  }

  /**
   * @dev Changes the admin of a proxy.
   * @param proxy Proxy to change admin.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeProxyAdmin(AdminUpgradeabilityProxy proxy, address newAdmin) public onlyOwner {
    proxy.changeAdmin(newAdmin);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract.
   * @param proxy Proxy to be upgraded.
   * @param implementation the address of the Implementation.
   */
  function upgrade(AdminUpgradeabilityProxy proxy, address implementation) public onlyOwner {
    proxy.upgradeTo(implementation);
  }

  /**
   * @dev Upgrades a proxy to the newest implementation of a contract and forwards a function call to it.
   * This is useful to initialize the proxied contract.
   * @param proxy Proxy to be upgraded.
   * @param implementation Address of the Implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeAndCall(AdminUpgradeabilityProxy proxy, address implementation, bytes memory data) payable public onlyOwner {
    proxy.upgradeToAndCall{value: msg.value}(implementation, data);
  }
}

pragma solidity ^0.7.5;

import './BaseAdminUpgradeabilityProxy.sol';

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

pragma solidity 0.7.5;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32
    internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), 'Cannot change the admin of a proxy to the zero address');
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

pragma solidity 0.7.5;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

pragma solidity 0.7.5;

import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32
    internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal override view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity 0.7.5;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal virtual view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is
  BaseAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import { IERC20 } from '../interfaces/IERC20.sol';

/**
 * @title MockStarkPerpetual
 * @author dYdX
 *
 * @notice Mock implementation for the StarkPerpetual contract, for accessing the dYdX L2 exchange.
 * @dev See https://github.com/starkware-libs/starkex-contracts
 */
contract MockStarkPerpetual {

  // ============ Mock Exchange Functionality ============

  event MockStarkRegistered(address ethKey, uint256 starkKey, bytes signature);

  event MockStarkDeposited(
    uint256 starkKey,
    uint256 assetType,
    uint256 vaultId,
    uint256 quantizedAmount
  );

  event MockStarkWithdrew(uint256 starkKey, uint256 assetType, uint256 amount);

  mapping(uint256 => address) public _REGISTRATIONS_;

  mapping(address => uint256) public _DEPOSITS_;

  IERC20 public immutable TOKEN;

  constructor(IERC20 token) {
    TOKEN = token;
  }

  function registerUser(
    address ethKey,
    uint256 starkKey,
    bytes calldata signature
  ) external {
    _REGISTRATIONS_[starkKey] = ethKey;
    emit MockStarkRegistered(ethKey, starkKey, signature);
  }

  function deposit(
    uint256 starkKey,
    uint256 assetType,
    uint256 vaultId,
    uint256 quantizedAmount
  ) external {
    // Require registered.
    getEthKey(starkKey);

    // Assume no overflow since this is just for test purposes.
    _DEPOSITS_[msg.sender] = _DEPOSITS_[msg.sender] + quantizedAmount;
    require(TOKEN.transferFrom(msg.sender, address(this), quantizedAmount));
    emit MockStarkDeposited(starkKey, assetType, vaultId, quantizedAmount);
  }

  function withdraw(uint256 starkKey, uint256 assetType) external {
    // Require registered.
    getEthKey(starkKey);

    uint256 amount = _DEPOSITS_[msg.sender];
    _DEPOSITS_[msg.sender] = 0;
    require(TOKEN.transfer(msg.sender, amount));
    emit MockStarkWithdrew(starkKey, assetType, amount);
  }

  function forcedWithdrawalRequest(
    uint256 starkKey,
    uint256 vaultId,
    uint256 quantizedAmount,
    bool premiumCost
  ) external {
    // Require registered.
    getEthKey(starkKey);
  }

  function getEthKey(uint256 starkKey) public view returns(address) {
    address ethKey = _REGISTRATIONS_[starkKey];
    require(ethKey != address(0), 'USER_UNREGISTERED');
    return ethKey;
  }

  // ============ Mock Governance Functionality ============

  mapping(address => bool) public _MAIN_GOVERNORS_;
  mapping(address => bool) public _PROXY_GOVERNORS_;
  mapping(uint256 => mapping(bytes32 => bool)) public _REGISTERED_ASSET_CONFIGS_;
  mapping(bytes32 => bool) public _REGISTERED_GLOBAL_CONFIGS_;
  mapping(uint256 => bytes32) public _ASSET_CONFIGS_;
  bytes32 public _GLOBAL_CONFIG_;

  function mainAcceptGovernance() external {
    // Assume already nominated.
    _MAIN_GOVERNORS_[msg.sender] = true;
  }

  function proxyAcceptGovernance() external {
    // Assume already nominated.
    _PROXY_GOVERNORS_[msg.sender] = true;
  }

  function mainRemoveGovernor(address governorForRemoval) external {
    require(_MAIN_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a main governor');
    require(governorForRemoval != msg.sender, 'MockStarkPerpetual: Cannot remove self');
    _MAIN_GOVERNORS_[governorForRemoval] = false;
  }

  function proxyRemoveGovernor(address governorForRemoval) external {
    require(_PROXY_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a proxy governor');
    require(governorForRemoval != msg.sender, 'MockStarkPerpetual: Cannot remove self');
    _PROXY_GOVERNORS_[governorForRemoval] = false;
  }

  function registerAssetConfigurationChange(uint256 assetId, bytes32 configHash) external {
    require(_MAIN_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a main governor');
    _REGISTERED_ASSET_CONFIGS_[assetId][configHash] = true;
  }

  function applyAssetConfigurationChange(uint256 assetId, bytes32 configHash) external {
    require(_MAIN_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a main governor');
    require(
      _REGISTERED_ASSET_CONFIGS_[assetId][configHash],
      'MockStarkPerpetual: Asset config not registered'
    );
    _ASSET_CONFIGS_[assetId] = configHash;
  }

  function registerGlobalConfigurationChange(bytes32 configHash) external {
    require(_MAIN_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a main governor');
    _REGISTERED_GLOBAL_CONFIGS_[configHash] = true;
  }

  function applyGlobalConfigurationChange(bytes32 configHash) external {
    require(_MAIN_GOVERNORS_[msg.sender], 'MockStarkPerpetual: Sender is not a main governor');
    require(
      _REGISTERED_GLOBAL_CONFIGS_[configHash],
      'MockStarkPerpetual: Global config not registered'
    );
    _GLOBAL_CONFIG_ = configHash;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';

contract DoubleTransferHelper {
  IERC20 public immutable TOKEN;

  constructor(IERC20 token) public {
    TOKEN = token;
  }

  function doubleSend(
    address to,
    uint256 amount1,
    uint256 amount2
  ) external {
    TOKEN.transfer(to, amount1);
    TOKEN.transfer(to, amount2);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import { IERC20 } from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { ExecutorWithTimelockMixin } from './ExecutorWithTimelockMixin.sol';
import { ProposalValidatorMixin } from './ProposalValidatorMixin.sol';

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author dYdX
 **/
contract Executor is ExecutorWithTimelockMixin, ProposalValidatorMixin {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )
    ExecutorWithTimelockMixin(admin, delay, gracePeriod, minimumDelay, maximumDelay)
    ProposalValidatorMixin(propositionThreshold, voteDuration, voteDifferential, minimumQuorum)
  {}
}

