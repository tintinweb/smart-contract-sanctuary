pragma solidity 0.4.20;

/**
* @title DocumentaryContract
*/
contract DocumentaryContract {

    // Owner of the contract    
    address owner;
    
    // Get the editor rights of an address
    mapping (address => bool) isEditor;

    // Total number of documents, starts with 1    
    uint128 doccnt;
    
    // Get the author of a document with a given docid
    mapping (uint128 => address) docauthor;		                    // docid => author
    
    // Get visibility of a document with a given docid
    mapping (uint128 => bool) isInvisible;		                    // docid => invisibility
    
    // Get the number of documents authored by an address
    mapping (address => uint32) userdoccnt;		                    // author => number docs of user
    
    // Get the document id that relates to the document number of a given address
    mapping (address => mapping (uint32 => uint128)) userdocid;		// author => (userdocid => docid)


    // Documents a new or modified document    
    event DocumentEvent (
        uint128 indexed docid,
        uint128 indexed refid,
        uint16 state,   // 0: original. Bit 1: edited
        uint doctime,
        address indexed author,
        string tags,
        string title,
        string text
    );

    // Documents a registration of a tag
    event TagEvent (
        uint128 docid,
        address indexed author,
        bytes32 indexed taghash,
        uint64 indexed channelid
    );

    // Documents the change of the visibility of a document 
    event InvisibleDocumentEvent (
        uint128 indexed docid,
        uint16 state    // 0: inactive. Bit 1: active
    );
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEditor {
        require(isEditor[msg.sender] == true);
        _;
    }

    modifier onlyAuthor(uint128 docid) {
        require(docauthor[docid] == msg.sender);
        _;
    }

    modifier onlyVisible(uint128 docid) {
        require(isInvisible[docid] == false);
        _;
    }

    modifier onlyInvisible(uint128 docid) {
        require(isInvisible[docid] == true);
        _;
    }

    function DocumentaryContract() public {
        owner = msg.sender;
        grantEditorRights(owner);
        doccnt = 1;
    }
    
    /**
    * @dev Grants editor rights to the passed address
    * @param user Address to obtain editor rights
    */
    function grantEditorRights(address user) public onlyOwner {
        isEditor[user] = true;
    }

    /**
    * @dev Revokes editor rights of the passed address
    * @param editor Address to revoke editor rights from
    */
    function revokeEditorRights(address editor) public onlyOwner {
        isEditor[editor] = false;
    }

    /**
    * @dev Adds a document to the blockchain
    * @param refid The document id to that the new document refers
    * @param doctime Timestamp of the creation of the document
    * @param taghashes Array containing the hashes of up to 5 tags
    * @param tags String containing the tags of the document
    * @param title String containing the title of the document
    * @param text String containing the text of the document
    */
    function documentIt(uint128 refid, uint64 doctime, bytes32[] taghashes, string tags, string title, string text) public {
        writeDocument(refid, 0, doctime, taghashes, tags, title, text);
    }
    
    /**
    * @dev Edits a document that is already present of the blockchain. The document is edited by writing a modified version to the blockchain
    * @param docid The document id of the document that is edited
    * @param doctime Timestamp of the edit of the document
    * @param taghashes Array containing the hashes of up to 5 tags
    * @param tags String containing the modified tags of the document
    * @param title String containing the modified title of the document
    * @param text String containing the modified text of the document
    */
    function editIt(uint128 docid, uint64 doctime, bytes32[] taghashes, string tags, string title, string text) public onlyAuthor(docid) onlyVisible(docid) {
        writeDocument(docid, 1, doctime, taghashes, tags, title, text);
    }

    /**
    * @dev Generic function that adds a document to the blockchain or modifies a document that already exists on the blockchain
    * @param refid The document id to that the new document refers
    * @param state The state of the document, if 0 a new document is written, if 1 an existing document is edited
    * @param doctime Timestamp of the creation of the document
    * @param taghashes Array containing the hashes of up to 5 tags
    * @param tags String containing the tags of the document
    * @param title String containing the title of the document
    * @param text String containing the text of the document
    */
    function writeDocument(uint128 refid, uint16 state, uint doctime, bytes32[] taghashes, string tags, string title, string text) internal {

        docauthor[doccnt] = msg.sender;
        userdocid[msg.sender][userdoccnt[msg.sender]] = doccnt;
        userdoccnt[msg.sender]++;
        
        DocumentEvent(doccnt, refid, state, doctime, msg.sender, tags, title, text);
        for (uint8 i=0; i<taghashes.length; i++) {
            if (i>=5) break;
            if (taghashes[i] != 0) TagEvent(doccnt, msg.sender, taghashes[i], 0);
        }
        doccnt++;
    }
    
    /**
    * @dev Markes the document with the passed id as invisible
    * @param docid Id of the document to be marked invisible
    */
    function makeInvisible(uint128 docid) public onlyEditor onlyVisible(docid) {
        isInvisible[docid] = true;
        InvisibleDocumentEvent(docid, 1);
    }

    /**
    * @dev Markes the document with the passed id as visible
    * @param docid Id of the document to be marked visible
    */
    function makeVisible(uint128 docid) public onlyEditor onlyInvisible(docid) {
        isInvisible[docid] = false;
        InvisibleDocumentEvent(docid, 0);
    }
    
    /**
    * @dev Returns the total number of documents on the blockchain
    * @return The total number of documents on the blockchain as uint128
    */
    function getDocCount() public view returns (uint128) {
        return doccnt;
    }

    /**
    * @dev Returns the total number of documents on the blockchain written by the passed user 
    * @param user Address of the user 
    * @return The total number of documents written by the passe user as uint32
    */
    function getUserDocCount(address user) public view returns (uint32) {
        return userdoccnt[user];
    }

    /**
    * @dev Returns the document id of the x-th document written by the passed user
    * @param user Address of the user
    * @param docnum Order number of the document 
    * @return The document id as uint128
    */
    function getUserDocId(address user, uint32 docnum) public view returns (uint128) {
        return userdocid[user][docnum];
    }
}