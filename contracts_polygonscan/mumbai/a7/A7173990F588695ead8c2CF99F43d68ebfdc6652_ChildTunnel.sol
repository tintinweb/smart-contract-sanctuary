// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { FxBaseChildTunnel } from "./tunnel/FxBaseChildTunnel.sol";

interface UChildERC20 {
    function withdraw(uint256 _amount) external;

    function deposit(address user, bytes calldata _data) external;
}

contract ChildTunnel is FxBaseChildTunnel {
    // Action types
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW = keccak256("WITHDRAW");

    // The contract for interacting with The Graph Token
    UChildERC20 private immutable graphToken;

    //////////////////////////////////////
    // Events
    //////////////////////////////////////

    /**
     * @dev Withdraw GRT from contract
     */
    event Withdraw(address indexed user, uint256 amount);

    event Deposit(address indexed user, uint256 amount);

    //////////////////////////////////////
    // Constructor
    //////////////////////////////////////

    /**
     * @dev Constructor function
     * @param _fxChild   FxChild contract address
     * @param _token     Graph Token address
     */
    constructor(address _fxChild, UChildERC20 _token) FxBaseChildTunnel(_fxChild) {
        graphToken = _token;
    }

    //////////////////////////////////////
    // External
    //////////////////////////////////////
    function withdraw(uint256 _amount) external {
        _withdraw(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    //////////////////////////////////////
    // Internal methods
    //////////////////////////////////////

    function _updateUserBalance() internal pure {}

    function _withdraw(address _requester, uint256 _amount) internal {
        // TODO: Update user balance
        _updateUserBalance();

        // Burn tokens from contract
        // graphToken.withdraw(_amount);
        graphToken.withdraw(_amount);

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

            // TODO: Update user balance
            // Depositor and amount is passed to this function
            //_updateUserBalance();

            // Mint tokens to contract
            // graphToken.deposit(address(this), abi.encode(amount));

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