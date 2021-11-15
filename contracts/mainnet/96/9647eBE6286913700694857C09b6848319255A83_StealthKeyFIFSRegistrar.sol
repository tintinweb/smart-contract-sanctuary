pragma solidity ^0.7.6;

import "@ensdomains/ens/contracts/ENS.sol";
import "./profiles/StealthKeyResolver.sol";
import "./profiles/AddrResolver.sol";

/**
 * A registrar that allocates StealthKey ready subdomains to the first person to claim them.
 * Based on the FIFSRegistrar contract here:
 * https://github.com/ensdomains/ens/blob/master/contracts/FIFSRegistrar.sol
 */
contract StealthKeyFIFSRegistrar {
    ENS public ens;
    bytes32 public rootNode;

    /**
     * Constructor.
     * @param _ens The address of the ENS registry.
     * @param _rootNode The node that this registrar administers.
     */
    constructor(ENS _ens, bytes32 _rootNode) {
        ens = _ens;
        rootNode = _rootNode;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param _label The hash of the label to register.
     * @param _owner The address of the new owner.
     * @param _resolver The Stealth Key compatible resolver that will be used for this subdomain
     * @param _spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @param _spendingPubKey The public key for generating a stealth address
     * @param _viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @param _viewingPubKey The public key to use for encryption
     */
    function register(
        bytes32 _label,
        address _owner,
        address _resolver,
        uint256 _spendingPubKeyPrefix,
        uint256 _spendingPubKey,
        uint256 _viewingPubKeyPrefix,
        uint256 _viewingPubKey
    ) public {
        // calculate the node for this subdomain
        bytes32 _node = keccak256(abi.encodePacked(rootNode, _label));

        // ensure the subdomain has not yet been claimed
        address _currentOwner = ens.owner(_node);
        require(_currentOwner == address(0x0), 'StealthKeyFIFSRegistrar: Already claimed');

        // temporarily make this contract the subnode owner to allow it to update the stealth keys & address
        ens.setSubnodeOwner(rootNode, _label, address(this));
        StealthKeyResolver(_resolver).setStealthKeys(_node, _spendingPubKeyPrefix, _spendingPubKey, _viewingPubKeyPrefix, _viewingPubKey);
        AddrResolver(_resolver).setAddr(_node, _owner);

        // transfer ownership to the registrant and set stealth key resolver
        ens.setSubnodeRecord(rootNode, _label, _owner, address(_resolver), 0);
    }
}

pragma solidity ^0.7.0;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity ^0.7.4;
import "../ResolverBase.sol";

abstract contract StealthKeyResolver is ResolverBase {
    bytes4 constant private STEALTH_KEY_INTERFACE_ID = 0x69a76591;

    /// @dev Event emitted when a user updates their resolver stealth keys
    event StealthKeyChanged(bytes32 indexed node, uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey);

    /**
     * @dev Mapping used to store two secp256k1 curve public keys useful for
     * receiving stealth payments. The mapping records two keys: a viewing
     * key and a spending key, which can be set and read via the `setsStealthKeys`
     * and `stealthKey` methods respectively.
     *
     * The mapping associates the node to another mapping, which itself maps
     * the public key prefix to the actual key . This scheme is used to avoid using an
     * extra storage slot for the public key prefix. For a given node, the mapping
     * may contain a spending key at position 0 or 1, and a viewing key at position
     * 2 or 3. See the setter/getter methods for details of how these map to prefixes.
     *
     * For more on secp256k1 public keys and prefixes generally, see:
     * https://github.com/ethereumbook/ethereumbook/blob/develop/04keys-addresses.asciidoc#generating-a-public-key
     *
     */
    mapping(bytes32 => mapping(uint256 => uint256)) _stealthKeys;

    /**
     * Sets the stealth keys associated with an ENS name, for anonymous sends.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @param spendingPubKey The public key for generating a stealth address
     * @param viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @param viewingPubKey The public key to use for encryption
     */
    function setStealthKeys(bytes32 node, uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey) external authorised(node) {
        require(
            (spendingPubKeyPrefix == 2 || spendingPubKeyPrefix == 3) &&
            (viewingPubKeyPrefix == 2 || viewingPubKeyPrefix == 3),
            "StealthKeyResolver: Invalid Prefix"
        );

        emit StealthKeyChanged(node, spendingPubKeyPrefix, spendingPubKey, viewingPubKeyPrefix, viewingPubKey);

        // Shift the spending key prefix down by 2, making it the appropriate index of 0 or 1
        spendingPubKeyPrefix -= 2;

        // Ensure the opposite prefix indices are empty
        delete _stealthKeys[node][1 - spendingPubKeyPrefix];
        delete _stealthKeys[node][5 - viewingPubKeyPrefix];

        // Set the appropriate indices to the new key values
        _stealthKeys[node][spendingPubKeyPrefix] = spendingPubKey;
        _stealthKeys[node][viewingPubKeyPrefix] = viewingPubKey;
    }

    /**
     * Returns the stealth key associated with a name.
     * @param node The ENS node to query.
     * @return spendingPubKeyPrefix Prefix of the spending public key (2 or 3)
     * @return spendingPubKey The public key for generating a stealth address
     * @return viewingPubKeyPrefix Prefix of the viewing public key (2 or 3)
     * @return viewingPubKey The public key to use for encryption
     */
    function stealthKeys(bytes32 node) external view returns (uint256 spendingPubKeyPrefix, uint256 spendingPubKey, uint256 viewingPubKeyPrefix, uint256 viewingPubKey) {
        if (_stealthKeys[node][0] != 0) {
            spendingPubKeyPrefix = 2;
            spendingPubKey = _stealthKeys[node][0];
        } else {
            spendingPubKeyPrefix = 3;
            spendingPubKey = _stealthKeys[node][1];
        }

        if (_stealthKeys[node][2] != 0) {
            viewingPubKeyPrefix = 2;
            viewingPubKey = _stealthKeys[node][2];
        } else {
            viewingPubKeyPrefix = 3;
            viewingPubKey = _stealthKeys[node][3];
        }

        return (spendingPubKeyPrefix, spendingPubKey, viewingPubKeyPrefix, viewingPubKey);
    }

    function supportsInterface(bytes4 interfaceID) public virtual override pure returns(bool) {
        return interfaceID == STEALTH_KEY_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.7.4;
import "../ResolverBase.sol";

abstract contract AddrResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) virtual external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) virtual public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) virtual public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.7.4;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

