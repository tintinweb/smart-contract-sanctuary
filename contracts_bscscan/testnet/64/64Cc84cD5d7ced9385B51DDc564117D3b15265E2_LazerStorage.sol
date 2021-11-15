// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./LazerStorageOwners.sol";
import "./interfaces/ILazerStorageSchema.sol";
import "./libs/IERC20.sol";
import "./libs/SafeMath.sol";

/**
 * @dev Contract for LazerMerchant's wallet storage
 */
contract LazerStorage is LazerStorageOwners, ILazerStorageSchema {
    using SafeMath for uint256;

    mapping(address => Wallet) internal merchantWalletsMapping;
    mapping(uint256 => mapping(address => Wallet)) internal merchantsIDToWalletMapping;
    //Mapping that enables ease of traversal of the Merchants stake Records
    mapping(address => RecordIndex) public merchantsWalletStakeRecordIndex;

    Wallet[] private _wallets;
    StakingRecord[] public _stakingRecords;

    function doesStakeRecordExist(address walletId) public view returns (bool) {
        return merchantsWalletStakeRecordIndex[walletId].exists;
    }

    function getRecordIndex(address walletId) public view returns (uint256) {
        require(doesStakeRecordExist(walletId), "The wallet does not exist");
        return merchantsWalletStakeRecordIndex[walletId].index;
    }

    function getLenghtOfStakeRecords() public view returns (uint256) {
        return _stakingRecords.length;
    }

    function getStakingRecordByIndex(uint256 index)
        public
        view
        returns (
            uint256 merchantId,
            uint256 amountStaked,
            uint256 derivativeBalance,
            uint256 derivativeTotalWithdrawn,
            uint256 derivativeDeposits,
            uint256 underlyingTotalWithdrawn,
            address stakeToken,
            address walletId,
            bool exists
        )
    {
        StakingRecord memory record = _stakingRecords[index];
        return (
            record.merchant,
            record.amountStaked,
            record.derivativeBalance,
            record.derivativeTotalWithdrawn,
            record.derivativeDeposits,
            record.underlyingTotalWithdrawn,
            record.stakeToken,
            record.walletId,
            record.exists
        );
    }

    function getStakingRecordByWalletAddress(address wallet)
        public
        view
        returns (
            uint256 merchantId,
            uint256 amountStaked,
            uint256 derivativeBalance,
            uint256 derivativeTotalWithdrawn,
            uint256 derivativeDeposits,
            uint256 underlyingTotalWithdrawn,
            address stakeToken,
            address walletId,
            bool exists
        )
    {
        RecordIndex memory index = merchantsWalletStakeRecordIndex[wallet];
        require(index.exists, "The wallet does not have a record");
        return getStakingRecordByIndex(index.index);
    }

    function createStakeRecord(
        uint256 merchantId,
        address walletId,
        uint256 amountStaked,
        uint256 derivativeBalance,
        uint256 derivativeTotalWithdrawn,
        uint256 derivativeDeposits,
        uint256 underlyingTotalWithdrawn,
        address stakeToken
    ) external onlyStorageOracle {
        RecordIndex memory recordIndex = merchantsWalletStakeRecordIndex[walletId];
        //Create a new record
        require(!doesStakeRecordExist(walletId), "wallet already has a record");
        StakingRecord memory newRecord = StakingRecord(
            merchantId,
            amountStaked,
            derivativeBalance,
            derivativeTotalWithdrawn,
            derivativeDeposits,
            underlyingTotalWithdrawn,
            stakeToken,
            walletId,
            true
        );
        //Add the record to the merchant's stake records
        recordIndex = RecordIndex(true, _stakingRecords.length);
        _stakingRecords.push(newRecord);
        //Add the record to the merchant's wallet's stake records
        merchantsWalletStakeRecordIndex[walletId] = recordIndex;
    }

    function updateStakeRecord(
        uint256 merchantId,
        address walletId,
        uint256 amountStaked,
        uint256 derivativeBalance,
        uint256 derivativeTotalWithdrawn,
        uint256 derivativeDeposits,
        uint256 underlyingTotalWithdrawn,
        address stakeToken
    ) external onlyStorageOracle {
        RecordIndex memory recordIndex = merchantsWalletStakeRecordIndex[walletId];
        //Update the record
        require(doesStakeRecordExist(walletId), "The wallet does not have a record");
        StakingRecord memory stakeRecord = StakingRecord(
            merchantId,
            amountStaked,
            derivativeBalance,
            derivativeTotalWithdrawn,
            derivativeDeposits,
            underlyingTotalWithdrawn,
            stakeToken,
            walletId,
            true
        );
        //Update the record in the merchant's stake records
        _stakingRecords[recordIndex.index] = stakeRecord;
        //Update the record in the merchant's wallet's stake records
        merchantsWalletStakeRecordIndex[walletId].index = recordIndex.index;
    }

    function getWallets() public view returns (Wallet[] memory) {
        return _wallets;
    }

    function getWalletById(address walletId) public view returns (Wallet memory) {
        Wallet memory wallet = merchantWalletsMapping[walletId];
        return wallet;
    }

    function createWalletMapping(
        uint256 merchant,
        address walletId,
        uint256 createdAt
    ) public onlyStorageOracle {
        require(merchant != 0, "merchant must be CANNOT BE 0");
        Wallet storage walletRecord = merchantWalletsMapping[walletId];
        walletRecord.createdAt = createdAt;
        walletRecord.merchant = merchant;
        walletRecord.walletId = walletId;
        _wallets.push(walletRecord);
    }

    function createWalletMappingToWalletID(
        uint256 merchant,
        address walletId,
        uint256 createdAt
    ) public onlyStorageOracle {
        mapping(address => Wallet) storage tempMapping = merchantsIDToWalletMapping[merchant];
        tempMapping[walletId].walletId = walletId;
        tempMapping[walletId].merchant = merchant;
        tempMapping[walletId].createdAt = createdAt;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

/**
 * @dev Contract for LazerPay's proxy layer
 */

contract LazerStorageOwners {
    address owner;
    mapping(address => bool) private storageOracles;

    constructor() public {
        owner = msg.sender;
    }

    function changeStorageOracleStatus(address oracle, bool status) external onlyOwner {
        storageOracles[oracle] = status;
    }

    function activateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = true;
    }

    function deactivateStorageOracle(address oracle) external onlyOwner {
        storageOracles[oracle] = false;
    }

    function reAssignStorageOracle(address newOracle) external onlyStorageOracle {
        storageOracles[msg.sender] = false;
        storageOracles[newOracle] = true;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
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

pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;
import "../libs/IERC20.sol";

interface ILazerStorageSchema {
    struct Wallet {
        address walletId;
        uint256 createdAt;
        uint256 merchant;
    }
    struct StakingRecord {
        uint256 merchant;
        uint256 amountStaked;
        uint256 derivativeBalance;
        uint256 derivativeTotalWithdrawn;
        uint256 derivativeDeposits;
        uint256 underlyingTotalWithdrawn;
        address stakeToken;
        address walletId;
        bool exists;
    }
    struct RecordIndex {
        bool exists;
        uint256 index;
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

