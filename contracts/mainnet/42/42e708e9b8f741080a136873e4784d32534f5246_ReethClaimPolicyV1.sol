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

// File: contracts/ReethClaimPolicyV1.sol

pragma solidity =0.6.6;

// This claim policy determines how much reeth is minted to a user based on time in the pool, eth spent and total eth value of strategy
// Rules for this policy are: exponentially (per time) increasing rewards rate up to a certain point, then linearly increasing
// To a maximum percent of claimback
// There is a minimum amount of time required to stake before being eligible for claiming

interface Staker {
    function getUserBalance(address _user) external view returns (uint256);
    function getLastActionTime(address _user) external view returns (uint256);
    function getLastETHSpent(address _user) external view returns (uint256);
    function getETHSpentSinceAction(address _user) external view returns (uint256);
}

interface PriceOracle {
    function getLatestREETHPrice() external view returns (uint256);
    function updateREETHPrice() external;
}

interface ZsTokenProtocol {
    function getCurrentStrategy() external view returns (address);
}

contract ReethClaimPolicyV1 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    // variables
    uint256 public minStakeTime = 5; // At least 5 seconds staked before being able to claim reeth
    uint256 public eFactor = 36; // The exponential factor that determines the early growth rate of claiming
    uint256 public eFactorLength = 14 days; // The length of period where the eFactor applies
    uint256 public maxEarlyAccumulation = 5200; // The most we can earn via the exponential early growth
    uint256 public maxAccumulatedClaim = 44800; // Total maximum accumulation claim back
    uint256 public dailyClaimRate = 500; // The amount of claim increases after the exponential growth phase
    
    address public reethAddress; // The address for the REETH tokens
    address public zsTokenAddress;
    address public stakerAddress; // The address for the staker
    address public priceOracleAddress; // The address of the price oracle

    uint256 constant DIVISION_FACTOR = 100000;
    address constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH address

    constructor(
        address _reeth,
        address _staker,
        address _oracle
    ) public {
        reethAddress = _reeth;
        stakerAddress = _staker;
        priceOracleAddress = _oracle;
    }
    
    modifier onlyStaker() {
        require(_msgSender() == stakerAddress, "Only staker can call this function");
        _;
    }
    
    // functions
    
    
    function getClaimBackPercent(address _user) public view returns (uint256) {
        // This function will calculate the max amount of claimback percent the user can expect based on accumulation time
        Staker _stake = Staker(stakerAddress);
        // First do sanity checks
        {
            uint256 _bal = _stake.getUserBalance(_user);
            if(_bal == 0){
                return 0;
            }
            uint256 _spent = _stake.getETHSpentSinceAction(_user);
            if(_spent == 0){
                return 0;
            }
        }
        uint256 lastTime = _stake.getLastActionTime(_user);
        if(lastTime == 0){
            return 0; // No deposits ever
        }
        if(now < lastTime + minStakeTime){
            return 0; // Too soon to claim
        }
        uint256 timeDiff = now - lastTime; // Will be at least minStakeTime
        
        // Complicated math stuff
        uint256 percent = eFactor.mul(timeDiff**2).div(1e10);
        if(percent > maxEarlyAccumulation){
            percent = maxEarlyAccumulation;
        }
        if(timeDiff > eFactorLength){
            // Add an additional percent up to a higher percent
            uint256 extra = dailyClaimRate.mul(timeDiff.sub(eFactorLength)).div(1 days);
            if(extra > maxAccumulatedClaim){
                extra = maxAccumulatedClaim;
            }
            percent = percent.add(extra);
        }
        return percent;
    }
    
    // Claim call
    function getClaimable(address _user) external onlyStaker returns (uint256){
        require(priceOracleAddress != address(0), "Price oracle not set yet");
        PriceOracle(priceOracleAddress).updateREETHPrice(); // Update the price
        uint256 claimable = queryClaimable(_user);
        return claimable;
    }
    
    function queryClaimable(address _user) public view returns (uint256) {
        require(PriceOracle(priceOracleAddress).getLatestREETHPrice() > 0, "There is no price yet determined for REETH");
        require(stakerAddress != address(0), "Staker not set yet");
        require(zsTokenAddress != address(0), "ZS token not set yet");
        uint256 claimPercent = getClaimBackPercent(_user);
        if(claimPercent == 0){
            return 0;
        }
        uint256 stackValue = calculateUserETHValue(_user); // Stack value in eth
        uint256 spentAmount = Staker(stakerAddress).getETHSpentSinceAction(_user);
        if(spentAmount == 0 || stackValue == 0){
            return 0;
        }
        uint256 claimable = stackValue.mul(claimPercent).div(DIVISION_FACTOR); // Maximum amount claimable in ETH based on stack
        if(claimable > spentAmount){
            claimable = spentAmount; // Cannot claim more than spent
        }
        uint256 reethPrice = PriceOracle(priceOracleAddress).getLatestREETHPrice();
        // Convert claimable to reeth units
        claimable = claimable.mul(10**uint256(IERC20(reethAddress).decimals())).div(10**uint256(IERC20(WETH_ADDRESS).decimals()));
        // This is claimable in reeth
        claimable = claimable.mul(1e18).div(reethPrice);
        return claimable;
    }
    
    function calculateUserETHValue(address _user) public view returns (uint256) {
        // Now calculate the eth value of the user's strategy position
        // This returns how much eth the user's staked position is worth
        Staker _stake = Staker(stakerAddress);
        uint256 _bal = _stake.getUserBalance(_user); // Amount of ZS tokens
        if(_bal == 0){ return 0; }
        ZsTokenProtocol zsToken = ZsTokenProtocol(zsTokenAddress);
        address strategyAddress = zsToken.getCurrentStrategy(); 
        uint256 totalZS = IERC20(zsTokenAddress).totalSupply();
        uint256 totalETH = IERC20(WETH_ADDRESS).balanceOf(zsTokenAddress);
        uint256 totalREETH = IERC20(reethAddress).balanceOf(zsTokenAddress);
        if(strategyAddress != address(0)){
            totalETH += IERC20(WETH_ADDRESS).balanceOf(strategyAddress);
            totalREETH += IERC20(reethAddress).balanceOf(strategyAddress);
        }
        uint256 reethPrice = PriceOracle(priceOracleAddress).getLatestREETHPrice();
        // Convert reeth decimals to ETH
        totalREETH = totalREETH.mul(10**uint256(IERC20(WETH_ADDRESS).decimals())).div(10**uint256(IERC20(reethAddress).decimals()));
        totalETH += totalREETH.mul(reethPrice).div(1e18);
        return totalETH.mul(_bal).div(totalZS); // This will be the user's equivalent balance in eth worth
    }
    
    // Governance only functions
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[6] private _timelock_data;
    
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
    
    // Change the claimable staker
    // --------------------
    function startChangeStaker(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
        if(stakerAddress == address(0)){
            _timelockType = 0;
            internalChangeStaker(_timelock_address);
        }
    }
    
    function finishChangeStaker() external onlyGovernance timelockConditionsMet(2) {
        internalChangeStaker(_timelock_address);
    }
    
    function internalChangeStaker(address _addr) internal {
        stakerAddress = _addr;
    }
    // --------------------
    
    // Change the price oracle
    // --------------------
    function startChangePriceOracle(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
        if(priceOracleAddress == address(0)){
            _timelockType = 0;
            internalChangePriceOracle(_timelock_address);
        }
    }
    
    function finishChangePriceOracle() external onlyGovernance timelockConditionsMet(3) {
        internalChangePriceOracle(_timelock_address);
    }
    
    function internalChangePriceOracle(address _addr) internal {
        priceOracleAddress = _addr;
    }
    // --------------------
    
    // Change the zs token
    // --------------------
    function startChangeZSToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;
        if(zsTokenAddress == address(0)){
            _timelockType = 0;
            internalChangeZSToken(_timelock_address);
        }
    }
    
    function finishChangeZSToken() external onlyGovernance timelockConditionsMet(4) {
        internalChangeZSToken(_timelock_address);
    }
    
    function internalChangeZSToken(address _addr) internal {
        zsTokenAddress = _addr;
    }
    // --------------------
    
    // Change the claim factors
    // --------------------
    function startChangeClaimFactors(uint256 _minStake, uint256 _eFac, uint256 _eFacLength, uint256 _maxEarly,
                                    uint256 _dailyPercent, uint256 _maxEnd) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data[0] = _minStake;
        _timelock_data[1] = _eFac;
        _timelock_data[2] = _eFacLength;
        _timelock_data[3] = _maxEarly;
        _timelock_data[4] = _dailyPercent;
        _timelock_data[5] = _maxEnd;
    }
    
    function finishChangeClaimFactors() external onlyGovernance timelockConditionsMet(5) {
        minStakeTime = _timelock_data[0];
        eFactor = _timelock_data[1];
        eFactorLength = _timelock_data[2];
        maxEarlyAccumulation = _timelock_data[3];
        dailyClaimRate = _timelock_data[4];
        maxAccumulatedClaim = _timelock_data[5];
    }
    // --------------------
   
}