// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./messenger/IMessenger.sol";

/**
 * @title MessengerRegistry
 * @dev MessengerRegistry is a contract to register openly distributed Messengers
 */
contract MessengerRegistry {
    struct Messenger {
        address ownerAddress;
        address messengerAddress;
        string specificationUrl;
        uint256 precision;
        uint256 requestsCounter;
        uint256 fulfillsCounter;
        uint256 id;
    }

    /// @dev array to store the messengers
    Messenger[] public messengers;
    /// @dev (messengerAddress=>bool) to check if the Messenger was
    mapping(address => bool) public registeredMessengers;
    /// @dev (userAddress=>messengerAddress[]) to register the messengers of an owner
    mapping(address => uint256[]) public ownerMessengers;
    /// @dev (userAddress=>messengerAddress[]) to register the owner of a Messenger
    address public slaRegistry;

    event MessengerRegistered(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    event MessengerModified(
        address indexed ownerAddress,
        address indexed messengerAddress,
        string specificationUrl,
        uint256 precision,
        uint256 id
    );

    /**
     * @dev sets the SLARegistry contract address and can only be called
     * once
     */
    function setSLARegistry() external {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );

        slaRegistry = msg.sender;
    }

    /**
     * @dev function to register a new Messenger
     */
    function registerMessenger(
        address _callerAddress,
        address _messengerAddress,
        string calldata _specificationUrl
    ) external {
        require(
            msg.sender == slaRegistry,
            "Should only be called using the SLARegistry contract"
        );
        require(
            !registeredMessengers[_messengerAddress],
            "messenger already registered"
        );

        IMessenger messenger = IMessenger(_messengerAddress);
        address messengerOwner = messenger.owner();
        require(
            messengerOwner == _callerAddress,
            "Should only be called by the messenger owner"
        );
        uint256 precision = messenger.messengerPrecision();
        uint256 requestsCounter = messenger.requestsCounter();
        uint256 fulfillsCounter = messenger.fulfillsCounter();
        registeredMessengers[_messengerAddress] = true;
        uint256 id = messengers.length - 1;
        ownerMessengers[messengerOwner].push(id);

        messengers.push(
            Messenger({
                ownerAddress: messengerOwner,
                messengerAddress: _messengerAddress,
                specificationUrl: _specificationUrl,
                precision: precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: id
            })
        );

        emit MessengerRegistered(
            messengerOwner,
            _messengerAddress,
            _specificationUrl,
            precision,
            id
        );
    }

    /**
     * @dev function to modifyMessenger a Messenger
     */
    function modifyMessenger(
        string calldata _specificationUrl,
        uint256 _messengerId
    ) external {
        Messenger storage storedMessenger = messengers[_messengerId];
        IMessenger messenger = IMessenger(storedMessenger.messengerAddress);
        require(
            msg.sender == messenger.owner(),
            "Can only be modified by the owner"
        );
        storedMessenger.specificationUrl = _specificationUrl;
        storedMessenger.ownerAddress = msg.sender;
        emit MessengerModified(
            storedMessenger.ownerAddress,
            storedMessenger.messengerAddress,
            storedMessenger.specificationUrl,
            storedMessenger.precision,
            storedMessenger.id
        );
    }

    function getMessengers() external view returns (Messenger[] memory) {
        Messenger[] memory returnMessengers =
            new Messenger[](messengers.length);
        for (uint256 index = 0; index < messengers.length; index++) {
            IMessenger messenger =
                IMessenger(messengers[index].messengerAddress);
            uint256 requestsCounter = messenger.requestsCounter();
            uint256 fulfillsCounter = messenger.fulfillsCounter();
            returnMessengers[index] = Messenger({
                ownerAddress: messengers[index].ownerAddress,
                messengerAddress: messengers[index].messengerAddress,
                specificationUrl: messengers[index].specificationUrl,
                precision: messengers[index].precision,
                requestsCounter: requestsCounter,
                fulfillsCounter: fulfillsCounter,
                id: messengers[index].id
            });
        }
        return returnMessengers;
    }

    function getMessengersLength() external view returns (uint256) {
        return messengers.length;
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IMessenger
 * @dev Interface to create new Messenger contract to add lo Messenger lists
 */

abstract contract IMessenger is Ownable {
    struct SLIRequest {
        address slaAddress;
        uint256 periodId;
    }

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param slaAddress 1. SLA address to store the SLI
     * @param periodId 2. id of the Chainlink request
     * @param requestId 3. id of the Chainlink request
     * @param chainlinkResponse 4. response from Chainlink
     */
    event SLIReceived(
        address indexed slaAddress,
        uint256 periodId,
        bytes32 indexed requestId,
        bytes32 chainlinkResponse
    );

    /**
     * @dev sets the SLARegistry contract address and can only be called once
     */
    function setSLARegistry() external virtual;

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. id of the period to be queried
     * @param _slaAddress 2. address of the receiver SLA
     * @param _slaAddress 2. if approval by owner or msg.sender
     */

    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _ownerApproval,
        address _callerAddress
    ) external virtual;

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param _chainlinkResponseUint256 response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 _chainlinkResponseUint256)
        external
        virtual;

    /**
     * @dev gets the messenger precision
     */
    function messengerPrecision() external view virtual returns (uint256);

    /**
     * @dev gets the slaRegistryAddress
     */
    function slaRegistryAddress() external view virtual returns (address);

    /**
     * @dev gets the chainlink oracle contract address
     */
    function oracle() external view virtual returns (address);

    /**
     * @dev gets the chainlink job id
     */
    function jobId() external view virtual returns (bytes32);

    /**
     * @dev gets the fee amount of LINK token
     */
    function fee() external view virtual returns (uint256);

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100
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