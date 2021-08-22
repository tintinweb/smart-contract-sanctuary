// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/optimism/messengers/iOVM_L1CrossDomainMessenger.sol";
import "./MessengerWrapper.sol";

/**
 * @dev A MessengerWrapper for Optimism - https://community.optimism.io/docs/
 * @notice Deployed on layer-1
 */

contract OptimismMessengerWrapper is MessengerWrapper {

    iOVM_L1CrossDomainMessenger public immutable l1MessengerAddress;
    address public immutable l2BridgeAddress;
    uint256 public immutable defaultGasLimit;

    constructor(
        address _l1BridgeAddress,
        address _l2BridgeAddress,
        iOVM_L1CrossDomainMessenger _l1MessengerAddress,
        uint256 _defaultGasLimit
    )
        public
        MessengerWrapper(_l1BridgeAddress)
    {
        l2BridgeAddress = _l2BridgeAddress;
        l1MessengerAddress = _l1MessengerAddress;
        defaultGasLimit = _defaultGasLimit;
    }

    /** 
     * @dev Sends a message to the l2BridgeAddress from layer-1
     * @param _calldata The data that l2BridgeAddress will be called with
     */
    function sendCrossDomainMessage(bytes memory _calldata) public override onlyL1Bridge {
        l1MessengerAddress.sendMessage(
            l2BridgeAddress,
            _calldata,
            uint32(defaultGasLimit)
        );
    }

    function verifySender(address l1BridgeCaller, bytes memory /*_data*/) public override {
        require(l1BridgeCaller == address(l1MessengerAddress), "OVM_MSG_WPR: Caller is not l1MessengerAddress");
        // Verify that cross-domain sender is l2BridgeAddress
        require(l1MessengerAddress.xDomainMessageSender() == l2BridgeAddress, "OVM_MSG_WPR: Invalid cross-domain sender");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

import { iOVM_BaseCrossDomainMessenger } from "./iOVM_BaseCrossDomainMessenger.sol";

/**
 * @title iOVM_L1CrossDomainMessenger
 */
interface iOVM_L1CrossDomainMessenger is iOVM_BaseCrossDomainMessenger {}

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
// +build ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_BaseCrossDomainMessenger
 */
interface iOVM_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;

    function deposit(
        address _depositor,
        uint256 _amount,
        bool _send
    ) external;
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
    "runs": 1
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