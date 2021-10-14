pragma solidity 0.4.24;

import "../lib/ens/AbstractENS.sol";
import "../lib/ens/IPublicResolver.sol";
import "./IFIFSResolvingRegistrar.sol";


/**
 * A registrar that allocates subdomains and sets resolvers to the first person to claim them.
 *
 * Adapted from ENS' FIFSRegistrar:
 *   https://github.com/ethereum/ens/blob/master/contracts/FIFSRegistrar.sol
 */
contract FIFSResolvingRegistrar is IFIFSResolvingRegistrar {
    bytes32 public rootNode;
    AbstractENS internal ens;
    IPublicResolver internal defaultResolver;

    bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;

    event ClaimSubdomain(bytes32 indexed subnode, address indexed owner, address indexed resolver);

    /**
     * Constructor.
     * @param _ensAddr The address of the ENS registry.
     * @param _defaultResolver The address of the default resolver to use for subdomains.
     * @param _node The node that this registrar administers.
     */
    constructor(AbstractENS _ensAddr, IPublicResolver _defaultResolver, bytes32 _node)
        public
    {
        ens = _ensAddr;
        defaultResolver = _defaultResolver;
        rootNode = _node;
    }

    /**
     * Register a subdomain with the default resolver if it hasn't been claimed yet.
     * @param _subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     */
    function register(bytes32 _subnode, address _owner) external {
        registerWithResolver(_subnode, _owner, defaultResolver);
    }

    /**
     * Register a subdomain if it hasn't been claimed yet.
     * @param _subnode The hash of the label to register.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the resolver.
     *                  If the resolver supports the address interface, the subdomain's address will
     *                  be set to the new owner.
     */
    function registerWithResolver(bytes32 _subnode, address _owner, IPublicResolver _resolver) public {
        bytes32 node = keccak256(rootNode, _subnode);
        address currentOwner = ens.owner(node);
        require(currentOwner == address(0));

        ens.setSubnodeOwner(rootNode, _subnode, address(this));
        ens.setResolver(node, _resolver);
        if (_resolver.supportsInterface(ADDR_INTERFACE_ID)) {
            _resolver.setAddr(node, _owner);
        }

        // Give ownership to the claimer
        ens.setOwner(node, _owner);

        emit ClaimSubdomain(_subnode, _owner, address(_resolver));
    }
}

pragma solidity 0.4.24;

import "../lib/ens/IPublicResolver.sol";


interface IFIFSResolvingRegistrar {
    function register(bytes32 _subnode, address _owner) external;
    function registerWithResolver(bytes32 _subnode, address _owner, IPublicResolver _resolver) public;
}

// See https://github.com/ensdomains/ens/blob/7e377df83f/contracts/AbstractENS.sol

pragma solidity ^0.4.15;


interface AbstractENS {
    function owner(bytes32 _node) public constant returns (address);
    function resolver(bytes32 _node) public constant returns (address);
    function ttl(bytes32 _node) public constant returns (uint64);
    function setOwner(bytes32 _node, address _owner) public;
    function setSubnodeOwner(bytes32 _node, bytes32 label, address _owner) public;
    function setResolver(bytes32 _node, address _resolver) public;
    function setTTL(bytes32 _node, uint64 _ttl) public;

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed _node, address _owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed _node, address _resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed _node, uint64 _ttl);
}

pragma solidity ^0.4.0;


interface IPublicResolver {
    function supportsInterface(bytes4 interfaceID) constant returns (bool);
    function addr(bytes32 node) constant returns (address ret);
    function setAddr(bytes32 node, address addr);
    function hash(bytes32 node) constant returns (bytes32 ret);
    function setHash(bytes32 node, bytes32 hash);
}