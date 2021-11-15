// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './interfaces/IStripToken.sol';

contract Vesting {
    using SafeMath for uint256;

    struct VestingSchedule {
      uint256 totalAmount; // Total amount of tokens to be vested.
      uint256 amountWithdrawn; // The amount that has been withdrawn.
      uint256 vestingPlan; // Vesting type - 0: presale, 1: influencer, 2: team
    }

    address private owner;
    address private presaleContract; // Presale contract
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds

    mapping(address => VestingSchedule) public recipients;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint256 constant TOTAL_AMOUNT = 500e27; // Total STRIP : 500b
    uint256 constant PRESALE_ALLOC = 100e27; // STRIP allocation for presale : 100b
    uint256 constant INFLUENCER_ALLOC = 50e27; // STRIP allocation for influencers and celebs: 50b
    uint256 constant TEAM_ALLOC = 15e27; // STRIP allocation for team : 15b
    uint256 constant UNLOCK_UNIT = 10; // 10% of the total allocation will be unlocked
    uint256 constant INITIAL_LOCK_PERIOD = 4 weeks; // No tokens will be unlocked for the first month

    uint256 public startTime;   // Vesting start time
    bool public isStartTimeSet;

    uint256[3] private unallocatedAmounts; // The amount of tokens that are not allocated yet..

    event VestingScheduleRegistered(address registeredAddress, uint256 totalAmount, uint256 plan);
    event VestingSchedulesRegistered(address[] registeredAddresses, uint256[] totalAmounts, uint256[] plans);

    IStripToken public stripToken;

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender || presaleContract == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(msg.sender == multiSigAdmin, "Should be multiSig contract");
        _;
    }

    constructor(address _stripToken, address _presaleContract, address payable _multiSigAdmin) {
        owner = msg.sender;

        stripToken = IStripToken(_stripToken);
        presaleContract = _presaleContract;
        multiSigAdmin = _multiSigAdmin;
        
        /// Allow presale contract to withdraw Unsold stripToken to multiSig admin
        stripToken.approve(presaleContract, MAX_UINT256);
        isStartTimeSet = false;
        unallocatedAmounts = [PRESALE_ALLOC, INFLUENCER_ALLOC, TEAM_ALLOC];
    }

    // Get vesting plan of a beneficiary
    function getVestingPlan(address _recipient) external onlyOwner returns (uint256) {
        require(_recipient != address(0x00), "Should be valid address");
        return recipients[_recipient].vestingPlan;
    }

    // Update vesting schedule for presale buyers
    function updateRecipient(address _recipient, uint256 _amount, uint256 _vestingPlan) external onlyOwner {
        require(!isStartTimeSet || startTime > block.timestamp, "updateRecipient: Cannot update the receipient after started");
        require(_recipient != address(0x00), "updateRecipient: Invalid recipient address");
        require(_amount > 0, "updateRecipient: Cannot vest 0");
        require(_vestingPlan < 3, "updateRecipient: Invalid vesting plan");

        recipients[_recipient].totalAmount = _amount;
        recipients[_recipient].vestingPlan = _vestingPlan;
    }
    
    function addRecipient(address _newRecipient, uint256 _totalAmount, uint256 _vestingPlan) external onlyMultiSigAdmin {
        require(!isStartTimeSet || startTime > block.timestamp, "addRecipient: Cannot update the receipient after started");
        require(_newRecipient != address(0x00), "addRecipient: Invalid recipient address");
        require(recipients[_newRecipient].totalAmount == 0, "addRecipient: User already vested");
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(_vestingPlan < 3, "addRecipient: Invalid vesting plan");

        unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].add(recipients[_newRecipient].totalAmount);
        require(_totalAmount > 0 && _totalAmount <= unallocatedAmounts[_vestingPlan]);

        recipients[_newRecipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0,
            vestingPlan: _vestingPlan
        });

        unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].sub(_totalAmount);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount, _vestingPlan);
    }

    function addRecipients(address[] memory _newRecipients, uint256[] memory _totalAmounts, uint256[] memory _vestingPlans) external onlyMultiSigAdmin {
        require(!isStartTimeSet || startTime > block.timestamp, "addRecipients: Cannot update the receipient after started");

        for (uint256 i = 0; i < _newRecipients.length; i++) {
            address _newRecipient = _newRecipients[i];
            uint256 _totalAmount = _totalAmounts[i];
            uint256 _vestingPlan = _vestingPlans[i];

            require(_newRecipient != address(0x00), "addRecipients: Invalid recipient address");
            require(recipients[_newRecipient].totalAmount == 0, "addRecipient: User already vested");
            require(_vestingPlan < 3, "addRecipients: Invalid vesting plan");

            unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].add(recipients[_newRecipient].totalAmount);
            require(_totalAmount > 0 && _totalAmount <= unallocatedAmounts[_vestingPlan]);

            recipients[_newRecipient] = VestingSchedule({
                totalAmount: _totalAmount,
                amountWithdrawn: 0,
                vestingPlan: _vestingPlan
            });

            unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].sub(_totalAmount);
        }

        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts, _vestingPlans);
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(!isStartTimeSet || startTime > block.timestamp, "setStartTime: Vesting has already started");
        require(_newStartTime > block.timestamp, "setStartTime: Start time can't be in the past");

        startTime = _newStartTime;
        isStartTimeSet = true;
    }

    function getLocked(address beneficiary) public view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    function getWithdrawable(address beneficiary) public view returns (uint256) {
        return getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    function withdrawToken(address recipient) external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = getWithdrawable(msg.sender);
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(stripToken.transfer(recipient, _withdrawable));
        
        return _withdrawable;
    }

    // Returns the amount of tokens you can withdraw
    function getVested(address beneficiary) public view virtual returns (uint256 _amountVested) {
        require(beneficiary != address(0x00), "getVested: Invalid address");
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];

        if (
            !isStartTimeSet ||
            (_vestingSchedule.totalAmount == 0) ||
            (block.timestamp < startTime) ||
            (block.timestamp < startTime.add(INITIAL_LOCK_PERIOD))
        ) {
            return 0;
        }

        uint256 vestedPercent = 0;
        uint256 firstVestingPoint = startTime.add(INITIAL_LOCK_PERIOD);

        if (_vestingSchedule.vestingPlan == 0) { // Presale
            uint256 secondVestingPoint = firstVestingPoint.add(20 weeks);
            if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
                vestedPercent = (block.timestamp - firstVestingPoint).div(20 weeks).mul(100);
            } else if (block.timestamp > secondVestingPoint) {
                vestedPercent = 100;
            }
        } else if (_vestingSchedule.vestingPlan == 1) { // Influencer & Celebs
            uint256 secondVestingPoint = firstVestingPoint.add(12 weeks);
            uint256 thirdVestingPoint = secondVestingPoint.add(28 weeks);
            
            if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
                vestedPercent = (block.timestamp - firstVestingPoint).div(12 weeks).mul(UNLOCK_UNIT).mul(2);
            } else if (block.timestamp > secondVestingPoint && block.timestamp <= thirdVestingPoint) {
                vestedPercent = 10 + (block.timestamp - secondVestingPoint).div(20 weeks).mul(UNLOCK_UNIT);
            } else if (block.timestamp > thirdVestingPoint) {
                vestedPercent = 30 + (block.timestamp - thirdVestingPoint).div(28 weeks).mul(70);
            }
        } else if (_vestingSchedule.vestingPlan == 2) { // Team
            uint256 secondVestingPoint = firstVestingPoint.add(24 weeks);
            if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
                vestedPercent = (block.timestamp - firstVestingPoint).div(24 weeks).mul(100);
            } else if (block.timestamp > secondVestingPoint) {
                vestedPercent = 100;
            }
        }
        
        uint256 vestedAmount = _vestingSchedule.totalAmount.mul(vestedPercent).div(100);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }

        return vestedAmount;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStripToken is IERC20 {
    function decimals() external view returns (uint256);
    function setMultiSigAdminAddress(address) external;
    function recoverERC20(address, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

