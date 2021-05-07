/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.6.3;



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
abstract contract Ownable is Context {
    address private _owner;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Destructor is Ownable {
    bool public destructing;

    modifier onlyBeforeDestruct() {
        require(!destructing, "pre destory...");
        _;
    }

    modifier onlyDestructing() {
        require(destructing, "destorying...");
        _;
    }

    function preDestruct() onlyOwner onlyBeforeDestruct public {
        destructing = true;
    }

    function destructERC20(address _erc20, uint256 _amount) onlyOwner onlyDestructing public {
        if (_amount == 0) {
            _amount = IERC20(_erc20).balanceOf(address(this));
        }
        require(_amount > 0, "check balance");
        IERC20(_erc20).transfer(owner(), _amount);
    }

    function destory() onlyOwner onlyDestructing public {
        selfdestruct(address(uint160(owner())));
    }
}

abstract contract Operable is Ownable {
    address public operator;

    event OperatorUpdated(address indexed previous, address indexed newOperator);
    constructor(address _operator) public {
        if (_operator == address(0)) {
            operator = msg.sender;
        } else {
            operator = _operator;
        }
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "Operable: caller is not the operator");
        _;
    }

    function updateOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "Operable: new operator is the zero address");
        emit OperatorUpdated(operator, newOperator);
        operator = newOperator;
    }
}

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

interface Mintable {
    function mint(address account, uint256 amount) external returns (bool);
}

interface IMintProxy {
    function mint(address account, uint256 amount, uint8 tp) external returns (bool);
}

contract TmpMintProxy is IMintProxy, Operable, Destructor {
    using SafeERC20 for IERC20;

    event Mint(address indexed user, uint8 indexed tp, uint256 amount);

    IERC20 public token;

    constructor(IERC20 _token) Operable(address(0)) public {
        token = _token;
    }

    // mint for deposit lp token
    function mint(address account, uint256 amount, uint8 tp) onlyOperator onlyBeforeDestruct override public returns (bool){
        require(account != address(0), "mint to the zero address");
        IERC20(token).safeTransfer(account, amount);
        emit Mint(account, tp, amount);
        return true;
    }
}

abstract contract Reward is Ownable {
    using SafeMath for uint256;
    uint256 private dayRewardAmount;

    mapping(address => uint256) rewardDetails;
    address[] rewardAddr;

    uint32 public lastMintDayTime;
    uint32 public units;

    event Mint(uint32 time, uint256 amount);

    constructor() public {
        units = 86400;
    }

    function updateUnits(uint32 _units) onlyOwner public{
        units = _units;
    }

    // update lastDayTime
    function refreshMintDay() internal returns(uint16)  {
        uint32 _units = units;
        uint32 _dayTime = ( uint32(now) / _units ) * _units;
        require(_dayTime>lastMintDayTime, "day time check");
        lastMintDayTime = _dayTime;
    }

    function clearReward() private {
        uint _addrsLength = rewardAddr.length;
        for (uint i=0; i< _addrsLength; i++) {
            delete rewardDetails[rewardAddr[i]];
        }
        delete rewardAddr;
    }

    function mint() internal {
        // clear reward
        clearReward();

        address[] memory _addrs;
        uint256[] memory _amounts;
        uint256 _total;
        (_addrs, _amounts, _total) = mintInfo();

        require(_addrs.length == _amounts.length, "check length");
        require(_total > 0, "check total");

        uint256 _rewardAmount = getRewardAmount();

        uint _addrsLength = _addrs.length;
        for (uint i=0; i< _addrsLength; i++) {
            require(_addrs[i]!=address(0), "check address");
            require(_amounts[i]>0, "check amount");

            rewardDetails[_addrs[i]] = _amounts[i].mul(_rewardAmount).div(_total);
            rewardAddr.push(_addrs[i]);
        }

        emit Mint(lastMintDayTime, _rewardAmount);
    }

    function withdraw() public {
        uint256 _amount = rewardDetails[msg.sender];
        require(_amount>0, "check reward amount");
        // clear
        rewardDetails[msg.sender] = 0;

        transferTo(msg.sender, _amount);
    }

    function myReward(address addr) public view returns(uint256){
        return rewardDetails[addr];
    }

    function withdrawInfo() public view returns(uint32, address[] memory,  uint256[] memory, uint256) {
        uint256[] memory _amounts = new uint256[](rewardAddr.length);
        uint256 _total = 0;
        uint _arrLength = rewardAddr.length;
        for (uint i=0; i< _arrLength; i++) {
            uint256 amount = rewardDetails[rewardAddr[i]];
            _total = _total.add(amount);
            _amounts[i] = amount;
        }
        return (lastMintDayTime, rewardAddr, _amounts, _total);
    }

    function transferTo(address _to, uint256 _amount) internal virtual;
    function getRewardAmount() public view virtual returns (uint256);
    function mintInfo() public view virtual returns(address[] memory,  uint256[] memory, uint256);
}

