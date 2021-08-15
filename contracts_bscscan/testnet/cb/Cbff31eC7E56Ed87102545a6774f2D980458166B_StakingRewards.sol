/**
 *Submitted for verification at BscScan.com on 2021-08-14
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
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
contract StakingRewards is Owned, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== UTIL FUNCTIONS ========== */

    function getTime() internal view returns (uint256) {
        // current block timestamp as seconds since unix epoch
        // Used to mock time changes in tests
        return block.timestamp;
    }

    /* ========== STATE VARIABLES ========== */

    // IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 private _totalSupply;

    mapping(address => uint256) private _stakedBalance;
    mapping(address => uint256) private _stakedTime;
    mapping(address => uint256) private _unstakingBalance;
    mapping(address => uint256) private _unstakingTime;
    mapping(address => uint256) private _rewardBalance;

    // Added for looping over addresses in event of APR change
    mapping(address => uint256) private _addressToIndex;
    address[] public allAddress;


    uint256 private rewardDistributorBalance = 0;
    uint256 internal rewardInterval = 60; // 60 Seconds
    uint256 internal unstakingInterval = 60; // 60 Seconds

    uint256 public rewardPerIntervalDivider = 411;

    uint256 private _convertDecimalTokenBalance = 10**18;

    uint256 public minStakeBalance = 1 * _convertDecimalTokenBalance; // 1 Token

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _stakingToken
    ) public Owned(_owner) {
        stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */

    // How much OM is in the contract total?
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // How much OM has address staked?
    function balanceOf(address account) public view returns (uint256) {
        return _stakedBalance[account];
    }

    // When did user stake?
    function stakeTime(address account) external view returns (uint256) {
        return _stakedTime[account];
    }

    // How much OM is unstaking in the address's current unstaking procedure?
    function unstakingBalanceOf(address account) external view returns (uint256) {
        return  _unstakingBalance[account];
    }

    // How much time is left in the address's current unstaking procedure?
    function unstakingTimeOf(address account) external view returns (uint256) {
        return _unstakingTime[account];
    }

    // How much have the address earned?
    function rewardBalanceOf(address account) external view returns (uint256) {
        return _rewardBalance[account];
    }

    // How much OM is available to distribute from reward disributor address? (Controlled by Mantra council)
    function rewardDistributorBalanceOf() external view returns (uint256) {
        return rewardDistributorBalance;
    }

    // When is the address's next reward going to become unstakable? 
    function nextRewardApplicableTime(address account) external view returns (uint256) {
        require(_stakedTime[account] != 0, "You dont have a stake in progress");
        require(_stakedTime[account] <= getTime(), "Your stake takes 24 hours to become available to interact with");
        uint256 secondsRemaining = (getTime() - _stakedTime[account]).mod(rewardInterval);
        return secondsRemaining;
    }

    // How much has account earned? Account's potential rewards ready to begin unstaking. 
    function earned(address account) public view returns (uint256) {
        uint256 perIntervalReward = perIntervalRewardOf(account);
        uint256 intervalsStaked = stakedIntervalsCountOf(account);
        return perIntervalReward.mul(intervalsStaked);
    }

    function perIntervalRewardOf(address account) public view returns (uint256) {
        return _stakedBalance[account].div(rewardPerIntervalDivider);
    // staked balance / rewardPerIntervalDivider
    }

    function stakedIntervalsCountOf(address account) public view returns (uint256) {
        if (_stakedTime[account] == 0) return 0;
        uint256 diffTime = getTime().sub(_stakedTime[account]);
        return diffTime.div(rewardInterval);
    }

    // Address loop

    function getAddresses(uint256 i) public view returns (address) {
        return allAddress[i];
    }

    function getAddressesLength() public view returns (uint256) {
        return allAddress.length;
    }

    

    // 

    /* ========== END OF VIEWS ========== */


    /* ========== MUTATIVE FUNCTIONS ========== */

    // ------ FUNCTION -------
    // 
    //  STAKE ()
    // 
    //      #require() amount is greater than ZERO
    //      #require() address that is staking is not the contract address
    // 
    //      Insert : token balance to user stakedBalances[address]
    //      Insert : current block timestamp timestamp to stakeTime[address]
    //      Add : token balance to total supply
    //      Transfer : token balance from user to this contract
    // 
    //  EXIT
    //  

    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
        
        require(amount > 0, "Cannot stake 0");
        uint256 newStakedBalance = _stakedBalance[msg.sender].add(amount);
        require(newStakedBalance >= minStakeBalance, "Staked balance is less than minimum stake balance");
        uint256 currentTimestamp = getTime();
        _stakedBalance[msg.sender] = newStakedBalance;
        _stakedTime[msg.sender] = currentTimestamp;
        _totalSupply = _totalSupply.add(amount);


        // 
            if (_addressToIndex[msg.sender] > 0) {
               
            } else {
                allAddress.push(msg.sender);
                uint256 index = allAddress.length;
                _addressToIndex[msg.sender] = index;
            }
        // 

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // ------ FUNCTION -------
    // 
    //   UNSTAKE () 
    // 
    //      initiate by running updateReward() to push the system forward
    //  
    //      #require() that the amount of tokens specified to unstake is above ZERO    
    //      #require() that the user has a current stakedBalance[address] above ZERO
    //      #require() that the amount of tokens specified to unstake is equal or less than thier current stakedBalance[] 
    //      #require() that the address staking is not the contract address
    //   
    //      MODIFY : subtract token balance from stakedBalance[address]
    // 
    //      if (stakedBalance == 0)
    //          Update : stake timestamp to ZERO stakeTime[address] // exit the system
    //      Else ()
    //          #require() that the updates stake balance is above minimum stake value
    //          Update : stake timestamp to now stakeTime[address] // Om for that address still remains in the system

    //      MODIFY : token balance to user  _unstakingBalance[address]
    //      MODIFY : (time + unstakingInterval) timestamp to stakeTime[address]
    //   
    //   EXIT
    //  

    function unstake(uint256 amount) public updateReward(msg.sender) {
        _unstake(msg.sender, amount);
    }

    // Allows user to unstake tokens without (or with partial) rewards in case of empty reward distribution pool
    function exit() public {
        uint256 reward = Math.min(earned(msg.sender), rewardDistributorBalance);
        require(reward > 0 || _rewardBalance[msg.sender] > 0 || _stakedBalance[msg.sender] > 0, "No tokens to exit");
        _addReward(msg.sender, reward);
        _stakedTime[msg.sender] = 0;
        if (_rewardBalance[msg.sender] > 0) withdrawReward();
        if (_stakedBalance[msg.sender] > 0) _unstake(msg.sender, _stakedBalance[msg.sender]);
    }

    // ------ FUNCTION -------
    // 
    //   WITHDRAW UNSTAKED BALANCE (uint256 amount) 
    // 
    //      updateReward()
    //  
    //      #require() that the amount of tokens specified to unstake is above ZERO    
    //      #require() that the user has a current unstakingBalance[address] above amount specified to withdraw
    //      #require() that the current block time is greater than their unstaking end date (their unstaking or vesting period has finished)
    //   
    //      MODIFY :  _unstakingBalance[address] to  _unstakingBalance[address] minus amount
    //      MODIFY : _totalSupply to _totalSupply[address] minus amount
    //      
    //      TRANSFER : amount to address that called the function
    // 
    //   
    //   EXIT
    //  
    
    function withdrawUnstakedBalance(uint256 amount) public nonReentrant updateReward(msg.sender) {

        require(amount > 0, "Account does not have an unstaking balance");
        require(_unstakingBalance[msg.sender] >= amount, "Account does not have that much balance unstaked");
        require(_unstakingTime[msg.sender] <= getTime(), "Unstaking period has not finished yet");

         _unstakingBalance[msg.sender] =  _unstakingBalance[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // ------ FUNCTION -------
    // 
    //   LOCK IN REWARD () 
    // 
    //      updateReward()
    //   
    //   EXIT
    //  

    function lockInReward() public updateReward(msg.sender) {}

    function lockInRewardOnBehalf(address _address) private updateReward(_address) {}

    // ------ FUNCTION -------
    // 
    //   WITHDRAW REWARD ()
    // 
    //      updateReward()
    //  
    //      #require() that the reward balance of the user is above ZERO
    //   
    //      TRANSFER : transfer reward balance to address that called the function
    // 
    //      MODIFY : update rewardBalance to ZERO
    //   
    //   EXIT
    //  

    function withdrawReward() public updateReward(msg.sender) {
        uint256 reward = _rewardBalance[msg.sender];
        require(reward > 0, "You have not earned any rewards yet");
        _rewardBalance[msg.sender] = 0;
        _unstakingBalance[msg.sender] = _unstakingBalance[msg.sender].add(reward);
        _unstakingTime[msg.sender] = getTime() + unstakingInterval;
        emit RewardWithdrawn(msg.sender, reward);
    }

    // ------ FUNCTION -------
    // 
    //   STAKE REWARD ()
    // 
    //      updateReward()
    //  
    //      #require() that the reward balance of the user is above ZERO
    //   
    //      MODIFY : update stakedBalances[address] = (stakedBalances[address] + _rewardBalance[msg.sender])
    // 
    //      MODIFY : update rewardBalance to ZERO
    //   
    //   EXIT
    //  

    function stakeReward() public updateReward(msg.sender) {
        require(_rewardBalance[msg.sender] > 0, "You have not earned any rewards yet");
        _stakedBalance[msg.sender] = _stakedBalance[msg.sender].add(_rewardBalance[msg.sender]);
        _rewardBalance[msg.sender] = 0;
    }

    // ------ FUNCTION -------
    // 
    //   ADD REWARD SUPPLY () 
    // 
    //      #require() that the amount of tokens being added is above ZERO
    //      #require() that the user
    //   
    //      MODIFY : update rewardDistributorBalance = rewardDistributorBalance + amount
    //      MODIFY : update _totalSupply = _totalSupply + amount
    //   
    //   EXIT
    //  

    function addRewardSupply(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot add 0 tokens");
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        rewardDistributorBalance = rewardDistributorBalance.add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    // ------ FUNCTION -------
    // 
    //   REMOVE REWARD SUPPLY | ONLY OWNER
    // 
    //      #require() that the amount of tokens being removed is above ZERO
    //      #require() that the amount is equal to or below the rewardDistributorBalance
    //      #require() that the amount is equal to or below the totalSupply of tokens in the contract
    //  
    //      TRANSFER: amount of tokens from contract
    //  
    //      MODIFY : update rewardDistributorBalance = rewardDistributorBalance - amount
    //      MODIFY : update _totalSupply = _totalSupply - amount
    //   
    //   EXIT
    //  

    function removeRewardSupply(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= rewardDistributorBalance, "rewardDistributorBalance has less tokens than requested");
        require(amount <= _totalSupply, "Amount is greater that total supply");
        stakingToken.safeTransfer(owner, amount);
        rewardDistributorBalance = rewardDistributorBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }

    // ------ FUNCTION -------
    // 
    //   SET REWARDS INTERVAL () ONLY OWNER
    // 
    //      #require() that reward interval sullpied as argument is greater than 1 and less than 365 inclusive
    //   
    //      MODIFY : rewardInterval to supplied _rewardInterval
    // 
    //      EMIT : update reward interval
    //   
    //   EXIT
    //  

    function setRewardsInterval(uint256 _rewardInterval) external onlyOwner {
        require(
            _rewardInterval >= 1 ,
            "Staking reward interval must be larger then 1"
        );
        rewardInterval = _rewardInterval * 1 minutes;
        emit RewardsDurationUpdated(rewardInterval);
    }

    // ------ FUNCTION -------#
    // 
    //   SET REWARDS DIVIDER () ONLY OWNER
    // 
    //      #require() that reward divider sullpied as argument is greater than original divider
    //   
    //      MODIFY : rewardIntervalDivider to supplied _rewardInterval
    //   
    //   EXIT
    //  

    function updateChunkUsersRewards(uint256 startIndex, uint256 endIndex) external onlyOwner {

        uint256 length = allAddress.length;
        require(endIndex <= length, "Cant end on index greater than length of addresses");
        require(endIndex > startIndex, "Nothing to iterate over");
        

        for (uint i = startIndex; i < endIndex; i++) {
            lockInRewardOnBehalf(allAddress[i]);
        }
    }

    function setRewardsDivider(uint256 _rewardPerIntervalDivider) external onlyOwner {
        require(
            _rewardPerIntervalDivider >= 1,
            "Reward can only be lowered, divider must be greater than 0"
        );
        rewardPerIntervalDivider = _rewardPerIntervalDivider;
    }

    // Keep in mind, that this method receives value in wei.
    // It means, that if owner wants to set min staking balance to 2 om
    // he needs to pass 2000000000000000000 as argument (if ERC20's decimals is 18).
    function setMinStakeBalance(uint256 _minStakeBalance) external onlyOwner {
        minStakeBalance = _minStakeBalance;
    }
    
  /* ========== MODIFIERS ========== */

    // ------ FUNCTION -------
    // 
    //   UPDATE REWARD (address) INTERNAL
    // 
    //      IF (stakeTime[address] > 0)
    //      
    //          VAR reward = 0;
    //          VAR diffTime : Take current block timestamp and subtract the users stakedTime entry (timestamp)
    //          VAR perIntervalReward : current staked balance divided by APR variable divider. Calculate the reward they should earn per interval that have occured since inital stake or last call of updateReward()
    //          VAR intervalsStaked : diffTime calculation divided by the rewardInterval (24 hours)
    //          reward : reward earned per interval based on current stake multiplied by how many intervals you have not calimed a reward for.
    //          
    // 
    //          #require() that reward user is about to receive is not greater than the rewardDistributorBalance
    // 
    //          IF (the reward is greater than ZERO)  
    // 
    //              MODIFY : rewardDistributorBalance to rewardDistributorBalance minus the reward paid
    //              MODIFY : _totalSupply to _totalSupply minus the reward paid
    //              MODIFY : _stakedTime[address] to now(timestamp)
    //              MODIFY : _rewardBalance[address] to _rewardBalance[address] plus reward
    // 
    //              EMIT : rewardPaid to the address calling the function (reward)
    // 
    //          ELSE
    //              NOTHING : user has nothing to claim. ignore and EXIT.
    //      ELSE
    //          NOTHING : user has nothing to claim. ignore and EXIT.
    //   
    //      EXIT
    // 

    function _addReward(address account, uint256 amount) private {
        if (amount == 0) return;
        // Update stake balance to unstaking balance
        rewardDistributorBalance = rewardDistributorBalance.sub(amount);
        _rewardBalance[account] = _rewardBalance[account].add(amount);
        emit RewardPaid(account, amount);
    }

    function _unstake(address account, uint256 amount) private {
        require(_stakedBalance[account] > 0, "Account does not have a balance staked");
        require(amount > 0, "Cannot unstake Zero OM");
        require(amount <= _stakedBalance[account], "Attempted to withdraw more than balance staked");
        _stakedBalance[account] = _stakedBalance[account].sub(amount);
        if (_stakedBalance[account] == 0) _stakedTime[account] = 0;
        else {
            require(
                _stakedBalance[account] >= minStakeBalance,
                "Your remaining staked balance would be under the minimum stake. Either leave at least 10 OM in the staking pool or withdraw all your OM"
            );
        }
        _unstakingBalance[account] = _unstakingBalance[account].add(amount);
        _unstakingTime[account] = getTime() + unstakingInterval;
        emit Unstaked(account, amount);
    }

    modifier updateReward(address account) {
        // If their _stakeTime is 0, this means they arent active in the system
        if (_stakedTime[account] > 0) {
            uint256 stakedIntervals = stakedIntervalsCountOf(account);
            uint256 perIntervalReward = perIntervalRewardOf(account);
            uint256 stakedBalance = balanceOf(account);
            // uint256 reward = stakedIntervals.mul(perIntervalReward);
            uint256 reward = rewardPerIntervalDivider.mul(stakedBalance.div(_totalSupply));
            require(reward <= rewardDistributorBalance, "Rewards pool is extinguished");
            _addReward(account, reward);
            _stakedTime[account] = _stakedTime[account].add(rewardInterval.mul(stakedIntervals));
        }
        _;
    }

    /* ========== END OF MODIFIERS ========== */



    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardWithdrawn(address indexed user, uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    /* ========== END EVENTS ========== */
}