// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) internal virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

// Stabilize Token Interface
interface StabilizeToken is IERC20 {

    /// Controller is the only contract that can mint
    function mint(address _to, uint256 _amount) external returns (bool);

    // Operator has initiated the burn to start
    function initiateBurn(uint256 rate) external returns (bool);
    
    // Owner call
    function owner() external view returns (address);

}

interface StabilizePriceOracle {
    function getPrice(address _address) external returns (uint256);
}

// File: contracts/Operator.sol

pragma solidity ^0.6.0;

// Operator is the controller of Stabilize Token, it can mint each week and controls the eventual 1% emission
// Operator ownership of the Stabilize Token cannot be changed once set, all controller modifications require a 24 hour timelock
// Aave & Chainlink Price Oracles are used to update price data
// 
contract Operator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for StabilizeToken;
    using Address for address;
    
    // variables
    uint256 constant duration = 604800; // Each reward period lasts for one week
    uint256 private _periodFinished; // The UTC time that the current reward period ends
    uint256 public protocolStart; // UTC time that the protocol begins to reward tokens
    uint256 public lastOracleTime; // UTC time that oracle was last ran
    uint256 constant minOracleRefresh = 21600; // The minimum amount of time we need to wait before refreshing the oracle prices
    uint256 private targetPrice = 1000000000000000000; // The target price for the stablecoins in USD
    StabilizeToken private StabilizeT; // A reference to the StabilizeToken
    StabilizePriceOracle private oracleContract; // A reference to the price oracle contract
    
    uint256 private _currentWeek = 0; // Week 1 to 52 are bootstrap weeks that have emissions, after week 52, token burns
    uint256 private _weekStart = 0; // This is the time that the current week starts, must be at least duration before starting a new week
    uint256[] private _mintSchedule; // The pre-programmed schedule for minting tokens from contract
    uint256 private weeklyReward; // The reward for the current week, this determines the reward rate
    
    // Reward variables
    uint256 private _maxSupplyFirstYear = 1000000000000000000000000; // Max emission during the first year, max 1,000,000 Stablize Token
    uint256 private _rewardPercentLP = 50000; // This is the percent of rewards reserved for LP pools. Represents 50% of all Stabilize Token rewards 
    uint256 constant _rewardPercentDev = 1000; // This percent of rewards going to development team during first year, 1%
    uint256 private _emissionRateLong = 1000; // This is the minting rate after the first year, currently 1% per year
    uint256 private _burnRateLong = 0; // This is the burn per transaction after the first year
    uint256 private _earlyBurnRate = 0; // Optionally, the contract may burn tokens if extra not needed
    uint256 constant divisionFactor = 100000;
    

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP/Stablecoin tokens the user has provided.
        uint256 rewardDebt; // Reward debt. The amount of rewards already given to depositer
        uint256 unclaimedReward; // Total reward potential
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 sToken; // Address of LP/Stablecoin token contract.
        uint256 rewardRate; // The rate at which Stabilize Token is earned per second
        uint256 rewardPerTokenStored; // Reward per token stored which should gradually increase with time
        uint256 lastUpdateTime; // Time the pool was last updated
        uint256 totalSupply; // The total amount of LP/Stablecoin in the pool
        bool active; // If active, the pool is earning rewards, otherwise its not
        uint256 poolID; // ID for the pool
        bool lpPool; // LP pools are calculated separate from stablecoin pools
        uint256 price; // Oracle price of token in pool
        uint256 poolWeight; // Weight of pool compared to the total
    }

    // Info of each pool.
    PoolInfo[] private totalPools;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    // List of the active pools IDs
    uint256[] private activePools;

    // Events
    event RewardAdded(uint256 pid, uint256 reward);
    event Deposited(uint256 pid, address indexed user, uint256 amount);
    event Withdrawn(uint256 pid, address indexed user, uint256 amount);
    event RewardPaid(uint256 pid, address indexed user, uint256 reward);
    event RewardDenied(uint256 pid, address indexed user, uint256 reward);
    event NewWeek(uint256 weekNum, uint256 rewardAmount);

    constructor(
        StabilizeToken _stabilize,
        StabilizePriceOracle _oracle,
        uint256 startTime
    ) public {
        StabilizeT = _stabilize;
        oracleContract = _oracle;
        protocolStart = startTime;
        setupEmissionSchedule(); // Publicize mint schedule
    }
    
    // Modifiers
    
    modifier updateRewardEarned(uint256 _pid, address account) {
        totalPools[_pid].rewardPerTokenStored = rewardPerToken(_pid);
        totalPools[_pid].lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            userInfo[_pid][account].unclaimedReward = rewardEarned(_pid,account);
            userInfo[_pid][account].rewardDebt = totalPools[_pid].rewardPerTokenStored;
        }
        _;
    }
    
    // Initialization functions
    
    function setupEmissionSchedule() internal {
        // This function creates the initial schedule of emission of tokens during the first year, only called during construction
        _mintSchedule.push(76000000000000000000000); // Week 1 emission
        _mintSchedule.push(57000000000000000000000); // Week 2 emission
        _mintSchedule.push(38000000000000000000000); // Week 3 emission
        _mintSchedule.push(19000000000000000000000); // Week 4 emission
        for(uint i = 4; i < 52; i++){
            _mintSchedule.push(16875000000000000000000); // Week 5-52 emissions, can be adjusted
        }
    }
    
    // Anyone can call the mintNewWeek function, this may be a gas heavy function
    function mintNewWeek() external {
        require(now >= protocolStart,"Too soon to start this protocol");
        if(_currentWeek > 0){
            // We cannot mint a new week until the current week is over
            require(now >= _periodFinished,"Too early to start next week");
        }
        require(StabilizeT.owner() == address(this),"The Operator does not have permission to mint tokens");
        _currentWeek = _currentWeek.add(1);
        // We will mint new tokens per the mint schedule, then the emission schedule
        uint256 rewardAmount = 0;
        if(_currentWeek < 53){
            // Mint per mint schedule
            uint256 devShare = 0;
            if(_currentWeek > 1){
                // First week was pre-allocated
                // devShare from total allocation
                devShare = _mintSchedule[_currentWeek-1].mul(_rewardPercentDev).div(divisionFactor);
                _mintSchedule[_currentWeek-1] = _mintSchedule[_currentWeek-1].sub(devShare);
                // Mint to the developer account
                StabilizeT.mint(owner(),devShare); // The Operator will mint tokens to the developer
            }else{
                // This is the first week, let's activate all the pending pools
                for(uint256 i = 0; i < totalPools.length; i++){
                    activePools.push(totalPools[i].poolID);
                    totalPools[i].active = true;
                }             
            }
            rewardAmount = _mintSchedule[_currentWeek-1];
            if(_earlyBurnRate > 0){
                // This will be utilized only if the contract has called for an early burn to reduce token supply
                rewardAmount = rewardAmount.sub(rewardAmount.mul(_earlyBurnRate).div(divisionFactor));
            }
        }else{
            // Mint per emission schedule
            if(_currentWeek == 53){
                // Start the burn rate
                StabilizeT.initiateBurn(_burnRateLong);
                // Set the maximum supply to the real total supply rate now
                _maxSupplyFirstYear = StabilizeT.totalSupply();
            }
            // No more devShare
            // Emission rate divided per week
            rewardAmount = _maxSupplyFirstYear.mul(_emissionRateLong).div(divisionFactor).div(52);
        }
        StabilizeT.mint(address(this),rewardAmount); // Mint at a set rate
        // Now adjust the contract values
        // Force update all the active pools before we extend the period
        for(uint256 i = 0; i < activePools.length; i++){
            forceUpdateRewardEarned(activePools[i],address(0));
            totalPools[activePools[i]].rewardRate = 0; // Set the reward rate to 0 until pools rebalanced
        }
        _periodFinished = now + duration;
        weeklyReward = rewardAmount; // This is this week's distribution
        lastOracleTime = now - minOracleRefresh; // Force oracle price to update
        rebalancePoolRewards(); // The pools will determine their reward rates based on the price
        emit NewWeek(_currentWeek,weeklyReward);
    }
    
    function currentWeek() external view returns (uint256){
        return _currentWeek;
    }
    
    function emissionRate() external view returns (uint256){
        return _emissionRateLong;
    }
    
    function periodFinished() external view returns (uint256){
        return _periodFinished;
    }

    function poolLength() public view returns (uint256) {
        return totalPools.length;
    }
    
    function rebalancePoolRewards() public {
        // This function can only be called once every 6 hours, it updates all the active pools reward rates based on the prices
        require(now >= lastOracleTime + minOracleRefresh, "Cannot update the oracle prices now");
        require(_currentWeek > 0, "Protocol has not started yet");
        require(oracleContract != StabilizePriceOracle(address(0)),"No price oracle contract has been selected yet");
        lastOracleTime = now;
        uint256 rewardPerSecond = weeklyReward.div(duration);
        uint256 rewardLeft = 0;
        uint256 timeLeft = 0;
        if(now < _periodFinished){
            timeLeft = _periodFinished.sub(now);
            rewardLeft = timeLeft.mul(rewardPerSecond); // The amount of rewards left in this week
        }
        uint256 lpRewardLeft = rewardLeft.mul(_rewardPercentLP).div(divisionFactor);
        uint256 sbRewardLeft = rewardLeft.sub(lpRewardLeft);
        
        // First figure out the pool splits for the lp tokens
        // LP pools are split evenly
        uint256 length = activePools.length;
        require(length > 0,"No active pools exist on the protocol");
        uint256 totalWeight = 0;
        uint256 i = 0;
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].lpPool == true){
                totalPools[activePools[i]].poolWeight = 1;
                totalWeight++;
            }else{
                // Get the prices of the non LP pools
                uint256 price = oracleContract.getPrice(address(totalPools[activePools[i]].sToken));
                if(price > 0){
                    totalPools[activePools[i]].price = price;
                }
            }
        }
        // Now split the lpReward between the pools
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].lpPool == true){
                uint256 rewardPercent = totalPools[activePools[i]].poolWeight.mul(divisionFactor).div(totalWeight);
                uint256 poolReward = lpRewardLeft.mul(rewardPercent).div(divisionFactor);
                forceUpdateRewardEarned(activePools[i],address(0)); // Update the stored rewards for this pool before changing the rates
                if(timeLeft > 0){
                    totalPools[activePools[i]].rewardRate = poolReward.div(timeLeft); // The rate of return per second for this pool
                }else{
                    totalPools[activePools[i]].rewardRate = 0;
                }               
            }
        }
        
        // Now we are going to rank the stablecoin pools from lowest price to highest and price closest to targetPrice
        totalWeight = 0;
        uint256 i2 = 0;
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].lpPool == false){
                uint256 amountBelow = 0;
                for(i2 = 0; i2 < length; i2++){
                    if(totalPools[activePools[i2]].lpPool == false){
                        if(i != i2){ // Do not want to check itself
                            if(totalPools[activePools[i]].price <= totalPools[activePools[i2]].price){
                                amountBelow++;
                            }
                        }
                    }
                }
                // Rank would be total non-LP pools minus amountBelow
                uint256 weight = (1 + amountBelow) * 100000;
                uint256 diff = 0;
                // Now multiply or divide the weight by its distance from the target price
                if(totalPools[activePools[i]].price > targetPrice){
                    diff = totalPools[activePools[i]].price - targetPrice;
                    diff = diff.div(1e14); // Normalize the difference
                    uint256 weightReduction = diff.mul(50); // Weight is reduced for each $0.0001 above target price
                    if(weightReduction >= weight){
                        weight = 1;
                    }else{
                        weight = weight.sub(weightReduction);
                    }
                }else if(totalPools[activePools[i]].price < targetPrice){
                    diff = targetPrice - totalPools[activePools[i]].price;
                    diff = diff.div(1e14); // Normalize the difference
                    uint256 weightGain = diff.mul(50); // Weight is added for each $0.0001 below target price
                    weight = weight.add(weightGain);      
                }
                totalPools[activePools[i]].poolWeight = weight;
                totalWeight = totalWeight.add(weight);
            }
        }
        // Now split the sbReward among the stablecoin pools
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].lpPool == false){
                uint256 rewardPercent = totalPools[activePools[i]].poolWeight.mul(divisionFactor).div(totalWeight);
                uint256 poolReward = sbRewardLeft.mul(rewardPercent).div(divisionFactor);
                forceUpdateRewardEarned(activePools[i],address(0)); // Update the stored rewards for this pool before changing the rates
                if(timeLeft > 0){
                    totalPools[activePools[i]].rewardRate = poolReward.div(timeLeft); // The rate of return per second for this pool
                }else{
                    totalPools[activePools[i]].rewardRate = 0;
                }               
            }
        }
    }
    
    function forceUpdateRewardEarned(uint256 _pid, address _address) internal updateRewardEarned(_pid, _address) {
        
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < _periodFinished ? block.timestamp : _periodFinished;
    }
    
    function rewardRate(uint256 _pid) external view returns (uint256) {
        return totalPools[_pid].rewardRate;
    }
    
    function poolSize(uint256 _pid) external view returns (uint256) {
        return totalPools[_pid].totalSupply;
    }
    
    function poolBalance(uint256 _pid, address _address) external view returns (uint256) {
        return userInfo[_pid][_address].amount;
    }
    
    function poolTokenAddress(uint256 _pid) external view returns (address) {
        return address(totalPools[_pid].sToken);
    }

    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        if (totalPools[_pid].totalSupply == 0) {
            return totalPools[_pid].rewardPerTokenStored;
        }
        return
            totalPools[_pid].rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(totalPools[_pid].lastUpdateTime)
                    .mul(totalPools[_pid].rewardRate)
                    .mul(1e18)
                    .div(totalPools[_pid].totalSupply)
            );
    }

    function rewardEarned(uint256 _pid, address account) public view returns (uint256) {
        return
            userInfo[_pid][account].amount
                .mul(rewardPerToken(_pid).sub(userInfo[_pid][account].rewardDebt))
                .div(1e18)
                .add(userInfo[_pid][account].unclaimedReward);
    }

    function deposit(uint256 _pid, uint256 amount) public updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot deposit 0");
        if(_currentWeek > 0){
            require(totalPools[_pid].active == true, "This pool is no longer active");
        }      
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.add(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.add(amount);
        totalPools[_pid].sToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposited(_pid, _msgSender(), amount);
    }

    // User can withdraw without claiming reward tokens
    function withdraw(uint256 _pid, uint256 amount) public updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot withdraw 0");
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.sub(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.sub(amount);
        totalPools[_pid].sToken.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_pid, _msgSender(), amount);
    }

    // Normally used to exit the contract and claim reward tokens
    function exit(uint256 _pid, uint256 _amount) external {
        withdraw(_pid, _amount);
        getReward(_pid);
    }

    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    function pushReward(uint256 _pid, address recipient) external updateRewardEarned(_pid, recipient) onlyOwner {
        uint256 reward = rewardEarned(_pid,recipient);
        if (reward > 0) {
            userInfo[_pid][recipient].unclaimedReward = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, it will fail as those contracts usually dump.
            if (!recipient.isContract()) {
                uint256 contractBalance = StabilizeT.balanceOf(address(this));
                if(contractBalance < reward){ // This prevents a contract with zero balance locking up
                    reward = contractBalance;
                }
                StabilizeT.safeTransfer(recipient, reward);
                emit RewardPaid(_pid, recipient, reward);
            } else {
                emit RewardDenied(_pid, recipient, reward);
            }
        }
    }

    function getReward(uint256 _pid) public updateRewardEarned(_pid, _msgSender()) {
        uint256 reward = rewardEarned(_pid,_msgSender());
        if (reward > 0) {
            userInfo[_pid][_msgSender()].unclaimedReward = 0;
            // If it is a normal user and not smart contract,
            // then the requirement will pass
            // If it is a smart contract, it will fail as those contracts usually dump.
            if (tx.origin == _msgSender()) {
                // Check the contract to make sure the reward exists
                uint256 contractBalance = StabilizeT.balanceOf(address(this));
                if(contractBalance < reward){ // This prevents a contract with zero balance locking up
                    reward = contractBalance;
                }
                StabilizeT.safeTransfer(_msgSender(), reward);
                emit RewardPaid(_pid, _msgSender(), reward);
            } else {
                emit RewardDenied(_pid, _msgSender(), reward);
            }
        }
    }
    
    // Governance only functions
    
    // Timelock variables
    // Timelock doesn't activate until protocol has started to distribute rewards
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant _timelockDuration = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    uint256 private _timelock_data_1;
    address private _timelock_address_1;
    bool private _timelock_bool_1;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(_currentWeek > 0){
            // Timelock is only required after the protocol starts
            require(now >= _timelockStart + _timelockDuration, "Timelock time not met");
        }
        _;
    }
    
    // Due to no tokens existing, must mint some tokens to add into the initial liquidity pool 
    function bootstrapLiquidty() external onlyOwner {
        require(StabilizeT.totalSupply() == 0, "This token has already been bootstrapped");
        require(StabilizeT.owner() == address(this),"The Operator does not have permission to mint tokens");
        // Take dev amount from the first week mint schedule
        uint256 devAmount = _mintSchedule[0].mul(_rewardPercentDev).div(divisionFactor);
        _mintSchedule[0] = _mintSchedule[0].sub(devAmount); // The first week doesn't give dev team any extra tokens
        StabilizeT.mint(owner(),devAmount); // The Operator will mint tokens to the developer
    }
    
    // Change the owner of the Operator contract
    // --------------------
    function startOwnerChange(address _address) external onlyOwner {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address_1 = _address;       
    }
    
    function finishOwnerChange() external onlyOwner timelockConditionsMet(1) {
        transferOwnership(_timelock_address_1);
    }
    // --------------------

    // Used to reduce minting rate in first 52 weeks
    // --------------------
    function startChangeEarlyBurnRate(uint256 _percent) external onlyOwner {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeEarlyBurnRate() external onlyOwner timelockConditionsMet(2) {
        _earlyBurnRate = _timelock_data_1;
    }
    // --------------------
    
    // Change the per transaction burn rate
    // --------------------
    function startChangeBurnRateLong(uint256 _percent) external onlyOwner {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeBurnRateLong() external onlyOwner timelockConditionsMet(3) {
       _burnRateLong  = _timelock_data_1;
       if(_currentWeek >= 53){
           // Adjust the token's burn rate
           StabilizeT.initiateBurn(_burnRateLong);
       }
    }
    // --------------------
    
    // Change the long term emission rate
    // --------------------
    function startChangeEmissionRateLong(uint256 _percent) external onlyOwner {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeEmissionRateLong() external onlyOwner timelockConditionsMet(4) {
        _emissionRateLong =_timelock_data_1;
    }
    // --------------------

    // Change the percent of rewards that is dedicated to LP providers
    // --------------------
    function startChangeRewardPercentLP(uint256 _percent) external onlyOwner {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data_1 = _percent;
    }
    
    function finishChangeRewardPercentLP() external onlyOwner timelockConditionsMet(5) {
        _rewardPercentLP = _timelock_data_1;
    }
    // --------------------

    // Change the target price for the stablecoins, due to inflation issues
    // --------------------
    function startChangeTargetPrice(uint256 _price) external onlyOwner {
        _timelockStart = now;
        _timelockType = 6;
        _timelock_data_1 = _price;
    }
    
    function finishChangeTargetPrice() external onlyOwner timelockConditionsMet(6) {
        targetPrice = _timelock_data_1;
    }
    // --------------------
    
    // Change the price oracle contract used, in case of upgrades
    // --------------------
    function startChangePriceOracle(address _address) external onlyOwner {
        _timelockStart = now;
        _timelockType = 7;
        _timelock_address_1 = _address;
    }
    
    function finishChangePriceOracle() external onlyOwner timelockConditionsMet(7) {
        oracleContract = StabilizePriceOracle(_timelock_address_1);
    }
    // --------------------
   
    // Add a new token to the pool
    // --------------------
    function startAddNewPool(address _address, bool _lpPool) external onlyOwner {
        _timelockStart = now;
        _timelockType = 8;
        _timelock_address_1 = _address;
        _timelock_bool_1 = _lpPool;
        if(_currentWeek == 0){
            finishAddNewPool(); // Automatically add the pool if protocol hasn't started yet
        }
    }
    
    function finishAddNewPool() public onlyOwner timelockConditionsMet(8) {
        // This adds a new pool to the pool lists
        totalPools.push(
            PoolInfo({
                sToken: IERC20(_timelock_address_1),
                poolID: poolLength(),
                lpPool: _timelock_bool_1,
                rewardRate: 0,
                poolWeight: 0,
                price: 0,
                rewardPerTokenStored: 0,
                lastUpdateTime: 0,
                totalSupply: 0,
                active: false
            })
        );
    }
    // --------------------
    
    // Select a pool to activate in rewards distribution
    // --------------------
    function startAddActivePool(uint256 _pid) external onlyOwner {
        _timelockStart = now;
        _timelockType = 9;
        _timelock_data_1 = _pid;
    }
    
    function finishAddActivePool() external onlyOwner timelockConditionsMet(9) {
        require(totalPools[_timelock_data_1].active == false, "This pool is already active");
        activePools.push(_timelock_data_1);
        totalPools[_timelock_data_1].active = true;
        // Rebalance the pools now that there is a new pool
        if(_currentWeek > 0){
            lastOracleTime = now - minOracleRefresh; // Force oracle price to update
            rebalancePoolRewards();
        }
    }
    // --------------------
    
    // Select a pool to deactivate from rewards distribution
    // --------------------
    function startRemoveActivePool(uint256 _pid) external onlyOwner {
        _timelockStart = now;
        _timelockType = 10;
        _timelock_data_1 = _pid;
    }
    
    function finishRemoveActivePool() external onlyOwner timelockConditionsMet(10) updateRewardEarned(_timelock_data_1, address(0)) {
        uint256 length = activePools.length;
        for(uint256 i = 0; i < length; i++){
            if(totalPools[activePools[i]].poolID == _timelock_data_1){
                // Move all the remaining elements down one
                totalPools[activePools[i]].active = false;
                totalPools[activePools[i]].rewardRate = 0; // Deactivate rewards but first make sure to store current rewards
                for(uint256 i2 = i; i2 < length-1; i2++){
                    activePools[i2] = activePools[i2 + 1]; // Shift the data down one
                }
                activePools.pop(); //Remove last element
                break;
            }
        }
        // Rebalance the remaining pools 
        if(_currentWeek > 0){
            lastOracleTime = now - minOracleRefresh; // Force oracle price to update
            rebalancePoolRewards();
        }
    }
    // --------------------
}