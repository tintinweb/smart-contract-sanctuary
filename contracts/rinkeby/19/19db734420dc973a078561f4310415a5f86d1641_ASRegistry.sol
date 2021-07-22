/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/Types.sol

pragma solidity 0.7.6;

// A representation of an empty/uninitialized UUID.
bytes32 constant EMPTY_UUID = 0;


// File contracts/IASVerifier.sol

pragma solidity 0.7.6;

/**
 * @title The interface of an optional AS verifier, submitted via the global AS registry.
 */
interface IASVerifier {
    /**
     * @dev Verifies whether the specified attestation data conforms to the spec.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The AS data schema.
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


// File contracts/IASRegistry.sol

pragma solidity 0.7.6;

/**
 * @title A struct representing a record for a submitted AS (Attestation Object).
 */
struct ASRecord {
    // A unique identifier of the AS.
    bytes32 uuid;
    // Optional schema verifier.
    IASVerifier verifier;
    // Auto-incrementing index for reference, assigned by the registry itself.
    uint256 index;
    // Custom specification of the AS (e.g., an ABI).
    bytes schema;
}

/**
 * @title The global AS registry interface.
 */
interface IASRegistry {
    /**
     * @dev Triggered when a new AS has been registered
     *
     * @param uuid The AS UUID.
     * @param index The AS index.
     * @param schema The AS schema.
     * @param verifier An optional AS schema verifier.
     * @param attester The address of the account used to register the AS.
     */
    event Registered(bytes32 indexed uuid, uint256 indexed index, bytes schema, IASVerifier verifier, address attester);

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     * @param verifier An optional AS schema verifier.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema, IASVerifier verifier) external returns (bytes32);

    /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);

    /**
     * @dev Returns the global counter for the total number of attestations
     *
     * @return The global counter for the total number of attestations.
     */
    function getASCount() external view returns (uint256);
}


// File contracts/ASRegistry.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;



/**
 * @title The global AS registry.
 */
contract ASRegistry is IASRegistry {
    string public constant VERSION = "0.4";

    // The global mapping between AS records and their IDs.
    mapping(bytes32 => ASRecord) private _registry;

    // The global counter for the total number of attestations.
    uint256 private _asCount;

    /**
     * @inheritdoc IASRegistry
     */
    function register(bytes calldata schema, IASVerifier verifier) external override returns (bytes32) {
        uint256 index = ++_asCount;

        ASRecord memory asRecord = ASRecord({uuid: EMPTY_UUID, index: index, schema: schema, verifier: verifier});

        bytes32 uuid = _getUUID(asRecord);
        require(_registry[uuid].uuid == EMPTY_UUID, "ERR_ALREADY_EXISTS");

        asRecord.uuid = uuid;
        _registry[uuid] = asRecord;

        emit Registered(uuid, index, schema, verifier, msg.sender);

        return uuid;
    }

    /**
     * @inheritdoc IASRegistry
     */
    function getAS(bytes32 uuid) external view override returns (ASRecord memory) {
        return _registry[uuid];
    }

    /**
     * @inheritdoc IASRegistry
     */
    function getASCount() external view override returns (uint256) {
        return _asCount;
    }

    /**
     * @dev Calculates a UUID for a given AS.
     *
     * @param asRecord The input AS.
     *
     * @return AS UUID.
     */
    function _getUUID(ASRecord memory asRecord) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(asRecord.schema, asRecord.verifier));
    }
}