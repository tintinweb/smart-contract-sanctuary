/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.16;


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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


// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// Inheritance
// https://docs.synthetix.io/contracts/Pausable
contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    constructor() internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// Inheritance
contract StakingRewards is Owned, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== UTIL FUNCTIONS ========== */

    function getTime() internal view returns (uint256) {
        // current block timestamp as seconds since unix epoch
        // Used to mock time changes in tests
        return now;
    }
    
     struct userStruct{
         
        uint256 stakedBal1;
        uint256 stakedTime1;
        uint256 lockTime1;
        
        uint256 stakedBal2;
        uint256 stakedTime2;
        uint256 lockTime2;
        
        uint256 stakedBal3;
        uint256 stakedTime3;
        uint256 lockTime3;
    }
    
    mapping(address => userStruct) public user;
    uint256 public totalStaked1 = 0;
    uint256 public totalStaked2 = 0;
    uint256 public totalStaked3 = 0;
    
   
    /* ========== STATE VARIABLES ========== */

    // IERC20 public rewardsToken;
    IERC20 public stakingToken;

   
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _stakingToken
    ) public Owned(_owner) {
        stakingToken = IERC20(_stakingToken);
    }

  
     uint256 internal rewardInterval = 86400 * 1; // 1 day
     
    ////////////////////////// STAKE plan 1 //////////////////////
     function stake1(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(user[msg.sender].stakedBal1 == 0, "Tokens Already Staked!");
        
        user[msg.sender].stakedBal1 = amount;
        user[msg.sender].stakedTime1 = getTime();
        user[msg.sender].lockTime1 = getTime() + 21 days;
        
        
        totalStaked1 = totalStaked1 + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    
     function IntervalRewardsOf1(address account) public view returns (uint256) {
         uint256 amount = user[account].stakedBal1;
         uint256 timeDiff = getTime().sub(user[account].stakedTime1);
         uint256 intervals = timeDiff.div(rewardInterval);
         uint256 perIntervalReward = amount.div(200); // 0.5% daily
        return intervals.mul(perIntervalReward);
    }
    
    function unstake1() external{
        require(user[msg.sender].stakedBal1 > 0, "Account does not have a balance staked");
        require(user[msg.sender].lockTime1 < now,"Lock Period Not Finished!");
        withdrawReward1();
        
        stakingToken.safeTransfer(msg.sender, user[msg.sender].stakedBal1);
        emit Unstaked(msg.sender, user[msg.sender].stakedBal1);
        
        user[msg.sender].stakedBal1 = 0;
        user[msg.sender].stakedTime1 = 0;
        user[msg.sender].lockTime1 = 0;
    }
    
    function withdrawReward1() public{
        uint256 rewards = IntervalRewardsOf1(msg.sender);
        require(rewards > 0, "Account does not have reward balance staked");
        user[msg.sender].stakedTime1 = getTime();
         stakingToken.safeTransfer(msg.sender, rewards);
        emit Withdrawn(msg.sender, rewards);
    }

 ////////////////////////// STAKE plan 2 //////////////////////
     function stake2(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(user[msg.sender].stakedBal2 == 0, "Tokens Already Staked!");
        
        user[msg.sender].stakedBal2 = amount;
        user[msg.sender].stakedTime2 = getTime();
        user[msg.sender].lockTime2 = getTime() + 21 days;
        
        
        totalStaked2 = totalStaked2 + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    
     function IntervalRewardsOf2(address account) public view returns (uint256) {
         uint256 amount = user[account].stakedBal2;
         uint256 timeDiff = getTime().sub(user[account].stakedTime2);
         uint256 intervals = timeDiff.div(rewardInterval);
         uint256 perIntervalReward = amount.div(100); // 1% daily
        return intervals.mul(perIntervalReward);
    }
    
    function unstake2() external{
        require(user[msg.sender].stakedBal2 > 0, "Account does not have a balance staked");
        require(user[msg.sender].lockTime2 < now,"Lock Period Not Finished!");
        withdrawReward2();
        
        stakingToken.safeTransfer(msg.sender, user[msg.sender].stakedBal2);
        emit Unstaked(msg.sender, user[msg.sender].stakedBal2);
        
        user[msg.sender].stakedBal2 = 0;
        user[msg.sender].stakedTime2 = 0;
        user[msg.sender].lockTime2 = 0;
    }
    
    function withdrawReward2() public{
        uint256 rewards = IntervalRewardsOf2(msg.sender);
        require(rewards > 0, "Account does not have reward balance staked");
        user[msg.sender].stakedTime2 = getTime();
         stakingToken.safeTransfer(msg.sender, rewards);
        emit Withdrawn(msg.sender, rewards);
    }

 ////////////////////////// STAKE plan 3 //////////////////////
     function stake3(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(user[msg.sender].stakedBal3 == 0, "Tokens Already Staked!");
        
        user[msg.sender].stakedBal3 = amount;
        user[msg.sender].stakedTime3 = getTime();
        user[msg.sender].lockTime3 = getTime() + 21 days;
        
        
        totalStaked3 = totalStaked3 + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }
    
     function IntervalRewardsOf3(address account) public view returns (uint256) {
         uint256 amount = user[account].stakedBal3;
         uint256 timeDiff = getTime().sub(user[account].stakedTime3);
         uint256 intervals = timeDiff.div(rewardInterval);
         uint256 perIntervalReward = amount.div(50); // 2% daily
        return intervals.mul(perIntervalReward);
    }
    
    function unstake3() external{
        require(user[msg.sender].stakedBal3 > 0, "Account does not have a balance staked");
        require(user[msg.sender].lockTime3 < now,"Lock Period Not Finished!");
        withdrawReward3();
        
        stakingToken.safeTransfer(msg.sender, user[msg.sender].stakedBal3);
        emit Unstaked(msg.sender, user[msg.sender].stakedBal3);
        
        user[msg.sender].stakedBal3 = 0;
        user[msg.sender].stakedTime3 = 0;
        user[msg.sender].lockTime3 = 0;
    }
    
    function withdrawReward3() public{
        uint256 rewards = IntervalRewardsOf3(msg.sender);
        require(rewards > 0, "Account does not have reward balance staked");
        user[msg.sender].stakedTime3 = getTime();
         stakingToken.safeTransfer(msg.sender, rewards);
        emit Withdrawn(msg.sender, rewards);
    }


    function withdrawTokens() external onlyOwner{
         require(stakingToken.balanceOf(address(this)) >=0 , "Tokens Not Available in contract!");
        stakingToken.safeTransfer(owner , stakingToken.balanceOf(address(this)));
    }
   

    

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /* ========== END EVENTS ========== */
}