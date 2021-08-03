// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/xDai/messengers/IArbitraryMessageBridge.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for xDai - https://www.xdaichain.com/ (also see https://docs.tokenbridge.net/)
 * @notice Deployed on layer-1
 */

contract XDaiMessengerWrapper is MessengerWrapper {

    IArbitraryMessageBridge public l1MessengerAddress;
    /// @notice The xDai AMB uses bytes32 for chainId instead of uint256
    bytes32 public l2ChainId;
    address public ambBridge;
    address public immutable l2BridgeAddress;
    uint256 public immutable defaultGasLimit;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        IArbitraryMessageBridge _l1MessengerAddress,
        uint256 _defaultGasLimit,
        uint256 _l2ChainId,
        address _ambBridge
    )
        public
        MessengerWrapper(_l1BridgeAddress)
    {
        l2BridgeAddress = _l2BridgeAddress;
        l1MessengerAddress = _l1MessengerAddress;
        defaultGasLimit = _defaultGasLimit;
        l2ChainId = bytes32(_l2ChainId);
        ambBridge = _ambBridge;
    }

    /**
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        l1MessengerAddress.requireToPassMessage(
            l2BridgeAddress,
            _calldata,
            defaultGasLimit
        );
    }

    /// @notice message data is not needed for message verification with the xDai AMB
    function verifySender(address l1BridgeCaller, bytes memory) public override {
        require(l1MessengerAddress.messageSender() == l2BridgeAddress, "L2_XDAI_BRG: Invalid cross-domain sender");
        require(l1BridgeCaller == ambBridge, "L2_XDAI_BRG: Caller is not the expected sender");

        // With the xDai AMB, it is best practice to also check the source chainId
        // https://docs.tokenbridge.net/amb-bridge/how-to-develop-xchain-apps-by-amb#receive-a-method-call-from-the-amb-bridge
        require(l1MessengerAddress.messageSourceChainId() == l2ChainId, "L2_XDAI_BRG: Invalid source Chain ID");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IArbitraryMessageBridge {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes memory _data, uint256 _gas) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IMessengerWrapper.sol";

abstract contract MessengerWrapper is IMessengerWrapper {
    address public immutable l1BridgeAddress;

    constructor(address _l1BridgeAddress) internal {
        l1BridgeAddress = _l1BridgeAddress;
    }

    modifier onlyL1Bridge {
        require(msg.sender == l1BridgeAddress, "MW: Sender must be the L1 Bridge");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

interface IMessengerWrapper {
    function sendCrossDomainMessage(bytes memory _calldata) external;
    function verifySender(address l1BridgeCaller, bytes memory _data) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 50000
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