abstract contract RewardERC20 is Reward {
    uint256 private dayRewardAmount;
    address public rewardToken;

    constructor(address _rewardToken, uint256 _dayRewardAmount) public {
        dayRewardAmount = _dayRewardAmount;
        rewardToken = _rewardToken;
    }

    function updateRewardAmount(uint256 _amount) onlyOwner public {
        dayRewardAmount = _amount;
    }

    function getRewardAmount() public view override returns (uint256) {
        return dayRewardAmount;
    }


    function transferTo(address _to, uint256 _amount) internal override {
        // transfer erc20 token
        IERC20(rewardToken).transfer(_to, _amount);
    }
}

interface ILiquidity {
    function emitJoin(address _taker, uint256 _ethVal) external;
}

contract LiquidityStats is Ownable {
    using SafeMath for uint256;

    mapping(address=>uint8) public factoryOwnerMap;
    address public clearOwner;

    mapping ( address => uint256 ) public takerValueMap;
    address[] public takerArr;

    uint256 public threshold;

    constructor(address[] memory _factorys, uint256 _threshold) public {
        uint _arrLength = _factorys.length;
        for (uint i=0; i< _arrLength; i++) {
            factoryOwnerMap[_factorys[i]] = 1;
        }
        threshold = _threshold;
    }

    function updateFactoryOwner(address[] memory _addrs, uint8[] memory _vals) onlyOwner public {
        uint _arrLength = _addrs.length;
        for (uint i=0; i< _arrLength; i++) {
            factoryOwnerMap[_addrs[i]] = _vals[i];
        }
    }

    function updateThreshold(uint256 _threshold) onlyOwner public {
        threshold = _threshold;
    }

    function updateClearOwner(address _addr) onlyOwner public {
        clearOwner = _addr;
    }

    function emitJoin(address _taker, uint256 _ethVal) public {
        require(factoryOwnerMap[msg.sender]>0, "factory address check");
        if(_ethVal>=threshold){
            uint256 prev = takerValueMap[_taker];
            if (prev == 0) {
                takerArr.push(_taker);
            }
            takerValueMap[_taker] = prev.add(1);
        }
    }

    function clear() public {
        require(msg.sender == clearOwner, "clear owner address check");

        uint _arrLength = takerArr.length;
        for (uint i=0; i< _arrLength; i++) {
            delete takerValueMap[takerArr[i]];
        }
        delete takerArr;
    }

    function stats() public view returns(address[] memory,  uint256[] memory, uint256) {
        uint256[] memory _amounts = new uint256[](takerArr.length);
        uint256 _total = 0;
        uint _arrLength = takerArr.length;
        for (uint i=0; i< _arrLength; i++) {
            uint256 amount = takerValueMap[takerArr[i]];
            _total = _total.add(amount);
            _amounts[i] = amount;
        }
        return (takerArr, _amounts, _total);
    }
}

interface IStats {
    function stats() external view returns(address[] memory,  uint256[] memory, uint256);
    function clear() external;
}

contract LiquidityMiner is Operable, RewardERC20, Destructor {
    address public liquidityStatsAddr;

    constructor(address _rewardToken, uint256 _dayRewardAmount, address _statsAddr, address _operatorAddr) Operable(_operatorAddr) RewardERC20(_rewardToken,_dayRewardAmount) public {
        liquidityStatsAddr = _statsAddr;
    }

    function updateStatsAddr(address _addr) onlyOwner public {
        require(_addr!=liquidityStatsAddr, "check stats address");
        require(_addr!=address(0), "check stats address 0");
        liquidityStatsAddr = _addr;
    }

    function liquidityMint() onlyOperator onlyBeforeDestruct public{
        // mint
        mint();
        // clear
        IStats(liquidityStatsAddr).clear();
    }

    function mintInfo() public view override returns(address[] memory,  uint256[] memory, uint256) {
        return IStats(liquidityStatsAddr).stats();
    }
}

