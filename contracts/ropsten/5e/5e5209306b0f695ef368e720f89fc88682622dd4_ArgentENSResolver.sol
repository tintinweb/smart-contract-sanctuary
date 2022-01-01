/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

pragma solidity ^0.4.24;

/**
 * ENS Resolver interface.
 */
contract ENSResolver {
    function addr(bytes32 _node) public view returns (address);
    function setAddr(bytes32 _node, address _addr) public;
    function name(bytes32 _node) public view returns (string);
    function setName(bytes32 _node, string _name) public;
}

/**
 * @title Owned
 * @dev Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @dev Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

/**
 * @title Managed
 * @dev Basic contract that defines a set of managers. Only the owner can add/remove managers.
 * @author Julien Niset - <[email protected]>
 */
contract Managed is Owned {

    // The managers
    mapping (address => bool) public managers;

    /**
     * @dev Throws if the sender is not a manager.
     */
    modifier onlyManager {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

    /**
    * @dev Adds a manager. 
    * @param _manager The address of the manager.
    */
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "M: Address must not be null");
        if(managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }        
    }

    /**
    * @dev Revokes a manager.
    * @param _manager The address of the manager.
    */
    function revokeManager(address _manager) external onlyOwner {
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

/**
 * @title ArgentENSResolver
 * @dev Basic implementation of a Resolver.
 * The contract defines a manager role who is the only role that can add a new name
 * to the list of resolved names. 
 * @author Julien Niset - <[email protected]>
 */
contract ArgentENSResolver is Owned, Managed, ENSResolver {

    bytes4 constant SUPPORT_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;

    // mapping between namehash and resolved records
    mapping (bytes32 => Record) records;

    struct Record {
        address addr;
        string name;
    }

    // *************** Events *************************** //

    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

    // *************** Public Functions ********************* //

    /**
     * @dev Lets the manager set the address associated with an ENS node.
     * @param _node The node to update.
     * @param _addr The address to set.
     */
    function setAddr(bytes32 _node, address _addr) public onlyManager {
        records[_node].addr = _addr;
        emit AddrChanged(_node, _addr);
    }

    /**
     * @dev Lets the manager set the name associated with an ENS node.
     * @param _node The node to update.
     * @param _name The name to set.
     */
    function setName(bytes32 _node, string _name) public onlyManager {
        records[_node].name = _name;
        emit NameChanged(_node, _name);
    }

    /**
     * @dev Gets the address associated to an ENS node.
     * @param _node The target node.
     * @return the address of the target node.
     */
    function addr(bytes32 _node) public view returns (address) {
        return records[_node].addr;
    }

    /**
     * @dev Gets the name associated to an ENS node.
     * @param _node The target ENS node.
     * @return the name of the target ENS node.
     */
    function name(bytes32 _node) public view returns (string) {
        return records[_node].name;
    }

    /**
     * @dev Returns true if the resolver implements the interface specified by the provided hash.
     * @param _interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 _interfaceID) public view returns (bool) {
        return _interfaceID == SUPPORT_INTERFACE_ID || _interfaceID == ADDR_INTERFACE_ID || _interfaceID == NAME_INTERFACE_ID;
    }
}