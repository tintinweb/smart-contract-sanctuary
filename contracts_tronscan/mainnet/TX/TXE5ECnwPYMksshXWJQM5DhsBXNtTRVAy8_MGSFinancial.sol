//SourceUnit: MGSFinancial.sol

pragma solidity ^0.5.8;

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

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);


    function decimals() external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        assembly {codehash := extcodehash(account)}
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
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;


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

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Community is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Agent {

        bool open;

        uint256 achieve;

        uint8 useStatus;
    }

    mapping(uint256 => Agent) public agents;

    mapping(address => address[]) public inviteRecord;

    mapping(address => uint256) public inviteEffectCount;

    mapping(address => bool) public effectUser;

    mapping(address => address) public inviter;

    mapping(address => uint256) public userAchieve;

    function inviteCount(address _account) public view returns (uint256){

        return inviteRecord[_account].length;
    }

    function setInviter(address _inviter) public returns (bool){
        require(msg.sender != _inviter, 'The inviter cannot be himself.');
        require(inviter[msg.sender] == address(0), 'Inviter already exists.');
        require(_inviter == address(this) || inviter[_inviter] != address(0), 'The inviter is illegal.');
        inviter[msg.sender] = _inviter;
        inviteRecord[_inviter].push(msg.sender);

        return true;
    }

    function addAgent(uint256 _code) public onlyOwner returns (bool){
        require(agents[_code].useStatus == 0, 'Channel used.');

        agents[_code].open = true;
        agents[_code].achieve = 0;
        agents[_code].useStatus = 1;

        return true;
    }

    function closeAgent(uint256 _code) public onlyOwner returns (bool){
        require(agents[_code].useStatus != 0, 'Illegal channel.');

        agents[_code].open = false;

        return true;
    }

}

contract GameBasic is Community {

    struct WinnerRecord {
        address winner;
        uint256 amount;
        uint256 time;
    }

    uint256 public lastRefreshTime;

    address public candidate;

    //奖池
    uint256 internal prizePool;

    uint256 pending;

    mapping(address => uint256) balance;

    WinnerRecord[] public winnerHistory;

    uint256 public drawInterval = 1 days;

    function setDrawInterval(uint256 _interval) public onlyOwner {
        drawInterval = _interval;
    }

    IERC20 public token = IERC20(0x412f93eca75e0ad4d7cd6cd04c29654fa0f140df7e);

    function balanceOf(address _account) public view returns (uint256){
        if (_account == candidate && now > lastRefreshTime && now - lastRefreshTime > drawInterval) {
            return prizePool.div(2).add(balance[_account]);
        }

        return balance[_account];
    }

    function getPrizePool() public view returns (uint256){
        if (address(0) != candidate && now > lastRefreshTime && now - lastRefreshTime > drawInterval) {
            return prizePool.div(2);
        }
        return prizePool;
    }

    function withdraw() public checkGame returns (uint256){

        uint256 value = balance[msg.sender];

        token.safeTransfer(msg.sender, value);
        balance[msg.sender] = 0;

        return value;
    }

    function joinGame(address _account, uint256 _value) internal {
        prizePool = prizePool.add(_value.mul(5).div(100));

        lastRefreshTime = now.sub(1);
        candidate = _account;
    }


    modifier checkGame()  {
        if (candidate != address(0) && now - lastRefreshTime > drawInterval) {
            balance[candidate] = balance[candidate].add(prizePool.div(2));
            candidate = address(0);
            prizePool = prizePool.div(2);
        }
        _;
    }

}


