// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
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

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
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
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IERC721.sol";
import "./ISourceChild.sol";
import './FxBaseChildTunnel.sol';

/**
 * @title HeroSourceBridgeFromPolygon
 */
contract HeroSourceBridgeFromPolygon is FxBaseChildTunnel {
    bytes32 public constant WITHDRAW_SINGLE = keccak256("WITHDRAW_SINGLE");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
    bytes32 public constant DEPOSIT_SINGLE = keccak256("DEPOSIT_SINGLE");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    uint256 public constant BATCH_LIMIT = 20;

    event Deposited(address indexed from, address indexed to, uint256 indexed tokenId);
    event Withdrawing(address indexed to, uint256 indexed tokenId);

    address public childToken;

    constructor(address _fxChild, address _childToken)
        FxBaseChildTunnel(_fxChild) 
    {
        childToken = _childToken;
    }

    // WITHDRAW_SINGLE
    function withdraw(uint256 tokenId) external {
        // withdraw token
        ISourceChild(childToken).burn(tokenId);
        emit Withdrawing(msg.sender, tokenId);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_SINGLE, abi.encode(msg.sender, tokenId)));
    }

    // WITHDRAW_BATCH
    function withdrawBatch(uint256[] memory tokenIds) external {
        // withdraw tokens
        for (uint i=0; i<tokenIds.length; i++) {
            ISourceChild(childToken).burn(tokenIds[i]);
            emit Withdrawing(msg.sender, tokenIds[i]);
        }

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_BATCH, abi.encode(msg.sender, tokenIds)));
    }

    //
    // Internal methods
    //
    function _processMessageFromRoot(uint256 /* stateId */, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {

        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT_SINGLE) {
            _syncDepositSingle(syncData);
        }  else if (syncType == DEPOSIT_BATCH) {
            _syncDepositBatch(syncData);
        } else {
            revert("HeroSourceBridgeFromPolygon: INVALID_SYNC_TYPE");
        }
    }

    function _syncDepositSingle(bytes memory syncData) internal {
        (address from, address to, uint256 tokenId, uint256 seed) = abi.decode(syncData, (address, address, uint256, uint256));

        // deposit token
        ISourceChild(childToken).mint(to, tokenId, seed);
        emit Deposited(from, to, tokenId);
    }

    function _syncDepositBatch(bytes memory syncData) internal {
        (address from, address to, uint256[] memory tokenIds, uint256[] memory seeds) = abi.decode(syncData, (address, address, uint256[], uint256[]));
        
        for (uint i=0; i<tokenIds.length; i++) {
            // deposit tokens
            ISourceChild(childToken).mint(to, tokenIds[i], seeds[i]);
            emit Deposited(from, to, tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ISourceChild {
    function mint(address to, uint256 tokenId, uint256 seed) external;
    function burn(uint256 tokenId) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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