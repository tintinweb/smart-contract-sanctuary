// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BaseVesting.sol";

contract AdvanceVesting is BaseVesting  {
    using SafeMath for uint256;

    uint256 public firstRelease;
    uint256 public cliffDuration;
    uint256 public tgePercentage;
    uint256 public remainingPercentage;

    constructor(address signer_) BaseVesting(signer_) {}

    function _calculateAvailablePercentage() internal view override returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        if (currentTimeStamp < startDate) {
            return 0;
        } else if (
            currentTimeStamp >= startDate && currentTimeStamp < firstRelease
        ) {
            return tgePercentage;
        } else if (
            currentTimeStamp >= firstRelease &&
            currentTimeStamp < vestingTimeEnd
        ) {
            uint256 noOfDays = currentTimeStamp.sub(firstRelease).div(PERIOD);
            uint256 currentUnlockedPercentage = noOfDays.mul(
                everyDayReleasePercentage
            );
            return tgePercentage.add(currentUnlockedPercentage);
        } else {
            return PERCENTAGE;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BaseVesting is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Investor {
        uint256 paidAmount;
        uint256 timeRewardPaid;
    }

    uint256 public constant PERIOD = 600;
    uint256 public constant PERCENTAGE = 1e20;

    IERC20 public token;
    uint256 public everyDayReleasePercentage;
    uint256 public periods;
    uint256 public startDate;
    uint256 public totalAllocatedAmount;
    uint256 public tokensForLP;
    uint256 public tokensForNative;
    uint256 public vestingDuration;
    uint256 public vestingTimeEnd;

    event RewardPaid(address indexed investor, uint256 amount);

    mapping(address => Counters.Counter) public nonces;
    mapping(address => bool) public trustedSigner;
    mapping(address => Investor) public investorInfo;

    constructor(address signer_) {
        require(signer_ != address(0), "Invalid signer address");
        trustedSigner[signer_] = true;
    }

    /**
     * @notice Adds new signer or removes permission from existing
     * @param signer signer address
     * @param permission set permission for signer address
     */
    function changeSignerList(address signer, bool permission)
        public
        onlyOwner
    {
        changePermission(signer, permission);
    }

    /**
     * @dev emergency tokens withdraw
     * @param tokenAddress_ token address
     * @param amount amount to withdraw
     */
    function emergencyTokenWithdraw(address tokenAddress_, uint256 amount)
        external
        onlyOwner
    {
        IERC20 tokenAddress = IERC20(tokenAddress_);
        require(
            tokenAddress.balanceOf(address(this)) >= amount,
            "Insufficient tokens balance"
        );
        tokenAddress.transfer(msg.sender, amount);
    }

    /**
     * @dev data and signature validation
     * @param addr investor address
     * @param portionLP investor portion for LP stake
     * @param portionNative investor portion for Native stake
     * @dev Last three parameters is signature from signer
     */
    function isValidData(
        address addr,
        uint256 portionLP,
        uint256 portionNative,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(
                address(this),
                addr,
                portionLP,
                portionNative,
                nonces[addr].current(),
                deadline
            )
        );

        address sender = ecrecover(message, v, r, s);
        if (trustedSigner[sender]) {
            nonces[addr].increment();
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Withdraw reward tokens from distribution contract by investor
     * @param portionLP investor portion for LP stake
     * @param portionNative investor portion for Native stake
     * @dev Last three parameters is signature from signer
     */
    function withdrawReward(
        uint256 portionLP,
        uint256 portionNative,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            portionLP <= PERCENTAGE && portionNative <= PERCENTAGE,
            "The percentage cannot be greater than 100"
        );
        require(deadline >= block.timestamp, 'Expired');
        bool access = isValidData(
            msg.sender,
            portionLP,
            portionNative,
            deadline,
            v,
            r,
            s
        );
        require(access, "Permission not granted");
        _withdrawReward(msg.sender, portionLP, portionNative);
    }

    /**
     * @dev Returns current available rewards for investor
     * @param percenageLP investor percenage for LP stake
     * @param percentageNative investor percentage for Native stake
     */
    function getRewardBalance(
        address beneficiary,
        uint256 percenageLP,
        uint256 percentageNative
    ) public view returns (uint256 amount) {
        uint256 reward = _getRewardBalance(percenageLP, percentageNative);
        Investor storage investor = investorInfo[beneficiary];
        uint256 balance = token.balanceOf(address(this));
        if (reward <= investor.paidAmount) {
            return 0;
        } else {
            uint256 amountToPay = reward.sub(investor.paidAmount);
            if (amountToPay >= balance) {
                return 0;
            }
            return amountToPay;
        }
    }

    function _withdrawReward(
        address beneficiary,
        uint256 percenageLP,
        uint256 percentageNative
    ) private {
        uint256 reward = _getRewardBalance(percenageLP, percentageNative);
        Investor storage investor = investorInfo[beneficiary];
        uint256 balance = token.balanceOf(address(this));
        require(reward > investor.paidAmount, "No rewards available");
        uint256 amountToPay = reward.sub(investor.paidAmount);
        require(amountToPay <= balance, "The rewards are over");
        investor.paidAmount = reward;
        investor.timeRewardPaid = block.timestamp;
        token.transfer(beneficiary, amountToPay);
        emit RewardPaid(beneficiary, amountToPay);
    }

    function _getRewardBalance(uint256 lpPercentage, uint256 nativePercentage)
        private
        view
        returns (uint256)
    {
        uint256 vestingAvailablePercentage = _calculateAvailablePercentage();
        uint256 amountAvailableForLP = tokensForLP
        .mul(vestingAvailablePercentage)
        .div(PERCENTAGE);
        uint256 amountAvailableForNative = tokensForNative
        .mul(vestingAvailablePercentage)
        .div(PERCENTAGE);
        uint256 rewardToPayLP = amountAvailableForLP.mul(lpPercentage).div(
            PERCENTAGE
        );
        uint256 rewardToPayNative = amountAvailableForNative
        .mul(nativePercentage)
        .div(PERCENTAGE);
        return rewardToPayLP.add(rewardToPayNative);
    }

    function _calculateAvailablePercentage()
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 currentTimeStamp = block.timestamp;
        if (currentTimeStamp < startDate) {
            return 0;
        } else if (
            currentTimeStamp >= startDate && currentTimeStamp < vestingTimeEnd
        ) {
            uint256 noOfDays = currentTimeStamp.sub(startDate).div(PERIOD);
            uint256 currentUnlockedPercentage = noOfDays.mul(
                everyDayReleasePercentage
            );
            return currentUnlockedPercentage;
        } else {
            return PERCENTAGE;
        }
    }

    function changePermission(address signer, bool permission) internal {
        require(signer != address(0), "Invalid signer address");
        trustedSigner[signer] = permission;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../BaseContracts/AdvanceVesting.sol";

contract Distribution is AdvanceVesting {
    using SafeMath for uint256;

    constructor(
        address signer_,
        address token_,
        uint256 startDate_,
        uint256 cliffDuration_,
        uint256 vestingDuration_,
        uint256 tgePercentage_,
        uint256 totalAllocatedAmount_
    ) AdvanceVesting(signer_) {
        require(token_ != address(0), "Invalid reward token address");
        require(startDate_ != 0, "TGE timestamp can't be 0");
        require(
            vestingDuration_ > 0 && cliffDuration_ > 0,
            "The vesting and cliff duration cannot be 0"
        );
        require(
            totalAllocatedAmount_ > 0,
            "The number of tokens for distribution cannot be 0"
        );
        token = IERC20(token_);
        startDate = startDate_;
        cliffDuration = cliffDuration_;
        vestingDuration = vestingDuration_;
        firstRelease = startDate.add(cliffDuration_);
        vestingTimeEnd = startDate.add(cliffDuration_).add(vestingDuration_);
        periods = vestingDuration_.div(PERIOD);
        tgePercentage = tgePercentage_;
        remainingPercentage = PERCENTAGE.sub(tgePercentage_);
        everyDayReleasePercentage = remainingPercentage.div(periods);
        totalAllocatedAmount = totalAllocatedAmount_;
        tokensForNative = totalAllocatedAmount_.div(3);
        tokensForLP = totalAllocatedAmount_.sub(tokensForNative);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

