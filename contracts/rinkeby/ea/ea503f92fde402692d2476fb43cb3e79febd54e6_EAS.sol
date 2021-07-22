/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/Types.sol

pragma solidity 0.7.6;

// A representation of an empty/uninitialized UUID.
bytes32 constant EMPTY_UUID = 0;


// File contracts/IAOVerifier.sol

pragma solidity 0.7.6;

/**
 * @title The interface of an optional AO verifier, submitted via the global AO registry.
 */
interface IAOVerifier {
    /**
     * @dev Verifies whether the specified attestation data conforms to the spec.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The AO data schema.
     * @param data The actual attestation data.
     * @param expirationTime The expiration time of the attestation.
     * @param msgSender The sender of the original attestation message.
     * @param msgValue The number of wei send with the original attestation message.
     *
     * @return Whether the data is valid according to the scheme.
     */
    function verify(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256 expirationTime,
        address msgSender,
        uint256 msgValue
    ) external view returns (bool);
}


// File contracts/IAORegistry.sol

pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title A struct representing a record for a submitted AO (Attestation Object).
 */
struct AORecord {
    // A unique identifier of the AO.
    bytes32 uuid;
    // Optional schema verifier.
    IAOVerifier verifier;
    // Auto-incrementing index for reference, assigned by the registry itself.
    uint256 index;
    // Custom specification of the AO (e.g., an ABI).
    bytes schema;
}

/**
 * @title The global AO registry interface.
 */
interface IAORegistry {
    /**
     * @dev Triggered when a new AO has been registered
     * @param uuid The AO UUID.
     * @param index The AO index.
     * @param schema The AO schema.
     * @param verifier An optional AO schema verifier.
     * @param attester The address of the account used to register the AO.
     */
    event Registered(bytes32 indexed uuid, uint256 indexed index, bytes schema, IAOVerifier verifier, address attester);

    /**
     * @dev Submits and reserve a new AO
     * @param schema The AO data schema.
     * @param verifier An optional AO schema verifier.
     * @return The UUID of the new AO.
     */
    function register(bytes calldata schema, IAOVerifier verifier) external returns (bytes32);

    /**
     * @dev Returns an existing AO by UUID
     * @param uuid The UUID of the AO to retrieve.
     * @return The AO data members.
     */
    function getAO(bytes32 uuid) external view returns (AORecord memory);

    /**
     * @dev Returns the global counter for the total number of attestations
     * @return The global counter for the total number of attestations.
     */
    function getAOCount() external view returns (uint256);
}


// File contracts/IEIP712Verifier.sol

pragma solidity 0.7.6;

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations interface.
 */
interface IEIP712Verifier {
    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested accunt.
     *
     * @return The current nonce.
     */
    function getNonce(address account) external view returns (uint256);

    /**
     * @dev Verifies signed attestation.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function attest(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Verifies signed revocations.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/IEAS.sol

pragma solidity 0.7.6;

/**
 * @dev A struct representing a single attestation.
 */
struct Attestation {
    // A unique identifier of the attestation.
    bytes32 uuid;
    // A unique identifier of the AO.
    bytes32 ao;
    // The recipient of the attestation.
    address recipient;
    // The attester/sender of the attestation.
    address attester;
    // The time when the attestation was created (Unix timestamp).
    uint256 time;
    // The time when the attestation expires (Unix timestamp).
    uint256 expirationTime;
    // The time when the attestation was revoked (Unix timestamp).
    uint256 revocationTime;
    // The UUID of the related attestation.
    bytes32 refUUID;
    // Custom attestation data.
    bytes data;
}

/**
 * @title EAS - Ethereum Attestation Service interface
 */
interface IEAS {
    /**
     * @dev Triggered when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uuid The UUID the revoked attestation.
     * @param ao The UUID of the AO.
     */
    event Attested(address indexed recipient, address indexed attester, bytes32 indexed uuid, bytes32 ao);

    /**
     * @dev Triggered when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param ao The UUID of the AO.
     * @param uuid The UUID the revoked attestation.
     */
    event Revoked(address indexed recipient, address indexed attester, bytes32 indexed uuid, bytes32 ao);

