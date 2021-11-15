// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/IBEP20/IBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETBStaking is Ownable {
    using SafeMath for uint256;

    struct HolderInfo {
        uint256 _depositTime;
        uint256 _amount;
    }

    struct StakingStage {
        uint256 _reward;
        uint256 _startTime;
        uint256 _endTime;
        uint256 _tokens;
        uint256 _holders;
        uint256 _balance;
        uint256 _rewardPerDay;
    }

    event Stake(
        uint256 indexed _stage,
        address indexed _user,
        uint256 indexed _amount
    );

    event StakingStageCreated(
        uint256 indexed _stage,
        uint256 indexed _startTime,
        uint256 indexed _endTime,
        uint256 _reward
    );

    event Withdraw(
        uint256 indexed _stage,
        address indexed _user,
        uint256 indexed _amount,
        uint256 _reward,
        uint256 _depositTime
    );

    address internal _tokenForStaking;
    address internal _rewardToken;

    uint256 internal _daySeconds = 1 days;

    StakingStage[] private _stakingStages;

    mapping(uint256 => mapping(address => HolderInfo)) _stagesStakeHolders;

    constructor(
        address tokenForStaking,
        address rewardToken) {
        _tokenForStaking = tokenForStaking;
        _rewardToken = rewardToken;
    }

    function addStakeStage(uint256 reward, uint256 startTime, uint256 endTime) external onlyOwner {
        require(reward > 0, "ETBStaking: reward must be > 0");
        require(endTime > startTime, "ETBStaking: startTime must be less then endTIme");
        require(IBEP20(_rewardToken).balanceOf(msg.sender) >= reward, 'ETBStaking: not enough required BEP20 token');

        IBEP20(_rewardToken).transferFrom(
            address(msg.sender),
            address(this),
            reward
        );

        (, uint256 stakingDurationDays) = SafeMath.tryDiv(endTime - startTime, _daySeconds);
        (, uint256 rewardPerDay) = SafeMath.tryDiv(reward, stakingDurationDays);
        _stakingStages.push(StakingStage({
            _reward : reward,
            _startTime : startTime,
            _endTime : endTime,
            _tokens : 0,
            _holders : 0,
            _balance : reward,
            _rewardPerDay : rewardPerDay
            }));


        emit StakingStageCreated(
            _stakingStages.length,
            startTime,
            endTime,
            reward
        );
    }

    function stake(uint256 stage, uint256 value) external {
        require(value > 0, 'ETBStaking: stake must be > 0');
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');
        require(block.timestamp > _stakingStages[stage]._startTime, 'ETBStaking: staking not stared yet');
        require(block.timestamp <= _stakingStages[stage]._endTime, 'ETBStaking: staking ended');
        require(IBEP20(_tokenForStaking).balanceOf(msg.sender) >= value, 'ETBStaking: not enough required BEP20 token');
        HolderInfo storage stakeHolder = _stagesStakeHolders[stage][msg.sender];
        require(stakeHolder._depositTime == 0, "ETBStaking: User already in staking pool");

        IBEP20(_tokenForStaking).transferFrom(
            address(msg.sender),
            address(this),
            value
        );

        stakeHolder._depositTime = block.timestamp;
        stakeHolder._amount += value;

        _stakingStages[stage]._holders += 1;
        _stakingStages[stage]._tokens += value;

        emit Stake({
            _stage : stage,
            _user : msg.sender,
            _amount : value
            }
        );
    }

    function withdraw(uint256 stage) external {
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');
        require(block.timestamp > _stakingStages[stage]._startTime, 'ETBStaking: staking not stared yet');
        require(IBEP20(_rewardToken).balanceOf(address(this)) >= _calculateReward(stage, msg.sender), 'ETBStaking: not enough balance for reward BEP20 token');
        HolderInfo storage stakeHolder = _stagesStakeHolders[stage][msg.sender];
        require(stakeHolder._depositTime > 0, "ETBStaking: Not stakeholder");
        require(stakeHolder._amount > 0, "ETBStaking: User already withdrawn");

        uint256 value = stakeHolder._amount;
        uint256 reward = _calculateReward(stage, msg.sender);

        IBEP20(_tokenForStaking).transfer(address(msg.sender), value);
        IBEP20(_rewardToken).transfer(address(msg.sender), reward);

        uint256 depositTime = stakeHolder._depositTime;

        _stakingStages[stage]._holders -= 1;
        _stakingStages[stage]._tokens -= stakeHolder._amount;
        _stakingStages[stage]._balance -= reward;

        stakeHolder._depositTime = 0;
        stakeHolder._amount = 0;

        emit Withdraw({
            _stage : stage,
            _user : msg.sender,
            _amount : value,
            _reward : reward,
            _depositTime : depositTime
            });
    }

    function getReward(uint256 stage, address holderAddress) external view returns (uint256) {
        return _calculateReward(stage, holderAddress);
    }

    function _calculateReward(uint256 stage, address holderAddress) internal view returns (uint256) {
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');

        HolderInfo storage stakeHolder = _stagesStakeHolders[stage][holderAddress];
        require(stakeHolder._depositTime > 0, "ETBStaking: Not stakeholder");

        //max end time for reward
        uint256 current = Math.min(block.timestamp, _stakingStages[stage]._endTime);

        //duration of holding
        (,uint256  holderDurationDay) = SafeMath.tryDiv(current - stakeHolder._depositTime, _daySeconds);
        //poolWeight
        (,uint256  poolWeight) = SafeMath.tryDiv(stakeHolder._amount, _stakingStages[stage]._tokens);

        //calc rewardPerDay * poolWeight
        (,uint256  rewardRate) = SafeMath.tryMul(_stakingStages[stage]._rewardPerDay, poolWeight);
        //bonus by days
        (,uint256  reward) = SafeMath.tryMul(holderDurationDay, rewardRate);

        return reward;
    }

    function isStackingStageIsActive(uint256 stage) external view returns (bool) {
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');
        return block.timestamp > _stakingStages[stage]._startTime && block.timestamp <= _stakingStages[stage]._endTime;
    }

    function getStackingStagesLength() external view returns (uint256) {
        return _stakingStages.length;
    }

    function getStackingStage(uint256 stage) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');
        return (
        _stakingStages[stage]._reward,
        _stakingStages[stage]._startTime,
        _stakingStages[stage]._endTime,
        _stakingStages[stage]._tokens,
        _stakingStages[stage]._holders,
        _stakingStages[stage]._balance,
        _stakingStages[stage]._rewardPerDay
        );
    }

    function getHolderInfo(uint256 stage, address holderAddress) external view returns (uint256, uint256, uint256) {
        require(stage < _stakingStages.length, 'ETBStaking: wrong number of stage');
        HolderInfo storage holder = _stagesStakeHolders[stage][holderAddress];
        return (
        holder._depositTime,
        holder._amount,
        _calculateReward(stage, holderAddress)
        );
    }

    function setRewardToken(address rewardToken) external onlyOwner {
        require(rewardToken != address(0), 'ETBStaking: supportedToken can\'t be zero address');
        _rewardToken = rewardToken;
    }

    function setSupportedToken(address supportedToken) external onlyOwner {
        require(supportedToken != address(0), 'ETBStaking: supportedToken can\'t be zero address');
        _tokenForStaking = supportedToken;
    }

    function getRewardToken() external view returns (address) {
        return _rewardToken;
    }

    function getSupportedToken() external view returns (address) {
        return _tokenForStaking;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function rescueBEP20(address token) external onlyOwner {
        uint256 amt = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(owner(), amt);
    }

    function rescue() external payable onlyOwner {
        address payable addressOwner = payable(address(owner()));
        addressOwner.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

