pragma solidity ^0.4.18;

// File: contracts/BNBNS.sol

interface BNBNS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

// File: contracts/BNBNSResolver.sol

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract BNBNSResolver {

    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant MULTIHASH_INTERFACE_ID = 0xe89401a1;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);
    event MultihashChanged(bytes32 indexed node, string indexedKey, bytes hash);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
        mapping(string=>bytes) multihash;
    }

    BNBNS bnbns;

    mapping (bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(bnbns.owner(node) == msg.sender);
        _;
    }

    /**
     * Constructor.
     * @param bnbnsAddr The BNBNS registrar contract.
     */
    function BNBNSResolver(BNBNS bnbnsAddr) public {
        bnbns = bnbnsAddr;
    }

    /**
     * Sets the address associated with an BNBNS node.
     * May only be called by the owner of that node in the BNBNS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address addr) public only_owner(node) {
        records[node].addr = addr;
        AddrChanged(node, addr);
    }

    /**
     * Sets the content hash associated with an BNBNS node.
     * May only be called by the owner of that node in the BNBNS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        ContentChanged(node, hash);
    }

    /**
     * Sets the multihash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param hash The multihash to set.
     */
    function setMultihash(bytes32 node, string key, bytes hash) public only_owner(node) {
        records[node].multihash[key] = hash;
        MultihashChanged(node, key, hash);
    }

    /**
     * Sets the name associated with an BNBNS node, for reverse records.
     * May only be called by the owner of that node in the BNBNS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string name) public only_owner(node) {
        records[node].name = name;
        NameChanged(node, name);
    }

    /**
     * Sets the text data associated with an BNBNS node and key.
     * May only be called by the owner of that node in the BNBNS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string key, string value) public only_owner(node) {
        records[node].text[key] = value;
        TextChanged(node, key, value);
    }

    /**
     * Returns the text data associated with an BNBNS node and key.
     * @param node The BNBNS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string key) public view returns (string) {
        return records[node].text[key];
    }

    /**
     * Returns the name associated with an BNBNS node, for reverse records.
     * @param node The BNBNS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string) {
        return records[node].name;
    }

    /**
     * Returns the content hash associated with an BNBNS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The BNBNS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

    /**
     * Returns the multihash associated with an ENS node.
     * @param node The ENS node to query.
     * @param key The multihash data key to query.
     * @return The associated multihash.
     */
    function multihash(bytes32 node, string key) public view returns (bytes) {
        return records[node].multihash[key];
    }

    /**
     * Returns the address associated with an BNBNS node.
     * @param node The BNBNS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
        interfaceID == CONTENT_INTERFACE_ID ||
        interfaceID == NAME_INTERFACE_ID ||
        interfaceID == TEXT_INTERFACE_ID ||
        interfaceID == MULTIHASH_INTERFACE_ID ||
        interfaceID == INTERFACE_META_ID;
    }
}