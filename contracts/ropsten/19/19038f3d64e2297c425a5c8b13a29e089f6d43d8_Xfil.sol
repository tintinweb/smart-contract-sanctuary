/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


library AddressLib {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
    function notZero(address account) internal pure {
        require(account != address(0),"AddressLib: require account not Zero");
    }
    
}
library ECDSA {
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            revert("ECDSA: signature length is invalid");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: signature.s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: signature.v is in the wrong range");
        }
        return ecrecover(hash, v, r, s);
    }
}

library EnumerableSetLib {
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
        return _add(set._inner, bytes32(uint256(uint160(address(value)))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(address(value)))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(address(value)))));
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
        return address( uint160(uint256(_at(set._inner, index)) ));
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

library SafeERC20Lib {
    using SafeMathLib for uint256;
    using AddressLib for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20Lib: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data); // real/low-level call  implementation in this proxy lib
        require(success, "SafeERC20Lib: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20Lib: ERC20 operation did not succeed");
        }
    }
}

library SafeMathLib {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function notZero(uint256 amount) internal pure returns (uint256){
        require(amount > 0, "SafeMath: require amount > 0 ");
        return amount;
    }

    function notGt(uint256 amount, uint256 balance) internal pure returns (uint256){
        require(
            amount <= balance,
            "SafeMath: require amount not great than  balance"
        );
        return amount;
    }
    function notLt(uint256 amount, uint256 balance) internal pure returns (uint256){
        require(
            amount > balance,
            "SafeMath: require amount not less than  balance"
        );
        return amount;
    }
    function eq(uint256 oldAmount,uint newAmount) internal pure returns (uint256){
        require(oldAmount==newAmount,"SafeMath: require oldAmount equal to newAmount");
        return oldAmount;
    }
}