    /**
     * @dev Returns the address of the AO global registry.
     *
     * @return The address of the AO global registry.
     */
    function getAORegistry() external view returns (IAORegistry);

    /**
     * @dev Returns the address of the EIP712 verifier used to verify signed attestations.
     *
     * @return The address of the EIP712 verifier used to verify signed attestations.
     */
    function getEIP712Verifier() external view returns (IEIP712Verifier);

    /**
     * @dev Returns the global counter for the total number of attestations.
     *
     * @return The global counter for the total number of attestations.
     */
    function getAttestationsCount() external view returns (uint256);

    /**
     * @dev Attests to a specific AO.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     *
     * @return The UUID of the new attestation.
     */
    function attest(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) external payable returns (bytes32);

    /**
     * @dev Attests to a specific AO using a provided EIP712 signature.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     *
     * @return The UUID of the new attestation.
     */
    function attestByDelegation(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes32);

    /**
     * @dev Revokes an existing attestation to a specific AO.
     *
     * @param uuid The UUID of the attestation to revoke.
     */
    function revoke(bytes32 uuid) external;

    /**
     * @dev Attests to a specific AO using a provided EIP712 signature.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns an existing attestation by UUID.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(bytes32 uuid) external view returns (Attestation memory);

    /**
     * @dev Checks whether an attestation exists.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(bytes32 uuid) external view returns (bool);

    /**
     * @dev Returns all received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 ao,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     *
     * @return The number of attestations.
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 ao) external view returns (uint256);

    /**
     * @dev Returns all sent attestation UUIDs.
     *
     * @param attester The attesting account.
     * @param ao The UUID of the AO.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 ao,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of sent attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     *
     * @return The number of attestations.
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 ao) external view returns (uint256);

    /**
     * @dev Returns all attestations related to a specific attestation.
     *
     * @param uuid The UUID of the attestation to retrieve.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of related attestation UUIDs.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The number of related attestations.
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid) external view returns (uint256);
}


// File contracts/EAS.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title EAS - Ethereum Attestation Service
 */
contract EAS is IEAS {
    string public constant VERSION = "0.3";

    // A terminator used when concatenating and hashing multiple fields.
    string private constant HASH_TERMINATOR = "@";

    // The AO global registry.
    IAORegistry private immutable _aoRegistry;

    // The EIP712 verifier used to verify signed attestations.
    IEIP712Verifier private immutable _eip712Verifier;

    // A mapping between attestations and their corresponding attestations.
    mapping(bytes32 => bytes32[]) private _relatedAttestations;

    // A mapping between an account and its received attestations.
    mapping(address => mapping(bytes32 => bytes32[])) private _receivedAttestations;

    // A mapping between an account and its sent attestations.
    mapping(address => mapping(bytes32 => bytes32[])) private _sentAttestations;

    // The global mapping between attestations and their UUIDs.
    mapping(bytes32 => Attestation) private _db;

    // The global counter for the total number of attestations.
    uint256 private _attestationsCount;

    /**
     * @dev Creates a new EAS instance.
     *
     * @param registry The address of the global AO registry.
     * @param verifier The address of the EIP712 verifier.
     */
    constructor(IAORegistry registry, IEIP712Verifier verifier) {
        require(address(registry) != address(0x0), "ERR_INVALID_REGISTRY");
        require(address(verifier) != address(0x0), "ERR_INVALID_EIP712_VERIFIER");

        _aoRegistry = registry;
        _eip712Verifier = verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getAORegistry() external view override returns (IAORegistry) {
        return _aoRegistry;
    }

    /**
     * @inheritdoc IEAS
     */
    function getEIP712Verifier() external view override returns (IEIP712Verifier) {
        return _eip712Verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestationsCount() external view override returns (uint256) {
        return _attestationsCount;
    }

    /**
     * @inheritdoc IEAS
     */
    function attest(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) public payable virtual override returns (bytes32) {
        return _attest(recipient, ao, expirationTime, refUUID, data, msg.sender);
    }

    /**
     * @inheritdoc IEAS
     */
    function attestByDelegation(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual override returns (bytes32) {
        _eip712Verifier.attest(recipient, ao, expirationTime, refUUID, data, attester, v, r, s);

        return _attest(recipient, ao, expirationTime, refUUID, data, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function revoke(bytes32 uuid) public virtual override {
        return _revoke(uuid, msg.sender);
    }

    /**
     * @inheritdoc IEAS
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        _eip712Verifier.revoke(uuid, attester, v, r, s);

        _revoke(uuid, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestation(bytes32 uuid) external view override returns (Attestation memory) {
        return _db[uuid];
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationValid(bytes32 uuid) public view override returns (bool) {
        return _db[uuid].uuid != 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 ao,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return _sliceUUIDs(_receivedAttestations[recipient][ao], start, length, reverseOrder);
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 ao) external view override returns (uint256) {
        return _receivedAttestations[recipient][ao].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 ao,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return _sliceUUIDs(_sentAttestations[attester][ao], start, length, reverseOrder);
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 ao) external view override returns (uint256) {
        return _sentAttestations[recipient][ao].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return _sliceUUIDs(_relatedAttestations[uuid], start, length, reverseOrder);
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid) external view override returns (uint256) {
        return _relatedAttestations[uuid].length;
    }

    /**
     * @dev Attests to a specific AO.
     *
     * @param recipient The recipient of the attestation.
     * @param ao The UUID of the AO.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     *
     * @return The UUID of the new attestation.
     */
    function _attest(
        address recipient,
        bytes32 ao,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester
    ) private returns (bytes32) {
        require(expirationTime > block.timestamp, "ERR_INVALID_EXPIRATION_TIME");

        AORecord memory aoRecord = _aoRegistry.getAO(ao);
        require(aoRecord.uuid != EMPTY_UUID, "ERR_INVALID_AO");
        require(
            address(aoRecord.verifier) == address(0x0) ||
                aoRecord.verifier.verify(recipient, aoRecord.schema, data, expirationTime, attester, msg.value),
            "ERR_INVALID_ATTESTATION_DATA"
        );

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            ao: ao,
            recipient: recipient,
            attester: attester,
            time: block.timestamp,
            expirationTime: expirationTime,
            revocationTime: 0,
            refUUID: refUUID,
            data: data
        });

        bytes32 uuid = _getUUID(attestation);
        attestation.uuid = uuid;

        _receivedAttestations[recipient][ao].push(uuid);
        _sentAttestations[attester][ao].push(uuid);

        _db[uuid] = attestation;
        _attestationsCount++;

        if (refUUID != 0) {
            require(isAttestationValid(refUUID), "ERR_NO_ATTESTATION");
            _relatedAttestations[refUUID].push(uuid);
        }

        emit Attested(recipient, attester, uuid, ao);

        return uuid;
    }

    /**
     * @dev Revokes an existing attestation to a specific AO.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     */
    function _revoke(bytes32 uuid, address attester) private {
        Attestation storage attestation = _db[uuid];
        require(attestation.uuid != EMPTY_UUID, "ERR_NO_ATTESTATION");
        require(attestation.attester == attester, "ERR_ACCESS_DENIED");
        require(attestation.revocationTime == 0, "ERR_ALREADY_REVOKED");

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, attester, uuid, attestation.ao);
    }

    /**
     * @dev Calculates a UUID for a given attestation.
     *
     * @param attestation The input attestation.
     *
     * @return Attestation UUID.
     */
    function _getUUID(Attestation memory attestation) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    attestation.ao,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.expirationTime,
                    attestation.data,
                    HASH_TERMINATOR,
                    _attestationsCount
                )
            );
    }

    /**
     * @dev Returns a slice in an array of attestation UUIDs.
     *
     * @param uuids The array of attestation UUIDs.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function _sliceUUIDs(
        bytes32[] memory uuids,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) private pure returns (bytes32[] memory) {
        uint256 attestationsLength = uuids.length;
        if (attestationsLength == 0) {
            return new bytes32[](0);
        }

        require(start < attestationsLength, "ERR_INVALID_OFFSET");

        uint256 len = length;
        if (attestationsLength < start + length) {
            len = attestationsLength - start;
        }

        bytes32[] memory res = new bytes32[](len);

        for (uint256 i = 0; i < len; ++i) {
            res[i] = uuids[reverseOrder ? attestationsLength - (start + i + 1) : start + i];
        }

        return res;
    }
}