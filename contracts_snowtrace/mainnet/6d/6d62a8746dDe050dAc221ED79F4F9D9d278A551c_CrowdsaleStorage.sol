// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CrowdsaleStorage
 * @dev CrowdsaleStorage is a shared contract that stores crowdsale state,
 * allowing to manage rounds and KYC levels.
 */
contract CrowdsaleStorage is AccessControl {
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

  enum State { None, Opened, Closed }

  struct Round {
    bool defined;
    State state;
    uint256 price;
    uint256 tokensSold;
    uint256 totalSupply;
  }

  enum KycLevel { Low, Medium, High }

  State private _state;
  Round[] private _rounds;
  uint256 private _activeRound;
  uint256 private _totalTokensSold;

  uint256 private _minInvestment;
  mapping(KycLevel => uint256) private _cap;
  mapping(address => uint256) private _investments;
  mapping(address => KycLevel) private _kyc;
  mapping(address => mapping(uint256 => uint256)) private _balances;

  event SaleStateUpdated(State state);
  event RoundOpened(uint256 indexed index);
  event RoundClosed(uint256 indexed index);
  event RoundAdded(uint256 price, uint256 totalSupply);
  event RoundUpdated(uint256 indexed index, uint256 price, uint256 totalSupply);
  event KycLevelUpdated(address indexed beneficiary, KycLevel levels);
  event MinInvestmentUpdated(uint256 minInvestment);
  event CapUpdated(KycLevel indexed level, uint256 cap);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @return Total tokens sold.
   */
  function getTotalTokensSold()
    external
    view
    returns (uint256)
  {
    return _totalTokensSold;
  }

  /**
   * @return Active round index.
   */
  function getActiveRound()
    external
    view
    returns (uint256)
  {
    return _activeRound;
  }

  /**
   * @return Round parameters by index.
   * @param index_  round index.
   */
  function getRound(uint256 index_)
    external
    view 
    returns (Round memory) 
  {
    return _rounds[index_];
  }

  /**
   * @return True if the crowdsale is opened.
   */
  function isOpened()
    public
    view
    returns (bool)
  {
    return _state == State.Opened;
  }

  /**
   * @return True if the crowdsale is closed.
   */
  function isClosed()
    public
    view
    returns (bool)
  {
    return _state == State.Closed;
  }

  /**
   * @dev Opens the crowdsale.
   */
  function openSale()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_state == State.None, "CrowdsaleStorage::openSale: sales is already open or closed");

    _state = State.Opened;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Closes the crowdsale.
   */
  function closeSale()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(isOpened(), "CrowdsaleStorage::closeSale: sales is already closed or not open");

    _state = State.Closed;

    emit SaleStateUpdated(_state);
  }

  /**
   * @dev Adds new round.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function addRound(uint256 price_, uint256 totalSupply_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(!isClosed(), "CrowdsaleStorage::addRound: sales is already closed");

    _rounds.push(
      Round({
        defined: true,
        state: State.None,
        price: price_,
        tokensSold: 0,
        totalSupply: totalSupply_
      })
    );

    emit RoundAdded(price_, totalSupply_);
  }

  /**
   * @dev Updates round parameters.
   * @param index_  round index.
   * @param price_  price per token unit.
   * @param totalSupply_  max amount of tokens available in the round.
   */
  function updateRound(uint256 index_, uint256 price_, uint256 totalSupply_) 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_rounds[index_].defined, "CrowdsaleStorage::updateRound: no round with provided index");
    require(_rounds[index_].state != State.Closed, "CrowdsaleStorage::updateRound: round is already closed");
    require(!isClosed(), "CrowdsaleStorage::updateRound: sales is already closed");

    _rounds[index_].price = price_;
    _rounds[index_].totalSupply = totalSupply_;

    emit RoundUpdated(index_, price_, totalSupply_);
  }

  /**
   * @dev Opens round for investment.
   * @param index_  round index.
   */
  function openRound(uint256 index_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(isOpened(), "CrowdsaleStorage::openRound: sales is not open yet");
    require(_rounds[index_].defined, "CrowdsaleStorage::openRound: no round with provided index");
    require(_rounds[index_].state == State.None, "CrowdsaleStorage::openRound: round is already open or closed");

    if (_rounds[_activeRound].state == State.Opened) {
      _rounds[_activeRound].state = State.Closed;
    }
    _rounds[index_].state = State.Opened;
    _activeRound = index_;

    emit RoundOpened(index_);
  }

  /**
   * @dev Closes round for investment.
   * @param index_  round index.
   */
  function closeRound(uint256 index_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(_rounds[index_].defined, "CrowdsaleStorage::closeRound: no round with provided index");
    require(_rounds[index_].state == State.Opened, "CrowdsaleStorage::closeRound: round is not open");

    _rounds[index_].state = State.Closed;

    emit RoundClosed(index_);
  }

  /**
   * @return Price of the token in the active round.
   */
  function getPrice()
    public
    view
    returns (uint256)
  {
    if (_rounds[_activeRound].state == State.Opened) {
      return _rounds[_activeRound].price;
    }
    return 0;
  }

  /**
   * @return Balance of purchased tokens by beneficiary.
   * @param round_  round of sale.
   * @param beneficiary_  address performing the token purchase.
   */
  function balanceOf(uint256 round_, address beneficiary_)
    external
    view
    returns (uint256)
  {
    return _balances[beneficiary_][round_];
  }

  /**
   * @return Beneficiary KYC level.
   * @param beneficiary_  address performing the token purchase.
   */
  function kycLevelOf(address beneficiary_)
    public
    view
    returns (KycLevel)
  {
    return _kyc[beneficiary_];
  }

  /**
   * @dev Sets beneficiary KYC level.
   * @param beneficiary_  address performing the token purchase.
   * @param level_  KYC level.
   */
  function setKyc(address beneficiary_, KycLevel level_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _kyc[beneficiary_] = level_;

    emit KycLevelUpdated(beneficiary_, level_);
  }

  /**
   * @dev Sets KYC levels to the beneficiaries in batches.
   * @param beneficiaries_  beneficiaries array to set the level for.
   * @param levels_  KYC levels.
   */
  function setKycBatches(address[] calldata beneficiaries_, KycLevel[] calldata levels_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    require(beneficiaries_.length == levels_.length, "CrowdsaleStorage::setKycBatches: mismatch in beneficiaries and levels length");

    uint256 length = beneficiaries_.length;
    for (uint256 index = 0; index < length; index++) {
      _kyc[beneficiaries_[index]] = levels_[index];

      emit KycLevelUpdated(beneficiaries_[index], levels_[index]);
    }
  }

  /**
   * @return Min investment amount.
   */
  function getMinInvestment()
    external
    view
    returns (uint256)
  {
    return _minInvestment;
  }

  /**
   * @dev Sets min investment amount.
   * @param minInvestment_  min investment amount.
   */
  function setMinInvestment(uint256 minInvestment_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _minInvestment = minInvestment_;

    emit MinInvestmentUpdated(_minInvestment);
  }

  /**
   * @return Cap according to KYC level.
   * @param beneficiary_  address performing the token purchase.
   */
  function capOf(address beneficiary_)
    external
    view
    returns (uint256)
  {
    uint256 investments = _investments[beneficiary_];
    if(investments > _cap[kycLevelOf(beneficiary_)]) {
      return 0;
    }
    return _cap[kycLevelOf(beneficiary_)] - investments;
  }

  /**
   * @return KYC level cap.
   * @param level_  KYC level.
   */
  function getCap(KycLevel level_)
    external
    view
    returns (uint256)
  {
    return _cap[level_];
  }

  /**
   * @dev Sets cap per KYC level.
   * @param level_  KYC level.
   * @param cap_  new cap value.
   */
  function setCap(KycLevel level_, uint256 cap_)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(level_ == KycLevel.Low) {
      require(_cap[KycLevel.Medium] >= cap_, "CrowdsaleStorage::setCap: cap higher than medium cap");
    }
    if(level_ == KycLevel.Medium) {
      require(_cap[KycLevel.High] >= cap_, "CrowdsaleStorage::setCap: cap higher than high cap");
    }    
    _cap[level_] = cap_;
  
    emit CapUpdated(level_, cap_);
  }

  /**
   * @dev Sets purchase state.
   * @param beneficiary_  address performing the token purchase.
   * @param investment_ normalized investment amount.
   * @param tokensSold_ amount of tokens purchased.
   */
  function setPurchaseState(address beneficiary_, uint256 investment_, uint256 tokensSold_)
    external
    onlyRole(CONTROLLER_ROLE)
  {
    _investments[beneficiary_] = _investments[beneficiary_] + investment_;
    _totalTokensSold = _totalTokensSold + tokensSold_;
    _rounds[_activeRound].tokensSold = _rounds[_activeRound].tokensSold + tokensSold_;
    _balances[beneficiary_][_activeRound] = _balances[beneficiary_][_activeRound] + tokensSold_;    
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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
            return "0x00";
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
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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