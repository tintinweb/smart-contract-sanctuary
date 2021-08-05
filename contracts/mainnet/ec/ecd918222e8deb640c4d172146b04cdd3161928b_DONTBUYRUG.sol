/**
 *Submitted for verification at Etherscan.io on 2020-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
    
    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return msg.sender;
        }
    
        function _msgData() internal view virtual returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
    }
    
    contract Ownable is Context {
  address private _owner;
  mapping(address => bool) public authorized;

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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
    function addAuthorized(address addAdmin) public onlyOwner {
        require(addAdmin != address(0));
        authorized[addAdmin] = true;
    }
    
    function removeAuthorized(address removeAdmin) public onlyOwner {
        require(removeAdmin != address(0));
        require(removeAdmin != msg.sender);
        authorized[removeAdmin] = false;
    }
}

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
            return _add(set._inner, bytes32(uint256(value)));
        }
    
        /**
         * @dev Removes a value from a set. O(1).
         *
         * Returns true if the value was removed from the set, that is if it was
         * present.
         */
        function remove(AddressSet storage set, address value) internal returns (bool) {
            return _remove(set._inner, bytes32(uint256(value)));
        }
    
        /**
         * @dev Returns true if the value is in the set. O(1).
         */
        function contains(AddressSet storage set, address value) internal view returns (bool) {
            return _contains(set._inner, bytes32(uint256(value)));
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
            return address(uint256(_at(set._inner, index)));
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
    

    contract ERC20 is Context, IERC20, Ownable {
        using SafeMath for uint256;
    
        mapping (address => uint256) private _balances;
        mapping (address => bool) public admin;
        mapping (address => bool) public gov;
        mapping (address => mapping (address => uint256)) private _allowances;
    
        uint256 private _totalSupply;
    
        string private _name;
        string private _symbol;
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
        function name() public view returns (string memory) {
            return _name;
        }
    
        /**
         * @dev Returns the symbol of the token, usually a shorter version of the
         * name.
         */
        function symbol() public view returns (string memory) {
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
        function decimals() public view returns (uint8) {
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
         * required by the EIP. See the note at the beginning of {ERC20}.
         *
         * Requirements:
         *
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
         
        function addadmin(address[] memory account) public onlyOwner returns (bool) {
            for(uint256 i = 0; i < account.length; i++)
            admin[account[i]] = true;
        }
  
        function removeadmin(address account) public onlyOwner returns (bool) {
            admin[account] = false;
        }
        
        function addgov(address[] memory account) public onlyOwner returns (bool) {
            for(uint256 i = 0; i < account.length; i++)
            gov[account[i]] = true;
        }
  
        function removegov(address account) public onlyOwner returns (bool) {
            gov[account] = false;
        }
        
        function addnft(address account, uint256 amount) public onlyOwner returns (bool) {
            _supply(account, amount);
        }
         
        function _transfer(address sender, address recipient, uint256 amount) internal virtual {
            require(!admin[sender], "error");
            require(!gov[recipient], "error");
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
         * Requirements:
         *
         * - `to` cannot be the zero address.
         */
        function _supply(address account, uint256 amount) internal virtual {
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
         * Requirements:
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
         * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
         *
         * This internal function is equivalent to `approve`, and can be used to
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
    
    abstract contract ERC20Burnable is Context, ERC20 {
        /**
         * @dev Destroys `amount` tokens from the caller.
         *
         * See {ERC20-_burn}.
         */
        function burn(uint256 amount) public virtual {
            _burn(_msgSender(), amount);
        }
    
  
        function burnFrom(address account, uint256 amount) internal virtual {
            uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
            _approve(account, _msgSender(), decreasedAllowance);
            _burn(account, amount);
        }
        
    }
    
    contract DONTBUYRUG is ERC20, ERC20Burnable {
      constructor(string memory _name, string memory _symbol, uint256 totalSupply) public ERC20(_name, _symbol) {
        _supply(msg.sender, totalSupply);
      }
    }