abstract contract ContextComp {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract ERC20DetailComp {
    // inner store
    string private p_name;
    string private p_symbol;
    uint8 private p_decimals;

    // in from child
    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal {
        p_name = _name;
        p_symbol = _symbol;
        p_decimals = _decimals;
    }

    // out
    function name() public view returns (string memory) {
        return p_name;
    }

    function symbol() public view returns (string memory) {
        return p_symbol;
    }

    function decimals() public view returns (uint8) {
        return p_decimals;
    }
}


abstract contract AccessControlComp is ContextComp {
    using EnumerableSetLib for EnumerableSetLib.AddressSet;
    using AddressLib for address;

    struct RoleData {
        EnumerableSetLib.AddressSet members;
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


contract Xfil is IERC20, ContextComp,ERC20DetailComp,AccessControlComp {
    /*
# inner-store:
  - decenetralized storage:
    - balance: how much money you had?
    - allowance: how much money the person or contract can spend from you?
    - total supply: state counts: 
  - event logs:

# in: send to it need pay eth coin
  - constractor
  - transfer
  - transferFrom
  - approve
  - mint
  - brun
# in-inner: 
  - _transfer: modify (_amount) the balances of _from, _to  by external/public method of this contact
  - _mint

# out: call to it no pay eth coin
  - get total supply from this contract to anybody
  - get balance of anyone from this contract to anybody
  - get allowance of holder had approve to spender from this contract to anybody
*/

    using SafeMathLib for uint256;
    using AddressLib for address;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // inner-store
    address public p_owner;         // ! owner address,control config set methods access
    address public p_mintAuthority; // ! mint auth address (hot)
    address public p_feeRecipient; //  ! fee Receive address (cold)

    
    uint256 public p_feeBIPS_denominator; // 10000 fee rate base
    uint256 public p_nextN; // mint or burn action sequence no
    uint256 public p_mintFeeBase;// 0 Fil
    uint256 public p_mintFeeBIPS; // ! 0

    uint256 public p_burnFeeBase; // 0.0000005 Fil
    uint256 public p_burnFeeBIPS; // ! 25
    uint256 public p_burnAmountMin ; // ! minimal burn amount 

    uint256 private p_totalSupply;

    mapping(address => uint256) private p_balances;
    mapping(address => mapping(address => uint256)) private p_allowances;
    mapping(bytes32 => bool) public p_mintHashStatus; // prevent double mint with same signature

    modifier onlyOwner() {
        require(_msgSender() == p_owner, "Ownable: caller is not the owner");
        _;
    }

    // out-event-logs
    event LogMint(address indexed _to,uint256 _amount_received,uint256 _amount_fee,uint256 indexed _n,bytes32 indexed _nHash);
    event LogBurn(bytes _toFilAddress,uint256 _amount_burned,uint256 _amount_fee,uint256 indexed _n,bytes indexed _indexedToFilAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // in
    constructor(address owner,address minter,address feeer,string memory _name,
        string memory _symbol,
        uint8 _decimals){
      p_owner = owner;
      p_mintAuthority = minter;
      p_feeRecipient = feeer;
      
      p_feeBIPS_denominator = 10000; // fee rate base
      p_mintFeeBase = 0;// 0 Fil
      p_mintFeeBIPS = 0; // ! 
      p_burnFeeBase = 500_000_000_000;// 0.0000005 Fil
      p_burnFeeBIPS = 25; // !
      p_burnAmountMin = 1_000_000_000_000_000;// 0.001 xFile
      p_totalSupply = 0;
      ERC20DetailComp.init(_name, _symbol, _decimals);

      _setupRole(OWNER_ROLE, p_owner);

      emit OwnershipTransferred(address(0), p_owner);
    }
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
      _transer(sender, recipient, amount);
      _approve(sender, recipient, p_allowances[sender][recipient].sub(amount,"ERC20: transfer amount exceeds allowance"));
      return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setMinterRole(address _minter) public {
        require(hasRole(OWNER_ROLE, _msgSender()), "not good");
         _setupRole(MINTER_ROLE, _minter);
    }

    function mint(address _to, uint256 _amount) public  {
        require(hasRole(MINTER_ROLE, _msgSender()), "not good");
        _mint(_to, _amount);
    }

    function mintWithSig(uint256 _amount,bytes32 _nHash,bytes memory _sig) external returns(uint256){
        address(_msgSender()).notZero();
        _amount.notLt(p_mintFeeBase);
        bytes32 _inputsHash = computeInputsHash(_msgSender(),_amount,_nHash);
        require(p_mintHashStatus[_inputsHash]==false,"Mint: nonce hash already spent");
        _verifySig(_inputsHash, _sig);

        uint256 amount_fee = _amount.mul(p_mintFeeBIPS).div(p_feeBIPS_denominator).add(p_mintFeeBase);
        uint256 amount_received =  _amount.sub(amount_fee,"Mint: fee exceeds amount");
        uint256 nextN = p_nextN;

        p_mintHashStatus[_inputsHash] = true;
        if(amount_fee>0){
            _mint(p_feeRecipient,amount_fee);
        }
        _mint(_msgSender(),amount_received);
        p_nextN += 1;

        emit LogMint(_msgSender(),amount_received,amount_fee,nextN,_nHash);

        return amount_received;
    }

    function burn(bytes memory _toFilAddress,uint256 _amount) external returns (uint256){
        // require(_toFilAddress.length==21 || _toFilAddress.length==49 ,"Burn: require file address is f1 with 21 bytes or f3 with 49 bytes");
        _amount.notLt(p_burnFeeBase).notLt(p_burnAmountMin).notGt(p_balances[_msgSender()]);

        uint256 amount_fee = _amount.mul(p_burnFeeBIPS).div(p_feeBIPS_denominator).add(p_burnFeeBase);
        uint256 amount_burn =  _amount.sub(amount_fee,"Burn: fee exceeds amount");
        uint256 nextN = p_nextN;

        _burn(_amount);
        if(amount_fee>0){
            _mint(p_feeRecipient,amount_fee);
        }
        p_nextN += 1;

        emit LogBurn(_toFilAddress,amount_burn,amount_fee,nextN,_toFilAddress);

        return amount_burn;
    }
    
    // in only from owner: update configs(mintAuthrityAddr,feeReceiveAddr,feeBase,feeBips,burnBips,burnAmountMin)
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    // in normal properties set
    function setMintAuthority(address mintAuthority) external onlyOwner{
        p_mintAuthority = mintAuthority;
    }
    function setFeeRecipient(address feeRecipient) external onlyOwner{
        p_feeRecipient = feeRecipient;
    }
    function setFeeBIPSDenominator(uint256 bipsDenominator) external onlyOwner{
        bipsDenominator.notLt(p_mintFeeBIPS);
        bipsDenominator.notLt(p_burnFeeBIPS);
        p_feeBIPS_denominator = bipsDenominator;
    }
    function setMintFeeBIPS(uint256 mintFeeBIPS) external onlyOwner{
        mintFeeBIPS.notLt(0);
        p_mintFeeBIPS = mintFeeBIPS;
    }
    function setBurnFeeBIPS(uint256 burnFeeBIPS) external onlyOwner{
        burnFeeBIPS.notLt(0);
        p_burnFeeBIPS = burnFeeBIPS;
    }
    function setMintFeeBase(uint256 mintFeeBase) external onlyOwner{
        mintFeeBase.notLt(0);
        p_mintFeeBase = mintFeeBase;
    }
    function setBurnFeeBase(uint256 burnFeeBase) external onlyOwner{
        burnFeeBase.notLt(0);
        p_burnFeeBase = burnFeeBase;
    }

    // in-inner
    
    function _verifySig(bytes32 _hash,bytes memory  _sig) private view {
        require(p_mintAuthority==ECDSA.recover(_hash, _sig),"Mint: signature error");
    }
    function _mint(address _to,uint256 _amount) private{
        _to.notZero();
        _amount.notZero();
        p_balances[_to] = p_balances[_to].add(_amount);

    }
    function _burn(uint256 _amount) private{
        _amount.notZero();
        p_balances[_msgSender()] = p_balances[_msgSender()].sub(_amount);
    }
    function _transer(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        _from.notZero();
        _to.notZero();
        _amount.notZero().notGt(p_balances[_from]);

        uint256 previousBalances = p_balances[_from].add(p_balances[_to]);
        p_balances[_from] = p_balances[_from].sub(_amount);
        p_balances[_to] = p_balances[_to].add(_amount);
        previousBalances.eq(p_balances[_from].add(p_balances[_to]));

        emit Transfer(_from, _to, _amount);
    }

    function _approve(
        address _holder,
        address _spender,
        uint256 _amount
    ) private {
        _holder.notZero();
        _spender.notZero();
        p_allowances[_holder][_spender] = _amount;
        emit Approval(_holder, _spender, _amount);
    }
    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(p_owner, newOwner);
        p_owner = newOwner;
    }
    

    // out
    function totalSupply() external view override returns (uint256) {
        return p_totalSupply;
    }

    function balanceOf(address _address)
        external
        view
        override
        returns (uint256)
    {
        return p_balances[_address];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return p_allowances[holder][spender];
    }
    // out pure: no read inner state ,just compute rule
    function computeInputsHash(address _to,uint256 _amountUnderling,bytes32 _nHash) public pure returns(bytes32 inputHash){
        inputHash = keccak256(abi.encode(_to,_amountUnderling,_nHash));
    }
}