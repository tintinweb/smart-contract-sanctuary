pragma solidity ^0.4.8;

// 8D806FF01FFBE3374D34C8EC57BE9B1DA7188DF639478D37E4447DE430BA6BF4
contract TrustedDocument {

    // Data structure for keeping document signatures and metadata.
    // String data types are used because its easier to read by humans 
    // without need of decoding, gas price is less important.
    struct Document {
        // Id of the document, starting at 1
        // 0 reserved for undefined / not found indicator
        uint documentId;

        // File name
        string fileName;

        // Hash of the main file
        string documentContentSHA256;

        // Hash of file containing extra metadata.
        // Secured same way as content of the file 
        // size to save gas on transactions.
        string documentMetadataSHA256;

        // IPFS hash of directory containing the document and metadata binaries.
        // Hash of the directory is build as merkle tree, so any change
        // to any of the files in folder will invalidate this hash.
        // So there is no need to keep IPFS hash for each single file.
        string IPFSdirectoryHash;

        // Block number
        uint blockNumber;

        // Document validity begin date, claimed by
        // publisher. Documents can be published
        // before they become valid, or in some
        // cases later.
        uint validFrom;

        // Optional valid date to if relevant
        uint validTo;

        // Reference to document update. Document
        // can be updated/replaced, but such update 
        // history cannot be hidden and it is 
        // persistant and auditable by everyone.
        // Update can address document itself aswell
        // as only metadata, where documentContentSHA256
        // stays same between updates - it can be
        // compared between versions.
        // This works as one way linked list
        uint updatedVersionId;
    }

    // Owner of the contract
    address public owner;

    // Needed for keeping new version address.
    // If 0, then this contract is up to date.
    // If not 0, no documents can be added to 
    // this version anymore. Contract becomes 
    // retired and documents are read only.
    address public upgradedVersion;

    // Total count of signed documents
    uint public documentsCount;

    // URLwith documents / GUI
    string public baseUrl;

    // Map of signed documents
    mapping(uint => Document) private documents;

    // Event for confirmation of adding new document
    event EventDocumentAdded(uint indexed documentId);

    // Event for updating document
    event EventDocumentUpdated(uint indexed referencingDocumentId, uint indexed updatedDocumentId);
    
    // Event for going on retirement
    event Retired(address indexed upgradedVersion);

    // Restricts call to owner
    modifier onlyOwner() {
        if (msg.sender == owner) 
        _;
    }

    // Restricts call only when this version is up to date == upgradedVersion is not set to a new address
    // or in other words, equal to 0
    modifier ifNotRetired() {
        if (upgradedVersion == 0) 
        _;
    } 

    // Constructor
    constructor() public {
        owner = msg.sender;
        baseUrl = "_";
    }

    // Enables to transfer ownership. Works even after
    // retirement. No documents can be added, but some
    // other tasks still can be performed.
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Adds new document - only owner and if not retired
    function addDocument(
        string _fileName,
        string _documentContentSHA256, 
        string _documentMetadataSHA256,
        string _IPFSdirectoryHash,  
        uint _validFrom, uint _validTo) public onlyOwner ifNotRetired {
        // Documents incremented before use so documents ids will
        // start with 1 not 0 (shifter by 1)
        // 0 is reserved as undefined value
        uint documentId = documentsCount+1;
        //
        emit EventDocumentAdded(documentId);
        documents[documentId] = Document(
            documentId, 
            _fileName, 
            _documentContentSHA256, 
            _documentMetadataSHA256, 
            _IPFSdirectoryHash,
            block.number, 
            _validFrom, 
            _validTo, 
            0
        );
        documentsCount++;
    }

    // Gets total count of documents
    function getDocumentsCount() public view
    returns (uint)
    {
        return documentsCount;
    }

    // Retire if newer version will be available. To persist
    // integrity, address of newer version needs to be provided.
    // After retirement there is no way to add more documents.
    function retire(address _upgradedVersion) public onlyOwner ifNotRetired {
        // TODO - check if such contract exists
        upgradedVersion = _upgradedVersion;
        emit Retired(upgradedVersion);
    }

    // Gets document with ID
    function getDocument(uint _documentId) public view
    returns (
        uint documentId,
        string fileName,
        string documentContentSHA256,
        string documentMetadataSHA256,
        string IPFSdirectoryHash,
        uint blockNumber,
        uint validFrom,
        uint validTo,
        uint updatedVersionId
    ) {
        Document memory doc = documents[_documentId];
        return (
            doc.documentId, 
            doc.fileName, 
            doc.documentContentSHA256, 
            doc.documentMetadataSHA256, 
            doc.IPFSdirectoryHash,
            doc.blockNumber, 
            doc.validFrom, 
            doc.validTo, 
            doc.updatedVersionId
            );
    }

    // Gets document updatedVersionId with ID
    // 0 - no update for document
    function getDocumentUpdatedVersionId(uint _documentId) public view
    returns (uint) 
    {
        Document memory doc = documents[_documentId];
        return doc.updatedVersionId;
    }

    // Gets base URL so everyone will know where to seek for files storage / GUI.
    // Multiple URLS can be set in the string and separated by comma
    function getBaseUrl() public view
    returns (string) 
    {
        return baseUrl;
    }

    // Set base URL even on retirement. Files will have to be maintained
    // for a very long time, and for example domain name could change.
    // To manage this, owner should be able to set base url anytime
    function setBaseUrl(string _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    // Utility to help seek fo specyfied document
    function getFirstDocumentIdStartingAtValidFrom(uint _unixTimeFrom) public view
    returns (uint) 
    {
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (doc.validFrom>=_unixTimeFrom) {
                return i;
            }
        }
        return 0;
    }

    // Utility to help seek fo specyfied document
    function getFirstDocumentIdBetweenDatesValidFrom(uint _unixTimeStarting, uint _unixTimeEnding) public view
    returns (uint firstID, uint lastId) 
    {
        firstID = 0;
        lastId = 0;
        //
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (firstID==0) {
                if (doc.validFrom>=_unixTimeStarting) {
                    firstID = i;
                }
            } else {
                if (doc.validFrom<=_unixTimeEnding) {
                    lastId = i;
                }
            }
        }
        //
        if ((firstID>0)&&(lastId==0)&&(_unixTimeStarting<_unixTimeEnding)) {
            lastId = documentsCount;
        }
    }

    // Utility to help seek fo specyfied document
    function getDocumentIdWithContentHash(string _documentContentSHA256) public view
    returns (uint) 
    {
        bytes32 documentContentSHA256Keccak256 = keccak256(_documentContentSHA256);
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (keccak256(doc.documentContentSHA256)==documentContentSHA256Keccak256) {
                return i;
            }
        }
        return 0;
    }

    // Utility to help seek fo specyfied document
    function getDocumentIdWithIPFSdirectoryHash(string _IPFSdirectoryHash) public view
    returns (uint) 
    {
        bytes32 IPFSdirectoryHashSHA256Keccak256 = keccak256(_IPFSdirectoryHash);
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (keccak256(doc.IPFSdirectoryHash)==IPFSdirectoryHashSHA256Keccak256) {
                return i;
            }
        }
        return 0;
    }

    // Utility to help seek fo specyfied document
    function getDocumentIdWithName(string _fileName) public view
    returns (uint) 
    {
        bytes32 fileNameKeccak256 = keccak256(_fileName);
        for (uint i = 0; i < documentsCount; i++) {
            Document memory doc = documents[i];
            if (keccak256(doc.fileName)==fileNameKeccak256) {
                return i;
            }
        }
        return 0;
    }

    // To update document:
    // 1 - Add new version as ordinary document
    // 2 - Call this function to link old version with update
    function updateDocument(uint referencingDocumentId, uint updatedDocumentId) public onlyOwner ifNotRetired {
        Document storage referenced = documents[referencingDocumentId];
        Document memory updated = documents[updatedDocumentId];
        //
        referenced.updatedVersionId = updated.documentId;
        emit EventDocumentUpdated(referenced.updatedVersionId,updated.documentId);
    }
}