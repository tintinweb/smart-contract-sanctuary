pragma solidity 0.4.24;

// File: contracts/ERC780.sol

/// @title ERC780
/// @notice The ERC780 interface for storing and interacting with claims.
/// See https://github.com/ethereum/EIPs/issues/780
contract ERC780 {
    function setClaim(address subject, bytes32 key, bytes32 value) public;
    function setSelfClaim(bytes32 key, bytes32 value) public;
    function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32);
    function removeClaim(address issuer, address subject, bytes32 key) public;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() public {
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

// File: contracts/RBACInterface.sol

/// @title RBACInterface
/// @notice The interface for Role-Based Access Control.
contract RBACInterface {
    function hasRole(address addr, string role) public view returns (bool);
}

// File: contracts/RBACManaged.sol

/// @title RBACManaged
/// @notice Controls access by delegating to a deployed RBAC contract.
contract RBACManaged is Ownable {

    RBACInterface public rbac;

    /// @param rbacAddr The address of the RBAC contract which controls access.
    constructor(address rbacAddr) public {
        rbac = RBACInterface(rbacAddr);
    }

    function roleAdmin() internal pure returns (string);

    /// @notice Check if an address has a role.
    /// @param addr The address.
    /// @param role The role.
    /// @return A boolean indicating whether the address has the role.
    function hasRole(address addr, string role) public view returns (bool) {
        return rbac.hasRole(addr, role);
    }

    modifier onlyRole(string role) {
        require(hasRole(msg.sender, role), "Access denied: missing role");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || hasRole(msg.sender, roleAdmin()), "Access denied: missing role");
        _;
    }

    /// @notice Change the address of the deployed RBAC contract which
    /// controls access. Only the owner or an admin can change the address.
    /// @param rbacAddr The address of the RBAC contract which controls access.
    function setRBACAddress(address rbacAddr) public onlyOwnerOrAdmin {
        rbac = RBACInterface(rbacAddr);
    }
}

// File: contracts/UserAddressAliasable.sol

/// @title UserAddressAliasable
/// @notice Allows the address that represents an entity (individual) to be
/// changed by setting aliases. Any data about an entity should be associated
/// to the original (canonical) address.
contract UserAddressAliasable is RBACManaged {

    event UserAddressAliased(address indexed oldAddr, address indexed newAddr);

    mapping(address => address) addressAlias;  // canonical => alias

    function roleAddressAliaser() internal pure returns (string);

    /// @notice Alias a new address to an old address. Requires caller to have
    /// the address aliaser role returned by roleAddressAliaser(). Requires
    /// that neither address is already aliased to another address.
    /// @param oldAddr The old address.
    /// @param newAddr The new address.
    function setAddressAlias(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        require(addressAlias[oldAddr] == address(0), "oldAddr is already aliased to another address");
        require(addressAlias[newAddr] == address(0), "newAddr is already aliased to another address");
        require(oldAddr != newAddr, "oldAddr and newAddr must be different");
        setAddressAliasUnsafe(oldAddr, newAddr);
    }

    /// @notice Alias a new address to an old address, bypassing all safety
    /// checks. Can result in broken state, so use at your own peril. Requires
    /// caller to have the address aliaser role returned by
    /// roleAddressAliaser().
    /// @param oldAddr The old address.
    /// @param newAddr The new address.
    function setAddressAliasUnsafe(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        addressAlias[newAddr] = oldAddr;
        emit UserAddressAliased(oldAddr, newAddr);
    }

    /// @notice Change an address to no longer alias to anything else. Calling
    /// setAddressAlias(oldAddr, newAddr) is reversed by calling
    /// unsetAddressAlias(newAddr).
    /// @param addr The address to unalias. Equivalent to newAddr in setAddressAlias.
    function unsetAddressAlias(address addr) public onlyRole(roleAddressAliaser()) {
        setAddressAliasUnsafe(0, addr);
    }

    /// @notice Resolve an address to its canonical address.
    /// @param addr The address to resolve.
    /// @return The canonical address.
    function resolveAddress(address addr) public view returns (address) {
        address parentAddr = addressAlias[addr];
        if (parentAddr == address(0)) {
            return addr;
        } else {
            return parentAddr;
        }
    }
}

// File: contracts/ODEMClaimsRegistry.sol

