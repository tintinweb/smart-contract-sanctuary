// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import { IAvartaToken } from "./interface/IAvartaToken.sol";
import { IAvartaStorage } from "./interface/IAvartaStorage.sol";
import { IAvartaStorageSchema } from "./interface/IAvartaStorageSchema.sol";
import { SafeMath } from "./libs/SafeMath.sol";
import { Ownable } from "./libs/Ownable.sol";

contract AvartaFarm is Ownable, IAvartaStorageSchema {
    using SafeMath for uint256;

    IAvartaStorage public avartaStorage;
    IAvartaToken public avartaToken;

    uint256 internal APY_VALUE_PERHOUR = 100000; //0.001%
    uint256 public totalFarmValue;
    uint256 private REFRESH_RATE = 1 * 60 * 60; // 1 hour
    uint256 private MAX_STAKING_POOL_SIZE_PERCENT = 10;
    uint256 public MAX_STAKING_POOL_SIZE;
    uint256 private PRECISION_VALUE = 100 * (10**9);
    uint256 private YEAR_SECONDS = 365 * 24 * 60 * 60;
    uint256 public LOCK_PERIOD = 30 * 60; // 30 minutes

    uint256 internal RewardPercentPerRefreshRate;

    event Stake(address indexed depositor, uint256 indexed amount, uint256 indexed recordId);
    event Withdraw(address indexed owner, uint256 indexed amount, uint256 indexed recordId);

    constructor(address storageAddress, address tokenAddress) {
        avartaStorage = IAvartaStorage(storageAddress);
        avartaToken = IAvartaToken(tokenAddress);
    }

    function getApyValue() public view returns (uint256) {
        return APY_VALUE_PERHOUR;
    }

    function getRefreshRate() public view returns (uint256) {
        return REFRESH_RATE;
    }

    function getMaxStakingPoolSize() public view returns (uint256) {
        return MAX_STAKING_POOL_SIZE;
    }

    function getMaxStakingPoolSizePercent() public view returns (uint256) {
        return MAX_STAKING_POOL_SIZE_PERCENT;
    }

    function getTotalFarmValue() public view returns (uint256) {
        return totalFarmValue;
    }

    function getPrecisionValue() public view returns (uint256) {
        return PRECISION_VALUE;
    }

    function getFixedDepositRecord(uint256 recordId) external view returns (FixedDepositRecord memory) {
        return _getFixedDepositRecordById(recordId);
    }

    function _getFixedDepositRecordById(uint256 recordId) internal view returns (FixedDepositRecord memory) {
        (
            uint256 recordId,
            address payable depositorId,
            uint256 amount,
            uint256 depositDateInSeconds,
            uint256 lockPeriodInSeconds,
            uint256 rewardAmountRecieved,
            bool hasWithdrawn
        ) = avartaStorage.getRecordById(recordId);
        FixedDepositRecord memory fixedDepositRecord = FixedDepositRecord(
            recordId,
            depositorId,
            hasWithdrawn,
            amount,
            depositDateInSeconds,
            lockPeriodInSeconds,
            rewardAmountRecieved
        );
        return fixedDepositRecord;
    }

    function updateApyValue(uint256 _apyValue) public onlyOwner {
        APY_VALUE_PERHOUR = _apyValue;
    }

    function updateRefreshRate(uint256 _refreshRate) public onlyOwner {
        REFRESH_RATE = _refreshRate;
    }

    function updateMaxStakingPoolSize() public onlyOwner {
        // 10% of the avartaToken total supply
        MAX_STAKING_POOL_SIZE = (avartaToken.totalSupply() * MAX_STAKING_POOL_SIZE_PERCENT) / 100;
    }

    function updateMaxStakingPoolSizePercent(uint256 _maxStakingPoolSizePercent) public onlyOwner {
        MAX_STAKING_POOL_SIZE_PERCENT = _maxStakingPoolSizePercent;
    }

    function updatePrecisionValue(uint256 _precisionValue) public onlyOwner {
        PRECISION_VALUE = _precisionValue;
    }

    function stake(uint256 amount, uint256 lockPeriod) public returns (bool) {
        address payable depositor = msg.sender;

        uint256 depositDate = block.timestamp;

        _validateLockPeriod(lockPeriod);

        require(avartaToken.balanceOf(depositor) >= amount, "Not enough avarta token balance");

        //check that the totalFarmValue is less than the max staking pool size
        require(totalFarmValue < MAX_STAKING_POOL_SIZE, "The totalFarmValue has reached limit");
        // check that the amount is less than the maximum staking pool size
        require(amount < MAX_STAKING_POOL_SIZE, "Amount is greater than the maximum staking pool size");

        // check allowance for the depositor
        require(avartaToken.allowance(depositor, address(this)) >= amount, "Not enough avarta token allowance");

        // transfer avarta token to the smart contract
        avartaToken.transferFrom(depositor, address(this), amount);

        // update the totalFarmValue
        totalFarmValue = totalFarmValue.add(amount);

        uint256 recordId = avartaStorage.createDepositRecordMapping(amount, lockPeriod, depositDate, depositor, 0, false);

        avartaStorage.createDepositorToDepositRecordIndexToRecordIDMapping(depositor, recordId);

        avartaStorage.createDepositorAddressToDepositRecordMapping(depositor, recordId, amount, lockPeriod, depositDate, 0, false);

        emit Stake(depositor, amount, recordId);

        return true;
    }

    function withdraw(uint256 recordId) public returns (bool) {
        address payable recepient = msg.sender;

        FixedDepositRecord memory fixedDepositRecord = _getFixedDepositRecordById(recordId);

        uint256 derivativeAmount = fixedDepositRecord.amountDeposited;

        require(derivativeAmount > 0, "Cannot withdraw 0 shares");

        require(fixedDepositRecord.depositorId == recepient, "Withdraw can only be called by depositor");

        uint256 lockPeriod = fixedDepositRecord.lockPeriodInSeconds;
        uint256 depositDate = fixedDepositRecord.depositDateInSeconds;

        _validateLockTimeHasElapsedAndHasNotWithdrawn(recordId);

        avartaToken.transfer(recepient, derivativeAmount);
        // pending when i write the calculateReward function
        uint256 rewardAmount = calculateReward(recordId);

        avartaStorage.updateDepositRecordMapping(recordId, derivativeAmount, lockPeriod, depositDate, recepient, rewardAmount, true);

        emit Withdraw(recepient, derivativeAmount, recordId);
    }

    function _validateLockPeriod(uint256 lockPeriod) internal view returns (bool) {
        require(lockPeriod > 0, "Lock period must be greater than 0");
        require(lockPeriod <= LOCK_PERIOD, "Lock period must be less than or equal to 30 minutes");
        return true;
    }

    function _validateLockTimeHasElapsedAndHasNotWithdrawn(uint256 recordId) internal view returns (bool) {
        FixedDepositRecord memory depositRecord = _getFixedDepositRecordById(recordId);

        uint256 maturityDate = depositRecord.lockPeriodInSeconds;

        bool hasWithdrawn = depositRecord.hasWithdrawn;

        require(!hasWithdrawn, "Individual has already withdrawn");

        uint256 currentTimeStamp = block.timestamp;

        require(currentTimeStamp >= maturityDate, "Funds are still locked, wait until lock period expires");

        return true;
    }

    function _updateRecord(FixedDepositRecord memory record) internal returns (bool) {
        avartaStorage.updateDepositRecordMapping(
            record.recordId,
            record.amountDeposited,
            record.lockPeriodInSeconds,
            record.depositDateInSeconds,
            record.depositorId,
            record.rewardAmountRecieved,
            record.hasWithdrawn
        );
    }

    function calculateReward(uint256 recordId) public view returns (uint256) {
        FixedDepositRecord memory record = _getFixedDepositRecordById(recordId);

        uint256 depositDate = record.depositDateInSeconds;

        uint256 depositAmount = record.amountDeposited;

        uint256 duration = block.timestamp.sub(depositDate);

        uint256 APR = calculateAprForDuration(duration);

        uint256 rewardAmount = (APR.mul(depositAmount)).div(APY_VALUE_PERHOUR);

        return rewardAmount;
    }

    function calculateAprForDuration(uint256 duration) public view returns (uint256) {
        uint256 APR = duration / 1 hours;

        return APR;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import { IERC20 } from "./IERC20.sol";

interface IAvartaToken is IERC20 {
    function getBlackListStatus(address _maker) external view returns (bool);

    function addBlackList(address _evilUser) external;

    function removeBlackList(address _clearedUser) external;

    function destroyBlackFunds(address _blackListedUser) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
import { IAvartaStorageSchema } from "./IAvartaStorageSchema.sol";

interface IAvartaStorage is IAvartaStorageSchema {
    function getRecordIndexFromDepositor(address member) external view returns (uint256);

    function createDepositRecordMapping(
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external returns (uint256);

    function updateDepositRecordMapping(
        uint256 depositRecordId,
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external;

    function getRecordId() external view returns (uint256);

    function getRecordById(uint256 depositRecordId)
        external
        view
        returns (
            uint256 recordId,
            address payable depositorId,
            uint256 amount,
            uint256 depositDateInSeconds,
            uint256 lockPeriodInSeconds,
            uint256 rewardAmountRecieved,
            bool hasWithdrawn
        );

    function getRecords() external view returns (FixedDepositRecord[] memory);

    function createDepositorAddressToDepositRecordMapping(
        address payable depositor,
        uint256 recordId,
        uint256 amountDeposited,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external;

    function createDepositorToDepositRecordIndexToRecordIDMapping(address payable depositor, uint256 recordId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface IAvartaStorageSchema {
    struct FixedDepositRecord {
        uint256 recordId;
        address payable depositorId;
        bool hasWithdrawn;
        uint256 amountDeposited;
        uint256 depositDateInSeconds;
        uint256 lockPeriodInSeconds;
        uint256 rewardAmountRecieved;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

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
    address payable public owner;
    address public WalletAdmin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address payable msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyLazerWalletOrOwner() {
        if (msg.sender == owner || msg.sender == WalletAdmin) _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyLazerWalletOrOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}