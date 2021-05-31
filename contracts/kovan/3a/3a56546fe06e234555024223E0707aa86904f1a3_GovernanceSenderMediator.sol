pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IAMB {
    function messageSender() external view returns (address);

    function maxGasPerTx() external view returns (uint256);

    function transactionHash() external view returns (bytes32);

    function messageId() external view returns (bytes32);

    function messageSourceChainId() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId)
        external
        view
        returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId)
        external
        view
        returns (address);

    function failedMessageSender(bytes32 _messageId)
        external
        view
        returns (address);

    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external payable returns (bytes32);

    function requireToConfirmMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

interface IGovernanceReceiverMediator {
    function queueTransaction(
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
    ) external payable;


    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function acceptAdmin() external;
}


contract GovernanceSenderMediator {
    using SafeMath for uint256;

    address public bridge;
    address public mediatorOnOtherSide;
    address public governance;
    uint256 public delay;
    uint256 public gasLimit;

    mapping(bytes32 => bool) public queuedTransactions;

    function init(
        address _bridge,
        address _mediatorOnOtherSide,
        address _governance,
        uint256 _gasLimit
    ) public {
        bridge = _bridge;
        mediatorOnOtherSide = _mediatorOnOtherSide;
        governance = _governance;
        gasLimit = _gasLimit;
    }

    function setGovernance(address _governance) public {
        governance = _governance;
    }

    function setMediatorContractOnOtherSide(address _mediatorOnOtherSide)
        public
    {
        mediatorOnOtherSide = _mediatorOnOtherSide;
    }


    function setBridgeContract(address _bridge) public {
        bridge = _bridge;
    }

    function setGasLimit(uint256 _newGasLimit) public {
        gasLimit = _newGasLimit;
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable {
        require(msg.sender == governance, "GovernanceReceiverMediator::queueTransaction: Call must come from governance");
        require(
            eta >= getBlockTimestamp().add(delay),
            "GovernanceReceiverMediator::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        bytes4 methodSelector = IGovernanceReceiverMediator(address(0)).queueTransaction.selector;

        bytes memory paramData = abi.encodeWithSelector(
            methodSelector,
            target,
            value,
            signature,
            data,
            eta
        );

        IAMB(bridge).requireToPassMessage(
            mediatorOnOtherSide,
            paramData,
            gasLimit
        );
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable {
        require(msg.sender == governance, "GovernanceReceiverMediator::executeTransaction: Call must come from governance");

        bytes4 methodSelector = IGovernanceReceiverMediator(address(0)).executeTransaction.selector;

        bytes memory paramData = abi.encodeWithSelector(
            methodSelector,
            target,
            value,
            signature,
            data,
            eta
        );

        IAMB(bridge).requireToPassMessage.value(value)(
            mediatorOnOtherSide,
            paramData,
            gasLimit
        );
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable {
        require(msg.sender == governance, "GovernanceReceiverMediator::cancelTransaction: Call must come from governance");

        bytes4 methodSelector = IGovernanceReceiverMediator(address(0)).cancelTransaction.selector;

        bytes memory paramData = abi.encodeWithSelector(
            methodSelector,
            target,
            value,
            signature,
            data,
            eta
        );

        IAMB(bridge).requireToPassMessage(
            mediatorOnOtherSide,
            paramData,
            gasLimit
        );
    }

    function acceptAdmin() public {
        require(msg.sender == governance, "GovernanceReceiverMediator::acceptAdmin: Call must come from governance");

        bytes4 methodSelector = IGovernanceReceiverMediator(address(0)).acceptAdmin.selector;

        bytes memory paramData = abi.encodeWithSelector(
            methodSelector
        );

        IAMB(bridge).requireToPassMessage(
            mediatorOnOtherSide,
            paramData,
            gasLimit
        );
    }

    function setDelay(uint256 _delay) public {
        require(msg.sender == bridge, "GovernanceSenderMediator::setDelay: Call must come from bridge");
        require(IAMB(bridge).messageSender() == mediatorOnOtherSide, "GovernanceSenderMediator::setDelay: Call must come from mediator");

        delay = _delay;
    }
}

pragma solidity ^0.5.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}