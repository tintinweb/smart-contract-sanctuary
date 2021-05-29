// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRing is IERC20 {
    function delegate(address delegatee) external;
    function setMinter(address minter_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../dao/IRing.sol";

/// @title TimelockedDelegator interface
/// @author Ring Protocol
interface ITimelockedDelegator {
    // ----------- Events -----------

    event Delegate(address indexed _delegatee, uint256 _amount);

    event Undelegate(address indexed _delegatee, uint256 _amount);

    // ----------- Beneficiary only state changing api -----------

    function delegate(address delegatee, uint256 amount) external;

    function undelegate(address delegatee) external returns (uint256);

    // ----------- Getters -----------

    function delegateContract(address delegatee)
        external
        view
        returns (address);

    function delegateAmount(address delegatee) external view returns (uint256);

    function totalDelegated() external view returns (uint256);

    function ring() external view returns (IRing);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITimelockedDelegator.sol";
import "../utils/LinearTokenTimelock.sol";

/// @title a proxy delegate contract for RING
/// @author Ring Protocol
contract Delegatee is Ownable {
    IRing public ring;

    /// @notice Delegatee constructor
    /// @param _delegatee the address to delegate RING to
    /// @param _ring the RING token address
    constructor(address _delegatee, address _ring) {
        ring = IRing(_ring);
        ring.delegate(_delegatee);
    }

    /// @notice send RING back to timelock and selfdestruct
    function withdraw() public onlyOwner {
        IRing _ring = ring;
        uint256 balance = _ring.balanceOf(address(this));
        _ring.transfer(owner(), balance);
        selfdestruct(payable(owner()));
    }
}

/// @title a timelock for RING allowing for sub-delegation
/// @author Ring Protocol
/// @notice allows the timelocked RING to be delegated by the beneficiary while locked
contract TimelockedDelegator is ITimelockedDelegator, LinearTokenTimelock {
    using SafeMathCopy for uint256;

    /// @notice associated delegate proxy contract for a delegatee
    mapping(address => address) public override delegateContract;

    /// @notice associated delegated amount of RING for a delegatee
    /// @dev Using as source of truth to prevent accounting errors by transferring to Delegate contracts
    mapping(address => uint256) public override delegateAmount;

    /// @notice the RING token contract
    IRing public override ring;

    /// @notice the total delegated amount of RING
    uint256 public override totalDelegated;

    /// @notice Delegatee constructor
    /// @param _ring the RING token address
    /// @param _beneficiary default delegate, admin, and timelock beneficiary
    /// @param _duration duration of the token timelock window
    constructor(
        address _ring,
        address _beneficiary,
        uint256 _duration
    ) LinearTokenTimelock(_beneficiary, _duration, _ring) {
        ring = IRing(_ring);
        ring.delegate(_beneficiary);
    }

    /// @notice delegate locked RING to a delegatee
    /// @param delegatee the target address to delegate to
    /// @param amount the amount of RING to delegate. Will increment existing delegated RING
    function delegate(address delegatee, uint256 amount)
        public
        override
        onlyBeneficiary
    {
        require(
            amount <= _ringBalance(),
            "TimelockedDelegator: Not enough Ring"
        );

        // withdraw and include an existing delegation
        if (delegateContract[delegatee] != address(0)) {
            amount = amount.add(undelegate(delegatee));
        }

        IRing _ring = ring;
        address _delegateContract =
            address(new Delegatee(delegatee, address(_ring)));
        delegateContract[delegatee] = _delegateContract;

        delegateAmount[delegatee] = amount;
        totalDelegated = totalDelegated.add(amount);

        _ring.transfer(_delegateContract, amount);

        emit Delegate(delegatee, amount);
    }

    /// @notice return delegated RING to the timelock
    /// @param delegatee the target address to undelegate from
    /// @return the amount of RING returned
    function undelegate(address delegatee)
        public
        override
        onlyBeneficiary
        returns (uint256)
    {
        address _delegateContract = delegateContract[delegatee];
        require(
            _delegateContract != address(0),
            "TimelockedDelegator: Delegate contract nonexistent"
        );

        Delegatee(_delegateContract).withdraw();

        uint256 amount = delegateAmount[delegatee];
        totalDelegated = totalDelegated.sub(amount);

        delegateContract[delegatee] = address(0);
        delegateAmount[delegatee] = 0;

        emit Undelegate(delegatee, amount);

        return amount;
    }

    /// @notice calculate total RING held plus delegated
    /// @dev used by LinearTokenTimelock to determine the released amount
    function totalToken() public view override returns (uint256) {
        return _ringBalance().add(totalDelegated);
    }

    /// @notice accept beneficiary role over timelocked RING. Delegates all held (non-subdelegated) ring to beneficiary
    function acceptBeneficiary() public override {
        _setBeneficiary(msg.sender);
        ring.delegate(msg.sender);
    }

    function _ringBalance() internal view returns (uint256) {
        return ring.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

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
library SafeMathCopy { // To avoid namespace collision between openzeppelin safemath and uniswap safemath
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LinearTokenTimelock interface
/// @author Ring Protocol
interface ILinearTokenTimelock {
    // ----------- Events -----------

    event Release(address indexed _beneficiary, address indexed _recipient, uint256 _amount);
    event BeneficiaryUpdate(address indexed _beneficiary);
    event PendingBeneficiaryUpdate(address indexed _pendingBeneficiary);

    // ----------- State changing api -----------

    function release(address to, uint amount) external;

    function releaseMax(address to) external;

    function setPendingBeneficiary(address _pendingBeneficiary) external;

    function acceptBeneficiary() external;


    // ----------- Getters -----------

    function lockedToken() external view returns (IERC20);

    function beneficiary() external view returns (address);

    function pendingBeneficiary() external view returns (address);

    function initialBalance() external view returns (uint256);

    function availableForRelease() external view returns (uint256);

    function totalToken() external view returns(uint256);

    function alreadyReleasedAmount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

// Inspired by OpenZeppelin TokenTimelock contract
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol

import "./Timed.sol";
import "./ILinearTokenTimelock.sol";
import "../external/SafeMathCopy.sol";

contract LinearTokenTimelock is ILinearTokenTimelock, Timed {
    using SafeMathCopy for uint256;

    /// @notice ERC20 basic token contract being held in timelock
    IERC20 public override lockedToken;

    /// @notice beneficiary of tokens after they are released
    address public override beneficiary;

    /// @notice pending beneficiary appointed by current beneficiary
    address public override pendingBeneficiary;

    /// @notice initial balance of lockedToken
    uint256 public override initialBalance;

    uint256 internal lastBalance;

    constructor(
        address _beneficiary,
        uint256 _duration,
        address _lockedToken
    ) Timed(_duration) {
        require(_duration != 0, "LinearTokenTimelock: duration is 0");
        require(
            _beneficiary != address(0),
            "LinearTokenTimelock: Beneficiary must not be 0 address"
        );

        beneficiary = _beneficiary;
        _initTimed();

        _setLockedToken(_lockedToken);
    }

    // Prevents incoming LP tokens from messing up calculations
    modifier balanceCheck() {
        if (totalToken() > lastBalance) {
            uint256 delta = totalToken().sub(lastBalance);
            initialBalance = initialBalance.add(delta);
        }
        _;
        lastBalance = totalToken();
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "LinearTokenTimelock: Caller is not a beneficiary"
        );
        _;
    }

    /// @notice releases `amount` unlocked tokens to address `to`
    function release(address to, uint256 amount) external override onlyBeneficiary balanceCheck {
        require(amount != 0, "LinearTokenTimelock: no amount desired");

        uint256 available = availableForRelease();
        require(amount <= available, "LinearTokenTimelock: not enough released tokens");

        _release(to, amount);
    }

    /// @notice releases maximum unlocked tokens to address `to`
    function releaseMax(address to) external override onlyBeneficiary balanceCheck {
        _release(to, availableForRelease());
    }

    /// @notice the total amount of tokens held by timelock
    function totalToken() public view override virtual returns (uint256) {
        return lockedToken.balanceOf(address(this));
    }

    /// @notice amount of tokens released to beneficiary
    function alreadyReleasedAmount() public view override returns (uint256) {
        return initialBalance.sub(totalToken());
    }

    /// @notice amount of held tokens unlocked and available for release
    function availableForRelease() public view override returns (uint256) {
        uint256 elapsed = timeSinceStart();
        uint256 _duration = duration;

        uint256 totalAvailable = initialBalance.mul(elapsed) / _duration;
        uint256 netAvailable = totalAvailable.sub(alreadyReleasedAmount());
        return netAvailable;
    }

    /// @notice current beneficiary can appoint new beneficiary, which must be accepted
    function setPendingBeneficiary(address _pendingBeneficiary)
        public
        override
        onlyBeneficiary
    {
        pendingBeneficiary = _pendingBeneficiary;
        emit PendingBeneficiaryUpdate(_pendingBeneficiary);
    }

    /// @notice pending beneficiary accepts new beneficiary
    function acceptBeneficiary() public override virtual {
        _setBeneficiary(msg.sender);
    }

    function _setBeneficiary(address newBeneficiary) internal {
        require(
            newBeneficiary == pendingBeneficiary,
            "LinearTokenTimelock: Caller is not pending beneficiary"
        );
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary);
        pendingBeneficiary = address(0);
    }

    function _setLockedToken(address tokenAddress) internal {
        lockedToken = IERC20(tokenAddress);
    }

    function _release(address to, uint256 amount) internal {
        lockedToken.transfer(to, amount);
        emit Release(beneficiary, to, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/// @title an abstract contract for timed events
/// @author Ring Protocol
abstract contract Timed {
    /// @notice the start timestamp of the timed period
    uint256 public startTime;

    /// @notice the duration of the timed period
    uint256 public duration;

    event DurationUpdate(uint256 _duration);

    event TimerReset(uint256 _startTime);

    constructor(uint256 _duration) {
        _setDuration(_duration);
    }

    modifier duringTime() {
        require(isTimeStarted(), "Timed: time not started");
        require(!isTimeEnded(), "Timed: time ended");
        _;
    }

    modifier afterTime() {
        require(isTimeEnded(), "Timed: time not ended");
        _;
    }

    /// @notice return true if time period has ended
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }

    /// @notice number of seconds remaining until time is up
    /// @return remaining
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart(); // duration always >= timeSinceStart which is on [0,d]
    }

    /// @notice number of seconds since contract was initialized
    /// @return timestamp
    /// @dev will be less than or equal to duration
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0; // uninitialized
        }
        uint256 _duration = duration;
        // solhint-disable-next-line not-rely-on-time
        uint256 timePassed = block.timestamp - startTime; // block timestamp always >= startTime
        return timePassed > _duration ? _duration : timePassed;
    }

    function isTimeStarted() public view returns (bool) {
        return startTime != 0;
    }

    function _initTimed() internal {
        // solhint-disable-next-line not-rely-on-time
        startTime = block.timestamp;
        
        // solhint-disable-next-line not-rely-on-time
        emit TimerReset(block.timestamp);
    }

    function _setDuration(uint _duration) internal {
        duration = _duration;
        emit DurationUpdate(_duration);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}