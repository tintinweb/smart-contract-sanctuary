/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

// File: contracts\interfaces\IERC20Detailed.sol

pragma solidity 0.8.3;

interface IERC20Detailed {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    event TokensReleased(address beneficiary, uint256 amount);
    event TokensLocked(address beneficiary, uint256 amount, uint256 paymentPlan);

    struct PaymentPlan {
        uint256 periodLength;
        uint256 periods;
        uint256 cliff;
    }

    struct Lock {
        address beneficiary;
        uint256 start;
        uint256 paymentPlan;
        uint256 totalAmount;
        uint256 released;
    }

    uint256 public constant PERCENT_100 = 100_00; // 100% with extra denominator

    PaymentPlan[] public paymentPlans;

    IERC20Detailed immutable token;

    mapping(address => Lock) public locks;

    constructor(IERC20Detailed _token) {
        token = _token;
    }

    function paymentPlansCount() external view returns (uint256) {
        return paymentPlans.length;
    }

    function detailsOf(address beneficiary)
        external
        view
        returns (Lock memory, PaymentPlan memory)
    {
        Lock storage lock = locks[beneficiary];
        PaymentPlan storage plan = paymentPlans[lock.paymentPlan];
        return (lock, plan);
    }

    /**
     * @dev Add new payment plan.
     * @param periodLength length of 1 period.
     * @param periods total vesting periods.
     * @param cliffPeriods number periods that will be scipped.
     */
    function addPaymentPlan(
        uint256 periodLength,
        uint256 periods,
        uint256 cliffPeriods
    ) public onlyOwner {
        require(cliffPeriods <= periods, "TokenVesting: invalid cliff periods");
        require(periods <= 36, "TokenVesting: max periods is 36");
        require(
            periodLength <= 2592000,
            "TokenVesting: max perido length is 30 days (2592000 seconds)"
        );
        paymentPlans.push(PaymentPlan(periodLength, periods, periodLength * cliffPeriods));
    }

    /**
     * @dev lock tokens. Allowance should be set!!!
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param amount amount of tokens to lock
     * @param start the time (as Unix time) at which point vesting starts
     * @param paymentPlan payment plan to apply
     */
    function lock(
        address beneficiary,
        uint256 amount,
        uint256 start,
        uint256 paymentPlan
    ) public {
        require(locks[beneficiary].beneficiary == address(0), "TokenVesting: already locked");
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(start > block.timestamp, "TokenVesting: final time is before current time");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "TokenVesting: transfer failed"
        );
        require(paymentPlan <= paymentPlans.length - 1, "TokenVesting: invalid payment plan");
        locks[beneficiary].beneficiary = beneficiary;
        locks[beneficiary].start = start;
        locks[beneficiary].paymentPlan = paymentPlan;
        locks[beneficiary].totalAmount = amount;
        emit TokensLocked(beneficiary, amount, paymentPlan);
    }

    function releasableAmount(address beneficiary) external view returns (uint256) {
        return _releasableAmount(locks[beneficiary]);
    }

    function release(address beneficiary) public {
        Lock storage lock = locks[beneficiary];
        uint256 unreleased = _releasableAmount(lock);
        require(unreleased > 0, "TokenVesting: no tokens available");
        lock.released = lock.released + unreleased;
        require(token.transfer(beneficiary, unreleased));
        emit TokensReleased(beneficiary, unreleased);
    }

    function _releasableAmount(Lock storage lock) private view returns (uint256) {
        return _vestedAmount(lock) - lock.released;
    }

    function _vestedAmount(Lock storage lock) private view returns (uint256) {
        PaymentPlan storage paymentPlan = paymentPlans[lock.paymentPlan];
        if (block.timestamp < lock.start + paymentPlan.cliff) {
            return 0;
        } else if (
            block.timestamp >= lock.start + (paymentPlan.periods * paymentPlan.periodLength)
        ) {
            return lock.totalAmount;
        } else {
            uint256 periodsPassed = (block.timestamp - lock.start) / paymentPlan.periodLength;
            uint256 unlockedPercents = periodsPassed * (PERCENT_100 / paymentPlan.periods);
            return (lock.totalAmount * unlockedPercents) / PERCENT_100;
        }
    }
}