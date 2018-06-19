pragma solidity 0.4.19;


/// @title Ethereum Claims Registry - A repository storing claims issued
///        from any Ethereum account to any other Ethereum account.
contract EthereumClaimsRegistry {

    mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt);

    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt);

    /// @dev Create or update a claim
    /// @param subject The address the claim is being issued to
    /// @param key The key used to identify the claim
    /// @param value The data associated with the claim
    function setClaim(address subject, bytes32 key, bytes32 value) public {
        registry[msg.sender][subject][key] = value;
        ClaimSet(msg.sender, subject, key, value, now);
    }

    /// @dev Create or update a claim about yourself
    /// @param key The key used to identify the claim
    /// @param value The data associated with the claim
    function setSelfClaim(bytes32 key, bytes32 value) public {
        setClaim(msg.sender, key, value);
    }

    /// @dev Allows to retrieve claims from other contracts as well as other off-chain interfaces
    /// @param issuer The address of the issuer of the claim
    /// @param subject The address to which the claim was issued to
    /// @param key The key used to identify the claim
    function getClaim(address issuer, address subject, bytes32 key) public constant returns(bytes32) {
        return registry[issuer][subject][key];
    }

    /// @dev Allows to remove a claims from the registry.
    ///      This can only be done by the issuer or the subject of the claim.
    /// @param issuer The address of the issuer of the claim
    /// @param subject The address to which the claim was issued to
    /// @param key The key used to identify the claim
    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(msg.sender == issuer || msg.sender == subject);
        require(registry[issuer][subject][key] != 0);
        delete registry[issuer][subject][key];
        ClaimRemoved(msg.sender, subject, key, now);
    }
}


/// @title Revoke and Publish - an interface for publishing data and 
///        rotating access to publish new data
contract RevokeAndPublish {

    event Revocation(
        address indexed genesis,
        address indexed from,
        address indexed to,
        uint updatedAt);

    mapping(address => address) public manager;
    EthereumClaimsRegistry registry = EthereumClaimsRegistry(0xAcA1BCd8D0f5A9BFC95aFF331Da4c250CD9ac2Da);

    function revokeAndPublish(address genesis, bytes32 key, bytes32 data, address newManager) public {
        publish(genesis, key, data);
        Revocation(genesis, manager[genesis], newManager, now);
        manager[genesis] = newManager;
    }

    /// @dev Publish some data
    /// @param genesis The address of the first publisher
    /// @param key The key used to identify the claim
    /// @param data The data associated with the claim
    function publish(address genesis, bytes32 key, bytes32 data) public {
        require((manager[genesis] == 0x0 && genesis == msg.sender) || manager[genesis] == msg.sender);
        registry.setClaim(genesis, key, data);
    }

    /// @dev Lookup the currently published data for genesis
    /// @param genesis The address of the first publisher
    /// @param key The key used to identify the claim
    function lookup(address genesis, bytes32 key) public constant returns(bytes32) {
      return registry.getClaim(address(this), genesis, key);
    }
}