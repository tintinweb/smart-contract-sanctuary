pragma solidity ^0.4.20;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
}


/**
 * A registrar that allocates subdomains to the first admin to claim them
 */
contract SvEnsRegistrar {
    ENS public ens;
    bytes32 public rootNode;
    mapping (bytes32 => bool) knownNodes;
    mapping (address => bool) admins;
    address public owner;


    modifier req(bool c) {
        require(c);
        _;
    }


    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param node The node that this registrar administers.
     */
    function SvEnsRegistrar(ENS ensAddr, bytes32 node) public {
        ens = ensAddr;
        rootNode = node;
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    function addAdmin(address newAdmin) req(admins[msg.sender]) external {
        admins[newAdmin] = true;
    }

    function remAdmin(address oldAdmin) req(admins[msg.sender]) external {
        require(oldAdmin != msg.sender && oldAdmin != owner);
        admins[oldAdmin] = false;
    }

    function chOwner(address newOwner, bool remPrevOwnerAsAdmin) req(msg.sender == owner) external {
        if (remPrevOwnerAsAdmin) {
            admins[owner] = false;
        }
        owner = newOwner;
        admins[newOwner] = true;
    }

    /**
     * Register a name that&#39;s not currently registered
     * @param subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     */
    function register(bytes32 subnode, address _owner) req(admins[msg.sender]) external {
        _setSubnodeOwner(subnode, _owner);
    }

    /**
     * Register a name that&#39;s not currently registered
     * @param subnodeStr The label to register.
     * @param _owner The address of the new owner.
     */
    function registerName(string subnodeStr, address _owner) req(admins[msg.sender]) external {
        // labelhash
        bytes32 subnode = keccak256(subnodeStr);
        _setSubnodeOwner(subnode, _owner);
    }

    /**
     * INTERNAL - Register a name that&#39;s not currently registered
     * @param subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     */
    function _setSubnodeOwner(bytes32 subnode, address _owner) internal {
        require(!knownNodes[subnode]);
        knownNodes[subnode] = true;
        ens.setSubnodeOwner(rootNode, subnode, _owner);
    }
}