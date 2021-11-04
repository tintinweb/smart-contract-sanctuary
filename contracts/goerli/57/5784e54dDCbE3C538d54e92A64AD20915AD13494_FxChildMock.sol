// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IStateReceiver represents interface to receive state
interface IStateReceiver {
    function onStateReceive(uint256 stateId, bytes calldata data) external;
}

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @title FxChild child contract for state receiver
 */
contract FxChildMock is IStateReceiver {
    address public fxRoot;
    address public systemCaller;

    event NewFxMessage(address rootMessageSender, address receiver, bytes data);

    constructor(address _systemCaller) {
        systemCaller = _systemCaller;
    }

    function setFxRoot(address _fxRoot) public {
        require(fxRoot == address(0x0));
        fxRoot = _fxRoot;
    }

    function onStateReceive(uint256 stateId, bytes calldata _data) external override {
        require(msg.sender == systemCaller, "Invalid sender: must be system super user");
        (address rootMessageSender, address receiver, bytes memory data) = abi.decode(_data, (address, address, bytes));
        emit NewFxMessage(rootMessageSender, receiver, data);
        IFxMessageProcessor(receiver).processMessageFromRoot(stateId, rootMessageSender, data);
    }
}