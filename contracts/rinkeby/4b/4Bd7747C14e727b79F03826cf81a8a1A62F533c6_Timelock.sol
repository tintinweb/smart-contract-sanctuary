pragma solidity ^0.5.17;

/**
 * @title Base contract to properly handle returned data on failed calls
 * @dev On EVM if the return data length of a call is less than 68,
 * then the transaction fails silently without a revert message!
 *
 * As described in the Solidity documentation
 * https://solidity.readthedocs.io/en/v0.5.17/control-structures.html#revert
 * the revert reason is an ABI-encoded string consisting of:
 * 0x08c379a0 // Function selector (method id) for "Error(string)" signature
 * 0x0000000000000000000000000000000000000000000000000000000000000020 // Data offset
 * 0x000000000000000000000000000000000000000000000000000000000000001a // String length
 * 0x4e6f7420656e6f7567682045746865722070726f76696465642e000000000000 // String data
 *
 * Another example, debug data from test:
 *   0x08c379a0
 *   0000000000000000000000000000000000000000000000000000000000000020
 *   0000000000000000000000000000000000000000000000000000000000000034
 *   54696d656c6f636b3a3a73657444656c61793a2044656c6179206d7573742065
 *   7863656564206d696e696d756d2064656c61792e000000000000000000000000
 *
 * Parsed into:
 *   Data offset: 20
 *   Length: 34
 *   Error message:
 *     54696d656c6f636b3a3a73657444656c61793a2044656c6179206d7573742065
 *     7863656564206d696e696d756d2064656c61792e000000000000000000000000
 */
contract ErrorDecoder {
    uint256 constant ERROR_MESSAGE_SHIFT = 68; // EVM silent revert error string length

    /**
     * @notice Concats two error strings taking into account ERROR_MESSAGE_SHIFT.
     * @param str1 First string, usually a hardcoded context written by dev.
     * @param str2 Second string, usually the error message from the reverted call.
     * @return The concatenated error string
     */
    function _addErrorMessage(string memory str1, string memory str2)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesStr1 = bytes(str1);
        bytes memory bytesStr2 = bytes(str2);
        string memory str12 = new string(
            bytesStr1.length + bytesStr2.length - ERROR_MESSAGE_SHIFT
        );
        bytes memory bytesStr12 = bytes(str12);
        uint256 j = 0;
        for (uint256 i = 0; i < bytesStr1.length; i++) {
            bytesStr12[j++] = bytesStr1[i];
        }
        for (uint256 i = ERROR_MESSAGE_SHIFT; i < bytesStr2.length; i++) {
            bytesStr12[j++] = bytesStr2[i];
        }
        return string(bytesStr12);
    }
}

pragma solidity >=0.5.0 <0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Integer division of two numbers, rounding up and truncating the quotient
     */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Integer division of two numbers, rounding up and truncating the quotient
     */
    function divCeil(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

pragma solidity ^0.5.17;

import "./ErrorDecoder.sol";
import "./SafeMath.sol";

interface ITimelock {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}

contract Timelock is ErrorDecoder, ITimelock {
    using SafeMath for uint256;

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 3 hours;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /**
     * @notice Function called on instance deployment of the contract.
     * @param admin_ Governance contract address.
     * @param delay_ Time to wait for queued transactions to be executed.
     * */
    constructor(address admin_, uint256 delay_) public {
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::constructor: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );

        admin = admin_;
        delay = delay_;
    }

    /**
     * @notice Fallback function is to react to receiving value (rBTC).
     * */
    function() external payable {}

    /**
     * @notice Set a new delay when executing the contract calls.
     * @param delay_ The amount of time to wait until execution.
     * */
    function setDelay(uint256 delay_) public {
        require(
            msg.sender == address(this),
            "Timelock::setDelay: Call must come from Timelock."
        );
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::setDelay: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );
        delay = delay_;

        emit NewDelay(delay);
    }

    /**
     * @notice Accept a new admin for the timelock.
     * */
    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    /**
     * @notice Set a new pending admin for the timelock.
     * @param pendingAdmin_ The new pending admin address.
     * */
    function setPendingAdmin(address pendingAdmin_) public {
        require(
            msg.sender == address(this),
            "Timelock::setPendingAdmin: Call must come from Timelock."
        );
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    /**
     * @notice Queue a new transaction from the governance contract.
     * @param target The contract to call.
     * @param value The amount to send in the transaction.
     * @param signature The stanndard representation of the function called.
     * @param data The ethereum transaction input data payload.
     * @param eta Estimated Time of Accomplishment. The timestamp that the
     * proposal will be available for execution, set once the vote succeeds.
     * */
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /**
     * @notice Cancel a transaction.
     * @param target The contract to call.
     * @param value The amount to send in the transaction.
     * @param signature The stanndard representation of the function called.
     * @param data The ethereum transaction input data payload.
     * @param eta Estimated Time of Accomplishment. The timestamp that the
     * proposal will be available for execution, set once the vote succeeds.
     * */
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /**
     * @notice Executes a previously queued transaction from the governance.
     * @param target The contract to call.
     * @param value The amount to send in the transaction.
     * @param signature The stanndard representation of the function called.
     * @param data The ethereum transaction input data payload.
     * @param eta Estimated Time of Accomplishment. The timestamp that the
     * proposal will be available for execution, set once the vote succeeds.
     * */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(
            callData
        );
        if (!success) {
            if (returnData.length <= ERROR_MESSAGE_SHIFT) {
                revert(
                    "Timelock::executeTransaction: Transaction execution reverted."
                );
            } else {
                revert(
                    _addErrorMessage(
                        "Timelock::executeTransaction: ",
                        string(returnData)
                    )
                );
            }
        }

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    /**
     * @notice A function used to get the current Block Timestamp.
     * @dev Timestamp of the current block in seconds since the epoch.
     * It is a Unix time stamp. So, it has the complete information about
     * the date, hours, minutes, and seconds (in UTC) when the block was
     * created.
     * */
    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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