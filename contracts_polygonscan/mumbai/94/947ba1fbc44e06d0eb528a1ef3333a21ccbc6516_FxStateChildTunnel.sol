// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FxBaseChildTunnel } from './tunnel/FxBaseChildTunnel.sol';
import { IERC20 } from "../../interfaces/IERC20.sol";

/** 
 * @title FxStateChildTunnel
 */
contract FxStateChildTunnel is FxBaseChildTunnel, Initializable {
    // event for token maping
    event TokenMapped(address indexed rootToken, address indexed childToken);
    // root to child token
    mapping(address => address) public rootToChildToken;
    // child to root token
    mapping(address => address) public childToRootToken;


    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    function initialize(address _fxChild) public initializer {
        _initialize(_fxChild);
    }

    function _processMessageFromRoot(uint256 /*stateId*/, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {

        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData);
        } else if (syncType == MAP_TOKEN) {
            _mapToken(syncData);
        } else {
            revert("FxERC20ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function withdraw(address childToken, uint256 amount) public {
        IERC20 childTokenContract = IERC20(childToken);
        // child token contract will have root token
        address rootToken = childToRootToken[childToken];

        // validate root and child token mapping
        require(
            childToken != address(0x0) &&
            rootToken != address(0x0) && 
            childToken == rootToChildToken[rootToken], 
            "ChildTunnel: NO_MAPPED_TOKEN"
        );

        // withdraw tokens
        childTokenContract.burnFrom(msg.sender, amount);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(rootToken, childToken, msg.sender, amount));
    }

    function _mapToken(bytes memory syncData) internal returns (address) {
        (address rootToken, address childToken) = abi.decode(syncData, (address, address));

        // check if it's already mapped
        require(childToken != rootToChildToken[rootToken], "ChildTunnel: ALREADY_MAPPED");

        require(childToken !=address(0), "Zero Address not allowed");

        // map the token
        rootToChildToken[rootToken] = childToken;
        childToRootToken[childToken] = rootToken;

        emit TokenMapped(rootToken, childToken);

        // return new child token
        return childToken;
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address rootToken, address depositor, address to, uint256 amount, bytes memory depositData) = abi.decode(syncData, (address, address, address, uint256, bytes));
        address childToken = rootToChildToken[rootToken];

        // deposit tokens
        IERC20 childTokenContract = IERC20(childToken);
        childTokenContract.mint(to, amount);

        // call `onTokenTranfer` on `to` with limit and ignore error
        if (_isContract(to)) {
            uint256 txGas = 2000000;
            bool success = false;
            bytes memory data = abi.encodeWithSignature("onTokenTransfer(address,address,address,address,uint256,bytes)", rootToken, childToken, depositor, to, amount, depositData);
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                success := call(txGas, to, 0, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }

    // check if address is contract
    function _isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

    function _initialize(address _fxChild) internal {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @notice function to mint rhoTokens - callable only by owner
     * @param account account for sending new minted tokens to
     * @param amount amount of tokens to be minted
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by owner
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by spender
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burnFrom(address account, uint256 amount) external;
}