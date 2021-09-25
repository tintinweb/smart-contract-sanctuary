// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

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
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./ISourceChild.sol";
import './FxBaseChildTunnel.sol';

/**
 * @title FxSourceChildTunnel
 */
contract FxSourceChildTunnel is FxBaseChildTunnel {
    bytes32 public constant WITHDRAW_SINGLE = keccak256("WITHDRAW_SINGLE");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
    bytes32 public constant DEPOSIT_SINGLE = keccak256("DEPOSIT_SINGLE");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    uint256 public constant BATCH_LIMIT = 20;

    event FxWithdrawing(address indexed rootToken, address indexed to, uint256 tokenId);
    event FxDeposited(address indexed rootToken, address indexed depositor, address indexed to, uint256 tokenId);

    // event for token maping
    event TokenMap(address indexed rootToken, address indexed childToken);
    // child to root token
    mapping(address => address) public childToRootTokens;
    // root to child token
    mapping(address => address) public rootToChildTokens;

    constructor(address _fxChild)
        FxBaseChildTunnel(_fxChild) 
    {
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal
     * @param rootToken address of token on root chain
     * @param childToken address of token on child chain
     */
    function mapToken(address rootToken, address childToken) public {
        // check if token is already mapped
        require(rootToChildTokens[rootToken] == address(0x0), "FxSourceChildTunnel: ALREADY_MAPPED");
        require(childToRootTokens[childToken] == address(0x0), "FxSourceChildTunnel: ALREADY_MAPPED");
        rootToChildTokens[rootToken] = childToken;
        childToRootTokens[childToken] = rootToken;
        emit TokenMap(rootToken, childToken);
    }

    // WITHDRAW_SINGLE
    function withdraw(address childToken, uint256 tokenId, bytes memory tokenData) external {
        address rootToken = childToRootTokens[childToken];
        require (childToken == rootToChildTokens[rootToken], "FxSourceChildTunnel: NOT_MAPPED");

        // withdraw token
        ISourceChild(childToken).burn(tokenId, tokenData);
        emit FxWithdrawing(rootToken, msg.sender, tokenId);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_SINGLE, abi.encode(rootToken, childToken, msg.sender, tokenId, tokenData)));
    }

    function genWithdraw(address childToken, uint256 tokenId, bytes memory tokenData) external view returns (bytes memory) {
        address rootToken = childToRootTokens[childToken];
        return abi.encode(WITHDRAW_SINGLE, abi.encode(rootToken, childToken, msg.sender, tokenId, tokenData));
    }

    // WITHDRAW_BATCH
    function withdrawBatch(address childToken, uint256[] memory tokenIds, bytes[] memory tokenDatas) external {
        require(tokenIds.length <= BATCH_LIMIT, "FxSourceChildTunnel: EXCEEDS_BATCH_LIMIT");
        require(tokenDatas.length == tokenIds.length || tokenDatas.length == 0, "FxSourceChildTunnel: TOKEN_DATAS_MISMATCHED");
        address rootToken = childToRootTokens[childToken];
        require(childToken == rootToChildTokens[rootToken], "FxSourceChildTunnel: NOT_MAPPED");

        // withdraw tokens
        for (uint i=0; i<tokenIds.length; i++) {
            ISourceChild(childToken).burn(tokenIds[i], tokenDatas.length == tokenIds.length ? tokenDatas[i] : bytes(''));
            emit FxWithdrawing(rootToken, msg.sender, tokenIds[i]);
        }

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_BATCH, abi.encode(rootToken, childToken, msg.sender, tokenIds, tokenDatas)));
    }

    function genWithdrawBatch(address childToken, uint256[] memory tokenIds, bytes[] memory tokenDatas) external view returns (bytes memory) {
        address rootToken = childToRootTokens[childToken];
        return abi.encode(WITHDRAW_BATCH, abi.encode(rootToken, childToken, msg.sender, tokenIds, tokenDatas));
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
            revert("FxSourceChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDepositSingle(bytes memory syncData) internal {
        (address rootToken, address depositor, address receiveAddress, uint256 tokenId, uint256 seed, bytes memory tokenData) = abi.decode(syncData, (address, address, address, uint256, uint256, bytes));
        
        address childToken = rootToChildTokens[rootToken];

        // deposit token
        ISourceChild(childToken).mint(receiveAddress, tokenId, seed, tokenData);
        emit FxDeposited(rootToken, depositor, receiveAddress, tokenId);
    }

    function _syncDepositBatch(bytes memory syncData) internal {
        (address rootToken, address depositor, address receiveAddress, uint256[] memory tokenIds, uint256[] memory seeds, bytes[] memory tokenDatas) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes[]));
        require(tokenIds.length > 0 && tokenIds.length == seeds.length);
        
        address childToken = rootToChildTokens[rootToken];

        for (uint i=0; i<tokenIds.length; i++) {
            // deposit tokens
            ISourceChild(childToken).mint(receiveAddress, tokenIds[i], seeds[i], tokenDatas.length == tokenIds.length ? tokenDatas[i] : bytes(''));
            emit FxDeposited(rootToken, depositor, receiveAddress, tokenIds[i]);
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
    function mint(address to, uint256 tokenId, uint256 seed, bytes memory data) external;
    function burn(uint256 tokenId, bytes memory data) external;
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