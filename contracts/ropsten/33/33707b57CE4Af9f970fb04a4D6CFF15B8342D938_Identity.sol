// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./IDelegation.sol";
import "./ERC165.sol";

contract Identity is IDelegation, ERC165 {
    /**
     * @dev Used for storing an address's delegation data
     */
    struct AddressDelegation {
        Role role;
        uint64 endBlock;
        uint32 nonce;
    }

    /**
     * @dev Storage for the delegation data
     */
    struct DelegationStorage {
        bytes32 domainSeparatorHash;
        bool initialized;
        mapping(address => AddressDelegation) delegations;
    }

    bytes32 private constant DELEGATION_STORAGE_SLOT =
        bytes32(uint256(keccak256("dsnp.org.delegations")) - 1);

    string private constant DELEGATE_ADD_TYPE =
        "DelegateAdd(uint32 nonce,address delegateAddr,uint8 role)";
    bytes32 private constant DELEGATE_ADD_TYPEHASH = keccak256(abi.encodePacked(DELEGATE_ADD_TYPE));
    string private constant DELEGATE_REMOVE_TYPE =
        "DelegateRemove(uint32 nonce,address delegateAddr,uint64 endBlock)";
    bytes32 private constant DELEGATE_REMOVE_TYPEHASH =
        keccak256(abi.encodePacked(DELEGATE_REMOVE_TYPE));

    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

    bytes32 private constant SALT =
        0xa0bec69846cdcc8c1ba1eb93be1c5728385a9e26062a73e238b1beda189ac4c9;

    /**
     * @dev We can store the role to permissions data currently via bitwise
     * uint256(...[32 bit ANNOUNCER permissions][32 bit OWNER permissions][32 bit NONE permissions])
     */
    uint256 private constant ROLE_PERMISSIONS =
        // Role.OWNER Mask
        (((1 << uint32(Permission.ANNOUNCE)) |
            (1 << uint32(Permission.OWNERSHIP_TRANSFER)) |
            (1 << uint32(Permission.DELEGATE_ADD)) |
            (1 << uint32(Permission.DELEGATE_REMOVE))) << (uint32(Role.OWNER) << 5)) |
            // Role.ANNOUNCER Mask
            ((1 << uint32(Permission.ANNOUNCE)) << (uint32(Role.ANNOUNCER) << 5));

    /*
     * @dev Modifier that requires that the contract data be initialized
     */
    modifier isInitialized() {
        require(_delegationData().initialized, "Contract not initialized");
        _;
    }

    /**
     * @dev Constructor is only for use if the contract is being used directly
     *      Construct with address(0x0) for logic contracts
     * @param owner Address to be set as the owner
     */
    constructor(address owner) {
        _init(owner);
    }

    /**
     * @dev Initialize for use as a proxy's logic contract
     * @param owner Address to be set as the owner
     */
    function initialize(address owner) external {
        // Checks
        require(_delegationData().initialized == false, "Already initialized");
        // Effects
        _init(owner);
    }

    function _init(address owner) private {
        _setDelegateRole(owner, Role.OWNER);
        _delegationData().initialized = true;
        _delegationData().domainSeparatorHash = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Identity"),
                keccak256("1"),
                block.chainid,
                address(this),
                SALT
            )
        );
    }

    /**
     * @dev Return the data storage slot
     *      Slot used to prevent memory collisions for proxy contracts
     * @return ds delegation storage
     */
    function _delegationData() internal pure returns (DelegationStorage storage ds) {
        bytes32 position = DELEGATION_STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Check to see if the role has a particular permission
     * @param role The Role to test against
     * @param permission The Permission to test with the role
     * @return true if the role is assigned the given permission
     */
    function doesRoleHavePermission(Role role, Permission permission) public pure returns (bool) {
        // bitwise (possible) AND (check single permission mask)
        return ROLE_PERMISSIONS & (((1 << uint32(permission))) << (uint32(role) << 5)) > 0x0;
    }

    /**
     * @dev Internal check authorization method
     * @param addr The address to inspect permissions of
     * @param permission The permission to check
     * @param blockNumber Block number to check at. Use 0x0 for endless permissions.
     * @return true if the address has the permission at the given block
     */
    function _checkAuthorization(
        address addr,
        Permission permission,
        uint256 blockNumber
    ) internal view returns (bool) {
        AddressDelegation storage delegation = _delegationData().delegations[addr];
        return
            // endBlock check, 0x0 reserved for endless permissions
            (delegation.endBlock == 0 || (delegation.endBlock > blockNumber && blockNumber != 0)) &&
            // Permission check
            doesRoleHavePermission(delegation.role, permission);
    }

    /**
     * @dev Checks to see if address is authorized with the given permission
     * @param addr Address that is used to test
     * @param permission Level of permission check. See Permission for details
     * @param blockNumber Check for authorization at a particular block number, 0x0 reserved for endless permissions
     * @return boolean
     *
     * @dev Return MAY change as deauthorization can revoke past messages
     */
    function isAuthorizedTo(
        address addr,
        Permission permission,
        uint256 blockNumber
    ) external view override returns (bool) {
        return _checkAuthorization(addr, permission, blockNumber);
    }

    /**
     * @dev Add or change permissions for delegate
     * @param newDelegate Address to delegate new permissions to
     * @param role Role for the delegate
     *
     * MUST be called by owner or other delegate with permissions
     * MUST consider newDelegate to be valid from the beginning to time
     * MUST emit DSNPAddDelegate
     */
    function delegate(address newDelegate, Role role) external override {
        // Checks
        require(
            _checkAuthorization(msg.sender, Permission.DELEGATE_ADD, block.number),
            "Sender does not have the DELEGATE_ADD permission."
        );
        require(role != Role.NONE, "Role.NONE not allowed. Use delegateRemove.");

        // Effects
        _setDelegateRole(newDelegate, role);
    }

    /**
     * @dev Add or change permissions for delegate by EIP-712 signature
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing new delegate address, role, and nonce
     *
     * MUST be signed by owner or other delegate with permissions (implementation specific)
     * MUST consider newDelegate to be valid from the beginning to time
     * MUST emit DSNPAddDelegate
     */
    function delegateByEIP712Sig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        DelegateAdd calldata change
    ) external override {
        // Get Signer
        address signer = delegateAddSigner(v, r, s, change);

        // Checks
        require(
            _checkAuthorization(signer, Permission.DELEGATE_ADD, block.number),
            "Signer does not have the DELEGATE_ADD permission."
        );
        require(change.role != Role.NONE, "Role.NONE not allowed. Use delegateRemove.");
        require(change.role <= Role.ANNOUNCER, "Unknown Role");
        require(
            _delegationData().delegations[change.delegateAddr].nonce == change.nonce,
            "Nonces do not match"
        );

        // Effects
        _setDelegateRole(change.delegateAddr, change.role);
    }

    /**
     * @dev Remove Delegate
     * @param addr Address to remove all permissions from
     * @param endBlock Block number to consider the permissions terminated (MUST be > 0x0).
     *
     * MUST be called by the delegate, owner, or other delegate with permissions
     * MUST store endBlock for response in isAuthorizedTo (exclusive)
     * MUST emit DSNPRemoveDelegate
     */
    function delegateRemove(address addr, uint64 endBlock) external override {
        // Checks
        require(_delegationData().delegations[addr].nonce > 0, "Never authorized");
        require(endBlock > 0x0, "endBlock 0x0 reserved for endless permissions");

        // Self removal checks
        if (!_checkAuthorization(msg.sender, Permission.DELEGATE_REMOVE, block.number)) {
            require(endBlock <= block.number, "Cannot self-remove in the future");
            require(msg.sender == addr, "Sender does not have the DELEGATE_REMOVE permission");
        }

        // Effects
        _setDelegateEnd(addr, endBlock);
    }

    /**
     * @dev Remove Delegate By EIP-712 Signature
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing new delegate address, endBlock, and nonce
     *
     * MUST be signed by the delegate, owner, or other delegate with permissions
     * MUST store endBlock for response in isAuthorizedTo (exclusive)
     * MUST emit DSNPRemoveDelegate
     */
    function delegateRemoveByEIP712Sig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        DelegateRemove calldata change
    ) external override {
        // Checks
        address signer = delegateRemoveSigner(v, r, s, change);

        // Self removal checks
        if (!_checkAuthorization(signer, Permission.DELEGATE_REMOVE, block.number)) {
            require(change.endBlock <= block.number, "Cannot self-remove in the future");
            require(
                signer == change.delegateAddr,
                "Signer does not have the DELEGATE_REMOVE permission"
            );
        }
        require(
            _delegationData().delegations[change.delegateAddr].nonce == change.nonce,
            "Nonces do not match"
        );
        require(change.nonce > 0, "Never authorized");
        require(change.endBlock > 0x0, "endBlock 0x0 reserved for endless permissions");

        // Effects
        _setDelegateEnd(change.delegateAddr, change.endBlock);
    }

    /**
     * @dev Get a delegate's nonce
     * @param addr The delegate's address to get the nonce for
     *
     * @return nonce value for delegate
     */
    function getNonceForDelegate(address addr) external view override returns (uint32) {
        return _delegationData().delegations[addr].nonce;
    }

    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     *  uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     *  `interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return
            interfaceID == type(ERC165).interfaceId || interfaceID == type(IDelegation).interfaceId;
    }

    /**
     * @dev Assigns a delegate role
     * @param addr The address to assign the given role to
     * @param role The role to assign
     */
    function _setDelegateRole(address addr, Role role) internal {
        AddressDelegation storage delegation = _delegationData().delegations[addr];
        delegation.role = role;
        delegation.endBlock = 0x0;
        delegation.nonce++;
        emit DSNPAddDelegate(addr, role);
    }

    /**
     * @dev Removes a delegate role at a given point
     * @param addr The address to revoke the given role to
     * @param endBlock The exclusive block to end permissions on (0x1 for always)
     */
    function _setDelegateEnd(address addr, uint64 endBlock) internal {
        AddressDelegation storage delegation = _delegationData().delegations[addr];
        delegation.endBlock = endBlock;
        delegation.nonce++;
        emit DSNPRemoveDelegate(addr, endBlock);
    }

    /**
     * @dev Recover the message signer from a DelegateAdd and a signature.
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change DelegateAdd data containing nonce, delegate address, new role
     * @return signer address (or some arbitrary address if signature is incorrect)
     */
    function delegateAddSigner(
        uint8 v,
        bytes32 r,
        bytes32 s,
        DelegateAdd calldata change
    ) internal view returns (address) {
        bytes32 typeHash = keccak256(
            abi.encode(DELEGATE_ADD_TYPEHASH, change.nonce, change.delegateAddr, change.role)
        );
        return signerFromHashStruct(v, r, s, typeHash);
    }

    /**
     * @dev Recover the message signer from a DelegateAdd and a signature.
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change DelegateRemove data containing nonce, delegate address, end block
     * @return signer address (or some arbitrary address if signature is incorrect)
     */
    function delegateRemoveSigner(
        uint8 v,
        bytes32 r,
        bytes32 s,
        DelegateRemove calldata change
    ) internal view returns (address) {
        bytes32 typeHash = keccak256(
            abi.encode(DELEGATE_REMOVE_TYPEHASH, change.nonce, change.delegateAddr, change.endBlock)
        );
        return signerFromHashStruct(v, r, s, typeHash);
    }

    /**
     * @dev Recover the message signer from a signature and a type hash for this domain.
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param hashStruct Hash of encoded type struct
     * @return signer address (or some arbitrary address if signature is incorrect)
     */
    function signerFromHashStruct(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hashStruct
    ) internal view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _delegationData().domainSeparatorHash, hashStruct)
        );
        return ecrecover(digest, v, r, s);
    }
}