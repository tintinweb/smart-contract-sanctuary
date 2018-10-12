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
        // block this agreement was created in
        uint blockNumber;
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

    /** Address of the DisclosureManager contract these agreements apply to */
    address public disclosureManager;

    /** Total agreements tracked */
    uint public agreementCount;

    /** Total disclosures with agreements */
    uint public disclosureCount;

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

    function _hasAgreement(Agreement agreement) private pure returns(bool) {
        return agreement.disclosureIndex != 0;
    }

    /** Return true if the agreement exists */
    function hasAgreement(bytes32 agreementHash) public view returns(bool) {
        return _hasAgreement(agreementMap[agreementHash]);
    }

    function _hasDisclosureAgreement(Latest latest) private pure returns(bool) {
        return latest.agreementCount != 0;
    }

    /** Return true if the disclosure has an agreement */
    function hasDisclosureAgreement(uint disclosureIndex) public view returns(bool) {
        return _hasDisclosureAgreement(latestMap[disclosureIndex]);
    }

    function _isAgreementFullySigned(Agreement agreement)
    private pure returns(bool) {
        return agreement.signedCount == agreement.signatories.length;
    }

    /** Return true if the agreement exists and is fully signed */
    function isAgreementFullySigned(bytes32 agreementHash)
    public view returns(bool) {
        Agreement storage agreement = agreementMap[agreementHash];
        return _hasAgreement(agreement)
            && _isAgreementFullySigned(agreement);
    }

    /** Return true if disclosures latest agreement is fully signed. */
    function isDisclosureFullySigned(uint disclosureIndex)
    public view returns(bool) {
        return isAgreementFullySigned(
            latestMap[disclosureIndex].agreementHash
        );
    }
    
    /**
     * Get the Agreement requiredSignatures map as an array of bools parallel
     * to its signatories array.
     */
    function _getRequiredSignaturesArray(Agreement storage agreement)
    private view returns (bool[]) {
        address[] storage signatories = agreement.signatories;
        bool[] memory requiredSignatureArray = new bool[](signatories.length);
        for (uint i = 0; i < signatories.length; i++) {
            address signatory = signatories[i];
            requiredSignatureArray[i] = agreement.requiredSignatures[signatory];
        }
        return requiredSignatureArray;
    }

    /** Get the agreement with the provided hash */
    function getAgreement(bytes32 agreementHash)
    public view returns(
        bytes32 previous, uint disclosureIndex, uint blockNumber,
        uint signedCount, address[] signatories, bool[] requiredSignatures
    ) {
        Agreement storage agreement = agreementMap[agreementHash];
        previous = agreement.previous;
        disclosureIndex = agreement.disclosureIndex;
        blockNumber = agreement.blockNumber;
        signedCount = agreement.signedCount;
        signatories = agreement.signatories;
        requiredSignatures = _getRequiredSignaturesArray(agreement);
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
        if (_hasAgreement(agreement)) {
            revert("Agreement already exists");
        }
        agreementCount++;
        agreement.disclosureIndex = disclosureIndex;
        agreement.blockNumber = block.number;
        agreement.signatories = signatories;

        Latest storage latest = latestMap[disclosureIndex];
        if (!_hasDisclosureAgreement(latest)) {
            disclosureCount++;
        }
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
    function signAgreement(bytes32 agreementHash) public {
        require(hasAgreement(agreementHash), "agreeement must exist");

        Agreement storage agreement = agreementMap[agreementHash];
        bool signed = agreement.requiredSignatures[msg.sender];
        require(signed, "sender already signed or not a signatory");

        agreement.requiredSignatures[msg.sender] = false;
        agreement.signedCount++;

        emit agreementSigned(
            agreementHash,
            agreement.disclosureIndex,
            msg.sender);

        if (_isAgreementFullySigned(agreement)) {
            emit agreementFullySigned(
                agreementHash,
                agreement.disclosureIndex);
        }
    }

    /** This contract does not accept payments */
    function () public payable {
        revert("payment not supported");
    }

}