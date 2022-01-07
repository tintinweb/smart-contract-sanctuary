// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  @dev This contract is one of 3 vesting contracts for the JustCarbon Foundation

  Here, we cover the case of complex vesting contract with a nonLinear vesting schedule over a fixed time period

  @author jordaniza ([email protected])
 */

contract ComplexVesting is Ownable, ReentrancyGuard {
    /* =============== Immutable variables ================= */

    // length of a vesting period
    uint256 public immutable vestingPeriodLength;

    // length of the interval to adjust the vesting rate,
    // in terms of vesting periods
    uint256 public immutable vestingPeriodsBeforeDecay;

    // qty by which to reduce the base vesting
    uint256 public immutable decayQty;

    // base vesting quantity over the decay interval
    uint256 public immutable baseQty;

    // address of the account who can interact with the contract
    address public immutable beneficiary;

    // start timestamp of vesting period for the account
    uint256 public immutable startTimestamp;

    // end timestamp of vesting period for the account
    uint256 public immutable endTimestamp;

    // the contract address of the token
    IERC20 private immutable token;

    /* ================ Mutable variables ================= */

    // balance of the contract
    uint256 public balance = 0;

    // total value already withdrawn by the account
    uint256 public withdrawn = 0;

    // Lifecycle flag to prevent adding beneficiaries after tokens have been deposited
    bool public tokensDeposited = false;

    // prevent contract interactions after withdraw method called
    bool public closed = false;

    /* ===== Events ===== */

    event DepositTokens(uint256 qty);
    event WithdrawSuccess(address benficiary, uint256 qty);
    event EmergencyWithdraw();

    /* ===== Constructor ===== */

    constructor(
        address _tokenAddress,
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _vestingPeriodLength,
        uint256 _vestingPeriodsBeforeDecay,
        uint256 _decayQty,
        uint256 _baseQty
    ) {
        require((_startTimestamp > block.timestamp), "Pass start in future");
        require(_endTimestamp > _startTimestamp, "End before start");
        require(_baseQty >= _decayQty, "Cannot decay more than base");
        require(
            (_vestingPeriodsBeforeDecay > 0) &&
                (_vestingPeriodLength > 0) &&
                (_decayQty > 0) &&
                (_baseQty > 0),
            "Pass positive quantities"
        );
        token = IERC20(_tokenAddress);
        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        vestingPeriodLength = _vestingPeriodLength;
        vestingPeriodsBeforeDecay = _vestingPeriodsBeforeDecay;
        decayQty = _decayQty;
        baseQty = _baseQty;
    }

    /* ===== Modifiers ==== */

    modifier afterDeposit() {
        require(tokensDeposited, "Cannot call before deposit");
        _;
    }

    modifier notClosed() {
        require(!closed, "Contract closed");
        _;
    }

    /* ===== Getters and view functions ===== */

    /**
    Non linear vesting schedule that pays out progressively less per period, as time goes on.

    @dev Compute the cumulative amount vested by incrementing a `vestingAmount` variable.
    Each decayPeriod (eg. year), the amount vesting per period (eg. month) declines, according to the decay

        @param elapsedDecayPeriods is the number of whole "decay periods" the contract has been running - eg. 3 years
        @param elapsedCarryover is the completed vesting periods in the in the decay period - eg. 2 months
        @return the amount that has been vested over time
    */
    function _calculateVestingAmount(
        uint256 elapsedDecayPeriods,
        uint256 elapsedCarryover
    ) private view returns (uint256) {
        // initially set the vesting amount to zero
        uint256 vestingAmount = 0;

        // then, for every whole "decay period" that has passed (i.e. years):
        for (uint256 i; i <= elapsedDecayPeriods; i++) {
            // initialize the quantity vested in this period to zero
            uint256 periodVestingQty = 0;
            uint256 decayForPeriod = decayQty * i;

            // if decay would cause underflow, just set vesting quantity to zero
            if (decayForPeriod < baseQty) {
                // otherwise, get the per period vesting quantity (i.e monthly)
                periodVestingQty =
                    (baseQty - decayForPeriod) /
                    vestingPeriodsBeforeDecay;
            }
            // i is the period, if it's less than the elapsed, just take the whole period
            if (i < elapsedDecayPeriods) {
                vestingAmount += periodVestingQty * vestingPeriodsBeforeDecay;

                // otherwise, take the number of periods in the current decay period
            } else {
                vestingAmount += periodVestingQty * elapsedCarryover;
            }
        }
        return vestingAmount;
    }

    /**
        @return the amount owed to the beneficiary at a given point in time
    */
    function calculateWithdrawal() public view returns (uint256) {
        require(block.timestamp >= startTimestamp, "Vesting not started");
        if (block.timestamp >= endTimestamp) {
            return balance;
        }
        uint256 elapsedSeconds = block.timestamp - startTimestamp;

        // whole vesting periods completed i.e. 14 months
        uint256 elapsedWholePeriods = elapsedSeconds / vestingPeriodLength;

        // whole periods completed where, after each, rate of vesting decays i.e. 2 years
        uint256 elapsedDecayPeriods = elapsedWholePeriods /
            vestingPeriodsBeforeDecay;

        // whole vesting periods in the current "decay period" i.e. 2 months (into year 3)
        uint256 elapsedCarryover = elapsedWholePeriods -
            (elapsedDecayPeriods * vestingPeriodsBeforeDecay);
        uint256 vestingAmount = _calculateVestingAmount(
            elapsedDecayPeriods,
            elapsedCarryover
        );
        uint256 finalAmount = vestingAmount - withdrawn;
        if (finalAmount > balance) {
            return balance;
        }
        return finalAmount;
    }

    /**
      @dev Deposit tokens into the contract, that can then be withdrawn by the beneficiaries
     */
    function deposit(uint256 amount) public onlyOwner returns (bool) {
        require(amount > 0, "Invalid amount");

        tokensDeposited = true;
        balance += amount;

        require(token.transferFrom(msg.sender, address(this), amount));
        emit DepositTokens(amount);

        return true;
    }

    /**
      @dev Transfer all tokens currently vested to the whitelisted account.  
     */
    function withdraw()
        public
        notClosed
        afterDeposit
        nonReentrant
        returns (bool)
    {
        require(msg.sender == beneficiary, "Only whitelisted");
        uint256 amount = calculateWithdrawal();
        require(amount > 0, "Nothing to withdraw");

        balance -= amount;
        withdrawn += amount;

        require(token.transfer(msg.sender, amount));

        emit WithdrawSuccess(msg.sender, amount);
        return true;
    }

    /**
      @dev Withdraw the full token balance of the contract to a the owner
      Used in the case of a discovered vulnerability.
     */
    function emergencyWithdraw() public onlyOwner returns (bool) {
        require(balance > 0, "No funds to withdraw");
        withdrawn += balance;
        balance = 0;
        closed = true;
        require(token.transfer(msg.sender, token.balanceOf(address(this))));
        emit EmergencyWithdraw();
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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