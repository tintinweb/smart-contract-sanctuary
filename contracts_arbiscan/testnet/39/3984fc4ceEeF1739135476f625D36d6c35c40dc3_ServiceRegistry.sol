pragma solidity ^0.5.11;

import "./zeppelin/Pausable.sol";

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(
        bytes32 _id,
        address _contractAddress,
        bytes20 _gitCommitHash
    ) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContract(bytes32 _id) public view returns (address);
}

pragma solidity ^0.5.11;

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

pragma solidity ^0.5.11;

import "./IManager.sol";
import "./IController.sol";

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        _onlyControllerOwner();
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        _whenSystemNotPaused();
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        _whenSystemPaused();
        _;
    }

    constructor(address _controller) public {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }

    function _onlyController() internal view {
        require(msg.sender == address(controller), "caller must be Controller");
    }

    function _onlyControllerOwner() internal view {
        require(msg.sender == controller.owner(), "caller must be Controller owner");
    }

    function _whenSystemNotPaused() internal view {
        require(!controller.paused(), "system is paused");
    }

    function _whenSystemPaused() internal view {
        require(controller.paused(), "system is not paused");
    }
}

pragma solidity ^0.5.11;

import "./Manager.sol";

/**
 * @title ManagerProxyTarget
 * @notice The base contract that target contracts used by a proxy contract should inherit from
 * @dev Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 potentially break the delegate proxy upgradeability mechanism
 */
contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller's registry
    bytes32 public targetContractId;
}

pragma solidity ^0.5.11;

import "./ManagerProxyTarget.sol";

/**
 * @title ServiceRegistry
 * @notice Maintains a registry of service metadata associated with service provider addresses (transcoders/orchestrators)
 */
contract ServiceRegistry is ManagerProxyTarget {
    // Store service metadata
    struct Record {
        string serviceURI; // Service URI endpoint that can be used to send off-chain requests
    }

    // Track records for addresses
    mapping(address => Record) private records;

    // Event fired when a caller updates its service URI endpoint
    event ServiceURIUpdate(address indexed addr, string serviceURI);

    /**
     * @notice ServiceRegistry constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @param _controller Address of a Controller that this contract will be registered with
     */
    constructor(address _controller) public Manager(_controller) {}

    /**
     * @notice Stores service URI endpoint for the caller that can be used to send requests to the caller off-chain
     * @param _serviceURI Service URI endpoint for the caller
     */
    function setServiceURI(string calldata _serviceURI) external {
        records[msg.sender].serviceURI = _serviceURI;

        emit ServiceURIUpdate(msg.sender, _serviceURI);
    }

    /**
     * @notice Returns service URI endpoint stored for a given address
     * @param _addr Address for which a service URI endpoint is desired
     */
    function getServiceURI(address _addr) public view returns (string memory) {
        return records[_addr].serviceURI;
    }
}

pragma solidity ^0.5.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity ^0.5.11;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}