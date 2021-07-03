/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

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
     * Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _owner;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts/ReethMonetaryPolicyV1.sol

pragma solidity =0.6.6;

// This monetary policy controls the rebase mechanism in the reeth token
// Rebase can only be called once a day by a non-contract

interface PriceOracle {
    function getLatestREETHPrice() external view returns (uint256);
    function updateREETHPrice() external; // Update price oracle upon every token transfer
    function mainLiquidity() external view returns (address); // Returns address of REETH/ETH LP pair
}

interface UniswapLikeLPToken {
    function sync() external; // Call sync right after rebase call
}

interface ReethToken {
    function isRebaseable() external view returns (bool);
    function reethScalingFactor() external view returns (uint256);
    function maxScalingFactor() external view returns (uint256);
    function rebase(uint256 _price, uint256 _indexDelta, bool _positive) external returns (uint256); // Epoch is stored in the token
}

interface SpentOracle{
    function addUserETHSpent(address _add, uint256 _ethback) external;
}

contract ReethMonetaryPolicyV1 is Ownable, ReentrancyGuard {
    // Adopted from YamRebaserV2
    using SafeMath for uint256;

    /// @notice an event emitted when deviationThreshold is changed
    event NewDeviationThreshold(uint256 oldDeviationThreshold, uint256 newDeviationThreshold);
    
    /// @notice Spreads out getting to the target price
    uint256 public rebaseLag;

    /// @notice Peg target
    uint256 public targetRate;
    
    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    uint256 public deviationThreshold;
    
    /// @notice More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    /// @notice Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    /// @notice The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    /// @notice The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    /// @notice The number of rebase cycles since inception
    uint256 public epoch;
    
    /// @notice Reeth token address
    address public reethAddress;
    
    // price oracle address
    address public reethPriceOracle;
    
    // spent eth oracle
    address public spentEthOracle;
    
    /// @notice list of uniswap like pairs to sync
    address[] public uniSyncPairs;
    
    // Used for division scaling math
    uint256 constant BASE = 1e18;
    
    constructor(
        address _reethAddress,
        address _priceOracle,
        address _spentOracle
    )
        public
    {
        reethAddress = _reethAddress;
        reethPriceOracle = _priceOracle;
        spentEthOracle = _spentOracle;
        
        minRebaseTimeIntervalSec = 1 days;
        rebaseWindowOffsetSec = 12 hours; // 12:00 UTC rebase
        
        // 1 REETH = 1 ETH
        targetRate = BASE;
        
        // once daily rebase, with targeting reaching peg in 10 days
        rebaseLag = 10;
        
        // 5%
        deviationThreshold = 5 * 10**16;
        
        // 60 minutes
        rebaseWindowLengthSec = 1 hours;

    }
    
    // This is an optional function that is ran anytime a reeth transfer is made
    function reethTransferActions() external {
        require(_msgSender() == reethAddress, "Not sent from REETH token");
        // We are running the price oracle update
        if(reethPriceOracle != address(0)){
            PriceOracle oracle = PriceOracle(reethPriceOracle);
            oracle.updateREETHPrice(); // Update the price of reeth            
        }
    }
    
    // Rebase function
    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     *      and targetRate is 1e18
     */
     // Users can give their gas spent to another user if they choose to (in case of bot calls)
    function rebase(address _delegateCaller)
        public
    {
        // Users will be recognized for 1.5x the eth they spend when using this oracle
        uint256 gasUsed = gasleft(); // Start calculate gas spent
        
        if(_delegateCaller == address(0)){
            _delegateCaller = _msgSender();
        }
        
        // EOA only or gov
        require(_msgSender() == tx.origin || _msgSender() == governance(), "Contract call not allowed unless governance");
        // ensure rebasing at correct time
        require(inRebaseWindow() == true, "Not in rebase window");

        // This comparison also ensures there is no reentrancy.
        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now, "Call already executed for this epoch");

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now.sub(
            now.mod(minRebaseTimeIntervalSec)).add(rebaseWindowOffsetSec);

        PriceOracle oracle = PriceOracle(reethPriceOracle);
        oracle.updateREETHPrice(); // Update the price of reeth
        
        uint256 exchangeRate = oracle.getLatestREETHPrice();
        require(exchangeRate > 0, "Bad oracle price");

        // calculates % change to supply
        (uint256 offPegPerc, bool positive) = computeOffPegPerc(exchangeRate);

        uint256 indexDelta = offPegPerc;

        // Apply the Dampening factor.
        indexDelta = indexDelta.div(rebaseLag);

        ReethToken reeth = ReethToken(reethAddress);

        if (positive) {
            require(reeth.reethScalingFactor().mul(BASE.add(indexDelta)).div(BASE) < reeth.maxScalingFactor(), "new scaling factor will be too big");
        }

        // rebase the token
        reeth.rebase(exchangeRate, indexDelta, positive);

        // sync the pools
        // first sync the main pool
        address mainLP = oracle.mainLiquidity();
        UniswapLikeLPToken lp = UniswapLikeLPToken(mainLP);
        lp.sync(); // Sync this pool post rebase
        
        // And any additional pairs to sync
        for(uint256 i = 0; i < uniSyncPairs.length; i++){
            lp = UniswapLikeLPToken(uniSyncPairs[i]);
            lp.sync();
        }

        if(spentEthOracle != address(0)){
            // Factor this gas usage to stake into the oracle
            SpentOracle spent = SpentOracle(spentEthOracle);
            gasUsed = gasUsed.sub(gasleft()).mul(tx.gasprice); // The amount of ETH used for this transaction
            gasUsed = gasUsed.mul(3).div(2); // Give a bonus 50%
            spent.addUserETHSpent(_delegateCaller, gasUsed);
        }
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {
        // First check if reeth token is active for rebasing
        if(ReethToken(reethAddress).isRebaseable() == false){return false;}
        
        return (block.timestamp.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
            block.timestamp.mod(minRebaseTimeIntervalSec) <
            (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)));
    }

    /**
     * @return Computes in % how far off market is from peg
     */
    function computeOffPegPerc(uint256 rate)
        private
        view
        returns (uint256, bool)
    {
        if (withinDeviationThreshold(rate)) {
            return (0, false);
        }

        // indexDelta =  (rate - targetRate) / targetRate
        if (rate > targetRate) {
            return (rate.sub(targetRate).mul(BASE).div(targetRate), true);
        } else {
            return (targetRate.sub(rate).mul(BASE).div(targetRate), false);
        }
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate)
        private
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** 18);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }

    // Governance only functions
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[3] private _timelock_data;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Add to the synced pairs
    // --------------------
    function startAddSyncPair(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishAddSyncPair() external onlyGovernance timelockConditionsMet(2) {
        uniSyncPairs.push(_timelock_address);
    }
    // --------------------
    
    // Remove from synced pairs
    // --------------------
    function startRemoveSyncPair(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishRemoveSyncPair() external onlyGovernance timelockConditionsMet(3) {
        uint256 length = uniSyncPairs.length;
        for(uint256 i = 0; i < length; i++){
            if(uniSyncPairs[i] == _timelock_address){
                for(uint256 i2 = i; i2 < length-1; i2++){
                    uniSyncPairs[i2] =uniSyncPairs[i2 + 1]; // Shift the data down one
                }
                uniSyncPairs.pop(); //Remove last element
                break;
            }
        }
    }
    // --------------------
    
    // Change the deviation threshold
    // --------------------
    function startChangeDeviationThreshold(uint256 _threshold) external onlyGovernance {
        require(_threshold > 0);
        _timelockStart = now;
        _timelockType = 4;
        _timelock_data[0] = _threshold;
    }
    
    function finishChangeDeviationThreshold() external onlyGovernance timelockConditionsMet(4) {
        deviationThreshold = _timelock_data[0];
    }
    // --------------------
    
    // Change the rebase lag
    // --------------------
    function startChangeRebaseLag(uint256 _lag) external onlyGovernance {
        require(_lag > 1);
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data[0] = _lag;
    }
    
    function finishChangeRebaseLag() external onlyGovernance timelockConditionsMet(5) {
        rebaseLag = _timelock_data[0];
    }
    // --------------------
    
    // Change the target rate
    // --------------------
    function startChangeTargetRate(uint256 _rate) external onlyGovernance {
        require(_rate > 0);
        _timelockStart = now;
        _timelockType = 6;
        _timelock_data[0] = _rate;
    }
    
    function finishChangeTargetRate() external onlyGovernance timelockConditionsMet(6) {
        targetRate = _timelock_data[0];
    }
    // --------------------
    
    // Change the rebase times
    // --------------------
    function startChangeRebaseTimes(uint256 _UTCOffset, uint256 _windowLength, uint256 _frequency) external onlyGovernance {
        require(_frequency > 0);
        require(_UTCOffset < _frequency);
        require(_UTCOffset + _windowLength < _frequency);
        _timelockStart = now;
        _timelockType = 7;
        _timelock_data[0] = _UTCOffset;
        _timelock_data[1] = _windowLength;
        _timelock_data[2] = _frequency;
    }
    
    function finishChangeRebaseTimes() external onlyGovernance timelockConditionsMet(7) {
        rebaseWindowOffsetSec = _timelock_data[0];
        rebaseWindowLengthSec = _timelock_data[1];
        minRebaseTimeIntervalSec = _timelock_data[2];
    }
    // --------------------
    
    // Change the eth spent oracle
    // --------------------
    function startChangeSpentOracle(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 8;
        _timelock_address = _address;
    }
    
    function finishChangeSpentOracle() external onlyGovernance timelockConditionsMet(8) {
        spentEthOracle = _timelock_address;
    }
    // --------------------
   
}