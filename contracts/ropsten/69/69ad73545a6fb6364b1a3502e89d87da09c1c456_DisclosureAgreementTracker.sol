pragma solidity 0.4.24;

/**
 * This contract is used to publish hashed contribution agreements for disclosures
 * already published in the DisclosureManager contract. These agreements require
 * multi party sign off which this contract facilitates.
 */
contract DisclosureAgreementTracker {

    /**
     * Represents a contribution agreement for a disclosure. An agreement is
     * referenced by the sha256 hash of its contract in `agreementMap`.
     */
    struct Agreement {
        // previous version of an agreement for this disclosure
        bytes32 previous;
        // index of the disclosure in disclosureManager
        uint disclosureIndex;
        // total signatures obtained so far
        uint signedCount;
        // addresses from which signatures are required
        address[] signatories;
        // map of signatory address to true, if signature not yet obtained
        mapping(address => bool) requiredSignatures;
    }

    /**
     * Tracks the latest agreement and total agreements for a disclosure.
     * Referenced by disclosure index in `latestAgreementMap`.
     */
    struct Latest {
        bytes32 agreementHash;
        uint agreementCount;
    }

    /** Contract creator */
    address public owner;

    /** Address of the DisclosureManager contract this tracks agreements for */
    address public disclosureManager;

    /** Map of agreements by contract sha256 hash */
    mapping(bytes32 => Agreement) public agreementMap;

    /** Map disclosure index to latest agreement */
    mapping(uint => Latest) public latestMap;

    /** Emitted when agreement is added */
    event agreementAdded(
        bytes32 agreementHash,
        uint disclosureIndex,
        address[] signatories);

    /** Emitted when agreement is signed */
    event agreementSigned(
        bytes32 agreementHash,
        uint disclosureIndex,
        address signatory);

    /** Emitted when an agreement is signed by all signatories */
    event agreementFullySigned(
        bytes32 agreementHash,
        uint disclosureIndex);

    constructor(address disclosureManagerAddress) public {
        owner = msg.sender;
        disclosureManager = disclosureManagerAddress;
    }

    /** Enforce function caller is contract owner */
    modifier isOwner() {
        if (msg.sender != owner) revert("sender must be owner");
        _;
    }

    function _agreementExists(Agreement agreement) private pure returns(bool) {
        return agreement.disclosureIndex != 0;
    }

    /** Return true if the agreement exists */
    function agreementExists(bytes32 agreementHash) public view returns(bool) {
        return _agreementExists(agreementMap[agreementHash]);
    }

    /** Return true if the disclosure has an agreement */
    function hasAgreement(uint disclosureIndex) public view returns(bool) {
        return latestMap[disclosureIndex].agreementCount != 0;
    }
    
    function _isAgreementSigned(Agreement agreement)
    private pure returns(bool) {
        return agreement.signedCount == agreement.signatories.length;
    }

    /** Return true if the agreement exists and is fully signed */
    function isAgreementSigned(bytes32 agreementHash)
    public view returns(bool) {
        Agreement storage agreement = agreementMap[agreementHash];
        return _agreementExists(agreement) && _isAgreementSigned(agreement);
    }
    
    /** Return true if disclosures latest agreement is fully signed. */
    function isDisclosureSigned(uint disclosureIndex)
    public view returns(bool) {
        return isAgreementSigned(
            latestMap[disclosureIndex].agreementHash
        );
    }

    /**
     * Add an agreement for the provided disclosure. If an agreement already
     * exists that disclosures latestAgreement will be updated and
     * the existing agreement will not be removed.
     */
    function addAgreement(
        bytes32 agreementHash,
        uint disclosureIndex,
        address[] signatories
    ) public isOwner {
        require(disclosureIndex > 0, "disclosureIndex must be greater than 0");
        require(agreementHash != 0, "agreementHash must not be 0");
        require(signatories.length > 0, "signatories must not be empty");

        Agreement storage agreement = agreementMap[agreementHash];
        agreement.disclosureIndex = disclosureIndex;
        agreement.signatories = signatories;

        Latest storage latest = latestMap[disclosureIndex];
        agreement.previous = latest.agreementHash;
        latest.agreementHash = agreementHash;
        latest.agreementCount++;

        for (uint i = 0; i < signatories.length; i++) {
            address signatory = signatories[i];
            if (agreement.requiredSignatures[signatory]) {
                revert("signatories must not contain duplicates");
            }
            agreement.requiredSignatures[signatory] = true;
        }

        emit agreementAdded(agreementHash, disclosureIndex, signatories);
    }

    /**
     * Sign an agreement.
     * Returns true if signature applied, false if not a signatory or already
     * signed.
     */
    function signAgreement(bytes32 agreementHash) public returns(bool signed) {
        require(agreementExists(agreementHash), "agreeement must exist");
        Agreement storage agreement = agreementMap[agreementHash];
        signed = agreement.requiredSignatures[msg.sender];
        if (signed) {
            agreement.requiredSignatures[msg.sender] = false;
            agreement.signedCount++;
            
            emit agreementSigned(
                agreementHash,
                agreement.disclosureIndex,
                msg.sender);
                
            if (_isAgreementSigned(agreement)) {
                emit agreementFullySigned(
                    agreementHash,
                    agreement.disclosureIndex);
            }
        }
    }

    /** This contract does not accept payments */
    function () public payable {
        revert("payment not supported");
    }

}