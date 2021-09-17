// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./IRegistry.sol";
import "./IDelegation.sol";
import "./ERC165.sol";

contract Registry is IRegistry {
    uint64 private idSequence = 1000;

    string private constant ADDRESS_CHANGE_TYPE =
        "AddressChange(uint32 nonce,address addr,string handle)";
    bytes32 private constant ADDRESS_CHANGE_TYPEHASH =
        keccak256(abi.encodePacked(ADDRESS_CHANGE_TYPE));
    string private constant HANDLE_CHANGE_TYPE =
        "HandleChange(uint32 nonce,string oldHandle,string newHandle)";
    bytes32 private constant HANDLE_CHANGE_TYPEHASH =
        keccak256(abi.encodePacked(HANDLE_CHANGE_TYPE));

    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant SALT =
        0x01597239a39b73c524db27009bfe992afd78e195ca64846a6fa0ce65ce37b2df;

    bytes32 private immutable domainSeparatorHash;

    // Id and identity contract address to be mapped to handle
    struct Registration {
        uint32 nonce;
        uint64 id;
        address identityAddress;
    }

    // Map from handle to registration
    mapping(string => Registration) private registrations;

    // Create domain separator on construction
    constructor() {
        domainSeparatorHash = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Registry"),
                keccak256("1"),
                block.chainid,
                address(this),
                SALT
            )
        );
    }

    /**
     * @dev Register a new DSNP Id
     * @param addr Address for the new DSNP Id to point at
     * @param handle The handle for discovery
     * @return id of registration
     */
    function register(address addr, string calldata handle) external override returns (uint64) {
        // Checks

        Registration storage reg = registrations[handle];
        require(reg.id == 0, "Handle already exists");

        // Effects

        // Set id to latest sequence number then increment
        reg.id = idSequence++;
        reg.identityAddress = addr;

        // emit registration event
        emit DSNPRegistryUpdate(reg.id, addr, handle);

        // Interactions

        ERC165 delegation = ERC165(addr);
        require(
            delegation.supportsInterface(type(IDelegation).interfaceId),
            "contract does not support IDelegation interface"
        );

        return reg.id;
    }

    /**
     * @dev Alter a DSNP Id resolution address
     * @param newAddr Original or new address to resolve to
     * @param handle The handle to modify
     */
    function changeAddress(address newAddr, string calldata handle) external override {
        // Checks

        Registration storage reg = registrations[handle];
        require(reg.id != 0, "Handle does not exist");

        // Effects

        address oldAddr = reg.identityAddress;
        reg.identityAddress = newAddr;
        emit DSNPRegistryUpdate(reg.id, newAddr, handle);

        // Interactions

        // ensure old delegation contract authorizes this change
        IDelegation oldAuth = IDelegation(oldAddr);
        require(
            oldAuth.isAuthorizedTo(
                msg.sender,
                IDelegation.Permission.OWNERSHIP_TRANSFER,
                block.number
            ),
            "Access denied"
        );

        // ensure new delegation contract implements IDelegation interface
        ERC165 delegation = ERC165(newAddr);
        require(
            delegation.supportsInterface(type(IDelegation).interfaceId),
            "contract does not support IDelegation interface"
        );
    }

    /**
     * @dev Alter a DSNP Id resolution address by EIP-712 Signature
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing nonce, new address and handle
     */
    function changeAddressByEIP712Sig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        AddressChange calldata change
    ) external override {
        // Checks

        Registration storage reg = registrations[change.handle];
        require(reg.id != 0, "Handle does not exist");
        require(reg.nonce == change.nonce, "Nonces do not match");

        address signer = addressChangeSigner(v, r, s, change);

        // Effects

        reg.nonce++;

        address oldAddr = reg.identityAddress;
        reg.identityAddress = change.addr;
        emit DSNPRegistryUpdate(reg.id, change.addr, change.handle);

        // Interactions

        // ensure old delegation contract authorizes this change
        IDelegation oldAuth = IDelegation(oldAddr);
        require(
            oldAuth.isAuthorizedTo(signer, IDelegation.Permission.OWNERSHIP_TRANSFER, block.number),
            "Access denied"
        );

        // ensure new delegation contract implements IDelegation interface
        ERC165 delegation = ERC165(change.addr);
        require(
            delegation.supportsInterface(type(IDelegation).interfaceId),
            "contract does not support IDelegation interface"
        );
    }

    /**
     * @dev Alter a DSNP Id handle
     * @param oldHandle The previous handle for modification
     * @param newHandle The new handle to use for discovery
     */
    function changeHandle(string calldata oldHandle, string calldata newHandle) external override {
        // Checks

        Registration storage oldReg = registrations[oldHandle];
        require(oldReg.id != 0, "Old handle does not exist");

        Registration storage newReg = registrations[newHandle];
        require(newReg.id == 0, "New handle already exists");

        // Effects

        // assign to new registration
        newReg.id = oldReg.id;
        newReg.identityAddress = oldReg.identityAddress;

        // signal that the old handle is unassigned and available
        oldReg.id = 0;

        // notify the change
        emit DSNPRegistryUpdate(newReg.id, newReg.identityAddress, newHandle);

        // Interactions

        IDelegation authorization = IDelegation(oldReg.identityAddress);
        require(
            authorization.isAuthorizedTo(
                msg.sender,
                IDelegation.Permission.OWNERSHIP_TRANSFER,
                block.number
            ),
            "Access denied"
        );
    }

    /**
     * @dev Alter a DSNP Id handle by EIP-712 Signature
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing nonce, old handle and new handle
     */
    function changeHandleByEIP712Sig(
        uint8 v,
        bytes32 r,
        bytes32 s,
        HandleChange calldata change
    ) external override {
        // Checks

        Registration storage oldReg = registrations[change.oldHandle];
        require(oldReg.id != 0, "Old handle does not exist");
        require(oldReg.nonce == change.nonce, "Nonces do not match");

        Registration storage newReg = registrations[change.newHandle];
        require(newReg.id == 0, "New handle already exists");

        address signer = handleChangeSigner(v, r, s, change);

        // Effects

        // assign to new registration
        newReg.id = oldReg.id;
        newReg.identityAddress = oldReg.identityAddress;

        // signal that the old handle is unassigned and available
        oldReg.id = 0;

        // increment nonce so this transaction cannot be replayed
        oldReg.nonce++;

        // notify the change
        emit DSNPRegistryUpdate(newReg.id, newReg.identityAddress, change.newHandle);

        // Interactions

        IDelegation authorization = IDelegation(oldReg.identityAddress);
        require(
            authorization.isAuthorizedTo(
                signer,
                IDelegation.Permission.OWNERSHIP_TRANSFER,
                block.number
            ),
            "Access denied"
        );
    }

    /**
     * @dev Resolve a handle to a DSNP Id and contract address
     * @param handle The handle to resolve
     *
     * Returns zeros if not found
     * @return A tuple of the DSNP Id and the Address of the contract
     */
    function resolveRegistration(string calldata handle)
        external
        view
        override
        returns (uint64, address)
    {
        Registration memory reg = registrations[handle];

        if (reg.id == 0) return (0, address(0));

        return (reg.id, reg.identityAddress);
    }

    /**
     * @dev Resolve a handle to nonce
     * @param handle The handle to resolve
     *
     * @return nonce value for handle
     */
    function resolveHandleToNonce(string calldata handle) external view override returns (uint32) {
        Registration memory reg = registrations[handle];

        require(reg.id != 0, "Handle does not exist");

        return reg.nonce;
    }

    /**
     * @dev Recover the message signer from an AddressChange and a signature.
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing nonce, handle and new address
     * @return signer address (or some arbitrary address if signature is incorrect)
     */
    function addressChangeSigner(
        uint8 v,
        bytes32 r,
        bytes32 s,
        AddressChange calldata change
    ) internal view returns (address) {
        bytes32 typeHash = keccak256(
            abi.encode(
                ADDRESS_CHANGE_TYPEHASH,
                change.nonce,
                change.addr,
                keccak256(bytes(change.handle))
            )
        );
        return signerFromHashStruct(v, r, s, typeHash);
    }

    /**
     * @dev Recover the message signer from a HandleChange and a signature.
     * @param v EIP-155 calculated Signature v value
     * @param r ECDSA Signature r value
     * @param s ECDSA Signature s value
     * @param change Change data containing nonce, old handle and new handle
     * @return signer address (or some arbitrary address if signature is incorrect)
     */
    function handleChangeSigner(
        uint8 v,
        bytes32 r,
        bytes32 s,
        HandleChange calldata change
    ) internal view returns (address) {
        bytes32 typeHash = keccak256(
            abi.encode(
                HANDLE_CHANGE_TYPEHASH,
                change.nonce,
                keccak256(bytes(change.oldHandle)),
                keccak256(bytes(change.newHandle))
            )
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
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, hashStruct));
        return ecrecover(digest, v, r, s);
    }
}