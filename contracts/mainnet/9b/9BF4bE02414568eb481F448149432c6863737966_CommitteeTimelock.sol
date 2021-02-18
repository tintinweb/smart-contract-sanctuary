// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ICommitteeTimelock.sol";


/**
 * @dev Timelock contract with an admin and superUser, where the admin
 * must wait for the timelock and the superUser can immediately execute
 * or cancel a transaction.
 *
 * The superUser is meant to be the timelock contract for a governance DAO,
 * while the admin is a committee with delegated power over some sensitive
 * function or assets.
 */
contract CommitteeTimelock is ICommitteeTimelock {
  using SafeMath for uint256;

  uint256 public constant override GRACE_PERIOD = 14 days;
  uint256 public constant override MINIMUM_DELAY = 2 days;
  uint256 public constant override MAXIMUM_DELAY = 30 days;

  address public immutable override superUser;

  address public override admin;
  address public override pendingAdmin;
  uint256 public override delay;

  modifier isAdmin {
    require(
      msg.sender == admin || msg.sender == superUser,
      "CommitteeTimelock::isAdmin: Call must come from admin or superUser."
    );
    _;
  }

  mapping(bytes32 => bool) public override queuedTransactions;

  constructor(address admin_, address superUser_, uint256 delay_) public {
    admin = admin_;
    superUser = superUser_;
    delay = delay_;
  }

  fallback() external payable {}

  function setDelay(uint256 delay_) public override {
    require(
      msg.sender == address(this),
      "CommitteeTimelock::setDelay: Call must come from Timelock."
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "CommitteeTimelock::setDelay: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "CommitteeTimelock::setDelay: Delay must not exceed maximum delay."
    );
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public override {
    require(
      msg.sender == pendingAdmin,
      "CommitteeTimelock::acceptAdmin: Call must come from pendingAdmin."
    );
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public override {
    require(
      msg.sender == address(this),
      "CommitteeTimelock::setPendingAdmin: Call must come from Timelock."
    );
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override isAdmin returns (bytes32) {
    require(
      eta >= getBlockTimestamp().add(delay),
      "CommitteeTimelock::queueTransaction: Estimated execution block must satisfy delay."
    );
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash] == false,
      "CommitteeTimelock::queueTransaction: Transaction already queued."
    );
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public override isAdmin {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable override isAdmin returns (bytes memory) {
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "CommitteeTimelock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "CommitteeTimelock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "CommitteeTimelock::executeTransaction: Transaction is stale."
    );
    return _executeTransaction(
      txHash,
      target,
      value,
      signature,
      data,
      eta
    );
  }

  function sudo(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) public payable override returns (bytes memory) {
    require(msg.sender == superUser, "CommitteeTimelock::sudo: Caller is not superUser.");
    uint256 eta = now;
    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    return _executeTransaction(
      txHash,
      target,
      value,
      signature,
      data,
      eta
    );
  }

  function _executeTransaction(
    bytes32 txHash,
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal returns (bytes memory) {
    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(
      success,
      "CommitteeTimelock::executeTransaction: Transaction execution reverted."
    );

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;


interface ICommitteeTimelock {
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

  function GRACE_PERIOD() external pure returns (uint256);
  
  function MINIMUM_DELAY() external pure returns (uint256);
  
  function MAXIMUM_DELAY() external pure returns (uint256);

  function admin() external view returns (address);

  function superUser() external view returns (address);

  function pendingAdmin() external view returns (address);

  function delay() external view returns (uint256);

  function queuedTransactions(bytes32) external view returns (bool);

  function setDelay(uint256 delay_) external;

  function acceptAdmin() external;

  function setPendingAdmin(address pendingAdmin_) external;

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

  function sudo(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data
  ) external payable returns (bytes memory);
}