interface IStaking {
    function hastaked(address _who) external returns(bool);
    function stats() external view returns(address[] memory,  uint256[] memory, uint256);
    function clear() external;
}

interface IFee {
    function emitFee(address _addr, uint256 _ethVal) payable external;
}

contract FeeStats {
    event Fee(address _addr, uint256 _ethVal);
    function emitFee(address _addr, uint256 _ethVal) payable public {
        require(_ethVal==msg.value, "fee value");
        emit Fee(_addr, _ethVal);
    }
}

interface Events {
    event CreatePool(uint32 indexed id, address indexed maker, bool priv, address tracker, uint256 amount, uint256 rate, uint256 units);
    event Join(uint32 indexed id, address indexed taker, bool priv, uint256 ethAmount, address tracker, uint256 amount);
    event Withdraw(uint32 indexed id, address indexed sender, uint256 amount, uint32 tp);
    event Close(uint32 indexed id, bool priv);
}

contract AbstractFactory is Ownable {
    address public liquidtyAddr;
    address public stakeAddr;
    address public feeAddr;
    uint32 public constant takerFeeBase = 100000;
    uint32 public takerFeeRate;
    uint256 public makerFixedFee;

    constructor() public {
        takerFeeRate = 0;
        makerFixedFee = 0;
    }

    modifier makerFee() {
        if(makerFixedFee>0) {
            require(msg.value >= makerFixedFee, "check maker fee, fee must be le value");
            require(feeAddr!=address(0), "check fee address, fail");

            // transfer fee to owner
            IFee(feeAddr).emitFee{value:makerFixedFee}(msg.sender, makerFixedFee);
        }
        _;
    }

    modifier takerFee(uint256 _value) {
        require(_value>0, "check taker value, value must be gt 0");
        uint256 _fee = 0;
        if(takerFeeRate>0){
            _fee = _value * takerFeeRate / takerFeeBase;
            require(_fee > 0, "check taker fee, fee must be gt 0");
            require(_fee < _value, "check taker fee, fee must be le value");
            require(feeAddr!=address(0), "check fee address, fail");

            // transfer fee to owner
            IFee(feeAddr).emitFee{value:_fee}(msg.sender, _fee);
        }
        require(_value+_fee<=msg.value,"check taker fee and value, total must be le value");
        _;
    }

    function joinPoolAfter(address _taker, uint256 _ethVal) internal {
        if(liquidtyAddr!=address(0)){
            ILiquidity(liquidtyAddr).emitJoin(_taker, _ethVal);
        }
    }
    function updateTakerFeeRate(uint32 _rate) public onlyOwner {
        takerFeeRate = _rate;
    }
    function updateMakerFee(uint256 _fee) public onlyOwner {
        makerFixedFee = _fee;
    }
    function updateFeeAddr(address _addr) public onlyOwner {
        feeAddr = _addr;
    }
    function updateLiquidityAddr(address _addr) public onlyOwner {
        liquidtyAddr = _addr;
    }
    function updateStakeAddr(address _addr) public onlyOwner {
        stakeAddr = _addr;
    }
    function hastaked(address _who) internal returns(bool) {
        if(stakeAddr==address(0)){
            return true;
        }
        return IStaking(stakeAddr).hastaked(_who);
    }
}

