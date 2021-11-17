// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// This should be replaced with a "real" import when Optimism release their new contract versions.
import "../../external/ovm/OVM_CrossDomainEnabled.sol";
import "../interfaces/ParentMessengerInterface.sol";
import "../interfaces/ParentMessengerConsumerInterface.sol";
import "./ParentMessengerBase.sol";

/**
 * @notice Sends cross chain messages from Ethereum L1 to Optimism L2 network.
 * @dev This contract's is ownable and should be owned by the DVM governor.
 */
contract Optimism_ParentMessenger is OVM_CrossDomainEnabled, ParentMessengerInterface, ParentMessengerBase {
    event SetDefaultGasLimit(uint32 newDefaultGasLimit);
    event MessageSentToChild(bytes data, address indexed childAddress, uint32 defaultGasLimit);
    event MessageReceivedFromChild(bytes data, address indexed childAddress);

    uint32 public defaultGasLimit = 5_000_000;

    /**
     * @notice Construct the Optimism_ParentMessenger contract.
     * @param _crossDomainMessenger The address of the Optimism cross domain messenger contract.
     * @param _childChainId The chain id of the Optimism L2 network this messenger should connect to.
     **/
    constructor(address _crossDomainMessenger, uint256 _childChainId)
        OVM_CrossDomainEnabled(_crossDomainMessenger)
        ParentMessengerBase(_childChainId)
    {}

    /**
     * @notice Changes the default gas limit that is sent along with transactions to Optimism.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newDefaultGasLimit the new L2 gas limit to be set.
     */
    function setDefaultGasLimit(uint32 newDefaultGasLimit) public onlyOwner {
        defaultGasLimit = newDefaultGasLimit;
        emit SetDefaultGasLimit(newDefaultGasLimit);
    }

    /**
     * @notice Sends a message to the child messenger via the canonical message bridge.
     * @dev The caller must be the either the OracleHub or the GovernorHub, deployed on L2. This is to send either a
     * price or initiate a governance action on L2.
     * @dev The recipient of this message is the child messenger. The messenger must implement processMessageFromParent
     * which then forwards the data to the target either the OracleSpoke or the governorSpoke depending on the caller.
     * @param data data message sent to the L2 messenger. Should be an encoded function call or packed data.
     */
    function sendMessageToChild(bytes memory data) public override onlyHubContract() {
        address target = msg.sender == oracleHub ? oracleSpoke : governorSpoke;
        bytes memory dataSentToChild =
            abi.encodeWithSignature("processMessageFromCrossChainParent(bytes,address)", data, target);
        sendCrossDomainMessage(childMessenger, defaultGasLimit, dataSentToChild);
        emit MessageSentToChild(data, target, defaultGasLimit);
    }

    /**
     * @notice Process a received message from the child messenger via the canonical message bridge.
     * @dev The caller must be the the child messenger, sent over the canonical message bridge.
     * @dev not that only the OracleHub can receive messages from the child messenger. Therefore we can always forward
     * these messages to this contract. The OracleHub must implement processMessageFromChild to handel this message.
     * @param data data message sent from the L2 messenger. Should be an encoded function call or packed data.
     */
    function processMessageFromCrossChainChild(bytes memory data)
        public
        override
        onlyFromCrossDomainAccount(childMessenger)
    {
        ParentMessengerConsumerInterface(oracleHub).processMessageFromChild(childChainId, data);
        emit MessageReceivedFromChild(data, childMessenger);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ParentMessengerBase is Ownable {
    uint256 public childChainId;

    address public childMessenger;

    address public oracleHub;
    address public governorHub;

    address public oracleSpoke;
    address public governorSpoke;

    event SetChildMessenger(address indexed childMessenger);
    event SetOracleHub(address indexed oracleHub);
    event SetGovernorHub(address indexed governorHub);
    event SetOracleSpoke(address indexed oracleSpoke);
    event SetGovernorSpoke(address indexed governorSpoke);

    modifier onlyHubContract() {
        require(msg.sender == oracleHub || msg.sender == governorHub, "Only privileged caller");
        _;
    }

    /**
     * @notice Construct the ParentMessengerBase contract.
     * @param _childChainId The chain id of the L2 network this messenger should connect to.
     **/
    constructor(uint256 _childChainId) {
        childChainId = _childChainId;
    }

    /*******************
     *  OWNER METHODS  *
     *******************/

    /**
     * @notice Changes the stored address of the child messenger, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newChildMessenger address of the new child messenger, deployed on L2.
     */
    function setChildMessenger(address newChildMessenger) public onlyOwner {
        childMessenger = newChildMessenger;
        emit SetChildMessenger(childMessenger);
    }

    /**
     * @notice Changes the stored address of the Oracle hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleHub address of the new oracle hub, deployed on L1 Ethereum.
     */
    function setOracleHub(address newOracleHub) public onlyOwner {
        oracleHub = newOracleHub;
        emit SetOracleHub(oracleHub);
    }

    /**
     * @notice Changes the stored address of the Governor hub, deployed on L1.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorHub address of the new governor hub, deployed on L1 Ethereum.
     */
    function setGovernorHub(address newGovernorHub) public onlyOwner {
        governorHub = newGovernorHub;
        emit SetGovernorHub(governorHub);
    }

    /**
     * @notice Changes the stored address of the oracle spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newOracleSpoke address of the new oracle spoke, deployed on L2.
     */
    function setOracleSpoke(address newOracleSpoke) public onlyOwner {
        oracleSpoke = newOracleSpoke;
        emit SetOracleSpoke(oracleSpoke);
    }

    /**
     * @notice Changes the stored address of the governor spoke, deployed on L2.
     * @dev The caller of this function must be the owner. This should be set to the DVM governor.
     * @param newGovernorSpoke address of the new governor spoke, deployed on L2.
     */
    function setGovernorSpoke(address newGovernorSpoke) public onlyOwner {
        governorSpoke = newGovernorSpoke;
        emit SetGovernorSpoke(governorSpoke);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ParentMessengerConsumerInterface {
    // Function called on Oracle hub to pass in data send from L2, with chain ID.
    function processMessageFromChild(uint256 chainId, bytes memory data) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ParentMessengerInterface {
    // Should send cross-chain message to Child messenger contract or revert.
    function sendMessageToChild(bytes memory data) external;

    // Should be targeted by ChildMessenger and executed upon receiving a message from child chain.
    function processMessageFromCrossChainChild(bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title iOVM_CrossDomainMessenger
 * @notice Copied directly from https://github.com/ethereum-optimism/optimism/blob/294246d65e650f497527de398f51b2f6d11f602f/packages/contracts/contracts/libraries/bridge/ICrossDomainMessenger.sol
 */
interface iOVM_CrossDomainMessenger {
    /*************
     * Variables *
     *************/

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
}

/**
 * @title OVM_CrossDomainEnabled
 * @notice Copied from: https://github.com/ethereum-optimism/optimism/blob/294246d65e650f497527de398f51b2f6d11f602f/packages/contracts/contracts/libraries/bridge/CrossDomainEnabled.sol
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {
    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(address _messenger) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(msg.sender == address(getCrossDomainMessenger()), "OVM_XCHAIN: messenger contract unauthenticated");

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger() internal virtual returns (iOVM_CrossDomainMessenger) {
        return iOVM_CrossDomainMessenger(messenger);
    }

    /**
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    ) internal {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}