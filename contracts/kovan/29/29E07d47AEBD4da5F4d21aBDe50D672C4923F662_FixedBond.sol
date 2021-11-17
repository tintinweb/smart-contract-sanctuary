// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @title A contract to simulate Real World Bonds / Fixed Deposits
// @author Marvel
// @notice You can use this contract for only the most basic simulation
// @dev All function calls are currently implemented without side effects
// @custom:experimental This is an experimental contract.
contract FixedBond is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public token;

    // Event triggered when owner adds rewards to the contract
    event RewardsAdded(uint256 _value);

    // Event triggered when user withdraws the deposited tokens
    event TokensWithdrawn(address indexed _from);

    // Event triggered when user deposits tokens
    event TokensDeposited(address indexed _from, uint256 _value);

    // ERC20 token address should be passed to the constructor while deployment
    constructor(address _token) {
        token = _token;
    }

    // Bond information struct
    // isActive -> whether the bond is active oor not a boolean tru or false
    // interestOneMonth -> total interest users get if they deposit for 1 month
    // interestThreeMonth -> total interest users get if they deposit for 3 months
    // interestSixMonth -> total interest users get if they deposit for 6 months
    // interestTwelveMonth -> total interest users get if they deposit for 12 months
    // minimumDeposit -> Minimum tokens user needs to deposit in the bond to earn interest
    struct BondInfo {
        bool isActive;
        uint256 interestOneMonth;
        uint256 interestThreeMonth;
        uint256 interestSixMonth;
        uint256 interestTwelveMonth;
        uint256 minimumDeposit;
    }

    // User information struct
    // amountDeposited -> amount deposited by the user
    // depositedOn -> timestamp when the user deposited the amount
    // lockPeriod -> time for the user wants to lock the amount in the bond (1, 3, 6, 12)
    struct UserInfo {
        uint256 amountDeposited;
        uint256 depositedOn;
        uint256 lockPeriod;
    }

    // Rewards balance of the contract
    uint256 public rewardsBalance = 0;

    // bondInfo -> Information about the bond
    BondInfo public bondInfo;

    // user address => tierId => tokensBought
    mapping(address => UserInfo) public userInfo;

    // Setting up the Bond for the first time on the contract
    // Parameters are the struct parameters for BondInfo
    // Can only be called by owner
    function setupBond(
        bool _isActive,
        uint256 _interestOneMonth,
        uint256 _interestThreeMonth,
        uint256 _interestSixMonth,
        uint256 _interestTwelveMonth,
        uint256 _minimumDeposit
    ) external onlyOwner {
        bondInfo.isActive = _isActive;
        bondInfo.interestOneMonth = _interestOneMonth;
        bondInfo.interestThreeMonth = _interestThreeMonth;
        bondInfo.interestSixMonth = _interestSixMonth;
        bondInfo.interestTwelveMonth = _interestTwelveMonth;
        bondInfo.minimumDeposit = _minimumDeposit;
    }

    // Updating the Bond
    // Can only activate or deactivate the bond and change minimum deposit
    // Can only be called by owner
    function updateBond(bool _isActive, uint256 _minimumDeposit)
        external
        onlyOwner
    {
        bondInfo.isActive = _isActive;
        bondInfo.minimumDeposit = _minimumDeposit;
    }

    // Deposit tokens in the rewards pool
    // Can only be called by owner
    function depositRewards(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount has to be greater than zero");
        rewardsBalance = rewardsBalance.add(_amount);
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        emit RewardsAdded(_amount);
    }

    // Deposit tokens in the bond
    // Input params -> Amount and the time in months for which the user wants to lock the tokens in the bond
    function deposit(uint256 _amount, uint256 _timeInMonths) public {
        require(bondInfo.isActive, "Bond is inactive");
        require(_timeInMonths >= 1, "Minimum time one month");
        require(_timeInMonths < 13, "Maximum time twelve months");
        require(_amount > 0, "Amount has to be greater than zero");
        require(
            userInfo[msg.sender].amountDeposited == 0,
            "Deposit already active"
        );
        userInfo[msg.sender].amountDeposited = _amount;
        userInfo[msg.sender].depositedOn = block.timestamp;
        userInfo[msg.sender].lockPeriod = _timeInMonths;
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        emit TokensDeposited(msg.sender, _amount);
    }

    // Calculate the rewards user has accumulated until now
    function calculateRewards(address _address) public view returns (uint256) {
        if (userInfo[_address].amountDeposited == 0) return 0;
        uint256 daysPassed = (block.timestamp -
            userInfo[_address].depositedOn) / 1 days;
        if (daysPassed == 0) return 0;
        uint256 lockPeriod = userInfo[_address].lockPeriod;
        if (daysPassed > lockPeriod * 30) {
            daysPassed = lockPeriod * 30;
        }
        uint256 rewards = userInfo[_address]
            .amountDeposited
            .mul(daysPassed)
            .div(30);
        if (lockPeriod == 1) {
            rewards = rewards.mul(bondInfo.interestOneMonth).div(100);
        } else if (lockPeriod == 3) {
            rewards = rewards.mul(bondInfo.interestThreeMonth).div(3).div(100);
        } else if (lockPeriod == 6) {
            rewards = rewards.mul(bondInfo.interestSixMonth).div(6).div(100);
        } else if (lockPeriod == 12) {
            rewards = rewards.mul(bondInfo.interestTwelveMonth).div(12).div(
                100
            );
        }
        return rewards;
    }

    // Withdraw tokens without caring about interest
    function emergencyWithdraw() public {
        require(userInfo[msg.sender].amountDeposited > 0, "No active deposit");
        IERC20(token).transfer(
            msg.sender,
            userInfo[msg.sender].amountDeposited
        );
        delete userInfo[msg.sender];
        emit TokensWithdrawn(msg.sender);
    }

    // Withdraw tokens after maturity, and also get the interest earned
    function withdraw() public {
        require(userInfo[msg.sender].amountDeposited > 0, "No active deposit");
        uint256 daysPassed = (block.timestamp -
            userInfo[msg.sender].depositedOn) / 1 days;
        require(
            daysPassed > userInfo[msg.sender].lockPeriod * 30,
            "Cant withdraw before maturity"
        );
        uint256 rewards = calculateRewards(msg.sender);
        require(rewardsBalance >= rewards, "Not enough rewards in contract");
        uint256 totalAmount = userInfo[msg.sender].amountDeposited.add(rewards);
        IERC20(token).transfer(msg.sender, totalAmount);
        rewardsBalance = rewardsBalance.sub(rewards);
        delete userInfo[msg.sender];
        emit TokensWithdrawn(msg.sender);
    }
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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