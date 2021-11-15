pragma solidity ^0.7.6;
import "@openzeppelin/contracts/math/SafeMath.sol";

contract EvryTimelock {
  using SafeMath for uint;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint indexed newDelay);
  event CancelTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);
  event ExecuteTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);
  event QueueTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);

  uint256 public minimumDelay;
  uint256 public maximumDelay;

  address public admin;
  address public pendingAdmin;

  struct TransactionData {
    address target;
    uint value;
    string signature;
    bytes data;
    uint eta;
  }
  mapping (uint256 => TransactionData) public pendingTransactions;
  bool[] transactionIndexs;

  constructor(address admin_, uint256 minimumDelay_, uint256 maximumDelay_) {
    require(minimumDelay_ <= maximumDelay_, "Timelock minimum delay must less than maximum delay");

    admin = admin_;
    minimumDelay = minimumDelay_;
    maximumDelay = maximumDelay_;
  }

  receive() external payable { }

  function pendingAdminConfirm() public {
    require(msg.sender == pendingAdmin, "Timelock pendingAdminConfirm must call from pendingAdmin");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(msg.sender == admin, "Timelock setPendingAdmin must come from admin");
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (uint256) {
    require(msg.sender == admin, "Timelock queue transaction must be call by admin");
    require(eta >= block.timestamp.add(minimumDelay), "Timelock queue transaction eta must be greater then minimum delay time");
    require(eta <= block.timestamp.add(maximumDelay), "Timelock queue transaction eta must be less then maximum delay time");

    TransactionData memory transactionData = TransactionData({
        target: target,
        value: value,
        signature: signature,
        data: data,
        eta: eta
    });
    uint256 id = transactionIndexs.length;
    transactionIndexs.push(true);
    pendingTransactions[id] = transactionData;

    emit QueueTransaction(id, target, value, signature, data, eta);
    return id;
  }

  function cancelTransaction(uint256 id) public {
    require(msg.sender == admin, "Timelock cancel transaction must come from admin");
    require(pendingTransactions[id].target != address(0), "Timelock cancel transaction ID is not valid");

    TransactionData memory transactionData = pendingTransactions[id];
    delete pendingTransactions[id];
    delete transactionIndexs[id];

    emit CancelTransaction(id, transactionData.target, transactionData.value, transactionData.signature, transactionData.data, transactionData.eta);
  }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
        // Slice the sighash.
        _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  function executeTransaction(uint256 id ) public payable returns (bytes memory) {
    require(msg.sender == admin, "Timelock execute transaction must come from admin");
    require(pendingTransactions[id].target != address(0), "Timelock execute transaction ID is not valid");

    TransactionData memory transactionData = pendingTransactions[id];
    require(block.timestamp >= transactionData.eta, "Timelock execute transaction hasn't surpassed time lock");

    bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(transactionData.signature))), transactionData.data);
    (bool success, bytes memory returnData) = transactionData.target.call{value: transactionData.value}(callData);
    require(success, _getRevertMsg(returnData));

    delete pendingTransactions[id];
    delete transactionIndexs[id];

    emit ExecuteTransaction(id, transactionData.target, transactionData.value, transactionData.signature, transactionData.data, transactionData.eta);

    return returnData;
  }

  function getPendingTransactions() external view returns (uint256[] memory txIds) {
    uint256 pendingIndexLenght = 0;
    for (uint256 i = 0; i < transactionIndexs.length; i++) {
      if (transactionIndexs[i] == true){
        pendingIndexLenght++;
      }
    }

    txIds = new uint256[](pendingIndexLenght);
    uint256 txsIndex = 0;
    for (uint256 i = 0; i < transactionIndexs.length; i++) {
      if (transactionIndexs[i] == true){
        txIds[txsIndex] = i;
        txsIndex++;
      }
    }
  }

  function getBlockTimestamp() public view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

