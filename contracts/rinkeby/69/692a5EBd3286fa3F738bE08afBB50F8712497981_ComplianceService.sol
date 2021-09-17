/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;
pragma abicoder v2;

contract ComplianceService {
    
    /**
    * @dev A struct representing a single attestation.
    */
    struct Attestation {
        // A unique identifier of the attestation.
        uint256 id;
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
        // Type of Document being attested.
        uint256 documentType;
        // Document hash of the document being attested.
        bytes32 docHash;
    }
    
    // A mapping between an account and its received attestation.
    mapping(address => mapping(uint256 => uint256)) private byRecipient;

    // A mapping between an account and its sent attestations.
    mapping(address => mapping(uint256 => uint256)) private byAttestor;
    
    // The global mapping between attestations and their IDs.
    mapping(uint256 => Attestation) private attestations;
    
    // The global counter for the total number of attestations.
    uint256 private attestationsCount;
    
    /**
     * @dev Triggered when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param docHash The has of the document being attested.
     * @param id The UUID the revoked attestation.
     */
    event Attested(address indexed recipient, address indexed attester, uint256 id, bytes32 indexed docHash);

    /**
     * @dev Triggered when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param docHash The hash of the document being attested.
     * @param id The UUID the revoked attestation.
     */
    event Revoked(address indexed recipient, address indexed attester, uint256 id, bytes32 indexed docHash);
    
    /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param expirationTime The expiration time of the attestation.
     * @param docHash The hash of the document being attested.
     * @param documentType The type of document being attested.
     * @return The UUID of the new attestation.
     */
    
    function attest(address recipient, uint256 expirationTime, uint256 documentType, bytes32 docHash ) external payable returns(uint256) {
        require(expirationTime > block.timestamp, "ERR_INVALID_EXPIRATION_TIME");
        attestationsCount++;
        
        Attestation memory attestation = Attestation({
           id: attestationsCount,
           recipient: recipient,
           attester: msg.sender,
           time: block.timestamp,
           expirationTime: expirationTime,
           revocationTime: 0,
           documentType: documentType,
           docHash: docHash
        });
        
        byRecipient[recipient][documentType] = attestationsCount;
        byAttestor[msg.sender][documentType] = attestationsCount;
        
        
        attestations[attestationsCount] = attestation;
        
        emit Attested(recipient, msg.sender, attestationsCount, docHash);
        
        return attestationsCount;
    }
    
    /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param id The ID of the attestation to revoke.
     */
    function revoke(uint256 id) external {
        Attestation storage attestation = attestations[id];
        require(attestation.attester == msg.sender, "ERR_ACCESS_DENIED");
        require(attestation.revocationTime == 0, "ERR_ALREADY_REVOKED");

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, msg.sender, id, attestation.docHash);
    }
    
    /**
     * @dev Returns an existing attestation by UUID.
     *
     * @param id The ID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(uint256 id) external view returns (Attestation memory) {
        return attestations[id];
    }

    
    /**
     * @dev Checks whether an attestation exists.
     *
     * @param id The ID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(uint256 id) external view returns (bool) {
        return attestations[id].revocationTime != 0;
    }


    function getAttestationByRecipient(address recipient, uint256 documentType) external view returns (Attestation memory) {
        return attestations[byRecipient[recipient][documentType]];
    }
    
}