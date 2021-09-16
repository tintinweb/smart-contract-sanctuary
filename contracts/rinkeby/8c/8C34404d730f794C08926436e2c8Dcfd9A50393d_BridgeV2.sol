// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BridgeV2 is Initializable, OwnableUpgradeable {
    /// ** PUBLIC states **

    address public oldMPC;
    address public newMPC;
    uint256 public newMPCEffectiveTime;

    mapping(address => bool) public isTransmitter;

    mapping(address => uint256) public nonce; // bridge => nonce

    /// ** EVENTS **

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed effectiveTime,
        uint256 chainId
    );
    event SetTransmitterStatus(address indexed transmitter, bool status);

    event OracleRequest(
        string requestType,
        address bridge,
        bytes32 requestId,
        bytes callData,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    );
    event ReceiveRequest(bytes32 requestId, address receiveSide, bytes32 tx);

    /// ** MODIFIERs **

    modifier onlyMPC() {
        require(msg.sender == mpc(), "BridgeV2: forbidden");
        _;
    }

    modifier onlyTransmitter() {
        require(isTransmitter[msg.sender], "BridgeV2: not a transmitter");
        _;
    }

    /// ** INITIALIZER **

    function initialize(address _mpc) public virtual initializer {
        __Ownable_init();

        newMPC = _mpc;
        newMPCEffectiveTime = block.timestamp;
    }

    /// ** VIEW functions **

    /**
     * @notice Returns MPC
     */
    function mpc() public view returns (address) {
        if (block.timestamp >= newMPCEffectiveTime) {
            return newMPC;
        }
        return oldMPC;
    }

    /**
     * @notice Returns chain ID of block
     */
    function currentChainId() public view returns (uint256) {
        return block.chainid;
    }

    /// ** MPC functions **

    /**
     * @notice Changes MPC
     */
    function changeMPC(address _newMPC) external onlyMPC returns (bool) {
        require(_newMPC != address(0), "BridgeV2: address(0x0)");
        oldMPC = mpc();
        newMPC = _newMPC;
        newMPCEffectiveTime = block.timestamp + 2 days;
        emit LogChangeMPC(
            oldMPC,
            newMPC,
            newMPCEffectiveTime,
            currentChainId()
        );
        return true;
    }

    /**
     * @notice Receives requests
     */
    function receiveRequestV2(
        bytes32 _requestId,
        bytes memory _callData,
        address _receiveSide,
        address _bridgeFrom
    ) external onlyMPC {
        bytes32 recreatedRequestId = keccak256(
            abi.encodePacked(
                _bridgeFrom,
                nonce[_bridgeFrom],
                _callData,
                _receiveSide,
                address(this),
                currentChainId()
            )
        );
        // require(_requestId == recreatedRequestId, 'CONSISTENCY FAILED');
        require(isTransmitter[_receiveSide], "BridgeV2: untrusted transmitter");

        (bool success, bytes memory data) = _receiveSide.call(_callData);
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BridgeV2: call failed"
        );

        nonce[_bridgeFrom] += 1;
        emit ReceiveRequest(_requestId, _receiveSide, recreatedRequestId);
    }

    /// ** TRANSMITTER functions **

    /**
     * @notice transmits request
     */
    function transmitRequestV2(
        bytes memory _callData,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId
    ) public onlyTransmitter {
        bytes32 requestId = _prepareRequestId(
            _callData,
            _receiveSide,
            _oppositeBridge,
            _chainId
        );

        emit OracleRequest(
            "setRequest",
            address(this),
            requestId,
            _callData,
            _receiveSide,
            _oppositeBridge,
            _chainId
        );
    }

    /// ** OWNER functions **

    /**
     * @notice Sets transmitter status
     */
    function setTransmitterStatus(address _transmitter, bool _status)
        external
        onlyOwner
    {
        isTransmitter[_transmitter] = _status;
        emit SetTransmitterStatus(_transmitter, _status);
    }

    /// ** INTERNAL functions **

    /**
     * @dev Prepares request Id
     * @dev Internal function used in transmitRequestV2
     */
    function _prepareRequestId(
        bytes memory _callData,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId
    ) internal returns (bytes32) {
        bytes32 requestId = keccak256(
            abi.encodePacked(
                address(this),
                nonce[_oppositeBridge],
                _callData,
                _receiveSide,
                _oppositeBridge,
                _chainId
            )
        );

        nonce[_oppositeBridge] += 1;
        return (requestId);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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