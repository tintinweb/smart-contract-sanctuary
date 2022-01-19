// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract FxBaseChildTunnel {

    address public admin;
    address public fxChild;
    address public fxRootTunnel;

    mapping(address => bool) public auth;

    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);
    event CallMade(address target, bool success, bytes data);

    /*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address fxChild_,address fxRootTunnel_) external {
        require(msg.sender == admin);

        fxChild        = fxChild_;///from docs
        fxRootTunnel   = fxRootTunnel_;///mainnet FxbaseRoot
    }

    function setAuth(address[] calldata adds_, bool status) external {
        require(msg.sender == admin, "not admin");
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }



    function sendMessage(bytes calldata message_) virtual external {
        require(auth[msg.sender], "not authorized to use portal");
        emit MessageSent(message_);
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        require(msg.sender         == fxChild,        "FxBaseChildTunnel: INVALID_SENDER");
        require(rootMessageSender == fxRootTunnel,  "FxBaseChildTunnel: INVALID_PORTAL" );

        _processMessageFromRoot(data);
    }

    function _processMessageFromRoot(bytes memory data) internal {
        (address target, bytes[] memory calls ) = abi.decode(data, (address, bytes[]));
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = target.call(calls[i]);
            emit CallMade(target, success, calls[i]);
        }
    }

    function replayCall(address target, bytes memory data, bool reqSuccess) external {
        require(msg.sender == admin, "not allowed");
        (bool succ, ) = target.call(data);
        if (reqSuccess) require(succ, "call failed");
    }

}