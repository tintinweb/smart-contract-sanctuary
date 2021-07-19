//SourceUnit: AccessControl.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./EnumerableSet.sol";
// import "./Address.sol";
import "./Context.sol";

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
    // using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
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
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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


//SourceUnit: CompetitiveTokenSale.sol

pragma solidity 0.6.0;

import "./ReferralTree.sol";
// import "./StructuredLinkedList.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";
import "./Ownable.sol";
import "./TokenInfo.sol";

contract CompetitiveTokenSale is Ownable, TokenInfo {

  using SafeMath for uint;
  // using StructuredLinkedList for StructuredLinkedList.List;
  // using EnumerableSet for EnumerableSet.AddressSet;

  IReferralTree private _referralTree;
  ITRC20 _token;

  uint private _minTrxPrice;
  uint private _minTokenPrice;

  uint[] private _referralParts;

  uint private _survivalTimeInterval;

  uint private _lastBuyTimestamp;
  address private _lastBuyer;

  uint private _currentRound;

  uint private constant _percentBase = 100;
  uint private constant _bankShare = 50;
  uint private constant _adminShare = 50;

  uint private _saleRate;

  // EnumerableSet.AddressSet _currentParticipants;
  // EnumerableSet.AddressSet _allParticipants;

  uint _bank;
  uint _adminComission;
  // address _collector;

  mapping(address => mapping(uint => uint)) private _prize;
  mapping(address => mapping(uint => uint)) private _boughtTokens;

  event BankChanged(uint round, uint newValue);
  event ComissionCollected(uint amount);
  event Purchased(uint round, address user, uint trxPrice, uint tokenPrice, uint accrued);
  event PrizeCollected(address user, uint amount);
  event TokensCollected(address user, uint amount);
  event Winner(uint round, address user, uint amount);

  constructor(address token, address referralTree) public {
    require(token != address(0));
    require(referralTree != address(0));
    _referralTree = IReferralTree(referralTree);
    _token = ITRC20(token);
    _currentRound = 0;
    _bank = 0;
    // _collector = msg.sender;
  }

  modifier checkProportion(uint trxPrice, uint tokenPrice) {
    // trxPrice/minTrxPrice == tokenPrice/minTokenPrice
    require(
      // trxPrice.mul(_minTokenPrice) == tokenPrice.mul(_minTrxPrice)
      trxPrice.mul(10**6).div(_minTrxPrice) == tokenPrice.mul(10**6).div(_minTokenPrice)
      , "Prices in the wrong proportion");
    _;
  }

  modifier registeredUser() {
    require(_referralTree.isRegistered(msg.sender), "User is not registered");
    _;
  }

  function isStopped() public view returns(bool) {
    return block.timestamp > _lastBuyTimestamp + _survivalTimeInterval;
  }

  function stopTimestamp() public view returns(uint) {
    return _lastBuyTimestamp + _survivalTimeInterval;
  }

  // function timeLeft() public view returns(uint left, uint total) {
  //   left = isStopped() ? 0 : _lastBuyTimestamp + _survivalTimeInterval - block.timestamp;
  //   total = _survivalTimeInterval;
  // }

  function finalizeRound() private {
    uint value = _bank;
    address parent = _referralTree.parentOf(_lastBuyer);
    for (uint256 i = 0; i < _referralParts.length; i++) {
      uint part = _bank.mul(_referralParts[i]).div(_percentBase);
      if(_referralTree.isRegistered(parent)) {
        _prize[parent][_currentRound] = part;
        emit Winner(_currentRound, parent, part);
      } else {
        _adminComission = _adminComission.add(part);
      }
      value = value.sub(part);
      parent = _referralTree.parentOf(parent);
    }
    _prize[_lastBuyer][_currentRound] = value;
    emit Winner(_currentRound, _lastBuyer, value);
  }

  function startNewRound(uint trxPrice, uint tokenPrice, uint saleRate, uint survivalTime, uint[] calldata referralParts) external onlyOwner {
    require(isStopped(), "Round is running already");
    require(trxPrice > 0, "TRX price must be positive");
    require(tokenPrice > 0, "Token price must be positive");
    require(survivalTime > 0, "Survival time must be positive");
    require(saleRate > 0, "Sale rate must be positive");
    _lastBuyTimestamp = block.timestamp;
    _minTrxPrice = trxPrice;
    _minTokenPrice = tokenPrice;
    _survivalTimeInterval = survivalTime;
    _saleRate = saleRate;
    if(_bank > 0) finalizeRound();
    _referralParts = referralParts;
    _bank = 0;
    _currentRound++;
    emit BankChanged(_currentRound, 0);
  }

  function bankIncrease() external payable {
    _bank += msg.value;
    emit BankChanged(_currentRound, _bank);
  }

  function collect() external onlyOwner {
    require(_adminComission > 0, "Nothing to collect");
    payable(msg.sender).transfer(_adminComission);
    emit ComissionCollected(_adminComission);
    _adminComission = 0;
  }

  function buy(uint trxPrice, uint tokenPrice) external payable checkProportion(trxPrice, tokenPrice) registeredUser {
    require(!isStopped(), "Round is not started");
    require(msg.value == trxPrice, "TRX amount mismatch");
    require(trxPrice >= _minTrxPrice, "TRX price too low");
    require(tokenPrice >= _minTokenPrice, "Token price too low");
    _token.transferFrom(msg.sender, address(this), tokenPrice);
    uint sum = trxPrice.mul(_bankShare).div(_percentBase); // bank part
    _bank = _bank.add(sum);
    sum = trxPrice.sub(sum); // admin part
    _adminComission = _adminComission.add(sum);
    sum = trxPrice.mul(_saleRate).div(_percentBase);
    _boughtTokens[msg.sender][_currentRound] = _boughtTokens[msg.sender][_currentRound].add(sum);
    _lastBuyTimestamp = block.timestamp;
    _lastBuyer = msg.sender;
    emit BankChanged(_currentRound, _bank);
    emit Purchased(_currentRound, msg.sender, trxPrice, tokenPrice, sum);
  }

  function getPrizes() external {
    uint sum = prizeOf(msg.sender);
    require(sum > 0, 'No prizes');
    payable(msg.sender).transfer(sum);
    uint round = 1;
    while(round < _currentRound) _prize[msg.sender][round++] = 0;
    emit PrizeCollected(msg.sender, sum);
  }

  function getTokens() external {
    uint sum = availableTokensOf(msg.sender);
    require(sum > 0, "No available tokens");
    _token.transfer(msg.sender, sum);
    uint round = 1;
    while(round < _currentRound) _boughtTokens[msg.sender][round++] = 0;
    emit TokensCollected(msg.sender, sum);
  }

  function prices() public view returns (uint minTrxPrice, uint minTokenPrice) {
      minTrxPrice = _minTrxPrice;
      minTokenPrice = _minTokenPrice;
  }

  function referralParts() public view returns (uint[] memory) {
    return _referralParts;
  }

  function saleRate() public view returns(uint rate, uint base) {
    base = _percentBase;
    rate = _saleRate;
  }

  function frozenTokensOf(address buyer) public view returns(uint) {
    return _boughtTokens[buyer][_currentRound];
  }

  function availableTokensOf(address buyer) public view returns(uint available) {
    uint round = 1; available = 0;
    while(round < _currentRound)
      available += _boughtTokens[buyer][round++];
  }

  function prizeOf(address buyer) public view returns(uint prize) {
    uint round = 1; prize = 0;
    while(round < _currentRound)
      prize += _prize[buyer][round++];
  }

  function bank() public view returns(uint) {
    return _bank;
  }

  function currentRound() public view returns(uint) {
    return _currentRound;
  }

}

