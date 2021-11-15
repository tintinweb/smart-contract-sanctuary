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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Tracer Standard Vesting Contract
 */
contract Vesting is Ownable {
    struct Schedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        bool isFixed;
        address asset;
    }

    // user => scheduleId => schedule
    mapping(address => mapping(uint256 => Schedule)) public schedules;
    mapping(address => uint256) public numberOfSchedules;

    mapping(address => uint256) public locked;

    event Claim(address indexed claimer, uint256 amount);
    event Vest(address indexed to, uint256 amount);
    event Cancelled(address account);

    constructor() {}

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @dev adds a new Schedule to the schedules mapping.
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after
     *                the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param asset the asset that the user is being vested
     * @param isFixed a flag for if the vesting schedule is fixed or not. Fixed vesting schedules can't be cancelled.
     * @param cliffWeeks the number of weeks that the cliff will be present at.
     * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
     * @param startTime the timestamp for when this vesting should have started
     */
    function vest(
        address account,
        uint256 amount,
        address asset,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        uint256 startTime
    ) public onlyOwner {
        // ensure cliff is shorter than vesting
        require(
            vestingWeeks >= cliffWeeks,
            "Vesting: cliff after vesting period"
        );

        uint256 currentLocked = locked[asset];

        // require the token is present
        require(
            IERC20(asset).balanceOf(address(this)) >= currentLocked + amount,
            "Vesting: Not enough tokens"
        );

        // create the schedule
        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            startTime,
            startTime + (cliffWeeks * 1 weeks),
            startTime + (vestingWeeks * 1 weeks),
            isFixed,
            asset
        );
        numberOfSchedules[account] = currentNumSchedules + 1;
        locked[asset] = currentLocked + amount;
        emit Vest(account, amount);
    }

    /**
     * @notice Sets up vesting schedules for multiple users within 1 transaction.
     * @dev adds a new Schedule to the schedules mapping.
     * @param accounts an array of the accounts that the vesting schedules are being set up for.
     *                 Will be able to claim tokens after the cliff period.
     * @param amount an array of the amount of tokens being vested for each user.
     * @param asset the asset that the user is being vested
     * @param isFixed bool setting if these vesting schedules can be rugged or not.
     * @param cliffWeeks the number of weeks that the cliff will be present at.
     * @param vestingWeeks the number of weeks the tokens will vest over (linearly)
     * @param startTime the timestamp for when this vesting should have started
     */
    function multiVest(
        address[] calldata accounts,
        uint256[] calldata amount,
        address asset,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        uint256 startTime
    ) external onlyOwner {
        uint256 numberOfAccounts = accounts.length;
        require(
            amount.length == numberOfAccounts,
            "Vesting: Array lengths differ"
        );
        for (uint256 i = 0; i < numberOfAccounts; i++) {
            vest(
                accounts[i],
                amount[i],
                asset,
                isFixed,
                cliffWeeks,
                vestingWeeks,
                startTime
            );
        }
    }

    /**
     * @notice allows users to claim vested tokens if the cliff time has passed.
     * @param scheduleNumber which schedule the user is claiming against
     */
    function claim(uint256 scheduleNumber) public {
        Schedule storage schedule = schedules[msg.sender][scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliff not reached"
        );
        require(schedule.totalAmount > 0, "Vesting: not claimable");

        // Get the amount to be distributed
        uint256 amount = calcDistribution(
            schedule.totalAmount,
            block.timestamp,
            schedule.startTime,
            schedule.endTime
        );

        // Cap the amount at the total amount
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint256 amountToTransfer = amount - schedule.claimedAmount;
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        locked[schedule.asset] = locked[schedule.asset] - amountToTransfer;
        IERC20(schedule.asset).transfer(msg.sender, amountToTransfer);
        emit Claim(msg.sender, amount);
    }

    /**
     * @notice Allows a vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the system.
     * @param account the account of the user whos vesting schedule is being cancelled.
     */
    function rug(address account, uint256 scheduleId) public onlyOwner {
        Schedule storage schedule = schedules[account][scheduleId];
        require(!schedule.isFixed, "Vesting: Account is fixed");
        uint256 outstandingAmount = schedule.totalAmount -
            schedule.claimedAmount;
        require(outstandingAmount != 0, "Vesting: no outstanding tokens");
        schedule.totalAmount = 0;
        locked[schedule.asset] = locked[schedule.asset] - outstandingAmount;
        IERC20(schedule.asset).transfer(owner(), outstandingAmount);
        emit Cancelled(account);
    }

    /**
     * @return calculates the amount of tokens to distribute to an account at any instance in time, based off some
     *         total claimable amount.
     * @param amount the total outstanding amount to be claimed for this vesting schedule.
     * @param currentTime the current timestamp.
     * @param startTime the timestamp this vesting schedule started.
     * @param endTime the timestamp this vesting schedule ends.
     */
    function calcDistribution(
        uint256 amount,
        uint256 currentTime,
        uint256 startTime,
        uint256 endTime
    ) public pure returns (uint256) {
        // avoid uint underflow
        if (currentTime < startTime) {
            return 0;
        }

        // if endTime < startTime, this will throw. Since endTime should never be
        // less than startTime in safe operation, this is fine.
        return (amount * (currentTime - startTime)) / (endTime - startTime);
    }

    /**
     * @notice Withdraws TCR tokens from the contract.
     * @dev blocks withdrawing locked tokens.
     */
    function withdraw(uint256 amount, address asset) public onlyOwner {
        IERC20 token = IERC20(asset);
        require(
            token.balanceOf(address(this)) - locked[asset] >= amount,
            "Vesting: Can't withdraw"
        );
        token.transfer(owner(), amount);
    }
}

