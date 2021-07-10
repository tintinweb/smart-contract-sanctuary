// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.3;

import {FxBaseChildTunnel} from "fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import {Layer2RebaseGateway} from "../../base-bridge-gateways/Layer2RebaseGateway.sol";

import {IXCAmpleController} from "../../_interfaces/IXCAmpleController.sol";
import {IXCAmpleControllerGateway} from "../../_interfaces/IXCAmpleControllerGateway.sol";
import {IXCAmple} from "../../_interfaces/IXCAmple.sol";

/**
 * @title MaticXCAmpleRebaseGateway: Matic-XCAmple Rebase Gateway Contract
 * @dev This contract is deployed on the satellite chain (Matic).
 *
 *      It's a pass-through contract between the Matic's bridge contracts and
 *      the xc-ample contracts.
 *
 */
contract MaticXCAmpleRebaseGateway is Layer2RebaseGateway, FxBaseChildTunnel {
    address public immutable xcAmple;
    address public immutable xcController;

    /**
     * @dev Forwards the most recent rebase information from the matic bridge to the xc-ample controller.
     *      "globalAmpleforthEpoch": Ampleforth monetary policy epoch from ethereum.
     *      "globalAMPLSupply": AMPL ERC-20 total supply from ethereum.
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        uint256 globalAmpleforthEpoch;
        uint256 globalAMPLSupply;
        (globalAmpleforthEpoch, globalAMPLSupply) = abi.decode(data, (uint256, uint256));

        uint256 recordedGlobalAmpleforthEpoch = IXCAmpleController(xcController)
            .globalAmpleforthEpoch();

        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();

        emit XCRebaseReportIn(
            globalAmpleforthEpoch,
            globalAMPLSupply,
            recordedGlobalAmpleforthEpoch,
            recordedGlobalAMPLSupply
        );

        IXCAmpleControllerGateway(xcController).reportRebase(
            globalAmpleforthEpoch,
            globalAMPLSupply
        );
    }

    constructor(
        address _fxChild,
        address xcAmple_,
        address xcController_
    ) FxBaseChildTunnel(_fxChild) {
        xcAmple = xcAmple_;
        xcController = xcController_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

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
    function setFxRootTunnel(address _fxRootTunnel) public {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
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

// SPDX-License-Identifier: GPL-3.0-or-later

import {IRebaseGatewayEvents} from "../_interfaces/bridge-gateways/IRebaseGatewayEvents.sol";

contract Layer2RebaseGateway is IRebaseGatewayEvents {
    // overridden on the base chain gateway (ethereum)
    function reportRebase() external virtual {
        require(false, "Gateway function NOT_IMPLEMENTED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IXCAmpleController {
    function rebase() external;

    function lastRebaseTimestampSec() external view returns (uint256);

    function globalAmpleforthEpoch() external view returns (uint256);

    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IXCAmpleControllerGateway {
    function nextGlobalAmpleforthEpoch() external view returns (uint256);

    function nextGlobalAMPLSupply() external view returns (uint256);

    function mint(address recipient, uint256 xcAmplAmount) external;

    function burn(address depositor, uint256 xcAmplAmount) external;

    function reportRebase(uint256 nextGlobalAmpleforthEpoch_, uint256 nextGlobalAMPLSupply_)
        external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "uFragments/contracts/interfaces/IAMPL.sol";

interface IXCAmple is IAMPL {
    function globalAMPLSupply() external view returns (uint256);

    function mint(address who, uint256 xcAmpleAmount) external;

    function burnFrom(address who, uint256 xcAmpleAmount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IRebaseGatewayEvents {
    // Logged on the base chain gateway (ethereum) when rebase report is propagated out
    event XCRebaseReportOut(
        // epoch from the Ampleforth Monetary Policy on the base chain
        uint256 globalAmpleforthEpoch,
        // totalSupply of AMPL ERC-20 contract on the base chain
        uint256 globalAMPLSupply
    );

    // Logged on the satellite chain gateway (tron, acala, near) when bridge reports most recent rebase
    event XCRebaseReportIn(
        // new value coming in from the base chain
        uint256 globalAmpleforthEpoch,
        // new value coming in from the base chain
        uint256 globalAMPLSupply,
        // existing value on the satellite chain
        uint256 recordedGlobalAmpleforthEpoch,
        // existing value on the satellite chain
        uint256 recordedGlobalAMPLSupply
    );
}

// pragma solidity ^0.4.24;

// Public interface definition for the AMPL - ERC20 token on Ethereum (the base-chain)
interface IAMPL {
    // ERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner_, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // EIP-2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // Elastic token interface
    function scaledBalanceOf(address who) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function transferAll(address to) external returns (bool);

    function transferAllFrom(address from, address to) external returns (bool);
}