contract FixedPoolFactory is Events, AbstractFactory, Destructor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct FixedPool {
        string name;
        address payable maker;

        uint32 endTime;
        bool enabled;

        uint256 tokenRate;
        address tokenaddr;
        uint256 tokenAmount; // left amount
        uint256 units;
        bool onlyHolder;
    }

    mapping(uint32 => FixedPool) public fixedPools;
    uint32 public fixedPoolCnt = 0;


    function createFixedPool(string memory _name, address _tracker, uint256 _amount, uint256 _rate, uint256 _units, uint32 _endTime, bool _onlyHolder) makerFee onlyBeforeDestruct payable public {
        require(_amount>0, "check create pool amount");
        require(_rate>0, "check create pool rate");
        require(_units>0, "check create pool units");

        // transfer erc20 token from maker
        IERC20(_tracker).safeTransferFrom(msg.sender, address(this), _amount);

        fixedPools[fixedPoolCnt] =  FixedPool({
            maker : msg.sender,
            tokenRate : _rate,
            tokenaddr : _tracker,
            tokenAmount : _amount,
            name: _name,
            endTime: uint32(now) + _endTime,
            units: _units,
            enabled: true,
            onlyHolder: _onlyHolder
            });
        emit CreatePool(fixedPoolCnt, msg.sender, false, _tracker, _amount, _rate, _units);
        fixedPoolCnt++;
    }

    function fixedPoolJoin(uint32 _id, uint256 _value) takerFee(_value) payable public {
        require(msg.value > 0, "check value, value must be gt 0");
        require(_value <= msg.value, "check value, value must be le msg.value");

        FixedPool storage _pool = fixedPools[_id];

        // check pool exist
        require(_pool.enabled, "check pool exists");
        if(_pool.onlyHolder){
            require(hastaked(msg.sender), "only holder");
        }
        // check end time
        require(now < _pool.endTime, "check before end time");

        uint _order = _value.mul(_pool.tokenRate).div(_pool.units);
        require(_order>0, "check taker amount");
        require(_order<=_pool.tokenAmount, "check left token amount");

        address _taker = msg.sender; // todo test gas

        _pool.tokenAmount = _pool.tokenAmount.sub(_order);

        // transfer ether to maker
        _pool.maker.transfer(_value);
        IERC20(_pool.tokenaddr).safeTransfer(_taker, _order);

        emit Join(_id, msg.sender, false, _value, _pool.tokenaddr, _order);
        joinPoolAfter(msg.sender, _value);
    }

    function fixedPoolClose(uint32 _id) public {
        FixedPool storage _pool = fixedPools[_id];

        require(_pool.enabled, "check pool exists");
        require(_pool.maker == msg.sender, "check maker owner");


        _pool.enabled = false;
        IERC20(_pool.tokenaddr).safeTransfer(_pool.maker, _pool.tokenAmount);
        emit Close(_id, false);
    }

}

contract PrivFixedPoolFactory is Events, AbstractFactory, Destructor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PrivFixedPool {
        string name;
        address payable maker;

        uint32 endTime;
        bool enabled;

        uint256 tokenRate;
        address tokenaddr;
        uint256 tokenAmount; // left amount
        uint256 units;
        address[] takers;
    }

    mapping(uint32 => PrivFixedPool) public privFixedPools;

    uint32 public privFixedPoolCnt = 0;

    function createPrivFixedPool(string memory  _name, address _tracker, uint256 _amount, uint256 _rate, uint256 _units, uint32 _endTime, address[] memory _takers)
    makerFee onlyBeforeDestruct payable public {

        require(_amount>0, "check create pool amount");
        require(_rate>0, "check create pool amount");
        require(_units>0, "check create pool amount");


        // transfer erc20 token from maker
        IERC20(_tracker).safeTransferFrom(msg.sender, address(this), _amount);

        privFixedPools[privFixedPoolCnt] =  PrivFixedPool({
            maker : msg.sender,
            tokenRate : _rate,
            tokenaddr : _tracker,
            tokenAmount : _amount,
            name: _name,
            endTime: uint32(now) + _endTime,
            units: _units,
            enabled: true,
            takers: _takers
            });

        emit CreatePool(privFixedPoolCnt, msg.sender, true, _tracker, _amount, _rate, _units);

        privFixedPoolCnt++;
    }

    function privFixedPoolJoin(uint32 _id, uint32 _index, uint256 _value) takerFee(_value) payable public {
        require(msg.value > 0, "check value, value must be gt 0");
        require(_value <= msg.value, "check value, value must be le msg.value");

        PrivFixedPool storage _pool = privFixedPools[_id];

        // check pool exist
        require(_pool.enabled, "check pool exists");

        // check end time
        require(now < _pool.endTime, "check before end time");
        // check taker limit
        require(_pool.takers[_index] == msg.sender, "check taker limit");

        uint _order = msg.value.mul(_pool.tokenRate).div(_pool.units);
        require(_order>0, "check taker amount");
        require(_order<=_pool.tokenAmount, "check left token amount");

        address _taker = msg.sender; // todo test gas

        _pool.tokenAmount = _pool.tokenAmount.sub(_order);

        // transfer ether to maker
        _pool.maker.transfer(_value);

        IERC20(_pool.tokenaddr).safeTransfer(_taker, _order);

        emit Join(_id, msg.sender, true, msg.value, _pool.tokenaddr, _order);
        joinPoolAfter(msg.sender, msg.value);
    }

    function privFixedPoolClose(uint32 _id) public {
        PrivFixedPool storage _pool = privFixedPools[_id];

        require(_pool.enabled, "check pool exists");
        require(_pool.maker == msg.sender, "check maker owner");

        _pool.enabled = false;
        IERC20(_pool.tokenaddr).safeTransfer(_pool.maker, _pool.tokenAmount);

        emit Close(_id, true);
    }


    function privFixedPoolTakers(uint32 _id) public view returns(address[] memory){
        PrivFixedPool storage _pool = privFixedPools[_id];
        return _pool.takers;
    }
}

