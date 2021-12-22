// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
import { SafeMath } from "./libs/SafeMath.sol";
import { AvartaStorageOwners } from "./AvartaStorageOwners.sol";
import { IAvartaStorageSchema } from "./interface/IAvartaStorageSchema.sol";

/**
 * @dev Contract for Avarta's proxy layer
 */

contract AvartaStorage is IAvartaStorageSchema, AvartaStorageOwners {
    using SafeMath for uint256;
    uint256 public DepositRecordId;

    FixedDepositRecord[] public fixedDepositRecords;

    mapping(uint256 => FixedDepositRecord) public DepositRecordMapping;

    //depositor address to depositor cycle mapping
    mapping(address => mapping(uint256 => FixedDepositRecord)) public DepositRecordToDepositorMapping;

    //  This maps the depositor to the record index and then to the record ID
    mapping(address => mapping(uint256 => uint256)) DepositorToRecordIndexToRecordIDMapping;

    //  This tracks the number of records by index created by a depositor
    mapping(address => uint256) public DepositorToDepositorRecordIndexMapping;

    function getRecordIndexFromDepositor(address member) external view returns (uint256) {
        return DepositorToDepositorRecordIndexMapping[member];
    }

    function createDepositRecordMapping(
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle returns (uint256) {
        DepositRecordId += 1;

        FixedDepositRecord storage _fixedDeposit = DepositRecordMapping[DepositRecordId];

        _fixedDeposit.recordId = DepositRecordId;
        _fixedDeposit.amountDeposited = amount;
        _fixedDeposit.lockPeriodInSeconds = lockPeriodInSeconds;
        _fixedDeposit.depositDateInSeconds = depositDateInSeconds;
        _fixedDeposit.hasWithdrawn = hasWithdrawn;
        _fixedDeposit.depositorId = depositor;
        _fixedDeposit.rewardAmountRecieved = rewardAmountRecieved;

        fixedDepositRecords.push(_fixedDeposit);

        return _fixedDeposit.recordId;
    }

    function updateDepositRecordMapping(
        uint256 depositRecordId,
        uint256 amount,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        address payable depositor,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle {
        FixedDepositRecord storage _fixedDeposit = DepositRecordMapping[depositRecordId];

        _fixedDeposit.recordId = depositRecordId;
        _fixedDeposit.amountDeposited = amount;
        _fixedDeposit.lockPeriodInSeconds = lockPeriodInSeconds;
        _fixedDeposit.depositDateInSeconds = depositDateInSeconds;
        _fixedDeposit.hasWithdrawn = hasWithdrawn;
        _fixedDeposit.depositorId = depositor;
        _fixedDeposit.rewardAmountRecieved = rewardAmountRecieved;

        //fixedDepositRecords.push(_fixedDeposit);
    }

    function getRecordId() external view returns (uint256) {
        return DepositRecordId;
    }

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
        )
    {
        FixedDepositRecord memory records = DepositRecordMapping[depositRecordId];

        return (
            records.recordId,
            records.depositorId,
            records.amountDeposited,
            records.depositDateInSeconds,
            records.lockPeriodInSeconds,
            records.rewardAmountRecieved,
            records.hasWithdrawn
        );
    }

    function getRecords() external view returns (FixedDepositRecord[] memory) {
        return fixedDepositRecords;
    }

    function createDepositorAddressToDepositRecordMapping(
        address payable depositor,
        uint256 recordId,
        uint256 amountDeposited,
        uint256 lockPeriodInSeconds,
        uint256 depositDateInSeconds,
        uint256 rewardAmountRecieved,
        bool hasWithdrawn
    ) external onlyStorageOracle {
        mapping(uint256 => FixedDepositRecord) storage depositorAddressMapping = DepositRecordToDepositorMapping[depositor];
        depositorAddressMapping[recordId].recordId = recordId;
        depositorAddressMapping[recordId].depositorId = depositor;
        depositorAddressMapping[recordId].amountDeposited = amountDeposited;
        depositorAddressMapping[recordId].depositDateInSeconds = depositDateInSeconds;
        depositorAddressMapping[recordId].lockPeriodInSeconds = lockPeriodInSeconds;
        depositorAddressMapping[recordId].rewardAmountRecieved = rewardAmountRecieved;
        depositorAddressMapping[recordId].hasWithdrawn = hasWithdrawn;
    }

    function createDepositorToDepositRecordIndexToRecordIDMapping(address payable depositor, uint256 recordId) external onlyStorageOracle {
        DepositorToDepositorRecordIndexMapping[depositor] = DepositorToDepositorRecordIndexMapping[depositor].add(1);

        uint256 DepositorCreatedRecordIndex = DepositorToDepositorRecordIndexMapping[depositor];
        mapping(uint256 => uint256) storage depositorCreatedRecordIndexToRecordId = DepositorToRecordIndexToRecordIDMapping[depositor];
        depositorCreatedRecordIndexToRecordId[DepositorCreatedRecordIndex] = recordId;
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

pragma solidity 0.7.0;

/**
 * @dev Contract for Avartas proxy layer
 */

contract AvartaStorageOwners {
    address owner;
    mapping(address => bool) private storageOracles;

    //// Events Declaration
    event StorageOracleStatus(address indexed oracle, bool indexed status);

    constructor() public {
        owner = msg.sender;
    }

    function changeStorageOracleStatus(address oracle, bool status) external onlyOwner {
        storageOracles[oracle] = status;

        emit StorageOracleStatus(oracle, status);
    }

    function activateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = true;

        emit StorageOracleStatus(oracle, true);
    }

    function deactivateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = false;

        emit StorageOracleStatus(oracle, false);
    }

    function reAssignStorageOracle(address newOracle) external onlyStorageOracle {
        storageOracles[msg.sender] = false;
        storageOracles[newOracle] = true;
    }

    function transferStorageOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }

        // require(newOwner == address(0), "new owneru");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized access to contract");
        _;
    }

    modifier onlyStorageOracle() {
        bool hasAccess = storageOracles[msg.sender];
        require(hasAccess, "unauthorized access to contract");
        _;
    }
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