//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


//SourceUnit: ContractFriendship.sol

pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Ownable.sol";

contract ContractFriendship is Ownable, AccessControl {

  bytes32 public constant FRIENDLY_CONTRACT_ROLE = keccak256("FRIENDLY_CONTRACT_ROLE");

  constructor () internal
  {
    _setupRole(DEFAULT_ADMIN_ROLE, owner());
    _setRoleAdmin(FRIENDLY_CONTRACT_ROLE, DEFAULT_ADMIN_ROLE);
  }
  
  modifier onlyFriendlyContract()
  {
    require(isFriendlyContract(msg.sender), "Restricted to friendly contracts");
    _;
  }

  function isFriendlyContract(address account)
    public virtual view returns (bool)
  {
    return hasRole(FRIENDLY_CONTRACT_ROLE, account);
  }

  function addFriendlyContract(address account)
    public virtual onlyOwner
  {
    grantRole(FRIENDLY_CONTRACT_ROLE, account);
  }
  
  function removeFriendlyContract(address account)
    public virtual onlyOwner
  {
    revokeRole(FRIENDLY_CONTRACT_ROLE, account);
  }

}

//SourceUnit: EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//SourceUnit: ITRC20.sol

pragma solidity 0.6.0;

interface ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

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

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;
    uint96 private _;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}


