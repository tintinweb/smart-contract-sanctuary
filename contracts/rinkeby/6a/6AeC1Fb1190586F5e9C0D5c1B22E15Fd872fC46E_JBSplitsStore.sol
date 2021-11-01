// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './libraries/JBOperations.sol';

// Inheritance
import './interfaces/IJBSplitsStore.sol';
import './interfaces/IJBDirectory.sol';
import './abstract/JBOperatable.sol';

/**
  @notice
  Stores splits for each project.
*/
contract JBSplitsStore is IJBSplitsStore, JBOperatable {
  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
    @notice
    All splits for each project ID's configurations.

    _projectId is The ID of the project to get splits for.
    _domain is An identifier within which the returned splits should be considered active.
    _group The identifying group of the splits.
  */
  mapping(uint256 => mapping(uint256 => mapping(uint256 => JBSplit[]))) private _splitsOf;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    The Projects contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /** 
    @notice 
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Get all splits for the specified project ID, within the specified domain, for the specified group.

    @param _projectId The ID of the project to get splits for.
    @param _domain An identifier within which the returned splits should be considered active.
    @param _group The identifying group of the splits.

    @return An array of all splits for the project.
    */
  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view override returns (JBSplit[] memory) {
    return _splitsOf[_projectId][_domain][_group];
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    directory = _directory;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Sets a project's splits.

    @dev
    Only the owner or operator of a project, or the current controller contract of the project, can set its splits.

    @dev
    The new splits must include any currently set splits that are locked.

    @param _projectId The ID of the project for which splits are being added.
    @param _domain An identifier within which the splits should be considered active.
    @param _group An identifier between of splits being set. All splits within this _group must add up to within 100%.
    @param _splits The splits to set.
  */
  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  )
    external
    override
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.SET_SPLITS,
      address(directory.controllerOf(_projectId)) == msg.sender
    )
  {
    // Get a reference to the project's current splits.
    JBSplit[] memory _currentSplits = _splitsOf[_projectId][_domain][_group];

    // Check to see if all locked splits are included.
    for (uint256 _i = 0; _i < _currentSplits.length; _i++) {
      // If not locked, continue.
      if (block.timestamp >= _currentSplits[_i].lockedUntil) continue;

      // Keep a reference to whether or not the locked split being iterated on is included.
      bool _includesLocked = false;

      for (uint256 _j = 0; _j < _splits.length; _j++) {
        // Check for sameness.
        if (
          _splits[_j].percent == _currentSplits[_i].percent &&
          _splits[_j].beneficiary == _currentSplits[_i].beneficiary &&
          _splits[_j].allocator == _currentSplits[_i].allocator &&
          _splits[_j].projectId == _currentSplits[_i].projectId &&
          // Allow lock extention.
          _splits[_j].lockedUntil >= _currentSplits[_i].lockedUntil
        ) _includesLocked = true;
      }
      require(_includesLocked, '0x0f: SOME_LOCKED');
    }

    // Delete from storage so splits can be repopulated.
    delete _splitsOf[_projectId][_domain][_group];

    // Add up all the percents to make sure they cumulative are under 100%.
    uint256 _percentTotal = 0;

    for (uint256 _i = 0; _i < _splits.length; _i++) {
      // The percent should be greater than 0.
      require(_splits[_i].percent > 0, '0x10: BAD_SPLIT_PERCENT');

      // The allocator and the beneficiary shouldn't both be the zero address.
      require(
        _splits[_i].allocator != IJBSplitAllocator(address(0)) ||
          _splits[_i].beneficiary != address(0),
        '0x11: ZERO_ADDRESS'
      );

      // Add to the total percents.
      _percentTotal = _percentTotal + _splits[_i].percent;

      // The total percent should be less than 10000000.
      require(_percentTotal <= 10000000, '0x12: BAD_TOTAL_PERCENT');

      // Push the new split into the project's list of splits.
      _splitsOf[_projectId][_domain][_group].push(_splits[_i]);

      emit SetSplit(_projectId, _domain, _group, _splits[_i], msg.sender);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.
*/
abstract contract JBOperatable is IJBOperatable {
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    require(
      _override ||
        msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed,
  Standby
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBTerminal.sol';
import './IJBFundingCycleStore.sol';

interface IJBController {
  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    uint256 _reserveRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function signalWithdrawlFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBTerminal _terminal
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBTerminal.sol';
import './IJBProjects.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event RemoveTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBTerminal indexed terminal,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function controllerOf(uint256 _projectId) external view returns (IJBController);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBTerminal);

  function terminalsOf(uint256 _projectId) external view returns (IJBTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBTerminal _terminal) external view returns (bool);

  function isTerminalDelegateOf(uint256 _projectId, address _delegate) external view returns (bool);

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function removeTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function state(uint256 _fundingCycleId, uint256 _configured)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 indexed configured,
    JBFundingCycleData data,
    uint256 metadata,
    address caller
  );

  event Tap(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 amount,
    uint256 newTappedAmount,
    address caller
  );

  event Init(uint256 indexed fundingCycleId, uint256 indexed projectId, uint256 indexed basedOn);

  function latestIdOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _fundingCycleId) external view returns (JBFundingCycle memory);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _fee
  ) external returns (JBFundingCycle memory fundingCycle);

  function tapFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBTerminal.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    bytes32 indexed handle,
    string uri,
    address caller
  );

  event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

  event SetUri(uint256 indexed projectId, string uri, address caller);

  event TransferHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    bytes32 newHandle,
    address caller
  );

  event ClaimHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    address caller
  );

  event ChallengeHandle(
    bytes32 indexed handle,
    uint256 indexed projectId,
    uint256 challengeExpiry,
    address caller
  );

  event RenewHandle(bytes32 indexed handle, uint256 indexed projectId, address caller);

  function count() external view returns (uint256);

  function metadataCidOf(uint256 _projectId) external view returns (string memory);

  function handleOf(uint256 _projectId) external returns (bytes32 handle);

  function idFor(bytes32 _handle) external returns (uint256 projectId);

  function transferAddressFor(bytes32 _handle) external returns (address receiver);

  function challengeExpiryOf(bytes32 _handle) external returns (uint256);

  function createFor(
    address _owner,
    bytes32 _handle,
    string calldata _metadataCid
  ) external returns (uint256 id);

  function setHandleOf(uint256 _projectId, bytes32 _handle) external;

  function setMetadataCidOf(uint256 _projectId, string calldata _metadataCid) external;

  function transferHandleOf(
    uint256 _projectId,
    address _transferAddress,
    bytes32 _newHandle
  ) external returns (bytes32 _handle);

  function claimHandle(
    bytes32 _handle,
    address _for,
    uint256 _projectId
  ) external;

  function challengeHandle(bytes32 _handle) external;

  function renewHandleOf(uint256 _projectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBSplitAllocator {
  event Allocate(
    uint256 indexed projectId,
    uint256 indexed forProjectId,
    address indexed beneficiary,
    uint256 amount,
    address caller
  );

  function allocate(
    uint256 _amount,
    uint256 _group,
    uint256 _projectId,
    uint256 _forProjectId,
    address _beneficiary,
    bool _preferClaimed
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';
import './IJBProjects.sol';
import './IJBDirectory.sol';
import './IJBSplitAllocator.sol';

import './../structs/JBSplit.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBVault.sol';

interface IJBTerminal {
  function token() external view returns (address);

  function ethBalanceOf(uint256 _projectId) external view returns (uint256);

  function delegate() external view returns (address);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable returns (uint256 fundingCycleId);

  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBDirectory.sol';

interface IJBVault {
  event Deposit(uint256 indexed projectId, uint256 amount, address caller);
  event Withdraw(uint256 indexed projectId, uint256 amount, address to, address caller);

  function token() external view returns (address);

  function deposit(uint256 _projectId, uint256 _amount) external payable;

  function withdraw(
    uint256 _projectId,
    uint256 _amount,
    address payable _to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant PRINT_PREMINED_TOKENS = 2;
  uint256 public constant REDEEM = 3;
  uint256 public constant MIGRATE_CONTROLLER = 4;
  uint256 public constant MIGRATE_TERMINAL = 5;
  uint256 public constant PROCESS_FEES = 6;
  uint256 public constant SET_HANDLE = 7;
  uint256 public constant SET_METADATA_CID = 8;
  uint256 public constant CLAIM_HANDLE = 9;
  uint256 public constant RENEW_HANDLE = 10;
  uint256 public constant ISSUE = 11;
  uint256 public constant CHANGE_TOKEN = 12;
  uint256 public constant MINT = 13;
  uint256 public constant BURN = 14;
  uint256 public constant TRANSFER = 15;
  uint256 public constant REQUIRE_CLAIM = 16;
  uint256 public constant SET_CONTROLLER = 17;
  uint256 public constant ADD_TERMINAL = 18;
  uint256 public constant REMOVE_TERMINAL = 19;
  uint256 public constant SET_PRIMARY_TERMINAL = 20;
  uint256 public constant USE_ALLOWANCE = 21;
  uint256 public constant SET_SPLITS = 22;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/// @notice The funding cycle structure represents a project stewarded by an address, and accounts for which addresses have helped sustain the project.
struct JBFundingCycle {
  // A unique number that's incremented for each new funding cycle, starting with 1.
  uint256 id;
  // The ID of the project contract that this funding cycle belongs to.
  uint256 projectId;
  // The number of this funding cycle for the project.
  uint256 number;
  // The ID of a previous funding cycle that this one is based on.
  uint256 basedOn;
  // The time when this funding cycle was last configured.
  uint256 configured;
  // A number determining the amount of redistribution shares this funding cycle will issue to each sustainer.
  uint256 weight;
  // The ballot contract to use to determine a subsequent funding cycle's reconfiguration status.
  IJBFundingCycleBallot ballot;
  // The time when this funding cycle will become active.
  uint256 start;
  // The number of seconds until this funding cycle's surplus is redistributed.
  uint256 duration;
  // The amount that this funding cycle is targeting in terms of the currency.
  uint256 target;
  // The currency that the target is measured in.
  uint256 currency;
  // The percentage of each payment to send as a fee to the Juicebox admin.
  uint256 fee;
  // A percentage indicating how much more weight to give a funding cycle compared to its predecessor.
  uint256 discountRate;
  // The amount of available funds that have been tapped by the project in terms of the currency.
  uint256 tapped;
  // A packed list of extra data. The first 8 bytes are reserved for versioning.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The target of the funding cycle.
  // This number is interpreted as a wad, meaning it has 18 decimal places.
  // A value of 0 means that all funds in the treasury are overflow.
  // A value of uint256.max() means that the entire treasury can be distributed to the preprogrammed payout splits at anytime.
  // A value in betweem, say 3 x 10^18, means that up to 3 (ETH, USD, ...) can be distributed to splits, and the rest of the treasury is overflow.
  uint256 target;
  // The currency of the funding cycle. 0 is ETH, 1 is USD.
  uint256 currency;
  // The duration of the funding cycle in days.
  // A duration of 0 is no duration, meaning projects can trigger a new funding cycle on demand by issueing a reconfiguration.
  uint256 duration;
  // The weight of the funding cycle.
  // This number is interpreted as a wad, meaning it has 18 decimal places.
  // The protocol uses the weight to determine how many tokens to mint upon receiving a payment during a funding cycle.
  // A value of 0 means that the weight should be inherited and potentially discounted from the currently active cycle if possible. Otherwise a weight of 0 will be used.
  // A value of 1 means that no tokens should be minted regardless of how many ETH was paid. The protocol will set the stored weight value to 0.
  // A value of 1 X 10^18 means that one token should be minted per ETH received.
  uint256 weight;
  // The discount rate of the funding cycle. This number is a percentage calculated out of 10000.
  // The protocol will use the discount rate to reduce the weight of the subsequent funding cycle by this percentage compared to this cycle's weight.
  uint256 discountRate;
  // The ballot of the funding cycle.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct JBOperatorData {
  // The address of the operator.
  address operator;
  // The domain within which the operator is being given permissions.
  uint256 domain;
  // The indexes of the permissions the operator is being given.
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

struct JBSplit {
  // A flag that only has effect if a projectId is also specified, and that project has issued its tokens.
  // If so, this flag indicates if the tokens that result from making a payment to the project should be delivered staked or unstaked to the beneficiary.
  bool preferClaimed;
  // The percent of the whole group that this split occupies. This number is out of 10000000.
  uint24 percent;
  // Specifies if the split should be unchangeable until the specifies time comes, with the exception of extending the lockedUntil period.
  uint48 lockedUntil;
  // The role the  beneficary depends on whether or not projectId is specified, or whether or not allocator is specified.
  // If allocator is set, the beneficiary will be forwarded to the allocator for it to use.
  // If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it.
  // If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  address payable beneficiary;
  // If an allocator is specified, funds will be sent to the allocator contract along with the projectId, beneficiary, preferClaimed properties.
  IJBSplitAllocator allocator;
  // If an allocator is not set but a projectId is set, funds will be sent to the Juicebox treasury belonging to the project who's ID is specified.
  // Resulting tokens will be routed to the beneficiary with the unstaked token prerence respected.
  uint56 projectId;
}