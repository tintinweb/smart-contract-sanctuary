// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./libraries/SafeMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IRFTStake.sol";
import "./lib/BEP20.sol";
import "./lib/Auth.sol";
import "./lib/Pausable.sol";

contract RFTStake is IRFTStake, Auth, Pausable, ReentrancyGuard{
    using SafeMath for uint;

    struct Stake {
        uint256 lastStaked;
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    address public override stakingToken;
    address public override rewardToken;

    uint256 public override totalRealised;
    uint256 public override totalStaked;

    mapping (address => Stake) public stakes;

    uint256 _accuracyFactor = 10 ** 36;
    uint256 _rewardsPerLP;
    uint256 _lastContractBalance;
    
    uint256 public penaltyTime = 7 days;
    uint256 public penaltyFee = 50; // 0.50%
    uint256 public penaltyFeeDenominator = 10000;
    address public penaltyFeeReceiver = 0x000000000000000000000000000000000000dEaD;

    constructor(address _stakingToken, address _rewardToken) Auth(msg.sender) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    /**
     * Total rewards realised and to be realised
     */
    function getTotalRewards() external override view returns (uint256) {
        return totalRealised + IBEP20(rewardToken).balanceOf(address(this)).sub(totalStaked);
    }

    /**
     * Total rewards per LP cumulatively, inflated by _accuracyFactor
     */
    function getCumulativeRewardsPerLP() external override view returns (uint256) {
        return _rewardsPerLP;
    }

    /**
     * The last balance the contract had
     */
    function getLastContractBalance() external override view returns (uint256) {
        return _lastContractBalance;
    }

    /**
     * Total amount of transaction fees sent or to be sent to stakers
     */
    function getAccuracyFactor() external override view returns (uint256) {
        return _accuracyFactor;
    }

    /**
     * Returns amount of LP that address has staked
     */
    function getStake(address account) public override view returns (uint256) {
        return stakes[account].amount;
    }

    /**
     * Returns total earnings (realised + unrealised)
     */
    function getRealisedEarnings(address staker) external view override returns (uint256) {
        return stakes[staker].totalRealised; // realised gains plus outstanding earnings
    }

    /**
     * Returns unrealised earnings
     */
    function getUnrealisedEarnings(address staker) external view override returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = stakes[staker].amount.mul(getCurrentRewardsPerLP()).div(_accuracyFactor);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards.sub(stakerTotalExcluded);
    }

    function getCumulativeRewards(uint256 amount) public view returns (uint256) {
        return amount.mul(_rewardsPerLP).div(_accuracyFactor);
    }

    function stake(uint amount) nonReentrant external override {
        require(amount > 0);

        _realise(msg.sender);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function stakeAll() nonReentrant external override {
        uint256 amount = IBEP20(stakingToken).balanceOf(msg.sender);
        require(amount > 0);

        _realise(msg.sender);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function unstake(uint amount) nonReentrant external override {
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function unstakeAll() nonReentrant external override {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function realise() nonReentrant external override notPaused {
        _realise(msg.sender);
    }

    function _realise(address staker) internal {
        _updateRewards();

        uint amount = earnt(staker);

        if (getStake(staker) == 0 || amount == 0) {
            return;
        }

        stakes[staker].totalRealised = stakes[staker].totalRealised.add(amount);
        stakes[staker].totalExcluded = stakes[staker].totalExcluded.add(amount);
        totalRealised = totalRealised.add(amount);

        IBEP20(rewardToken).transfer(staker, amount);

        _updateRewards();

        emit Realised(staker, amount);
    }
    
    function earnt(address staker) internal view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = getCumulativeRewards(stakes[staker].amount);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards.sub(stakerTotalExcluded);
    }

    function _stake(address staker, uint256 amount) internal notPaused {
        require(amount > 0);

        // add to current address' stake
        stakes[staker].lastStaked = block.timestamp;
        stakes[staker].amount = stakes[staker].amount.add(amount);
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked = totalStaked.add(amount);

        emit Staked(staker, amount);
    }

    function _unstake(address staker, uint256 amount) internal notPaused {
        require(stakes[staker].amount >= amount, "Insufficient Stake");

        _realise(staker); // realise staking gains

        // remove stake
        stakes[staker].amount = stakes[staker].amount.sub(amount);
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked = totalStaked.sub(amount);

        if(stakes[staker].lastStaked + penaltyTime > block.timestamp){
            uint256 penalty = amount.mul(penaltyFee).div(penaltyFeeDenominator);
            uint256 remaining = amount.sub(penalty);
            
            IBEP20(stakingToken).transfer(staker, remaining);
            IBEP20(stakingToken).transfer(penaltyFeeReceiver, penalty);
            
            emit EarlyWithdrawalPenalty(staker, penalty);
        }else{
            IBEP20(stakingToken).transfer(staker, amount);
        }

        emit Unstaked(staker, amount);
    }

    function _updateRewards() internal  {
        uint tokenBalance = getTokenBalance();

        if(tokenBalance > _lastContractBalance && totalStaked != 0) {
            uint256 newRewards = tokenBalance.sub(_lastContractBalance);
            uint256 additionalAmountPerLP = newRewards.mul(_accuracyFactor).div(totalStaked);
            _rewardsPerLP = _rewardsPerLP.add(additionalAmountPerLP);
        }

        if(totalStaked > 0){ _lastContractBalance = tokenBalance; }
    }

    function getCurrentRewardsPerLP() public view returns (uint256 currentRewardsPerLP) {
        uint tokenBalance = getTokenBalance();

        if(tokenBalance > _lastContractBalance && totalStaked != 0){
            uint256 newRewards = tokenBalance.sub(_lastContractBalance);
            uint256 additionalAmountPerLP = newRewards.mul(_accuracyFactor).div(totalStaked);
            currentRewardsPerLP = _rewardsPerLP.add(additionalAmountPerLP);
        }
    }

    function getTokenBalance() public view returns (uint256 tokenBalance) {
        return IBEP20(rewardToken).balanceOf(address(this)).sub(totalStaked);
    }

    function setAccuracyFactor(uint256 newFactor) external authorized {
        _rewardsPerLP = _rewardsPerLP.mul(newFactor).div(_accuracyFactor); // switch _rewardsPerLP to be inflated by the new factor instead
        _accuracyFactor = newFactor;
    }
    
    function setPenalty(uint256 time, uint256 fee, uint256 denominator, address receiver) external authorized {
        penaltyTime = time;
        penaltyFee = fee;
        penaltyFeeDenominator = denominator;
        penaltyFeeReceiver = receiver;
    }

    function emergencyUnstakeAll() external {
        require(stakes[msg.sender].amount > 0, "No Stake");

        IBEP20(stakingToken).transfer(msg.sender, stakes[msg.sender].amount);
        totalStaked = totalStaked.sub(stakes[msg.sender].amount);
        stakes[msg.sender].amount = 0;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT


pragma solidity ^0.8;

import "./Auth.sol";

abstract contract Pausable is Auth {

    bool public paused;

    constructor() {
        paused = false;
    }

    modifier notPaused {
        require(isPaused() == false || isAuthorized(msg.sender), "Contract is paused");
        _;
    }

    modifier onlyWhenPaused {
       require(isPaused() == true || isAuthorized(msg.sender), "Contract is active");
        _;
    }

    function pause() notPaused onlyOwner external {
        paused = true;
        emit Paused();
    }

    function unpause() onlyWhenPaused onlyOwner public {
        paused = false;
        emit Unpaused();
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    event Paused();
    event Unpaused();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "../interfaces/IBEP20.sol";
import "../libraries/SafeMath.sol";

/**
 * Implement the basic BEP20 functions
 */
abstract contract BEP20 is IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply = 0;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals = 18;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8;


abstract contract Auth{

    address owner;

    mapping (address => bool) private authorizations;

    constructor(address _owner){
        owner = _owner;
        authorizations[owner] = true;
    }

    modifier onlyOwner{
        require(isOwner(msg.sender), "Only owner can call this function");
        _;
    }

    modifier authorized{
        require(isAuthorized(msg.sender), "Only authorized users can call this function");
        _;
    }

    function isAuthorized(address _account) public view returns (bool){
        return authorizations[_account];
    }

    function isOwner(address account) private view returns (bool){
        return account == owner;
    }

    function authorize(address _account) external authorized{
        authorizations[_account] = true;
    }

    function revoke(address _account) external onlyOwner{
        authorizations[_account] = false;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IRFTStake {

   function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);

    function totalStaked() external view returns (uint256);
    function totalRealised() external view returns (uint256);

    function getTotalRewards() external view returns (uint256);

    function getCumulativeRewardsPerLP() external view returns (uint256);
    function getLastContractBalance() external view returns (uint256);
    function getAccuracyFactor() external view returns (uint256);

    function getStake(address staker) external view returns (uint256);
    function getRealisedEarnings(address staker) external returns (uint256);
    function getUnrealisedEarnings(address staker) external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeAll() external;

    function unstake(uint256 amount) external;
    function unstakeAll() external;

    function realise() external;

    event Realised(address account, uint amount);
    event Compounded(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);
    event EarlyWithdrawalPenalty(address account, uint amount);
}

interface IRFTStakeLP{
    function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);
    
    function totalStaked() external view returns (uint256);
    function totalRealised() external view returns (uint256);

    function getTotalRewards() external view returns (uint256);

    function getCumulativeRewardsPerLP() external view returns (uint256);
    function getLastContractBalance() external view returns (uint256);
    function getAccuracyFactor() external view returns (uint256);

    function getStake(address staker) external view returns (uint256);
    function getRealisedEarnings(address staker) external returns (uint256);
    function getUnrealisedEarnings(address staker) external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeFor(address staker, uint256 amount) external;
    function stakeAll() external;

    function unstake(uint256 amount) external;
    function unstakeAll() external;
    
    function realise() external;

    event Realised(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}