/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-23
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity 0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity 0.5.16;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity 0.5.16;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity 0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _factory;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FactoryTransferred(address indexed previousFactory, address indexed newFactory);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        _factory = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function factory() public view returns (address) {
        return _factory;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(isFactory(), "Ownable: caller is not the factory");
        _;
    }

    modifier onlyFactoryOrOwner() {
        require(isFactory() || isOwner(), "Ownable: caller is not the factory");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function isFactory() public view returns (bool) {
        return _msgSender() == _factory;
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

    function renounceFactory() public onlyFactory {
        emit FactoryTransferred(_owner, address(0));
        _factory = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function setOwnerOnce(address newOwner) public onlyFactory {
        _owner = newOwner;
    }

    function setFactory(address newFactory) public onlyOwner {
        _factory = newFactory;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function mint(address account, uint amount) external;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity 0.5.16;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity 0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/**
 * Reward Amount Interface
 */
pragma solidity 0.5.16;

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(address _stakeToken, uint256 _startTime, uint256 _duration, uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyFactoryOrOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

/**
 * Staking Token Wrapper
 */
pragma solidity 0.5.16;

contract FrogTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken = IERC20(0x0);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, bool transfer) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if(transfer) stakeToken.safeTransfer(msg.sender, amount);
    }
}

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IStats {
    function incrIIStats(uint256 k, uint256 v) external returns (uint256);
    function decrIIStats(uint256 k, uint256 v) external returns (uint256);
    function incrAIStats(address k, uint256 v) external returns (uint256);
    function decrAIStats(address k, uint256 v) external returns (uint256);
    function incrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function decrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function incrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function decrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function incrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function decrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function setIAAStats(uint256 k, address addr1, address addr2) external returns (address);
    function getIIStats(uint256 k) external view returns (uint256);
    function getAIStats(address addr) external view returns (uint256);
    function getAAIStats(address addr0, address addr1) external view returns (uint256);
    function getAIIStats(address addr, uint256 k) external view returns (uint256);
    function getIAIStats(uint256 k, address addr) external view returns (uint256);
    function getIAAStats(uint256 k, address addr) external view returns (address);
    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
}
contract FrogStats is Ownable {
    using SafeMath for uint256;

    IERC20 public frog = IERC20(0x4fEe21439F2b95b72da2F9f901b3956f27fE91D5);
    address public devPool = address(0x96eD0b21d024b82A430386A3A1477324f25f0143);
    address public rewardPool = address(0xC81acf050fa511FBA998b394a6087c569d3D103A);

    mapping (address => bool) public minters;
    mapping (uint256 => uint256) public iiStats;
    mapping (address => uint256) public aiStats;
    mapping (address => mapping(uint256 => uint256)) public aiiStats;
    mapping (address => mapping(address => uint256)) public aaiStats;
    mapping (uint256 => mapping(address => uint256)) public iaiStats;
    mapping (uint256 => mapping(address => address)) public iaaStats;

    uint256 public constant STATS_TYPE_INVITE_RELATION = 5;
    uint256 public constant STATS_TYPE_INVITE_1ST_COUNT = 6;
    uint256 public constant STATS_TYPE_INVITE_2ND_COUNT = 7;
 
    constructor() public {
    }

    function incrIIStats(uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _incrIIStats(k, v);
    }
    function _incrIIStats(uint256 k, uint256 v) internal returns (uint256){
        iiStats[k] = iiStats[k].add(v);
        return iiStats[k];
    }
    function decrIIStats(uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _decrIIStats(k, v);
    }
    function _decrIIStats(uint256 k, uint256 v) internal returns (uint256){
        if(iiStats[k] < v){
            v = iiStats[k];
        }
        iiStats[k] = iiStats[k].sub(v);
        return iiStats[k];
    }
    function incrAIStats(address k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _incrAIStats(k, v);
    }
    function _incrAIStats(address k, uint256 v) internal returns (uint256){
        aiStats[k] = aiStats[k].add(v);
        return aiStats[k];
    }
    function decrAIStats(address k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _decrAIStats(k, v);
    }
    function _decrAIStats(address k, uint256 v) internal returns (uint256){
        if(aiStats[k] < v){
            v = aiStats[k];
        }
        aiStats[k] = aiStats[k].sub(v);
        return aiStats[k];
    }
    function incrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _incrAIIStats(addr, k, v);
    }
    function _incrAIIStats(address addr, uint256 k, uint256 v) internal returns (uint256){
        aiiStats[addr][k] = aiiStats[addr][k].add(v);
        return aiiStats[addr][k];
    }
    function decrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _decrAIIStats(addr, k, v);
    }
    function _decrAIIStats(address addr, uint256 k, uint256 v) internal returns (uint256){
        if(aiiStats[addr][k] < v){
            v = aiiStats[addr][k];
        }
        aiiStats[addr][k] = aiiStats[addr][k].sub(v);
        return aiiStats[addr][k];
    }
    function incrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _incrAAIStats(addr0, addr1, v);
    }
    function _incrAAIStats(address addr0, address addr1, uint256 v) internal returns (uint256){
        aaiStats[addr0][addr1] = aaiStats[addr0][addr1].add(v);
        return aaiStats[addr0][addr1];
    }
    function decrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _decrAAIStats(addr0, addr1, v);
    }
    function _decrAAIStats(address addr0, address addr1, uint256 v) internal returns (uint256){
        if(aaiStats[addr0][addr1] < v){
            v = aaiStats[addr0][addr1];
        }
        aaiStats[addr0][addr1] = aaiStats[addr0][addr1].sub(v);
        return aaiStats[addr0][addr1];
    }

    function incrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _incrIAIStats(k, addr1, v);
    }
    function _incrIAIStats(uint256 k, address addr1, uint256 v) internal returns (uint256){
        iaiStats[k][addr1] = iaiStats[k][addr1].add(v);
        return iaiStats[k][addr1];
    }
    function decrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _decrIAIStats(k, addr1, v);
    }
    function _decrIAIStats(uint256 k, address addr1, uint256 v) internal returns (uint256){
        if(iaiStats[k][addr1] < v){
            v = iaiStats[k][addr1];
        }
        iaiStats[k][addr1] = iaiStats[k][addr1].sub(v);
        return iaiStats[k][addr1];
    }

    function setIAAStats(uint256 k, address addr1, address addr2) external returns (address){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        return _setIAAStats(k, addr1, addr2);
    }
    function _setIAAStats(uint256 k, address addr1, address addr2) internal returns (address){
        iaaStats[k][addr1] = addr2;
        return iaaStats[k][addr1];
    }

    function getIIStats(uint256 k) external view returns (uint256) {
        return iiStats[k];
    }
    function getAIStats(address addr) external view returns (uint256) {
        return aiStats[addr];
    }
    function getAAIStats(address addr0, address addr1) external view returns (uint256) {
        return aaiStats[addr0][addr1];
    }
    function getAIIStats(address addr, uint256 k) external view returns (uint256) {
        return aiiStats[addr][k];
    }
    function getIAIStats(uint256 k, address addr) external view returns (uint256) {
        return iaiStats[k][addr];
    }
    function getIAAStats(uint256 k, address addr) external view returns (address) {
        return iaaStats[k][addr];
    }
    /** 
     * Add minter
     * @param _minter minter
     */
    function addMinter(address _minter) external onlyFactoryOrOwner {
        minters[_minter] = true;
    }
    
    /** 
     * Remove minter
     * @param _minter minter
     */
    function removeMinter(address _minter) external onlyFactoryOrOwner {
        minters[_minter] = false;
    }

    function setInvitedBy(address invitedBy) public{
        // if(!enableInvite){
        //     return;
        // }
        if(invitedBy == address(0x0)){
            return;
        }
        if(invitedBy == msg.sender){
            return;
        }
        if(this.getIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender) != address(0x0)){
            return;
        }
        if(this.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy) == msg.sender){
            return;
        }
        _setIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender, invitedBy);
        _incrIAIStats(STATS_TYPE_INVITE_1ST_COUNT, invitedBy, 1);
        uint256 user1STCount = this.getIAIStats(STATS_TYPE_INVITE_1ST_COUNT, msg.sender);
        if(user1STCount > 0){
            _incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, invitedBy, user1STCount);
        }
        address topInviter = this.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy);
        if(topInviter != address(0x0)){
            _incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, topInviter, 1);
        }
    }
}