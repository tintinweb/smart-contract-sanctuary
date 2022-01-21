// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/Math.sol";

import { FxBaseChildTunnel } from "./tunnel/FxBaseChildTunnel.sol";
import { Governed } from "./Governed.sol";

interface UChildERC20 {
    function withdraw(uint256 _amount) external;

    function deposit(address user, bytes calldata _data) external;

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ChildTunnel is FxBaseChildTunnel, Governed {
    // Action types
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");

    // The contract for interacting with The Graph Token
    UChildERC20 public immutable graphToken;

    // The gateway address
    address public gateway;

    // Maps user address -> user billing balance
    mapping(address => uint256) public userBalances;

    //////////////////////////////////////
    // Modifiers
    //////////////////////////////////////

    /**
     * @dev Check if the caller is the gateway.
     */
    modifier onlyGateway() {
        require(msg.sender == gateway, "Caller must be gateway");
        _;
    }

    //////////////////////////////////////
    // Events
    //////////////////////////////////////

    /**
     * @dev Withdraw GRT from contract
     */
    event Withdraw(address indexed user, uint256 amount);

    event Deposit(address indexed user, uint256 amount);

    /**
     * @dev User adds tokens
     */
    event TokensAdded(address indexed user, uint256 amount);

    /**
     * @dev Gateway pulled tokens from a user
     */
    event TokensPulled(address indexed user, uint256 amount);

    /**
     * @dev Gateway address updated
     */
    event GatewayUpdated(address indexed newGateway);

    //////////////////////////////////////
    // Constructor
    //////////////////////////////////////

    /**
     * @dev Constructor function
     * @param _fxChild   FxChild contract address
     * @param _token     Graph Token address
     * @param _gateway   Gateway address
     * @param _token     Graph Token address
     * @param _governor  Governor address
     */
    constructor(
        address _fxChild,
        address _gateway,
        UChildERC20 _token,
        address _governor
    ) FxBaseChildTunnel(_fxChild) Governed(_governor) {
        _setGateway(_gateway);
        graphToken = _token;
    }

    //////////////////////////////////////
    // External
    //////////////////////////////////////
    /**
     * @dev Gateway pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external onlyGateway {
        uint256 maxAmount = _pull(_user, _amount);
        _sendTokens(_to, maxAmount);
    }

    /**
     * @dev Gateway pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external onlyGateway {
        require(_users.length == _amounts.length, "Lengths not equal");
        uint256 totalPulled;
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 userMax = _pull(_users[i], _amounts[i]);
            totalPulled = totalPulled + userMax;
        }
        _sendTokens(_to, totalPulled);
    }

    function withdraw(uint256 _amount) external {
        _withdraw(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    //////////////////////////////////////
    // Internal methods
    //////////////////////////////////////
    /**
     * @dev Gateway pulls tokens from the billing contract. Uses Math.min() so that it won't fail
     * in the event that a user removes in front of the gateway pulling
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     */
    function _pull(address _user, uint256 _amount) internal returns (uint256) {
        uint256 maxAmount = Math.min(_amount, userBalances[_user]);
        if (maxAmount > 0) {
            userBalances[_user] = userBalances[_user] - maxAmount;
            emit TokensPulled(_user, maxAmount);
        }
        return maxAmount;
    }

    /**
     * @dev Send tokens to a destination account
     * @param _to Address where to send tokens
     * @param _amount Amount of tokens to send
     */
    function _sendTokens(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            require(_to != address(0), "Cannot transfer to empty address");
            require(graphToken.transfer(_to, _amount), "Token transfer failed");
        }
    }

    function _withdraw(address _requester, uint256 _amount) internal {
        // Burn tokens from contract
        graphToken.withdraw(_amount);

        // Update user balance
        userBalances[_requester] = userBalances[_requester] - _amount;

        // Send message to root regarding tokens burn
        _sendMessageToRoot(abi.encode(_requester, _amount));
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        // Decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            // Decode syncData
            (address depositor, uint256 amount) = abi.decode(syncData, (address, uint256));

            // Mint tokens to contract
            graphToken.deposit(address(this), abi.encode(amount));

            // Update user balance
            userBalances[depositor] = userBalances[depositor] + amount;

            emit Deposit(depositor, amount);
        } else if (syncType == WITHDRAW) {
            // Decode syncData
            (address depositor, uint256 amount) = abi.decode(syncData, (address, uint256));

            // Withdraw from contract
            _withdraw(depositor, amount);
        } else {
            revert("Billing: INVALID_SYNC_TYPE");
        }
    }

    //////////////////////////////////////
    // Setters
    //////////////////////////////////////

    /**
     * @dev Set the new gateway address
     * @param _newGateway  New gateway address
     */
    function setGateway(address _newGateway) external onlyGovernor {
        _setGateway(_newGateway);
    }

    /**
     * @dev Set the new gateway address
     * @param _newGateway  New gateway address
     */
    function _setGateway(address _newGateway) internal {
        require(_newGateway != address(0), "Gateway cannot be 0");
        gateway = _newGateway;
        emit GatewayUpdated(gateway);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Graph Governance contract
 * @dev Allows a contract to be owned and controlled by the 'governor'
 */
contract Governed {
    // -- State --

    // The address of the governor
    address public governor;
    // The address of the pending governor
    address public pendingGovernor;

    // -- Events --

    // Emit when the pendingGovernor state variable is updated
    event NewPendingOwnership(address indexed from, address indexed to);
    // Emit when the governor state variable is updated
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor with the _initGovernor param.
     * @param _initGovernor Governor address
     */
    constructor(address _initGovernor) {
        require(_initGovernor != address(0), "Governor must not be 0");
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}