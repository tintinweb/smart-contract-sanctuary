pragma solidity 0.4.25;

// File: openzeppelin-solidity/contracts/cryptography/ECDSA.sol

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

// File: contracts/Durium.sol

contract Durium {

    // ------------------------------------------------------------------------------------------ //
    // STRUCTS
    // ------------------------------------------------------------------------------------------ //
    
    // Defines a single document
    struct Document {
        uint documentId;       // id of the document
        string fileName;       // fileName of the document
        string contentHash;    // hash of document&#39;s content
        string location;       // location of the document
        uint blockNumber;      // number of the block in which the document was added
        uint validFrom;        // timestamp of when the document became valid
        uint validTo;          // document&#39;s expiration timestamp
        uint updatedVersionId; // if document was updated; new version of the document
    }

    // ------------------------------------------------------------------------------------------ //
    // MODIFIERS
    // ------------------------------------------------------------------------------------------ //

    // Restricts function use by veryfing given signature
    modifier onlyCorrectlySigned(string _methodName, bytes memory _methodArgument, bytes memory _signature) {
        bytes memory abiEncoded = abi.encode(actionId++, _methodName, _methodArgument);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(keccak256(abiEncoded));
        require(ECDSA.recover(ethSignedMessageHash, _signature) == owner, "Signature mismatch.");
        _;
    }

    // Restricts function use after contract&#39;s retirement
    modifier ifNotRetired() {
        require(upgradedVersion == address(0), "You cannot use that function because this contract is retired.");
        _;
    } 

    // ------------------------------------------------------------------------------------------ //
    // EVENTS
    // ------------------------------------------------------------------------------------------ //

    // An event emitted when a new document is published on the contract
    event DocumentAdded(uint indexed documentId);
    
    // An event emitted when the document gets updated
    event DocumentUpdated(uint indexed referencingDocumentId, uint indexed updatedDocumentId);
    
    // An event emitted when the contract gets retired
    event ContractRetired(address indexed upgradedVersion);

    // ------------------------------------------------------------------------------------------ //
    // FIELDS
    // ------------------------------------------------------------------------------------------ //

    address public upgradedVersion;              // if the contract gets retired; address of a new contract

    uint public actionId;                        // ID of the next action

    address public owner;                        // owner of the contract
    // (this address is checked in signature verification)

    string private baseUrl;                      // common part of the url, shared by all documents

    uint private documentsCount;                 // count of documents published on the contract
    mapping(uint => Document) private documents; // document storage

    // ------------------------------------------------------------------------------------------ //
    // CONSTRUCTOR
    // ------------------------------------------------------------------------------------------ //

    constructor(address _owner) public {
        owner = _owner;               // address given as a constructor parameter becomes the &#39;owner&#39;
        actionId = 0;                 // first actionId is 0
        baseUrl = "_";                // default baseUrl is &#39;_&#39;, but it can be freely changed by the owner
    }

    // ------------------------------------------------------------------------------------------ //
    // VIEW FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    // Returns the amount of documents on the contract
    function getDocumentsCount() public view
    returns (uint)
    {
        return documentsCount;
    }

    // Returns all information about a single document
    function getDocument(uint _documentId) public view
    returns (
        uint documentId,           // id of the document
        string memory fileName,    // fileName of the document
        string memory contentHash, // hash of document&#39;s content
        string memory location,    // location of the document
        uint blockNumber,          // number of the block in which the document was added
        uint validFrom,            // timestamp of when the document became valid
        uint validTo,              // document&#39;s expiration timestamp
        uint updatedVersionId      // if document was updated; new version of the document
    )
    {
        Document memory doc = documents[_documentId];
        return (
            doc.documentId, 
            doc.fileName, 
            doc.contentHash,
            doc.location,
            doc.blockNumber, 
            doc.validFrom, 
            doc.validTo, 
            doc.updatedVersionId
        );
    }

    // Gets the id of the new version of given document
    function getDocumentUpdatedVersionId(uint _documentId) public view
    returns (uint) 
    {
        Document memory doc = documents[_documentId];
        return doc.updatedVersionId;
    }

    // Gets the common part of the url shared by all documents
    function getBaseUrl() public view
    returns (string memory) 
    {
        return baseUrl;
    }

    // Gets the id of the document with given contentHash
    function getDocumentIdWithContentHash(string memory _contentHash) public view
    returns (uint) 
    {
        bytes32 contentHashKeccak256 = keccak256(bytes(_contentHash));
        for (uint i = 1; i < documentsCount + 1; i++) {
            Document memory doc = documents[i];
            if (keccak256(bytes(doc.contentHash)) == contentHashKeccak256) {
                return i;
            }
        }
        return 0;
    }

    // Gets the id of the document with given location
    function getDocumentIdWithLocation(string memory _location) public view
    returns (uint) 
    {
        bytes32 locationSHA256Keccak256 = keccak256(bytes(_location));
        for (uint i = 1; i < documentsCount + 1; i++) {
            Document memory doc = documents[i];
            if (keccak256(bytes(doc.location)) == locationSHA256Keccak256) {
                return i;
            }
        }
        return 0;
    }

    // Gets the id of the document with given name
    function getDocumentIdWithName(string memory _fileName) public view
    returns (uint) 
    {
        bytes32 fileNameKeccak256 = keccak256(bytes(_fileName));
        for (uint i = 1; i < documentsCount + 1; i++) {
            Document memory doc = documents[i];
            if (keccak256(bytes(doc.fileName)) == fileNameKeccak256) {
                return i;
            }
        }
        return 0;
    }

    // ------------------------------------------------------------------------------------------ //
    // STATE-CHANING FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    // Changes the contract owner
    function transferOwnership(address _newOwner, bytes memory _signature) public
    onlyCorrectlySigned("transferOwnership", abi.encode(_newOwner), _signature)
    {
        owner = _newOwner;
    }

    // Adds a new document
    function addDocument(
        string memory _fileName,
        string memory _contentHash,
        string memory _location,
        uint _validFrom,
        uint _validTo,
        bytes memory _signature
    ) public
    ifNotRetired
    onlyCorrectlySigned("addDocument", bytes(_contentHash), _signature)
    {
        uint documentId = documentsCount+1;
        emit DocumentAdded(documentId);
        documents[documentId] = Document(
            documentId, 
            _fileName, 
            _contentHash, 
            _location,
            block.number, 
            _validFrom, 
            _validTo, 
            0
        );
        documentsCount++;
    }

    // Retires this contract and saves the address of the new one
    function retire(address _upgradedVersion, bytes memory _signature) public
    ifNotRetired
    onlyCorrectlySigned("retire", abi.encode(_upgradedVersion), _signature)
    {
        upgradedVersion = _upgradedVersion;
        emit ContractRetired(upgradedVersion);
    }

    // Changes the base url
    function setBaseUrl(string memory _baseUrl, bytes memory _signature) public
    onlyCorrectlySigned("setBaseUrl", bytes(_baseUrl), _signature)
    {
        baseUrl = _baseUrl;
    }

    // Marks updated document as a new version of referencing document
    function updateDocument(uint _referencingDocumentId, uint _updatedDocumentId, bytes memory _signature) public
    ifNotRetired
    onlyCorrectlySigned("updateDocument", abi.encode(_referencingDocumentId), _signature)
    {
        Document storage referenced = documents[_referencingDocumentId];
        Document memory updated = documents[_updatedDocumentId];
        referenced.updatedVersionId = updated.documentId;
        emit DocumentUpdated(referenced.updatedVersionId, updated.documentId);
    }
}