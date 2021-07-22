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


// File contracts/AORegistry.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title The global AO registry.
 */
contract AORegistry is IAORegistry {
    string public constant VERSION = "0.3";

    // The global mapping between AO records and their IDs.
    mapping(bytes32 => AORecord) private _registry;

    // The global counter for the total number of attestations.
    uint256 private _aoCount;

    /**
     * @inheritdoc IAORegistry
     */
    function register(bytes calldata schema, IAOVerifier verifier) external override returns (bytes32) {
        uint256 index = ++_aoCount;

        AORecord memory ao = AORecord({uuid: EMPTY_UUID, index: index, schema: schema, verifier: verifier});

        bytes32 uuid = _getUUID(ao);
        require(_registry[uuid].uuid == EMPTY_UUID, "ERR_ALREADY_EXISTS");

        ao.uuid = uuid;
        _registry[uuid] = ao;

        emit Registered(uuid, index, schema, verifier, msg.sender);

        return uuid;
    }

    /**
     * @inheritdoc IAORegistry
     */
    function getAO(bytes32 uuid) external view override returns (AORecord memory) {
        return _registry[uuid];
    }

    /**
     * @inheritdoc IAORegistry
     */
    function getAOCount() external view override returns (uint256) {
        return _aoCount;
    }

    /**
     * @dev Calculates a UUID for a given AO.
     *
     * @param ao The input AO.
     *
     * @return AO UUID.
     */
    function _getUUID(AORecord memory ao) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(ao.schema, ao.verifier));
    }
}