contract MGSFinancial is GameBasic {

    struct Assets {
        //投资总额
        uint256 investTotal;

        //待释放
        uint256 waitRelease;

        //动态收益
        uint256 dynamicIncome;

        //静态收益
        uint256 staticIncome;

        //最后接收静态天数
        uint256 lastReceiveDay;

        //最后接收静态数量
        uint256 lastReceiveValue;

        //每日投资总额
        mapping(uint256 => uint256) investRecord;
    }


    uint256 internal totalFunds;


    mapping(uint256 => uint256) public todayStaticTotal;


    mapping(uint256 => uint256) internal todayStaticReceiveTotal;


    mapping(uint256 => mapping(address => uint256)) public dynamicIncome;


    mapping(uint256 => uint256) public dynamicIncomeByDay;

    mapping(address => Assets) public userAssets;

    uint256 public investTotal;

    uint256 internal releaseTotal;


    mapping(uint256 => uint256) public investRecord;


    mapping(uint256 => uint256) internal staticSnapshot;

    uint256 StartDay;

    function totalSupply() public view returns (uint256){
        uint256 value = todayReleaseTotal();

        if (StartDay == currentDay()) {
            return totalFunds;
        }
        return totalFunds.sub(value).add(todayStaticTotal[currentDay()]);
    }

    function invest(uint256 _code, uint256 _value) public checkGame releaseStatic {
        require(_value >= 10 ** token.decimals(), 'Less than the minimum limit.');

        if (StartDay == 0) {
            StartDay = currentDay();
        }

        if (!effectUser[msg.sender]) {
            effectUser[msg.sender] = true;
            inviteEffectCount[inviter[msg.sender]] = inviteEffectCount[inviter[msg.sender]].add(1);
        }

        joinGame(msg.sender, _value);

        Assets storage assets = userAssets[msg.sender];

        assets.investTotal = assets.investTotal.add(_value);
        assets.waitRelease = assets.waitRelease.add(_value.mul(3));

        assets.investRecord[currentDay()] = assets.investRecord[currentDay()].add(_value);
        token.safeTransferFrom(msg.sender, address(this), _value);

        uint256 totalReward = rewardCommunity(_code, msg.sender, _value);

        totalFunds = totalFunds.add(_value.mul(95).div(100)).sub(totalReward);
        investTotal = investTotal.add(_value);
        investRecord[currentDay()] = investRecord[currentDay()].add(_value);
    }

    function todayReleaseTotal() public view returns (uint256){

        if (StartDay == currentDay()) {
            return 0;
        }

        uint256 value = staticSnapshot[currentDay()].div(30);

        if (value == 0) {
            uint256 left = yesterdayUnReceive();
            value = (totalFunds.add(left)).div(30);
        }

        return value;
    }

    function yesterdayUnReceive() internal view returns (uint256){
        return todayStaticTotal[currentDay().sub(1)].sub(todayStaticReceiveTotal[currentDay().sub(1)]);
    }


    modifier releaseStatic() {
        if (todayStaticTotal[currentDay()] == 0 && StartDay < currentDay()) {

            uint256 left = yesterdayUnReceive();
            if (left > 0) {
                totalFunds = totalFunds.add(left);
                releaseTotal = releaseTotal.sub(left);
            }

            uint256 value = totalFunds.div(30);
            staticSnapshot[currentDay()] = totalFunds;
            totalFunds = totalFunds.sub(value);
            todayStaticTotal[currentDay()] = value;
            releaseTotal = releaseTotal.add(value);
        }
        _;
    }


    function todayStaticIncome(address _account) public view returns (uint256){
        Assets storage assets = userAssets[_account];

        if (assets.lastReceiveDay == currentDay()) {
            return assets.lastReceiveValue;
        }

        uint256 releaseHistory = releaseTotal.sub(dynamicIncomeByDay[currentDay()]);
        if (todayStaticTotal[currentDay()] > 0) {
            releaseHistory = releaseHistory.sub(todayReleaseTotal());
        } else {
            releaseHistory = releaseHistory.sub(yesterdayUnReceive());
        }
        uint256 leftReleaseTotal = (investTotal.sub(investRecord[currentDay()])).mul(3).sub(releaseHistory);
        if (leftReleaseTotal == 0) {
            return 0;
        }

        uint256 value = (assets.waitRelease.sub(assets.investRecord[currentDay()].mul(3)).add(dynamicIncome[currentDay()][_account])).mul(todayReleaseTotal()).div(leftReleaseTotal);

        return value;
    }


    function receiveStaticIncome() public releaseStatic {

        Assets storage assets = userAssets[msg.sender];
        require(assets.lastReceiveDay < currentDay(), 'No repeat collection.');

        uint256 value = todayStaticIncome(msg.sender);

        assets.waitRelease = assets.waitRelease - value;
        assets.staticIncome = assets.staticIncome.add(value);
        assets.lastReceiveDay = currentDay();
        assets.lastReceiveValue = value;
        balance[msg.sender] = balance[msg.sender].add(value);

        todayStaticReceiveTotal[currentDay()] = todayStaticReceiveTotal[currentDay()].add(value);
    }


    uint256 public day;

    function addDay() public onlyOwner {
        day = day.add(1);
    }

    function subDay() public onlyOwner {
        day = day.sub(1);
    }

    function currentDay() public view returns (uint256){

        return day.add(now.div(1 days));

    }

    function getNow() public view returns (uint256){
        return now;
    }


    function rewardCommunity(uint256 _code, address _investor, uint256 _value) internal returns (uint256){
        require(agents[_code].open, 'Illegal channel.');

        agents[_code].achieve = agents[_code].achieve.add(_value);

        address account = _investor;
        uint256 totalReward;
        for (uint256 i = 0; i < 9; i++) {

            account = inviter[account];
            if (account == address(0)) {
                break;
            }

            userAchieve[account] = userAchieve[account].add(_value);

            uint256 inviteNum = inviteEffectCount[account];
            if (inviteNum <= i) {
                continue;
            }

            Assets storage assets = userAssets[account];
            if (assets.waitRelease == 0) {
                continue;
            }

            uint256 reward;
            if (i == 0) {
                reward = _value.mul(10).div(100);
            } else if (i == 1) {
                reward = _value.mul(5).div(100);
            } else if (i == 2) {
                reward = _value.mul(3).div(100);
            } else {
                reward = _value.mul(1).div(100);
            }

            if (assets.waitRelease > reward) {
                assets.waitRelease = assets.waitRelease - reward;
            } else {
                reward = assets.waitRelease;
                assets.waitRelease = 0;
                effectUser[account] = false;
                inviteEffectCount[inviter[account]] = inviteEffectCount[inviter[account]].sub(1);
            }
            assets.dynamicIncome = assets.dynamicIncome.add(reward);
            totalReward = totalReward.add(reward);
            balance[account] = balance[account].add(reward);
            dynamicIncome[currentDay()][account] = dynamicIncome[currentDay()][account].add(reward);
            releaseTotal = releaseTotal.add(reward);
            dynamicIncomeByDay[currentDay()] = dynamicIncomeByDay[currentDay()].add(reward);
        }
        return totalReward;
    }


    function userInfo(address _user) public view returns (
        address _inviter,
        uint256 _leftRelease,
        uint256 _todayStatic,
        bool _isReceive,
        uint256 _todayDynamic,
        uint256 _balanceInContract,
        uint256 _balanceInMgs,
        uint256 _totalIncome,
        uint256 _staticTotal,
        uint256 _dynamicTotal
    ){
        Assets memory assets = userAssets[_user];
        _inviter = inviter[_user];
        _leftRelease = assets.waitRelease;
        _todayStatic = todayStaticIncome(_user);
        _isReceive = assets.lastReceiveDay == currentDay();
        _todayDynamic = dynamicIncome[currentDay()][_user];
        _balanceInContract = balanceOf(_user);
        _balanceInMgs = token.balanceOf(_user);
        _staticTotal = assets.staticIncome;
        _dynamicTotal = assets.dynamicIncome;
        _totalIncome = _staticTotal.add(_dynamicTotal);
    }

    function teamInfo(uint256 _code, address _user, uint256 _page) public view returns (
        uint256 _inviteCount,
        uint256 _inviteEffect,
        uint256 _teamAchieve,
        uint256 _nodeAchieve,
        address[] memory _inviteRecord
    ){
        _inviteCount = inviteRecord[_user].length;
        _teamAchieve = userAchieve[_user];
        _nodeAchieve = agents[_code].achieve;
        _inviteEffect = inviteEffectCount[_user];
        uint256 size = 10;
        _inviteRecord = new address[](size);
        if (_page > 0) {
            uint256 startIndex = _page.sub(1).mul(size);
            for (uint256 i = 0; i < 10; i++) {
                if (startIndex.add(i) >= inviteRecord[_user].length) {
                    break;
                }
                _inviteRecord[i] = (inviteRecord[_user][startIndex.add(i)]);
            }
        }
    }


    function contractInfo() public view returns (
        address _gameCandidate,
        uint256 _gamePrizePool,
        uint256 _gameRefreshTime,
        uint256 _nowTime,
        uint256 _totalSupply,
        uint256 _todayStaticRelease,
        uint256 _drawInterval
    ){
        _gameCandidate = candidate;
        _gamePrizePool = getPrizePool();
        _gameRefreshTime = lastRefreshTime;
        _nowTime = getNow();
        _totalSupply = totalSupply();
        _todayStaticRelease = todayReleaseTotal();
        _drawInterval = drawInterval;
    }

}