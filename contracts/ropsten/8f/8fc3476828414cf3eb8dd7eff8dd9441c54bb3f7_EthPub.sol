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
    mapping(bytes32 => mapping(address => bytes32)) public ownerships; // content hash, content owner address, encrypted secret key
    mapping(bytes32 => Content) public contents; // content hash, Content (author, totalSupply, contentPath, contentSecret)

   struct Content {
       address author;
       uint256 totalSupply;
       string contentPath;
       bytes32 contentSecret;
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
    * @param _contentSecret bytes32 [key used for content encryption] encrypted by the author&#39;s secret key
    */
    function publish (bytes32 _contentHash, string _contentPath, bytes32 _contentSecret) public {
        require(contents[_contentHash].author == 0); // only if the content hash is not already used
        contents[_contentHash].author = msg.sender;
        contents[_contentHash].totalSupply = 0;
        contents[_contentHash].contentPath = _contentPath;
        contents[_contentHash].contentSecret = _contentSecret;
    }

    /**
    * @dev Issue a content ownership a specified account
    * @param _to address address of an account who will obtain ownership of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    * @param _key bytes32 a secret key encrypted by a new owner&#39;s public key
    */
    function issue(address _to, bytes32 _contentHash, bytes32 _key) public onlyAuthor(_contentHash) {
        require(ownerships[_contentHash][_to] == 0); // only if the _to already has ownership
        ownerships[_contentHash][_to] = _key; // set encrypted secret key
        contents[_contentHash].totalSupply += 1; // count up total number of issuance of the content
    }

    /**
    * @dev Transfer a content ownership from one to another account
    * @param _to address address of an account who will obtain ownership of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    * @param _key bytes32 a secret key encrypted by a new owner&#39;s public key
    */
    function transfer(address _to, bytes32 _contentHash, bytes32 _key) public {
        require(ownerships[_contentHash][msg.sender] != "");
        ownerships[_contentHash][msg.sender] = ""; // revoke old ownership
        ownerships[_contentHash][_to] = _key; // grant new ownership
    }

    /**
    * @dev Transfer a content authorship (right to issue content) from original author to another
    * @dev (It&#39;s rarely used)
    * @param _to address address of an account who will obtain authorship of the content
    * @param _contentHash bytes32 unique id of the content (it can be IPFS hash)
    * @param _secret bytes32 [key used for content encryption] encrypted by the new author&#39;s secret key
    */
    function transferAuthorship(address _to, bytes32 _contentHash, bytes32 _secret) public onlyAuthor(_contentHash) {
        contents[_contentHash].author = _to;
        contents[_contentHash].contentSecret = _secret;
    }

    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
}