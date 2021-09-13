/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

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


// Dependency file: contracts/interfaces/ISafeStorage.sol


// pragma solidity >=0.7.6;
pragma abicoder v2;

interface ISafeStorage {
    function execute(
        address _receipts,
        uint256 _value,
        bytes memory _data
    ) external payable returns (bool success, bytes memory result);
}


// Dependency file: contracts/libs/TimelockLibrary.sol


// pragma solidity >=0.8.0;

library TimelockLibrary {
    struct Transaction {
        address callFrom;
        bytes32 hash;
        address target;
        uint256 value;
        string signature;
        bytes data;
        uint256 eta;
    }

    uint256 public constant GRACE_PERIOD = 14 days;
}


// Root file: contracts/timelock/Timelock.sol


pragma solidity >=0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "contracts/interfaces/ISafeStorage.sol";
// import "contracts/libs/TimelockLibrary.sol";

contract Timelock is Ownable {
    using SafeMath for uint256;

    struct Transaction {
        address callFrom;
        bytes32 hash;
        address target;
        uint256 value;
        string signature;
        bytes data;
        uint256 eta;
    }

    uint256 public constant MINIMUM_DELAY = 6 hours;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public safeStorage;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed hash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed hash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed hash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    constructor(
        address _safeStorage,
        uint256 _delay
    ) {
        require(
            _delay >= MINIMUM_DELAY,
            "Timelock::constructor: Delay must exceed minimum delay."
        );
        require(
            _delay <= MAXIMUM_DELAY,
            "Timelock::constructor: Delay must not exceed maximum delay."
        );

        safeStorage = _safeStorage;
        delay = _delay;
    }

    fallback() external payable {}

    receive() external payable {
        require(false, "Dont accept direct ether deposit");
    }

    function setDelay(uint256 _delay) public onlyThis {
        require(
            _delay >= MINIMUM_DELAY,
            "Timelock::setDelay: Delay must exceed minimum delay."
        );
        require(
            _delay <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );
        delay = _delay;

        emit NewDelay(delay);
    }

    function queueTransaction(Transaction memory _tx) public onlyOwner {
        require(
            _tx.eta >= _getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        queuedTransactions[_tx.hash] = true;

        emit QueueTransaction(
            _tx.hash,
            _tx.target,
            _tx.value,
            _tx.signature,
            _tx.data,
            _tx.eta
        );
    }

    function cancelTransaction(Transaction memory _tx) public onlyOwner {
        queuedTransactions[_tx.hash] = false;

        emit CancelTransaction(
            _tx.hash,
            _tx.target,
            _tx.value,
            _tx.signature,
            _tx.data,
            _tx.eta
        );
    }

    function executeTransaction(Transaction memory _tx)
        public
        payable
        onlyOwner
        returns (bytes memory returnData)
    {
        require(
            queuedTransactions[_tx.hash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            _getBlockTimestamp() >= _tx.eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            _getBlockTimestamp() <= _tx.eta.add(TimelockLibrary.GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[_tx.hash] = false;

        bool success;
        if (_tx.callFrom == safeStorage) {
            // solium-disable-next-line security/no-call-value
            (success, returnData) = ISafeStorage(safeStorage).execute{
                value: msg.value
            }(_tx.target, _tx.value, _tx.data);

            emit ExecuteTransaction(
                _tx.hash,
                _tx.target,
                _tx.value,
                _tx.signature,
                _tx.data,
                _tx.eta
            );

            return returnData;
        }

        // solium-disable-next-line security/no-call-value
        (success, returnData) = _tx.target.call{value: _tx.value}(_tx.data);
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(
            _tx.hash,
            _tx.target,
            _tx.value,
            _tx.signature,
            _tx.data,
            _tx.eta
        );

        return returnData;
    }

    function _getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    modifier onlyThis() {
        require(
            msg.sender == address(this),
            "Timelock: Call must come from this contract."
        );
        _;
    }
}