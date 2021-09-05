// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IENSResolver.sol";
import "./IPass3Registrar.sol";
import "./IENSReverseRegistrar.sol";
import "./IENS.sol";

contract Pass3Registrar is IPass3Registrar, Ownable {
    // ============ Constants ============

    // A map of expiry times
    mapping(bytes32=>uint) avaliableTime;
    /**
     * namehash('addr.reverse')
     */
    bytes32 public constant ADDR_REVERSE_NODE =
        0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    // ============ Immutable Storage ============

    /**
     * The name of the ENS root, e.g. "pass3.me".
     */
    string public rootName;

    /**
     * The node of the root name (e.g. namehash(pass3.me))
     */
    bytes32 public immutable rootNode;

    /**
     * The address of the public ENS registry.
     * ENS registry is at 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e.
     */
    IENS public immutable ensRegistry;

    /**
     * The address of the Pass3Token that gates access to this namespace.
     */
    address public immutable passToken;

    /**
     * The address of the MirrorENSResolver.
     */
    IENSResolver public immutable ensResolver;

    // ============ Mutable Storage ============

    /**
     * Set by anyone to the correct address after configuration,
     * to prevent a lookup on each registration.
     */
    IENSReverseRegistrar public reverseRegistrar;

    address public renameRole;


    // ============ Events ============

    event RootNodeOwnerChange(bytes32 indexed node, address indexed owner);
    event RegisteredENS(address indexed _owner, string _ens);
    event RenameRoleChange(address indexed user);

    // ============ Modifiers ============

    /**
     * @dev Modifier to check whether the `msg.sender` is the MirrorWriteToken.
     * If it is, it will run the function. Otherwise, it will revert.
     */
    modifier onlyPassToken() {
        require(
            msg.sender == passToken,
            "Pass3Registrar: caller is not the Pass3 Token"
        );
        _;
    }

    modifier onlyRenameRole() {
        require(
            msg.sender == renameRole,
            "Pass3Registrar: missing rename role"
        );
        _;
    }

 

    // ============ Constructor ============

    /**
     * @notice Constructor that sets the ENS root name and root node to manage.
     * @param rootName_ The root name (e.g. pass3.me).
     * @param rootNode_ The node of the root name (e.g. namehash(pass3.me)).
     * @param ensRegistry_ The address of the ENS registry
     * @param ensResolver_ The address of the ENS resolver
     * @param passToken_ The address of the Mirror Write Token
     */
    constructor(
        string memory rootName_,
        bytes32 rootNode_,
        address ensRegistry_,
        address ensResolver_,
        address passToken_
    ) {
        rootName = rootName_;
        rootNode = rootNode_;

        passToken = passToken_;

        ensRegistry = IENS(ensRegistry_);
        ensResolver = IENSResolver(ensResolver_);
    }

    // =========== Rename Configuration ============

    function setRenameRole(address user) public onlyOwner{
        renameRole = user;
        emit RenameRoleChange(user);
    }

    // ============ Registration ============

    /**
     * @notice Assigns an ENS subdomain of the root node to a target address.
     * Registers both the forward and reverse ENS. Can only be called by writeToken.
     * @param label_ The subdomain label.
     * @param owner_ The owner of the subdomain.
     */
    function register(string calldata label_, address owner_)
        external
        override
        onlyPassToken
    {
        
        bytes32 labelNode = keccak256(abi.encodePacked(label_));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));
        string memory name = string(abi.encodePacked(label_, ".", rootName));
        bytes32 reverseNode = reverseRegistrar.node(owner_);
        require(
            ensRegistry.owner(node) == address(0),
            "Pass3Registrar: label is already owned"
        );

        require(avaliableTime[node] < block.timestamp, 
            "Pass3Registrar: label is not avaliable now");
        
        require(
            bytes(ensResolver.name(reverseNode)).length == 0,            
            "Pass3Registrar: pass name already has picked"
        );

        // Forward ENS
        ensRegistry.setSubnodeRecord(
            rootNode,
            labelNode,
            owner_,
            address(ensResolver),
            0
        );

        ensResolver.setAddr(node, owner_);

        // Reverse ENS
        ensResolver.setName(reverseNode, name);

        emit RegisteredENS(owner_, name);
    }



    function rename(string calldata oldLabel_, string calldata newLabel_, address owner_, uint freeze_dur) onlyRenameRole public {
        bytes32 reverseNode = reverseRegistrar.node(owner_);

        require(
            bytes(ensResolver.name(reverseNode)).length > 0,
            "Pass3Registrar: user has not registered"
        );
        
        bytes32 oldLabelNode = keccak256(abi.encodePacked(oldLabel_));
        bytes32 oldNode = keccak256(abi.encodePacked(rootNode, oldLabelNode));

        require(
            ensRegistry.owner(oldNode) == owner_,
            "Pass3Registrar: old name is not owned by owner"
        );
        
        // Update New Forward ENS
        bytes32 newLabelNode = keccak256(abi.encodePacked(newLabel_));
        bytes32 newNode = keccak256(abi.encodePacked(rootNode, newLabelNode));

        require(
            ensRegistry.owner(newNode) == address(0),
            "Pass3Registrar: new name has been registered"
        );

        // Freeze old name
        avaliableTime[oldNode] = block.timestamp + freeze_dur;
        
        // Clear Forward ENS
        ensRegistry.setSubnodeRecord(
            rootNode,
            oldLabelNode,
            address(0),
            address(ensResolver),
            0
        );

        // Assert name has been released in ens registry
        assert(ensRegistry.owner(oldNode) == address(0));

        // Update Forward ENS
        ensRegistry.setSubnodeRecord(
            rootNode,
            newLabelNode,
            owner_,
            address(ensResolver),
            0
        );
        ensResolver.setAddr(newNode, owner_);

        assert(ensRegistry.owner(newNode) == owner_);
        
        // Update Reverse ENS
        ensResolver.setName(reverseNode, newLabel_);

    }

    // ============ ENS Management ============

    /**
     * @notice This function must be called when the ENS Manager contract is replaced
     * and the address of the new Manager should be provided.
     * @param _newOwner The address of the new ENS manager that will manage the root node.
     */
    function changeRootNodeOwner(address _newOwner)
        external
        override
        onlyOwner
    {
        ensRegistry.setOwner(rootNode, _newOwner);
        emit RootNodeOwnerChange(rootNode, _newOwner);
    }

    /**
     * @notice Updates to the reverse registrar.
     */
    function updateENSReverseRegistrar() external override onlyOwner {
        reverseRegistrar = IENSReverseRegistrar(
            ensRegistry.owner(ADDR_REVERSE_NODE)
        );
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
pragma solidity >=0.8.0;

interface IENSResolver {
    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

    function addr(bytes32 _node) external view returns (address);

    function setAddr(bytes32 _node, address _addr) external;

    function name(bytes32 _node) external view returns (string memory);

    function setName(bytes32 _node, string calldata _name) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPass3Registrar {
    function changeRootNodeOwner(address newOwner_) external;

    function register(string calldata label_, address owner_) external;

    function updateENSReverseRegistrar() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IENSReverseRegistrar {
    function claim(address _owner) external returns (bytes32);

    function claimWithResolver(address _owner, address _resolver)
        external
        returns (bytes32);

    function setName(string calldata _name) external returns (bytes32);

    function node(address _addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IENS {

    // Logged when the owner_ of a node assigns a new owner_ to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner_);

    // Logged when the owner_ of a node transfers owner_ship to a new account.
    event Transfer(bytes32 indexed node, address owner_);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver_);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl_);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner_, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner_, address resolver_, uint64 ttl_) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner_, address resolver_, uint64 ttl_) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner_) external returns(bytes32);
    function setResolver(bytes32 node, address resolver_) external;
    function setOwner(bytes32 node, address owner_) external;
    function setTTL(bytes32 node, uint64 ttl_) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner_, address operator) external view returns (bool);
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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