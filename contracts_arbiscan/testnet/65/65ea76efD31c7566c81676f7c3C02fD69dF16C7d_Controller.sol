pragma solidity ^0.5.11;

import "./IController.sol";
import "./IManager.sol";

import "./zeppelin/Pausable.sol";

contract Controller is Pausable, IController {
    // Track information about a registered contract
    struct ContractInfo {
        address contractAddress; // Address of contract
        bytes20 gitCommitHash; // SHA1 hash of head Git commit during registration of this contract
    }

    // Track contract ids and contract info
    mapping(bytes32 => ContractInfo) private registry;

    constructor() public {
        // Start system as paused
        paused = true;
    }

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function setContractInfo(
        bytes32 _id,
        address _contractAddress,
        bytes20 _gitCommitHash
    ) external onlyOwner {
        registry[_id].contractAddress = _contractAddress;
        registry[_id].gitCommitHash = _gitCommitHash;

        emit SetContractInfo(_id, _contractAddress, _gitCommitHash);
    }

    /**
     * @notice Update contract's controller
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _controller Controller address
     */
    function updateController(bytes32 _id, address _controller) external onlyOwner {
        return IManager(registry[_id].contractAddress).setController(_controller);
    }

    /**
     * @notice Return contract info for a given contract id
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function getContractInfo(bytes32 _id) public view returns (address, bytes20) {
        return (registry[_id].contractAddress, registry[_id].gitCommitHash);
    }

    /**
     * @notice Get contract address for an id
     * @param _id Contract id
     */
    function getContract(bytes32 _id) public view returns (address) {
        return registry[_id].contractAddress;
    }
}

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