/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Protocol for registering content and signatures.
contract SignableRegistry {
    event Sign(address indexed signer, uint256 indexed index);
    event Revoke(address indexed revoker, uint256 indexed index);
    event Register(address indexed admin, string indexed content);
    event Amend(address indexed admin, uint256 indexed index, string indexed content);
    event GrantAdmin(address indexed admin);
    event RevokeAdmin(address indexed admin);
    
    /// @dev EIP-712 variables:
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant SIG_HASH = keccak256("SignMeta(address signer,uint256 index)");
    
    uint256 public signablesCount;
    
    address public superAdmin;
    
    mapping(address => bool) public admins;
    mapping(uint256 => Signable) public signables;
    
    struct Signable {
        string content;
        mapping(address => bool) signed;
    }

    /// @dev Initialize contract and `DOMAIN_SEPARATOR`.
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SignableRegistry")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        
        superAdmin = msg.sender;
        admins[msg.sender] = true;
    }

    // **** MODIFIERS **** //
    // ------------------ //
    
    modifier onlyAdmins() {
        require(admins[msg.sender] == true, "NOT_ADMIN");
        _;
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "NOT_SUPER_ADMIN");
        _;
    }
    
    modifier contentExists(uint256 index) {
        require(0 < signablesCount && signablesCount > index, "NOT_CONTENT");
        _;
    }
    
    // **** ADMIN MANAGEMENT **** //
    // ------------------------- //
    
    /// @notice Grant an `admin` `content` registration rights.
    /// @dev Can only be called by `superAdmin`.
    /// @param admin Account to grant rights.
    function grantAdmin(address admin) external onlySuperAdmin {
        admins[admin] = true;
        emit GrantAdmin(admin);
    }
    
    /// @notice Revoke an `admin` from `content` registration rights.
    /// @dev Can only be called by `superAdmin`.
    /// @param admin Account to revoke rights from.
    function revokeAdmin(address admin) external onlySuperAdmin {
        admins[admin] = false;
        emit RevokeAdmin(admin);
    }
    
    // **** SIGNING PROTOCOL **** //
    // ------------------------- //
    
    /// @notice Check an `account` for signature against indexed `content`.
    /// @param signer Account to check signature for.
    /// @param index `content` # to check signature against.
    function checkSignature(address signer, uint256 index) external view contentExists(index) returns (bool signed) {
        signed = signables[index].signed[signer];
    }
    
    // **** SIGNING
    
    /// @notice Register signature against indexed `content`.
    /// @param index `content` # to map signature against.
    function sign(uint256 index) external contentExists(index) {
        signables[index].signed[msg.sender] = true;
        emit Sign(msg.sender, index);
    }
    
    /// @notice Register signature against indexed `content` using EIP-712 metaTX.
    /// @param signer Account to register signature for.
    /// @param index `content` # to map signature against.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function signMeta(address signer, uint256 index, uint8 v, bytes32 r, bytes32 s) external contentExists(index) {
        // Validate signature elements:
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SIG_HASH,
                            signer,
                            index
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == signer, "INVALID_SIG");
        // Register signature:
        signables[index].signed[signer] = true;
        emit Sign(signer, index);
    }
    
    // **** REVOCATION
    
    /// @notice Revoke signature against indexed `content`.
    /// @param index `content` # to map signature revocation against.
    function revoke(uint256 index) external contentExists(index) {
        signables[index].signed[msg.sender] = false;
        emit Revoke(msg.sender, index);
    }
    
    /// @notice Revoke signature against indexed `content` using EIP-712 metaTX.
    /// @param signer Account to revoke signature for.
    /// @param index `content` # to map signature revocation against.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function revokeMeta(address signer, uint256 index, uint8 v, bytes32 r, bytes32 s) external contentExists(index) {
        // Validate revocation elements:
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SIG_HASH,
                            signer,
                            index
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == signer, "INVALID_SIG");
        // Register revocation:
        signables[index].signed[signer] = false;
        emit Revoke(signer, index);
    }
    
    // **** REGISTRY PROTOCOL **** //
    // -------------------------- //
    
    /// @notice Register `content` for signatures.
    /// @dev Can only be called by `admins`.
    /// @param content Signable string - could be IPFS hash, plaintext, or JSON.
    function register(string calldata content) external onlyAdmins {
        uint256 index = signablesCount;
        signables[index].content = content;
        unchecked { signablesCount++; }
        emit Register(msg.sender, content);
    }
    
    /// @notice Update `content` for signatures.
    /// @dev Can only be called by `admins`.
    /// @param index `content` # to update.
    /// @param content Signable string - could be IPFS hash, plaintext, or JSON.
    function amend(uint256 index, string calldata content) external onlyAdmins contentExists(index) {
        signables[index].content = content;
        emit Amend(msg.sender, index, content);
    }
}