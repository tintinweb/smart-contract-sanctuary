pragma solidity ^0.4.25;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnershipOfContract(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title DRM on Blockchain
 * @author Yoshikazu Nishimura, G.U.Lab
 * @dev Digital rights management on Blockchain
 * @dev A content will be stored on any accessible storage encrypted by a "common" key.
 * @dev The "common" key is encrypted by an author&#39;s secret key, and get a "secret" key.
 * @dev This "secret" key is stored on the blockchain, but nobody other than the author can recover it.
 * @dev If an account obtained ownership (right to access a content) will receive encrypted common key
 * @dev by encrypting the "common" key by the account&#39;s public key.
 * @dev The ownership granted account can recover the original "common" key by decrypting it by his private key,
 * @dev and decrypt the content by using the "common" key recovered to get the original readable content.
 */

contract EthPub is Ownable{
    mapping(bytes32 => mapping(address => bool)) public ownerships; // content hash, content owner address, encrypted secret key
    mapping(bytes32 => Content) public contents; // content hash, Content (author, totalSupply, contentPath, contentSecret)

    //mapping(address => uint256) authorNumContents;
    mapping(address => bytes32[]) private authorContents;
    mapping(address => mapping(bytes32 => uint256)) private authorContentIndex; // content hash, content owner address, encrypted secret key

    //mapping(address => uint256) userNumContents;
    mapping(address => bytes32[]) private userContents;
    mapping(address => mapping(bytes32 => uint256)) private userContentIndex; // content hash, content owner address, encrypted secret key

   struct Content {
       address author;
       uint256 totalSupply;
       uint256 price;
       string contentPath;
   }

    modifier onlyAuthor(bytes32 _contentHash) {
      require(contents[_contentHash].author == msg.sender);
      _;
    }

    constructor() public {}

    /**
    * @dev Newly publish a content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    * @param _contentPath string content path either of IPFS hash/path or web URL
    * @param _price uint256 price in Finney (milli ETH)
    */
    function publish (bytes32 _contentHash, string _contentPath, uint256 _price) public {
        require(contents[_contentHash].author == 0); // only if the content hash is not already used
        contents[_contentHash].author = msg.sender;
        contents[_contentHash].totalSupply = 0;
        contents[_contentHash].price = _price * 1 ether / 1000;
        contents[_contentHash].contentPath = _contentPath;
        authorContents[msg.sender].push(_contentHash);
    }
    
    /**
    * @dev Issue a content ownership a specified account
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    */
    function purchase(bytes32 _contentHash) public payable {
        require(msg.value >= contents[_contentHash].price);
        require(!ownerships[_contentHash][msg.sender]); // only if the _to already has ownership
        ownerships[_contentHash][msg.sender] = true; // set encrypted secret key
        userContents[msg.sender].push(_contentHash);
        userContentIndex[msg.sender][_contentHash] = userContents[msg.sender].length - 1;
        contents[_contentHash].totalSupply += 1; // count up total number of issuance of the content
    }    

    /**
    * @dev Issue a content ownership a specified account
    * @param _to address address of an account who will obtain ownership of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    */
    function issue(address _to, bytes32 _contentHash) public onlyAuthor(_contentHash) {
        require(!ownerships[_contentHash][_to]); // only if the _to already has ownership
        ownerships[_contentHash][_to] = true; // set encrypted secret key
        userContents[_to].push(_contentHash);
        userContentIndex[_to][_contentHash] = userContents[_to].length - 1;
        contents[_contentHash].totalSupply += 1; // count up total number of issuance of the content
    }

    /**
    * @dev Transfer a content ownership from one to another account
    * @param _to address address of an account who will obtain ownership of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    */
    function transfer(address _to, bytes32 _contentHash) public {
        require(ownerships[_contentHash][msg.sender]);
        ownerships[_contentHash][msg.sender] = false; // revoke old ownership
        userContents[msg.sender][userContentIndex[msg.sender][_contentHash]] = 0x0; // remove from list
        userContentIndex[msg.sender][_contentHash] = 0; // update index
        
        require(!ownerships[_contentHash][_to]);
        ownerships[_contentHash][_to] = true; // grant ownership
        userContents[_to].push(_contentHash); // add to list
        userContentIndex[_to][_contentHash] = userContents[_to].length - 1; // update index
    }
    
    /**
     * @dev Return number of publications (contents published by msg.sender)
     * @return numContents uint256 num of contents
    */
    function getNumPublications() public view returns (uint256 numContents) {
        return authorContents[msg.sender].length;
    }
    
    /**
     * @dev Return number of owned contents (contents published by msg.sender)
     * @return numContents uint256 num of contents
    */
    function getNumContents() public view returns (uint256 numContents) {
        return userContents[msg.sender].length;
    }
    
    /**
     * @dev Return content hash at the specified index of msg.sender&#39;s publications)
     * @return contentHash bytes32 content hash
    */
    function authorContentByIndex(uint256 _index) public view returns (bytes32 contentHash) {
        return authorContents[msg.sender][_index];
    }
    
    /**
     * @dev Return content hash at the specified index of contents msg.sender owns )
     * @return contentHash bytes32 content hash
    */
    function userContentByIndex(uint256 _index) public view returns (bytes32 contentHash) {
        return userContents[msg.sender][_index];
    }

    /**
    * @dev Transfer a content authorship (right to issue content) from original author to another
    * @dev (It&#39;s rarely used)
    * @param _to address address of an account who will obtain authorship of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    */
    function transferAuthorship(address _to, bytes32 _contentHash) public onlyAuthor(_contentHash) {
        contents[_contentHash].author = _to;
        authorContents[msg.sender][authorContentIndex[msg.sender][_contentHash]] = 0x0;
        authorContentIndex[msg.sender][_contentHash] = 0;
        authorContents[_to].push(_contentHash);
        authorContentIndex[_to][_contentHash] = authorContents[_to].length - 1;
    }

    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
}