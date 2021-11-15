// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import '../utils/EnumerableSet.sol';
import '../utils/Address.sol';
import '../utils/Context.sol';

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
  using EnumerableSet for EnumerableSet.AddressSet;
  using Address for address;

  struct RoleData {
    EnumerableSet.AddressSet members;
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
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return _roles[role].members.contains(account);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) public view returns (uint256) {
    return _roles[role].members.length();
  }

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index)
    public
    view
    returns (address)
  {
    return _roles[role].members.at(index);
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
  function grantRole(bytes32 role, address account) public virtual {
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to grant'
    );

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
  function revokeRole(bytes32 role, address account) public virtual {
    require(
      hasRole(_roles[role].adminRole, _msgSender()),
      'AccessControl: sender must be an admin to revoke'
    );

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
  function renounceRole(bytes32 role, address account) public virtual {
    require(
      account == _msgSender(),
      'AccessControl: can only renounce roles for self'
    );

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
    emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (_roles[role].members.add(account)) {
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (_roles[role].members.remove(account)) {
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface IERC1155 {
  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice Transfers amount of an _id from the _from address to the _to address specified
   * @dev MUST emit TransferSingle event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev MUST emit TransferBatch event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if length of `_ids` is not the same as length of `_amounts`
   * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {
  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import '../../utils/SafeMath.sol';
import '../../interfaces/IERC1155TokenReceiver.sol';
import '../../interfaces/IERC1155.sol';
import '../../utils/Address.sol';
import '../../utils/ERC165.sol';

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping(address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping(address => mapping(address => bool)) internal operators;

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) public virtual override {
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      'ERC1155#safeTransferFrom: INVALID_OPERATOR'
    );
    require(_to != address(0), 'ERC1155#safeTransferFrom: INVALID_RECIPIENT');
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) public virtual override {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      'ERC1155#safeBatchTransferFrom: INVALID_OPERATOR'
    );
    require(
      _to != address(0),
      'ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT'
    );

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    _beforeTokenTransfer(msg.sender, _from, _to, _id, _amount, '');

    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
        IERC1155TokenReceiver(_to).onERC1155Received{ gas: _gasLimit }(
          msg.sender,
          _from,
          _id,
          _amount,
          _data
        );
      require(
        retval == ERC1155_RECEIVED_VALUE,
        'ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE'
      );
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    require(
      _ids.length == _amounts.length,
      'ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(msg.sender, _from, _to, _ids, _amounts, '');

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
        IERC1155TokenReceiver(_to).onERC1155BatchReceived{ gas: _gasLimit }(
          msg.sender,
          _from,
          _ids,
          _amounts,
          _data
        );
      require(
        retval == ERC1155_BATCH_RECEIVED_VALUE,
        'ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE'
      );
    }
  }

  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    public
    virtual
    override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    virtual
    override
    returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }

  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public
    view
    override
    returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public
    view
    override
    returns (uint256[] memory)
  {
    require(
      _owners.length == _ids.length,
      'ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH'
    );

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }

  /***********************************|
  |               HOOKS               |
  |__________________________________*/

  /**
   * @notice overrideable hook for single transfers.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual {}

  /**
   * @notice overrideable hook for batch transfers.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import '../../interfaces/IERC1155Metadata.sol';
import '../../utils/ERC165.sol';

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string private _baseMetadataURI;

  // contract metadata URL
  string private _contractMetadataURI;

  // Hex numbers for creating hexadecimal tokenId
  bytes16 private constant HEX_MAP = '0123456789ABCDEF';

  // bytes4(keccak256('contractURI()')) == 0xe8a3d485
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return _uri(_id);
  }

  /**
   * @notice Opensea calls this fuction to get information about how to display storefront.
   *
   * @return full URI to the location of the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return _contractMetadataURI;
  }

  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_uri(_tokenIDs[i]), _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory newBaseMetadataURI) internal {
    _baseMetadataURI = newBaseMetadataURI;
  }

  /**
   * @notice Will update the contract metadata URI
   * @param newContractMetadataURI New contract metadata URI
   */
  function _setContractMetadataURI(string memory newContractMetadataURI)
    internal
  {
    _contractMetadataURI = newContractMetadataURI;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` or CONTRACT_URI
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (
      _interfaceID == type(IERC1155Metadata).interfaceId ||
      _interfaceID == _INTERFACE_ID_CONTRACT_URI
    ) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /***********************************|
  |    Utility private Functions     |
  |__________________________________*/

  /**
   * @notice returns uri
   * @param tokenId Unsigned integer to convert to string
   */
  function _uri(uint256 tokenId) private view returns (string memory) {
    // Calculate URI
    string memory baseURL = _baseMetadataURI;
    uint256 temp = tokenId;
    uint256 length = tokenId == 0 ? 1 : 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    bytes memory buffer = new bytes(2 * length);
    for (uint256 i = 2 * length; i > 0; --i) {
      buffer[i - 1] = HEX_MAP[tokenId & 0xf];
      tokenId >>= 4;
    }
    return string(abi.encodePacked(baseURL, buffer, '.json'));
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './ERC1155.sol';

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    _beforeTokenTransfer(msg.sender, address(0x0), _to, _id, _amount, _data);

    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal {
    require(
      _ids.length == _amounts.length,
      'ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(
      msg.sender,
      address(0x0),
      _to,
      _ids,
      _amounts,
      _data
    );

    // Number of mints to execute
    uint256 nMint = _ids.length;

    // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(
      address(0x0),
      _to,
      _ids,
      _amounts,
      gasleft(),
      _data
    );
  }

  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) internal {
    _beforeTokenTransfer(msg.sender, _from, address(0x0), _id, _amount, '');

    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(
      nBurn == _amounts.length,
      'ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH'
    );

    _beforeBatchTokenTransfer(
      msg.sender,
      _from,
      address(0x0),
      _ids,
      _amounts,
      ''
    );

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

abstract contract ERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    returns (bool)
  {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Set type with
  // bytes32 values.
  // The Set implementation uses private functions, and user-facing
  // implementations (such as AddressSet) are just wrappers around the
  // underlying Set.
  // This means that we can only create new EnumerableSets for types that fit
  // in bytes32.

  struct Set {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath#mul: OVERFLOW');

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath#div: DIVISION_BY_ZERO');
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath#sub: UNDERFLOW');
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath#add: OVERFLOW');

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath#mod: DIVISION_BY_ZERO');
    return a % b;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/interfaces/IERC20.sol';

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IMinterCallback.sol';
import './WOWSMinterPauser.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard, including the Metadata URI extension.
 *
 * This contract is an extension of the minter preset. It accepts the address
 * of the contract minting the token via the ERC-1155 data parameter. When
 * the token is transferred or burned, the minter is notified.
 */
contract TradeFloor is Context, WOWSMinterPauser {
  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Mapping from minted token ID to minting contract
   *
   * Token IDs are approved for a minting contract upon minting. The token ID
   * is then exclusive to that contract, and can't be reused by a different
   * minting contract.
   */
  mapping(uint256 => address) private _tokenIdToMinter;

  /**
   * @dev Per token information, used to cap NFT's and
   * to allow querying a list of NFT's owned by an address
   */

  // using a stuct allows us to work byRef
  struct ListKey {
    uint64 index;
  }

  // Per token information
  struct TokenInfo {
    bool minted; // Make sure we only mint 1
    ListKey listKey; // Next tokenId in the owner linkedList
  }
  mapping(uint64 => TokenInfo) private _tokenInfos;

  // Mapping owner -> first owned token
  //
  // Note that we work 1 based here because of initialization
  // e.g. firstId == 1 links to tokenId 0;
  struct Owned {
    uint64 count;
    ListKey listKey; // First tokenId in linked list
  }
  mapping(address => Owned) private _owned;

  /**
   * @dev the registry to get the required addreeses from
   */
  IAddressRegistry private _addressRegistry;

  // solhint-disable-next-line const-name-snakecase
  string public constant name = 'WolvesOfWallStreet NFT';
  // solhint-disable-next-line const-name-snakecase
  string public constant symbol = 'WOWS NFT';

  // OpenSea Compatibility
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  // Rarible compatibility
  /*
   * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
   * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
   *
   * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
   */
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
  uint256 private _fee;
  address private _feeRecipient;

  // Rarible events
  // solhint-disable-next-line event-name-camelcase
  event CreateERC1155_v1(address indexed creator, string name, string symbol);
  event SecondarySaleFees(
    uint256 tokenId,
    address payable[] recipients,
    uint256[] bps
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry registry containing our system addresses
   *
   * Note: Pause operation in this context. Only calls from Proxy allowed
   */
  constructor(IAddressRegistry addressRegistry) {
    // Initialize {AccessControl}
    address marketingWallet =
      addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);
    _pause(true);
  }

  /**
   * @dev One time contract initializer
   *
   * @param addressRegistry registry containing our system addresses
   * @param tokenUriPrefix The ERC-1155 metadata URI Prefix
   * @param contractUri The contract metadata URI
   */
  function initialize(
    IAddressRegistry addressRegistry,
    string memory tokenUriPrefix,
    string memory contractUri
  ) public {
    require(address(_addressRegistry) == address(0), 'already initialized');
    // Set tokenURIPrefix
    _setBaseMetadataURI(tokenUriPrefix);

    // Initialize {AccessControl}
    address marketingWallet =
      addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    _feeRecipient = addressRegistry.getRegistryEntry(
      AddressBook.REWARD_HANDLER
    );
    _fee = 1000; // 10%

    _addressRegistry = addressRegistry;
    _setContractMetadataURI(contractUri);

    // Rarible: Need a real wallet for setting up storefront
    address deployer = addressRegistry.getRegistryEntry(AddressBook.DEPLOYER);
    // This event initializes Rarible storefront
    emit CreateERC1155_v1(deployer, name, symbol);
    // OpenSea enable storefront editing
    emit OwnershipTransferred(address(0), deployer);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Get the minter of a given token
   *
   * @param tokenId the token ID to check
   *
   * @return minter Address of the minter of the token, or address(0) if the
   * token is not minted
   */
  function getMinter(uint256 tokenId) public view returns (address minter) {
    return _tokenIdToMinter[tokenId];
  }

  /**
   * @dev Return list of tokenIds owned by `account`
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory)
  {
    Owned storage list = _owned[account];
    uint256[] memory result = new uint256[](list.count);
    ListKey storage key = list.listKey;
    for (uint256 i = 0; i < list.count; ++i) {
      result[i] = key.index;
      key = _tokenInfos[key.index].listKey;
    }
    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `tokenId`.
   *
   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - The caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    // Only tokenIds >= 64 Bit allowed
    require((tokenId >> 64) != 0, 'TokenId reserved');

    // Translate parameter
    address minter = _getAddress(data);
    require(minter != address(0), 'Invalid minter from user data');

    // Update state
    _onMint(minter, tokenId);

    // Call ancestor
    super.mint(to, tokenId, amount, data);
  }

  /**
   * @dev Batched variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    // Translate parameter
    address minter = _getAddress(data);
    require(minter != address(0), 'Invalid minter in data');

    // Update state
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Only tokenIds >= 64 Bit allowed
      require((tokenIds[i] >> 64) != 0, 'TokenId reserved');
      _onMint(minter, tokenIds[i]);
    }

    // Call ancestor
    super.mintBatch(to, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Burning interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155MintBurn-_burn}.
   */
  function burn(
    address account,
    uint256 tokenId,
    uint256 value
  ) public override {
    // Validate parameters
    require(account != address(0), 'Invalid zero address');

    // Call ancestor
    super.burn(account, tokenId, value);

    uint256[] memory tokenIds = new uint256[](1);
    uint256[] memory values = new uint256[](1);
    tokenIds[0] = tokenId;
    values[0] = value;

    _onBurn(account, tokenIds, values);
  }

  /**
   * @dev See {ERC1155MintBurn-_batchBurn}.
   */
  function burnBatch(
    address account,
    uint256[] memory tokenIds,
    uint256[] memory values
  ) public virtual override {
    // Validate parameters
    require(account != address(0), 'Invalid zero address');
    require(tokenIds.length == values.length, "Lengths don't match");

    // Call parent
    super.burnBatch(account, tokenIds, values);
    _onBurn(account, tokenIds, values);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override {
    // Validate parameters
    require(from != address(0), "Can't transfer from zero address");
    require(to != address(0), "Can't transfer to zero address");

    // Look up minter
    address minter = _tokenIdToMinter[tokenId];
    require(minter != address(0), 'Invalid minter for token');

    // Call parent
    super.safeTransferFrom(from, to, tokenId, amount, data);

    if ((tokenId >> 64) == 0)
      _relinkOwner(from, to, uint64(tokenId));
      // Invoke callback
    else IMinterCallback(minter).onTransferFrom(from, to, tokenId, amount);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override {
    // Validate parameters
    require(from != address(0), "Can't transfer from zero address");
    require(to != address(0), "Can't transfer to zero address");
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Call parent
    super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);

    // Invoke callbacks
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if ((tokenId >> 64) == 0) {
        _relinkOwner(from, to, uint64(tokenId));
      } else {
        address minter = _tokenIdToMinter[tokenId];
        require(minter != address(0), 'Invalid minter for token');

        IMinterCallback(minter).onTransferFrom(from, to, tokenId, amounts[i]);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155MetadataURI}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * Revert for unminted SFT NFTs
   */
  function uri(uint256 tokenId) public view override returns (string memory) {
    // Validate state
    require(
      (tokenId >> 64) > 0 || _tokenInfos[uint64(tokenId)].minted,
      'Token not minted'
    );

    return super.uri(tokenId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Rarible Fees and events
  //////////////////////////////////////////////////////////////////////////////

  function setFee(uint256 fee) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    // Update state
    _fee = fee;
  }

  function setFeeRecipient(address feeRecipient) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    // Update state
    _feeRecipient = feeRecipient;
  }

  function getFeeRecipients(uint256)
    public
    view
    returns (address payable[] memory)
  {
    // Return value
    address payable[] memory recipients = new address payable[](1);

    // Load state
    recipients[0] = payable(_feeRecipient);
    return recipients;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    // Return value
    uint256[] memory bps = new uint256[](1);

    // Load state
    bps[0] = _fee;

    return bps;
  }

  //////////////////////////////////////////////////////////////////////////////
  // OpenSea compatibility
  //////////////////////////////////////////////////////////////////////////////

  function isOwner() external view returns (bool) {
    return _msgSender() == owner();
  }

  function owner() public view returns (address) {
    return _addressRegistry.getRegistryEntry(AddressBook.DEPLOYER);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Hooks
  //////////////////////////////////////////////////////////////////////////////

  function onERC1155Received(
    address,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes memory
  ) external returns (bytes4) {
    // Update state
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(from, tokenIds, amounts);

    // This contract supports safe ERC-1155 transfers
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external returns (bytes4) {
    _onTokensReceived(from, tokenIds, amounts);

    // This contract supports safe ERC-1155 transfers
    return this.onERC1155BatchReceived.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Administrative functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155Metadata-setBaseMetadataURI}.
   */
  function setBaseMetadataURI(string memory baseMetadataURI) external {
    // Access control
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Access denied');
    // Set state
    _setBaseMetadataURI(baseMetadataURI);
  }

  /**
   * @dev Set contract metadata URI
   */
  function setContractMetadataURI(string memory newContractUri) public {
    // Access control
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');

    _setContractMetadataURI(newContractUri);
  }

  /**
   * @dev Register interfaces
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    // Register rarible fee interface
    if (_interfaceID == _INTERFACE_ID_FEES) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /**
   * @dev Withdraw tokenAddress ERC20token to destination
   * tokenAddress cannot be rewardToken.
   * TODO: provide the possibility to swap into WOWS
   *
   * @param tokenAddress the address of the token to transfer
   */
  function collectGarbage(address tokenAddress) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    // Transfer token to msg.sender
    uint256 amountToken = IERC20(tokenAddress).balanceOf(address(this));
    if (amountToken > 0)
      IERC20(tokenAddress).transfer(_msgSender(), amountToken);
  }

  /**
   * remove before mainnet deploy
   */
  function testSelfDestroy() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');
    selfdestruct(_msgSender());
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onBurn(
    address account,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    // Count tokenIds < 64 Bit
    uint256 numStakes = 0;

    // Invoke callbacks / count SFT's
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];

      // Unstake SFT on burn
      if ((tokenId >> 64) == 0) {
        ++numStakes;
        _relinkOwner(account, address(0), uint64(tokenId));
      } else {
        address minter = _tokenIdToMinter[tokenId];
        require(minter != address(0), 'Token has no minter');

        IMinterCallback(minter).onBurn(account, tokenId, amounts[i]);
      }
    }

    // Unstake SFTs if required
    if (numStakes > 0) {
      uint256[] memory unstakeIds = new uint256[](numStakes);
      uint256[] memory unstakeAmounts = new uint256[](numStakes);

      for (uint256 i = 0; i < tokenIds.length; ++i) {
        uint256 tokenId = tokenIds[i];
        if ((tokenId >> 64) == 0) {
          unstakeIds[--numStakes] = tokenId;
          unstakeAmounts[numStakes] = 1;
        }
      }
      // Load address
      IERC1155 sftContract =
        IERC1155(_addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER));

      sftContract.safeBatchTransferFrom(
        address(this),
        _msgSender(),
        unstakeIds,
        unstakeAmounts,
        ''
      );
    }
  }

  /**
   * @dev Update the state of this contract when `minter` mints `tokenId`
   *
   * Reverts if the token has already been minted by a different minting
   * contract.
   *
   * @param minter The contract doing the minting
   * @param tokenId The token ID being minted
   */
  function _onMint(address minter, uint256 tokenId) private {
    bool tokenMinted = (_tokenIdToMinter[tokenId] != address(0));

    if (tokenMinted) {
      // Token has been minted before, require match
      require(
        _tokenIdToMinter[tokenId] == minter,
        'Token minted by different minter'
      );
    } else {
      // Token hasn't been minted before, record minter
      _tokenIdToMinter[tokenId] = minter;
    }
  }

  /**
   * @dev SFT Token arrived, provide a NFT
   */
  function _onTokensReceived(
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    // We only support tokens from our SFT Holder contract
    require(
      _msgSender() == _addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER),
      'Invald sender'
    );

    // Validate parameters
    require(tokenIds.length == amounts.length, 'Lengths mismatch');

    // Update state
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      require((tokenId >> 64) == 0, 'Invalid TokenId');
      require(amounts[i] == 1, 'Amount != 0 not alowed');
      require(
        _tokenInfos[uint64(tokenId)].minted == false,
        'Token already minted'
      );
      _relinkOwner(address(0), from, uint64(tokenId));
      // OpenSea only listens to TransferSingle event on mint
      _mint(from, tokenId, 1, '');
      // Even the tokenId has not changed we fire URI to
      // let clients know that Metadata has to be refreshed
      emit URI(uri(tokenId), tokenId);
      // Rarible needs to be informed abiut fees
      emit SecondarySaleFees(tokenId, getFeeRecipients(0), getFeeBps(0));
    }
  }

  /**
   * @dev Ownership change -> update linked list owner -> tokenId
   *
   * linkKeys are 1 based where tokenIds are 0-based.
   */
  function _relinkOwner(
    address from,
    address to,
    uint64 tokenId
  ) internal {
    // Load state
    TokenInfo storage tokenInfo = _tokenInfos[tokenId];

    // Remove tokenId from List
    if (from != address(0)) {
      // Load state
      Owned storage fromList = _owned[from];

      // Validate state
      require(fromList.count > 0, 'Count mismatch');

      ListKey storage key = fromList.listKey;
      uint64 count = fromList.count;

      // Search the token which links to tokenId
      for (; count > 0 && key.index != tokenId; --count)
        key = _tokenInfos[key.index].listKey;
      require(key.index == tokenId, 'Key mismatch');

      // Unlink prev -> tokenId
      key.index = tokenInfo.listKey.index;
      // Unlink tokenId -> next
      tokenInfo.listKey.index = 0;
      // Decrement count
      fromList.count--;
    }

    // Update state
    if (to != address(0)) {
      Owned storage toList = _owned[to];
      tokenInfo.listKey.index = toList.listKey.index;
      toList.listKey.index = tokenId;
      toList.count++;
      _tokenInfos[uint64(tokenId)].minted = true;
    } else {
      _tokenInfos[uint64(tokenId)].minted = false;
    }
  }

  /**
   * @dev Get the address from the user data parameter
   *
   * @param data Per ERC-1155, the data parameter is additional data with no
   * specified format, and is sent unaltered in the call to
   * {IERC1155Receiver-onERC1155Received} on the receiver of the minted token.
   */
  function _getAddress(bytes memory data) public pure returns (address addr) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      addr := mload(add(data, 20))
    }
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 * *
 * This file is derived from OpenZeppelin, available under the MIT
 * license. https://openzeppelin.com/contracts/

 * SPDX-License-Identifier: Apache-2.0 AND MIT
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155Metadata.sol';
import '../../0xerc1155/tokens/ERC1155/ERC1155MintBurn.sol';

/**
 * @dev Partial implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155]
 * Multi Token Standard
 *
 * This contract is a replacement for the file ERC1155PresetMinterPauser.sol
 * in the OpenZeppelin project.
 */
contract WOWSMinterPauser is
  Context,
  AccessControl,
  ERC1155MintBurn,
  ERC1155Metadata
{
  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // Role to pause token transfers
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

  // Role to mint new tokens
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  // Pause
  bool private _pauseActive;
  // Event triggered when _pause state changed
  event Pause(bool active);

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  constructor() {}

  //////////////////////////////////////////////////////////////////////////////
  // Pausing interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Pauses all token transfers.
   *
   * Requirements:
   *
   * - The caller must have the `DEFAULT_ADMIN_ROLE`.
   */
  function pause(bool active) public {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'pauser role required');

    if (_pauseActive != active) {
      // Update state
      _pauseActive = active;
      emit Pause(active);
    }
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    return _pauseActive;
  }

  function _pause(bool active) internal {
    _pauseActive = active;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Minting interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `tokenId`.
   *
   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - The caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'minter role required');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");

    // Update state
    _mint(to, tokenId, amount, data);
  }

  /**
   * @dev Batched variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    // Validate access
    require(hasRole(MINTER_ROLE, _msgSender()), 'minter role required');

    // Validate parameters
    require(to != address(0), "Can't mint to zero address");
    require(tokenIds.length == amounts.length, "Lengths don't match");

    // Update state
    _batchMint(to, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Burning interface
  //////////////////////////////////////////////////////////////////////////////

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );
    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'Caller is not owner nor approved'
    );

    _batchBurn(account, ids, values);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ERC1155}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ERC1155-_beforeBatchTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    require(_pauseActive == false, 'Transfer operation paused!');
    // Call ancestor
    super._beforeTokenTransfer(operator, from, to, tokenId, amount, data);
  }

  /**
   * @dev See {ERC1155-_beforeBatchTokenTransfer}.
   *
   * This function is necessary due to diamond inheritance.
   */
  function _beforeBatchTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    require(_pauseActive == false, 'Transfer operation paused!');
    // Call ancestor
    super._beforeBatchTokenTransfer(
      operator,
      from,
      to,
      tokenIds,
      amounts,
      data
    );
  }

  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override(ERC1155, ERC1155Metadata)
    returns (bool)
  {
    return super.supportsInterface(_interfaceID);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to receive callbacks when minted tokens are burnt
 */
interface IMinterCallback {
  /**
   * @dev Called when a token minted by a minter is transferred
   *
   * @param from The account sending the token
   * @param to The account receiving the token
   * @param tokenId The ERC-1155 token ID
   * @param amount The amount of tokens transfered
   */
  function onTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  /**
   * @dev Called when a token minted by a minter is burned
   *
   * @param account The account owning the token
   * @param tokenId The ERC-1155 token ID
   * @param amount The amount of tokens burned
   */
  function onBurn(
    address account,
    uint256 tokenId,
    uint256 amount
  ) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library AddressBook {
  bytes32 public constant DEPLOYER = 'DEPLOYER';
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant WOWS_BOOSTER = 'WOWS_BOOSTER';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_HOLDER = 'SFT_HOLDER';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get an registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}

