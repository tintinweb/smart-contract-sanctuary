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
import "./ISource.sol";
import './FxBaseChildTunnel.sol';

/**
 * @title HeroSourceBridgePolygon
 */
contract HeroSourceBridgePolygon is FxBaseChildTunnel {
    bytes32 public constant DEPART_SINGLE = keccak256("DEPART_SINGLE");
    bytes32 public constant DEPART_BATCH = keccak256("DEPART_BATCH");
    uint256 public constant BATCH_LIMIT = 20;

    event Depart(address indexed from, address indexed to, uint256 indexed tokenId, uint256 blockNumber);
    event Arrive(address indexed from, address indexed to, uint256 indexed tokenId, uint256 blockNumber);

    address public childToken;

    constructor(address _fxChild, address _childToken)
        FxBaseChildTunnel(_fxChild) 
    {
        childToken = _childToken;
    }

    function depart(address to, uint256 tokenId) external {
        uint256 seed = ISource(childToken).seeds(tokenId);
        _depart(msg.sender, to, tokenId, block.number);
        _sendMessageToRoot(abi.encode(DEPART_SINGLE, abi.encode(msg.sender, to, tokenId, seed, block.number)));
    }

    function departBatch(address to, uint256[] memory tokenIds) external {
        require(tokenIds.length <= BATCH_LIMIT, "HeroSourceBridgePolygon: EXCEEDS_BATCH_LIMIT");
        uint256[] memory seeds = new uint256[](tokenIds.length);
        for (uint i=0; i<tokenIds.length; i++) {
            seeds[i] = ISource(childToken).seeds(tokenIds[i]);
            _depart(msg.sender, to, tokenIds[i], block.number);
        }
        _sendMessageToRoot(abi.encode(DEPART_BATCH, abi.encode(msg.sender, to, tokenIds, seeds, block.number)));
    }

    function _processMessageFromRoot(uint256 /* stateId */, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {

        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPART_SINGLE) {
            _syncDepartFromRootSingle(syncData);
        }  else if (syncType == DEPART_BATCH) {
            _syncDepartFromRootBatch(syncData);
        } else {
            revert("HeroSourceBridgePolygon: INVALID_SYNC_TYPE");
        }
    }

    function _syncDepartFromRootSingle(bytes memory syncData) private {
        (address from, address to, uint256 tokenId, uint256 seed, uint256 blockNumber) = abi.decode(syncData, (address, address, uint256, uint256, uint256));
        _arrive(from, to, tokenId, seed, blockNumber);
    }

    function _syncDepartFromRootBatch(bytes memory syncData) private {
        (address from, address to, uint256[] memory tokenIds, uint256[] memory seeds, uint256 blockNumber) = abi.decode(syncData, (address, address, uint256[], uint256[], uint256));
        for (uint i=0; i<tokenIds.length; i++) {
            _arrive(from, to, tokenIds[i], seeds[i], blockNumber);
        }
    }

    function _depart(address from, address to, uint256 tokenId, uint256 blockNumber) private {
        require(from != address(0) && to != address(0) && tokenId != 0 && blockNumber != 0);
        if (tokenId % 7 == 1) {
            // ethereum origin
            require(IERC721(childToken).ownerOf(tokenId) == from);
            ISource(childToken).bridgeBurn(tokenId);
        } else if (tokenId % 7 == 2) {
            // polygon origin
            IERC721(childToken).transferFrom(
                from,
                address(this),
                tokenId
            );
        } else {
            revert();
        }
        emit Depart(from, to, tokenId, blockNumber);
    }

    function _arrive(address from, address to, uint256 tokenId, uint256 seed, uint256 blockNumber) private {
        require(from != address(0) && to != address(0) && tokenId != 0 && seed != 0 && blockNumber != 0);
        if (tokenId % 7 == 1) {
            // ethereum origin
            ISource(childToken).bridgeMint(to, tokenId, seed);
        } else if (tokenId % 7 == 2) {
            // polygon origin
            IERC721(childToken).safeTransferFrom(
                address(this),
                to,
                tokenId
            );
        } else {
            revert();
        }
        emit Arrive(from, to, tokenId, blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ISource {
    function seeds(uint256 tokenId) external returns (uint256);
    function bridgeMint(address to, uint256 tokenId, uint256 seed) external;
    function bridgeBurn(uint256 tokenId) external;
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