contract PoolFactory is FixedPoolFactory, PrivFixedPoolFactory {}

contract BidPoolFactory is Events, AbstractFactory, Destructor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BidPool {
        string name;
        address payable maker;

        uint32 endTime;
        bool enabled;

        address tokenaddr;
        uint256 tokenAmount; // maker erc20 token amount

        uint256 takerAmountTotal; // taker ether coin amount
        uint256 makerReceiveTotal; // maker received = all - fee
        mapping(address=>uint256) takerAmountMap; // taker ether coin amount

        bool onlyHolder; // only token holder could join
    }

    mapping(uint32 => BidPool) public bidPools;
    uint32 public bidPoolCnt = 0;

    function createBidPool(string memory  _name, address _tracker, uint256 _amount, uint32 _endTime, bool _onlyHolder) makerFee onlyBeforeDestruct payable public {
        require(_amount>0, "check create pool amount");

        // transfer erc20 token from maker            
        IERC20(_tracker).safeTransferFrom(msg.sender, address(this), _amount);

        bidPools[bidPoolCnt] = BidPool({
            name: _name,
            maker : msg.sender,
            endTime: uint32(now) + _endTime,
            tokenaddr : _tracker,
            tokenAmount : _amount,
            takerAmountTotal: 0,
            enabled: true,
            makerReceiveTotal:0,
            onlyHolder:_onlyHolder
            });
        emit CreatePool(bidPoolCnt, msg.sender, false, _tracker, _amount, 0, 0);
        bidPoolCnt++;
    }

    function bidPoolJoin(uint32 _id, uint256 _value) takerFee(_value) payable public {
        require(msg.value > 0, "check value, value must be gt 0");
        require(_value <= msg.value, "check value, value must be le msg.value");

        BidPool storage _pool = bidPools[_id];

        // check pool exist
        require(_pool.enabled, "check pool exists");

        // check end time
        require(now < _pool.endTime, "check before end time");

        // check holder
        if(_pool.onlyHolder){
            require(hastaked(msg.sender), "only holder");
        }
        address _taker = msg.sender;
        _pool.takerAmountMap[_taker] = _pool.takerAmountMap[_taker].add(_value);
        _pool.takerAmountTotal = _pool.takerAmountTotal.add(_value);
        _pool.makerReceiveTotal = _pool.makerReceiveTotal.add(_value);

        emit Join(_id, msg.sender, false, _value, _pool.tokenaddr, 0);
        joinPoolAfter(msg.sender, _value);
    }

    function bidPoolTakerWithdraw(uint32 _id) public {
        BidPool storage _pool = bidPools[_id];

        // check end time
        require(now > _pool.endTime, "check after end time");

        address _taker = msg.sender;
        uint256 _amount = _pool.takerAmountMap[_taker];
        require(_amount>0, "amount check");

        uint256 _order = _amount.mul(_pool.tokenAmount).div(_pool.takerAmountTotal);

        // clear taker amount
        delete _pool.takerAmountMap[_taker];
        IERC20(_pool.tokenaddr).safeTransfer(_taker, _order);
        emit Withdraw(_id, _taker, _order, uint32(2));
    }

    function bidPoolMakerWithdraw(uint32 _id) public {
        BidPool storage _pool = bidPools[_id];
        // check end time
        require(now > _pool.endTime, "check after end time");
        require(_pool.enabled, "check pool enabled");
        require(_pool.maker == msg.sender, "check pool owner");
        if( _pool.takerAmountTotal == 0 ){
            _pool.enabled = false;
            IERC20(_pool.tokenaddr).safeTransfer(_pool.maker, _pool.tokenAmount);
            return;
        }
        uint256 _order = _pool.makerReceiveTotal;
        require( _order>0, "check received value");
        _pool.makerReceiveTotal = 0;
        msg.sender.transfer(_order);
        emit Withdraw(_id, msg.sender, _order, uint32(1));
    }

    function bidTakerAmount(uint32 _id, address _taker) public view returns(uint256) {
        BidPool storage _pool = bidPools[_id];
        uint256 _amount = _pool.takerAmountMap[_taker];
        return _amount;
    }
}