//SourceUnit: ReferralTree.sol

pragma solidity 0.6.0;

import "./ContractFriendship.sol";

interface IReferralTree {
  function parentOf(address user) external view returns(address);
  // function idOf(address user) external view returns(uint256);
  function list() external view returns(address[] memory);
  function isRegistered(address user) external view returns(bool);
  function register(address child, address parent) external;  
}

contract ReferralTree is ContractFriendship {

  struct Node {
    uint96 id;
    address parent;
  }

  mapping(address => Node) private _nodes;
	address[] private _addresses;  

  event Registration(address child, address parent);
	
	function _add(address child, address parent) internal {
		require(isRegistered(parent), "Parent address is not registered");
		if(isRegistered(child)) return;
    _addresses.push(child);
		_nodes[child] = Node(uint96(_addresses.length), parent);
    emit Registration(child, parent);
	}  

	function isRegistered(address user) public view returns(bool) {
		return _nodes[user].id != 0;
	}  	

  function parentOf(address user) public view returns(address) {
		return _nodes[user].parent;
	}

  // function idOf(address user) public view returns(uint256) {
	// 	return uint256(_nodes[user].id);
	// }

  function externalRegister(address child, address parent) external onlyFriendlyContract {
    _add(child, parent);
  }

  function register(address parent) external {
    _add(msg.sender, parent);
  }

  function list() public view returns(address[] memory) {
		address[] memory results = new address[](_addresses.length);
		for (uint256 i = 0; i < _addresses.length; i++)
			results[i] = _addresses[i];
		return results;
	}

  function links() public view returns(address[2][] memory) {
		address[2][] memory results = new address[2][](_addresses.length);
		for (uint256 i = 0; i < _addresses.length; i++) {
			results[i][0] = _addresses[i];
      results[i][1] = parentOf(_addresses[i]);
    }
		return results;
	}

  constructor() public {
    _addresses.push(0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4); // TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
    _nodes[0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4] = Node(1, address(0));
    _add(0x6e51535175fe54cFBC8609B49f4A44E3174abB92, 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4); // TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
    _add(0xA6Bd32CBe694cDDe1ae31135366852F7449dD688, 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4); // TRAqpe4X2fxtrgV6cUzDQQ9FZW8148whcB => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
    _add(0x5F708E04c2B172eC6512144CF5CF8C0Eb3bB1B7A, 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4); // TJfr2izEGa7foFZw9WWRbWXuYNWqNCFMTt => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
    _add(0x716b5b8B12169dFe22210f7B49d4350AE8291C3C, 0x40c1FEd422126EA27400C9Ae894FCd016f76D8E4); // TLJuy58Wx88nmd2AMmcksPFYR8GJNmdPBk => TFsceNgCEvz6UWexuv3W145TvHKVjZ7fsn
    _add(0xb753Aa288F5076E7935804BFf1C3CaedC4D24f17, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TSgYtHetGy9HQuwsgkenidRd7gqPGjBY1W => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0xD2eF80f95F15305774AcfAC68415290719E057c4, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TVCXpMoczF2S6beRVpPw6u8JA6MM6CvsDr => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x0d6bFE30C32CC5463D1f2F980ebB0cc1E10F0f08, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TBCBA2t26KN9pGnruEtwuHvqS9dW6FFhpd => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0xEb61D050822Af2Ec1Be1F4157c74fd7B73e69aC6, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TXRnyMcLFsh8DMHpmjsdE6yKSAX8fvUPXL => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x28799942C53aadDAFc33D127B40ce97EFdADC4E1, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TGx1RtnvSwWFFJTCUBv4QtVhonDbiJuSo5 => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x9464191A13A7e43dC7Ee1deA6c6bDa8eEE2B167b, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TPVpvPG9zKPA1TGWKLdY2i9SXN8F7yVZXu => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0xe3A1FBd153FFb6Ba4371763C1Bb6C7bc9B2DBe63, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TWipSRhhmaA8TUnGHAgbkuMPiZTCUfb2AN => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x54346bAbfcfd3295B93A84dF5b979A87f75Bb846, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // THeSZRHAY34b9KYwxcmhVxZwh9L7riaWan => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0xE7A87Af6b84CB5e3815393E57661b16De4041275, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TX66vbBcvTxwxQPALd3vXLUxw8DZNQvwhD => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0xD53140D111b57F4C676Cc728E00Bb10F63dfC950, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TVQTw6Cn6HgQ3d5RHiH4cioSsHH8oQgruz => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TJTugUKoA4QnNUZx1VKTETo54hvgjEJa5t => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0xa093C0936F100635D7aE0C15f8Cb30a66F9384Da, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TQcG7kvfUcurNnX7Ug3gP6QnvdHALX5uPG => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0x8385a9DA4Eef33CC94bA00aF84F50113c9a29fB9, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TMxdeHpArwkhaw9dNj7FaQ2RphAjaLWXDc => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0x51685a90eDc84e86515B44093f64b9a28A8C57d0, 0xD53140D111b57F4C676Cc728E00Bb10F63dfC950); // THPekDymc87NtjttjPPHGFtXozFiLob9WD => TVQTw6Cn6HgQ3d5RHiH4cioSsHH8oQgruz
    _add(0x74b862277FF9a1067376B601aadD0e5cBaE17a46, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TLcNGVhVf3sCxnE1NmVnvRZAWfwUXJJzYn => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x04E3D97F90BD6eaD52Fe50678FDbbF56E1dF93E5, 0x6e51535175fe54cFBC8609B49f4A44E3174abB92); // TAR4f6RM1N7qQ7c2ED1JyeAnzu3iyXkVLh => TL2WkkbdKTsfdPbn3gjuE4x1SSBQ6XZMwo
    _add(0x5953Ad26dc84ab19f1DFA73d1a55040Ce4A09a32, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TJ7XP4v4Pv1dv2ozD5raYgNH7iCuZkEY8G => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0x6a656A13Fe75F23d96be7D485e2066662Ede7882, 0x5d2E9C5b0fC970d94b41998CA99aEf7922b841bd); // TKfn7nb6kL9iXqjLKzrWH9VEAbAKxfFnky => TJTugUKoA4QnNUZx1VKTETo54hvgjEJa5t
    _add(0xE600AE2F7D2EE5fd021CE043A0e276949B228B93, 0x28799942C53aadDAFc33D127B40ce97EFdADC4E1); // TWwMETPmFKUjfXujTgyaY5NEZS5oBssfMS => TDfDhZDaNB4mD7Gi7rJXpronqrs4BuLitf
    _add(0x7E0E49f23E59228aaae1b1747FD8327C3B39259e, 0x4C8eCe0B58Ec878DbDa21Aa58c93f476DD31cEB1); // TMTjG356H2LHBcSH5z9CbVVJCXwB74PWe9 => TGx1RtnvSwWFFJTCUBv4QtVhonDbiJuSo5
    _add(0x8F121849f09DCc7D492530F92d30605F89768DbC, 0x7E0E49f23E59228aaae1b1747FD8327C3B39259e); // TP1hJkACV3qE65oVxn4qLu7JUiJMHHsCXX => TMTjG356H2LHBcSH5z9CbVVJCXwB74PWe9
    _add(0x03c169C19521C003CBf97321984eA210497900be, 0x8F121849f09DCc7D492530F92d30605F89768DbC); // TAK4jDJhLsoeAMRb9JFDCJus9rE7xCsyH7 => TP1hJkACV3qE65oVxn4qLu7JUiJMHHsCXX
  }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TokenInfo.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";

contract TokenInfo {
  function _tokenInfo(ITRC20 token) internal view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    name = token.name();
    symbol = token.symbol();
    decimals = token.decimals();
    tokenAddress = address(token);
  }
}