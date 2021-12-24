/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;		
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)public virtual override returns (bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }
	function allowance(address owner, address spender)public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }
	function approve(address spender, uint256 amount) public virtual override returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }
	function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender].add(addedValue));
        return true;
    }
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }
	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	function mint(uint amount) public returns (bool){
		_mint(msg.sender,amount);
		return true;
	}
	function burn(uint amount) public returns (bool){
		_burn(msg.sender,amount);
		return true;
	}
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount,"ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual {}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success,"Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data)internal returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
	function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data,value,"Address: low-level call with value failed");
    }
	function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) =target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data)internal view returns (bytes memory){
        return functionStaticCall(target,data,"Address: low-level static call failed");
    }
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data)internal returns (bytes memory){
        return functionDelegateCall(target,data,"Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token,address spender,uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token,abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance =token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token,abi.encodeWithSelector(token.approve.selector,spender,newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance =token.allowance(address(this), spender).sub(value,"SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token,abi.encodeWithSelector(token.approve.selector,spender,newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
		bytes memory returndata = address(token).functionCall(data,"SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)),"SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
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
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
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

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
abstract contract Ownable  {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol";
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}



contract AutoFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebtBUST; // Reward debt. See explanation below.
        uint256 rewardDebtBNB;
        // We do some fancy math here. Basically, any point in time, the amount of BUST
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (amount * pool.accBUSTPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accBUSTPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. BUST to distribute per block.
        uint256 lastRewardBlock; // Last block number that BUST distribution occurs.
        uint256 accBUSTPerShare; // Accumulated BUST per share, times 1e12. See below.
        uint256 accBNBPerShare;// // Accumulated BNB per share, times 1e12. See below.
        address strat; // Strategy address that will auto compound want tokens
    }
    address public daoAddress;  
    address public stkAddress;
    address public rewardPool;
    uint public lastRPBlock ;
    
    uint public rPInterval;
    uint public defaultRewardValue=0;
    uint public defaultRewardValueBNB=0;
    address public BUST = 0xfD0507faC1152faF870C778ff6beb1cA3B9f7A1F;
    address public BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public fundSourceBNB; //source of BUST tokens to pull from
    address public fundSourceBUST;////source of BNB tokens to pull from

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    //initialize at zero and update later
    uint256 public BUSTPerBlock = 0; // BUST tokens distributed per block
    uint256 public BNBPerBlock= 0;//// BNB tokens distributed per block
    
    uint DENOMINATOR=10000;
    uint public dao=100;
    uint public poolRewardPercentage=9500;


    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event PendingRewardsBUST(address indexed user,uint256 indexed pid,uint256 amount);
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    constructor( address _daoAddress, uint _daopercentage, address _rewardPool, uint256 _poolRewardPercentage, address _stkAddress,  uint _BNBPerBlock, uint _BUSTPerBlock, address _fundSourceBNB,  address _fundSourceBUST, uint _lastRPBlock, uint _rPInterval) public {       
    
          daoAddress= _daoAddress;
          dao = _daopercentage;
          rewardPool = _rewardPool;
          poolRewardPercentage=_poolRewardPercentage;
          stkAddress = _stkAddress;
          BNBPerBlock = _BNBPerBlock;
          defaultRewardValueBNB = _BNBPerBlock;
          BUSTPerBlock = _BUSTPerBlock;
          defaultRewardValue = _BUSTPerBlock;
          fundSourceBNB = _fundSourceBNB;
          fundSourceBUST = _fundSourceBUST;
          lastRPBlock = _lastRPBlock;
          rPInterval = _rPInterval;
            
        // bankroll , setBankRollPercentage, BNBPerBlock, BUSTPerBlock, daoAddress, setDAOPercentage, fundSourceBUST, fundSourceBNB, lastRPBlock, rewardPool, rewardpoolpercent, rPInterval, stkAddress
    }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. (Only if want tokens are stored here.)

    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBUSTPerShare: 0,
                accBNBPerShare:0,
                strat: _strat
            })
        );
    }

    // Update the given pool's BUST allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }
    
    

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending BUST on frontend.
    function pendingBUST(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBUSTPerShare = pool.accBUSTPerShare;
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BUSTReward =
                multiplier.mul(BUSTPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            
            accBUSTPerShare = accBUSTPerShare.add(
                BUSTReward.mul(1e12).div(sharesTotal)
            );

            uint userReward=user.shares.mul(accBUSTPerShare).div(1e12).sub(user.rewardDebtBUST);

            uint reReward = userReward.mul(poolRewardPercentage).div(DENOMINATOR);
            uint daoReward=reReward.mul(dao).div(DENOMINATOR);
            reReward=reReward.sub(daoReward);
            return reReward;
        }
        return user.shares.mul(accBUSTPerShare).div(1e12).sub(user.rewardDebtBUST);
    }
        //  View function to see pending BUST on frontend.

    function pendingBNB(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBNBPerShare = pool.accBNBPerShare;
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 BNBReward =
                multiplier.mul(BNBPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );

             accBNBPerShare = accBNBPerShare.add(
                BNBReward.mul(1e12).div(sharesTotal)
            );
            uint userReward=user.shares.mul(accBNBPerShare).div(1e12).sub(user.rewardDebtBNB);
                
           
            uint daoReward=userReward.mul(dao).div(DENOMINATOR);
            userReward=userReward.sub(daoReward); 
               
            return userReward;
        }
        return user.shares.mul(accBNBPerShare).div(1e12).sub(user.rewardDebtBNB);
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(wantLockedTotal).div(sharesTotal);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }

        uint256 BUSTReward =
            multiplier.mul(BUSTPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            
         uint256 BNBReward=
             multiplier.mul(BNBPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );      

        getBUST(BUSTReward);
        getBNB(BNBReward);

        pool.accBUSTPerShare = pool.accBUSTPerShare.add(
            BUSTReward.mul(1e12).div(sharesTotal)
        );
        
        pool.accBNBPerShare = pool.accBNBPerShare.add(
            BNBReward.mul(1e12).div(sharesTotal)
        );
        pool.lastRewardBlock = block.number;

    }

    function _updateRewardPerBlock() internal{
         // auto calculate

        if(lastRPBlock.add(rPInterval) < block.number){
            
            uint rewardGenerated = IERC20(BUST).balanceOf(rewardPool);
            uint rewardGeneratedBNB = IERC20(BNB).balanceOf(rewardPool);
            
            uint increment = rewardGenerated.div(rPInterval);
            uint incrementBNB = rewardGeneratedBNB.div(rPInterval);
            
                if(increment > 0){
                BUSTPerBlock = defaultRewardValue.add(increment);
                IERC20(BUST).transferFrom(rewardPool, fundSourceBUST, rewardGenerated);
               
                }
                else{
                    BUSTPerBlock = defaultRewardValue;
                }
                
                if(incrementBNB > 0){
                BNBPerBlock = defaultRewardValueBNB.add(incrementBNB);
                IERC20(BNB).transferFrom(rewardPool, fundSourceBNB, rewardGeneratedBNB);
                }
                else{
                    BNBPerBlock = defaultRewardValueBNB;
                }
                
            lastRPBlock=block.number;
            
            
        }
        

    }




    // Want tokens moved from user -> BUSTFarm (BUST allocation) -> Strat (compounding)
    function deposit(uint256 _pid, uint256 _wantAmt) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.shares > 0) {
            uint256 pendingBUSTD =
                user.shares.mul(pool.accBUSTPerShare).div(1e12).sub(
                    user.rewardDebtBUST
                );
                
                
            uint256 pendingBNBD =
                user.shares.mul(pool.accBNBPerShare).div(1e12).sub(
                    user.rewardDebtBNB
                );
                
            if (pendingBUSTD > 0) {
                uint poolRewardPart=pendingBUSTD.mul(poolRewardPercentage).div(DENOMINATOR);
                uint stakeRewardPart=pendingBUSTD.mul(DENOMINATOR.sub(poolRewardPercentage)).div(DENOMINATOR);
                uint daoReward=poolRewardPart.mul(dao).div(DENOMINATOR);
                poolRewardPart=poolRewardPart.sub(daoReward);
                safeBUSTTransfer(msg.sender,poolRewardPart);
                safeBUSTTransfer(daoAddress,daoReward);
                safeBUSTTransfer(stkAddress, stakeRewardPart);
                emit PendingRewardsBUST(msg.sender, _pid, pendingBUSTD);
            }
            
            if (pendingBNBD > 0) {
                uint daoReward=pendingBNBD.mul(dao).div(DENOMINATOR);
                pendingBNBD=pendingBNBD.sub(daoReward);
                safeBNBTransfer(msg.sender, pendingBNBD);
                safeBNBTransfer(daoAddress,daoReward);
                
            }
        }
        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded =
                IStrategy(poolInfo[_pid].strat).deposit(msg.sender, _wantAmt);
            user.shares = user.shares.add(sharesAdded);
        }
        user.rewardDebtBUST = user.shares.mul(pool.accBUSTPerShare).div(1e12);
        user.rewardDebtBNB = user.shares.mul(pool.accBNBPerShare).div(1e12);


        _updateRewardPerBlock();
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // Withdraw pending BUST
        uint256 pendingBUSTW =
            user.shares.mul(pool.accBUSTPerShare).div(1e12).sub(
                user.rewardDebtBUST
            );
            
        uint256 pendingBNBW =
            user.shares.mul(pool.accBNBPerShare).div(1e12).sub(
                user.rewardDebtBNB
            );
        if (pendingBUSTW > 0) {
                uint poolRewardPart=pendingBUSTW.mul(poolRewardPercentage).div(DENOMINATOR);
                uint stakeRewardPart=pendingBUSTW.mul(DENOMINATOR.sub(poolRewardPercentage)).div(DENOMINATOR);
                uint daoReward=poolRewardPart.mul(dao).div(DENOMINATOR);
                poolRewardPart=poolRewardPart.sub(daoReward);
                safeBUSTTransfer(msg.sender,poolRewardPart);
                safeBUSTTransfer(daoAddress,daoReward);
                safeBUSTTransfer(stkAddress, stakeRewardPart);
                emit PendingRewardsBUST(msg.sender, _pid, pendingBUSTW);
            }
            
        if (pendingBNBW > 0) {
                uint daoReward=pendingBNBW.mul(dao).div(DENOMINATOR);
                pendingBNBW=pendingBNBW.sub(daoReward);
                safeBNBTransfer(msg.sender, pendingBNBW);
                safeBNBTransfer(daoAddress,daoReward);
            }

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved =
                IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebtBUST = user.shares.mul(pool.accBUSTPerShare).div(1e12);
        user.rewardDebtBNB = user.shares.mul(pool.accBNBPerShare).div(1e12);
        _updateRewardPerBlock();
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) public {
        withdraw(_pid, uint256(-1));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
            IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, amount);

        pool.want.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        user.shares = 0;
        user.rewardDebtBUST = 0;
        user.rewardDebtBNB = 0;
    }

    // Safe BUST transfer function, just in case if rounding error causes pool to not have enough
    function safeBUSTTransfer(address _to, uint256 _BUSTAmt) internal {
        uint256 BUSTBal = IERC20(BUST).balanceOf(address(this));
        if (_BUSTAmt > BUSTBal) {
            IERC20(BUST).transfer(_to, BUSTBal);
        } else {
            IERC20(BUST).transfer(_to, _BUSTAmt);
        }
    }
    
    // Safe BNB transfer function, just in case if rounding error causes pool to not have enough

    function safeBNBTransfer(address _to, uint256 _BNBAmt) internal {
        uint256 BNBBal = IERC20(BNB).balanceOf(address(this));
        if (_BNBAmt > BNBBal) {
            IERC20(BNB).transfer(_to, BNBBal);
        } else {
            IERC20(BNB).transfer(_to, _BNBAmt);
        }
    }

    //gets BUST for distribution from external address
    function getBUST(uint256 _BUSTAmt) internal {
        IERC20(BUST).transferFrom(fundSourceBUST, address(this), _BUSTAmt);
    }
    //gets BNB for distribution from external address
    function getBNB(uint256 _BNBAmt) internal {
        IERC20(BNB).transferFrom(fundSourceBNB, address(this), _BNBAmt);
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount)
        external
        onlyOwner
    {
        require(_token != BUST, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function setBUSTPerBlock(uint _BUSTPerBlock) external onlyOwner {
        BUSTPerBlock = _BUSTPerBlock;
        defaultRewardValue = _BUSTPerBlock;
    }
    
    function setBNBPerBlock(uint _BNBPerBlock) external onlyOwner {
        BNBPerBlock = _BNBPerBlock;
        defaultRewardValueBNB = _BNBPerBlock;
    }
    
    function setFundSourceBNB(address _fundSourceBNB) external onlyOwner {
        fundSourceBNB = _fundSourceBNB;
    }
    
    function setFundSourceBUST(address _fundSourceBUST) external onlyOwner {
        fundSourceBUST = _fundSourceBUST;
    }
    
    function setStkAddress(address _stkAddress) external onlyOwner {
        stkAddress = _stkAddress;
    }
    
    function setDaokAddress(address _daoAddress) external onlyOwner{
        daoAddress= _daoAddress;
    }
    
    
    
    function setRewardPool(address _rewardPool) external onlyOwner {
        rewardPool = _rewardPool;
    }

    function setLastRPBlock(uint _lastRPBlock) external onlyOwner {
        lastRPBlock = _lastRPBlock;
    }

    function setRPInterval(uint _rPInterval) external onlyOwner {
        rPInterval = _rPInterval;
    }

    
    function setDAOPercentage(uint _percentage)external onlyOwner{
        require(_percentage<DENOMINATOR, "should be less");
        dao=_percentage;
    }
    
    function setPoolRewardPercentage(uint256 _poolRewardPercentage) external onlyOwner{
        require(_poolRewardPercentage<=DENOMINATOR, "should be less than or equal too");
        poolRewardPercentage=_poolRewardPercentage;
    }
    


}

contract DarkPool is Ownable {

    address public BUST = 0xfD0507faC1152faF870C778ff6beb1cA3B9f7A1F;

    constructor(address _JPOW) public {
        IERC20(BUST).approve(_JPOW, uint256(-1));
    }

    function transferERC20(address _token, address _receiver, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_receiver, _amount);
    }

}

// bankroll , setBankRollPercentage, BNBPerBlock, BUSTPerBlock, daoAddress, setDAOPercentage, fundSourceBUST, fundSourceBNB, lastRPBlock, rewardPool, rewardpoolpercent, rPInterval, stkAddress