/// @title ODEMClaimsRegistry
/// @notice When an individual completes an event (educational course) with
/// ODEM, ODEM generates a certificate of completion and sets a corresponding
/// claim in this contract. The claim contains the URI (usually an IPFS path)
/// where the certificate can be downloaded, and its hash (SHA-256) to prove its
/// authenticity.
/// If an individual changes their Ethereum address, for example if they lose
/// access to their account, ODEM may alias the new address to the old
/// address. Then claims apply automatically to both addresses.
/// Implements the ERC780 interface.
contract ODEMClaimsRegistry is RBACManaged, UserAddressAliasable, ERC780 {

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt
    );
    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt
    );

    string constant ROLE_ADMIN = "claims__admin";
    string constant ROLE_ISSUER = "claims__issuer";
    string constant ROLE_ADDRESS_ALIASER = "claims__address_aliaser";

    struct Claim {
        bytes uri;
        bytes32 hash;
    }

    mapping(address => mapping(bytes32 => Claim)) internal claims;  // subject => key => claim

    // Used for safe address aliasing. Never reset to false.
    mapping(address => bool) internal hasClaims;

    /// @param rbacAddr The address of the RBAC contract which controls access to this
    /// contract.
    constructor(address rbacAddr) RBACManaged(rbacAddr) public {}

    /// @notice Get an ODEM claim.
    /// @param subject The address of the individual.
    /// @param key The ODEM event code.
    /// @return The URI where the certificate can be downloaded, and the hash
    /// of the certificate file.
    function getODEMClaim(address subject, bytes32 key) public view returns (bytes uri, bytes32 hash) {
        address resolved = resolveAddress(subject);
        return (claims[resolved][key].uri, claims[resolved][key].hash);
    }

    /// @notice Set an ODEM claim.
    /// Only ODEM can set claims.
    /// @dev Requires caller to have the role "claims__issuer".
    /// @param subject The address of the individual.
    /// @param key The ODEM event code.
    /// @param uri The URI where the certificate can be downloaded.
    /// @param hash The hash of the certificate file.
    function setODEMClaim(address subject, bytes32 key, bytes uri, bytes32 hash) public onlyRole(ROLE_ISSUER) {
        address resolved = resolveAddress(subject);
        claims[resolved][key].uri = uri;
        claims[resolved][key].hash = hash;
        hasClaims[resolved] = true;
        emit ClaimSet(msg.sender, subject, key, hash, now);
    }

    /// @notice Remove an ODEM claim. Anyone can remove a claim about
    /// themselves.
    /// Only ODEM can remove claims about others.
    /// @dev Requires caller to have the role "claims__issuer" or to be the
    /// subject.
    /// @param subject The address of the individual.
    /// @param key The ODEM event code.
    function removeODEMClaim(address subject, bytes32 key) public {
        require(hasRole(msg.sender, ROLE_ISSUER) || msg.sender == subject, "Access denied: missing role");
        address resolved = resolveAddress(subject);
        delete claims[resolved][key];
        emit ClaimRemoved(msg.sender, subject, key, now);
    }

    /// @notice Alias a new address to an old address.
    /// Only ODEM can set aliases.
    /// @dev Requires caller to have the role "claims__address_aliaser".
    /// Requires that neither address is already aliased to another address,
    /// and that the new address does not already have claims.
    /// @param oldAddr The old address.
    /// @param newAddr The new address.
    function setAddressAlias(address oldAddr, address newAddr) public onlyRole(ROLE_ADDRESS_ALIASER) {
        require(!hasClaims[newAddr], "newAddr already has claims");
        super.setAddressAlias(oldAddr, newAddr);
    }

    /// @notice Get a claim. Provided for compatibility with ERC780.
    /// Only gets claims where the issuer is ODEM.
    /// @param issuer The address which set the claim.
    /// @param subject The address of the individual.
    /// @param key The ODEM event code.
    /// @return The hash of the certificate file.
    function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32) {
        if (hasRole(issuer, ROLE_ISSUER)) {
            return claims[subject][key].hash;
        } else {
            return bytes32(0);
        }
    }

    /// @notice Provided for compatibility with ERC780. Always fails.
    function setClaim(address subject, bytes32 key, bytes32 value) public {
        revert();
    }

    /// @notice Provided for compatibility with ERC780. Always fails.
    function setSelfClaim(bytes32 key, bytes32 value) public {
        revert();
    }

    /// @notice Remove a claim. Provided for compatibility with ERC780.
    /// Only removes claims where the issuer is ODEM.
    /// Anyone can remove a claim about themselves. Only ODEM can remove
    /// claims about others.
    /// @dev Requires issuer to have the role "claims__issuer".
    /// Requires caller to have the role "claims__issuer" or to be the
    /// subject.
    /// @param issuer The address which set the claim.
    /// @param subject The address of the individual.
    /// @param key The ODEM event code.
    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(hasRole(issuer, ROLE_ISSUER), "Issuer not recognized");
        removeODEMClaim(subject, key);
    }

    // Required by RBACManaged.
    function roleAdmin() internal pure returns (string) {
        return ROLE_ADMIN;
    }

    // Required by UserAddressAliasable
    function roleAddressAliaser() internal pure returns (string) {
        return ROLE_ADDRESS_ALIASER;
    }
}