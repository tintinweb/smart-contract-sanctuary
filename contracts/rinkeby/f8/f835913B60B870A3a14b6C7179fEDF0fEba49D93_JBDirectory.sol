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

import './interfaces/IJBTerminal.sol';
import './interfaces/IJBDirectory.sol';
import './abstract/JBOperatable.sol';

/**
  @notice
  Allows project owners to deploy proxy contracts that can pay them when receiving funds directly.
*/
contract JBDirectory is IJBDirectory, JBOperatable {
  // --- public immutable stored properties --- //

  /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
  IJBProjects public immutable override projects;

  /// @notice For each project ID, the juicebox terminal that the direct payment addresses are proxies for.
  mapping(uint256 => IJBTerminal[]) private _terminalsOf;

  // --- public stored properties --- //

  /// @notice For each project ID, the juicebox terminal that the direct payment addresses are proxies for.
  mapping(uint256 => mapping(address => IJBTerminal)) public override terminalOf;

  // --- external transactions --- //
  function terminalsOf(uint256 _projectId) external view override returns (IJBTerminal[] memory) {
    return _terminalsOf[_projectId];
  }

  function isTerminalOf(uint256 _projectId, address _terminal) public view override returns (bool) {
    for (uint256 _i; _i < _terminalsOf[_projectId].length; _i++)
      if (address(_terminalsOf[_projectId][_i]) == _terminal) return true;

    return false;
  }

  /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _operatorStore A contract storing operator assignments.
    */
  constructor(IJBProjects _projects, IJBOperatorStore _operatorStore) JBOperatable(_operatorStore) {
    projects = _projects;
  }

  // /**
  //   @notice
  //   Update the juicebox terminal that payments to direct payment addresses will be forwarded for the specified project ID.

  //   @param _projectId The ID of the project to set a new terminal for.
  //   @param _terminal The new terminal to set.
  // */
  // function setTerminalOf(uint256 _projectId, IJBTerminal _terminal)
  //     external
  //     override
  // {
  // }

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external override {
    // 1. make sure the terminal has been allowed.
    // 2. make sure the msg.sender is either the project owner.
    // 3. add the terminal to the list of terminals.

    // Either:
    // - case 1: the current terminal hasn't been set yet and the msg sender is the terminal being set's data authority.
    // - case 2: the current terminal's data authority is setting a new terminal.
    require(
      // case 1.
      ((_terminalsOf[_projectId].length == 0) && msg.sender == address(_terminal)) ||
        // case 2.
        isTerminalOf(_projectId, msg.sender),
      'UNAUTHORIZED'
    );

    // // The project must exist.
    // require(projects.exists(_projectId), 'NOT_FOUND');

    // Can't set the zero address.
    require(_terminal != IJBTerminal(address(0)), 'ZERO_ADDRESS');

    // If the terminal is already set, nothing to do.
    if (isTerminalOf(_projectId, address(_terminal))) return;

    // Set the new terminal.
    _terminalsOf[_projectId].push(_terminal);

    emit SetTerminal(_projectId, _terminal, msg.sender);
  }

  function transferTerminalOf(uint256 _projectId, IJBTerminal _terminal) external override {
    // 1. make sure the terminal has been allowed.
    // 2. make sure the msg.sender is a current terminal.
    // 3. add the terminal to the list of terminals.
    // 4. remove the calling terminal from the list of terminals.
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
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  modifier requirePermissionAllowingWildcardDomain(
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

  modifier requirePermissionAcceptingAlternateAddress(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    address _alternate
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        msg.sender == _alternate,
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  /// @notice A contract storing operator assignments.
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

import './IJBTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  function projects() external view returns (IJBProjects);

  function terminalOf(uint256 _projectId, address _token) external view returns (IJBTerminal);

  function terminalsOf(uint256 _projectId) external view returns (IJBTerminal[] memory);

  function isTerminalOf(uint256 _projectId, address _terminal) external view returns (bool);

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  // function setTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function transferTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct OperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

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

  function setOperator(OperatorData calldata _operatorData) external;

  function setOperators(OperatorData[] calldata _operatorData) external;
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

  function uriOf(uint256 _projectId) external view returns (string memory);

  function handleOf(uint256 _projectId) external returns (bytes32 handle);

  function idFor(bytes32 _handle) external returns (uint256 projectId);

  function transferAddressFor(bytes32 _handle) external returns (address receiver);

  function challengeExpiryOf(bytes32 _handle) external returns (uint256);

  function createFor(
    address _owner,
    bytes32 _handle,
    string calldata _uri
  ) external returns (uint256 id);

  function setHandleOf(uint256 _projectId, bytes32 _handle) external;

  function setUriOf(uint256 _projectId, string calldata _uri) external;

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

import './IJBDirectory.sol';

interface IJBTerminal {
  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTickets,
    bool _preferUnstakedTickets,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable returns (uint256 fundingCycleId);

  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable;
}

