// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    uint256 constant PRESALE_ALLOC = 120e27; // STRIP allocation for presale : 100b
    uint256 constant INFLUENCER_ALLOC = 50e27; // STRIP allocation for influencers and celebs: 50b
    uint256 constant TEAM_ALLOC = 15e27; // STRIP allocation for team : 15b
    uint256 constant UNLOCK_UNIT = 10; // 10% of the total allocation will be unlocked
    uint256 constant INITIAL_LOCK_PERIOD = 45 minutes; // No tokens will be unlocked for the first month

    uint256 public startTime;   // Vesting start time
    bool public isStartTimeSet;

    uint256[3] private unallocatedAmounts; // The amount of tokens that are not allocated yet..

    event VestingStarted(uint256 _startTime);
    event VestingScheduleRegistered(address registeredAddress, uint256 totalAmount, uint256 plan);
    event VestingSchedulesRegistered(address[] registeredAddresses, uint256[] totalAmounts, uint256[] plans);

    IStripToken public stripToken;

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(msg.sender == multiSigAdmin || presaleContract == msg.sender, "Should be multiSig contract");
        _;
    }

    constructor(address _stripToken, address _presaleContract, address payable _multiSigAdmin) {
        owner = msg.sender;

        stripToken = IStripToken(_stripToken);
        presaleContract = _presaleContract;
        multiSigAdmin = _multiSigAdmin;
        
        /// Allow presale contract to withdraw unsold strip tokens to multiSig admin
        stripToken.approve(presaleContract, MAX_UINT256);
        isStartTimeSet = false;
        unallocatedAmounts = [PRESALE_ALLOC, INFLUENCER_ALLOC, TEAM_ALLOC];
    }

    /**
     * @dev Private function to add a recipient to vesting schedule
     * @param _recipient the address to be added
     * @param _totalAmount integer variable to indicate strip amount of the recipient
     * @param _vestingPlan integer variable to indicate vesting plan
     */

    function addRecipient(address _recipient, uint256 _totalAmount, uint256 _vestingPlan) private {
        require(_recipient != address(0x00), "addRecipient: Invalid recipient address");
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(_vestingPlan < 3, "addRecipient: Invalid vesting plan");
        // require(_vestingPlan > 0 && recipients[_recipient].totalAmount == 0, "addRecipient: User already vested"); // Not for presale buyers

        unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].add(recipients[_recipient].totalAmount);
        require(_totalAmount > 0 && _totalAmount <= unallocatedAmounts[_vestingPlan]);

        recipients[_recipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0,
            vestingPlan: _vestingPlan
        });

        unallocatedAmounts[_vestingPlan] = unallocatedAmounts[_vestingPlan].sub(_totalAmount);
    }
    
    /**
     * @dev Add new recipient to vesting schedule
     * @param _newRecipient the address to be added
     * @param _totalAmount integer variable to indicate strip amount of the recipient
     * @param _vestingPlan integer variable to indicate vesting plan
     */

    function addNewRecipient(address _newRecipient, uint256 _totalAmount, uint256 _vestingPlan) external onlyMultiSigAdmin {
        require(!isStartTimeSet || startTime > block.timestamp, "addNewRecipient: Cannot update the receipient after started");

        addRecipient(_newRecipient, _totalAmount, _vestingPlan);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount, _vestingPlan);
    }

    /**
     * @dev Add new recipients to vesting schedule
     * @param _newRecipients the addresses to be added
     * @param _totalAmounts integer array to indicate strip amount of recipients
     * @param _vestingPlans integer array to indicate vesting plans of recipients
     */

    function addNewRecipients(address[] memory _newRecipients, uint256[] memory _totalAmounts, uint256[] memory _vestingPlans) external onlyMultiSigAdmin {
        require(!isStartTimeSet || startTime > block.timestamp, "addNewRecipients: Cannot update the receipient after started");

        for (uint256 i = 0; i < _newRecipients.length; i++) {
            addRecipient(_newRecipients[i], _totalAmounts[i], _vestingPlans[i]);
        }
        
        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts, _vestingPlans);
    }

    /**
     * @dev Starts vesting schedule
     * @param _newStartTime _startTime
     */

    function startVesting(uint256 _newStartTime) external onlyOwner {
        require(!isStartTimeSet || startTime > block.timestamp, "setStartTime: Vesting has already started");
        require(_newStartTime > block.timestamp, "setStartTime: Start time can't be in the past");

        startTime = _newStartTime;
        isStartTimeSet = true;
        
        emit VestingStarted(startTime);
    }

    /**
     * @dev Get vesting plan of a recipient
     * @param _recipient address of recipient
     */
    function getVestingPlan(address _recipient) external view returns (uint256) {
        require(_recipient != address(0x00), "Should be valid address");
        if (recipients[_recipient].vestingPlan == 0) return 0;
        return recipients[_recipient].vestingPlan;
    }

    /**
     * @dev Gets the locked strip amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getLocked(address beneficiary) external view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    /**
     * @dev Gets the claimable strip amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getWithdrawable(address beneficiary) public view returns (uint256) {
        return getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    /**
     * @dev Claim unlocked strip tokens of a recipient
     * @param _recipient address of recipient
     */
    function withdrawToken(address _recipient) external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = _vested.sub(recipients[msg.sender].amountWithdrawn);
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(stripToken.transfer(_recipient, _withdrawable));
        
        return _withdrawable;
    }

    /**
     * @dev Get claimable strip token amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
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
        uint256 vestingPeriod = 270 minutes;
        
        uint256 secondVestingPoint = firstVestingPoint.add(vestingPeriod);
        if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
            vestedPercent = 10 + (block.timestamp - firstVestingPoint).mul(90).div(vestingPeriod);
        } else if (block.timestamp > secondVestingPoint) {
            vestedPercent = 100;
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