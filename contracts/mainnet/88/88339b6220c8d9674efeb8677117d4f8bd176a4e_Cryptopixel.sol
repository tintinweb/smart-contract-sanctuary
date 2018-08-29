pragma solidity 0.4.24;

contract Cryptopixel {

    // Name of token
    string constant public name = "CryptoPixel";
    // Symbol of Cryptopixel token
  	string constant public symbol = "CPX";


    using SafeMath for uint256;

    /////////////////////////
    // Variables
    /////////////////////////
    // Total number of stored artworks
    uint256 public totalSupply;
    // Group of artwork - 52 is limit
    address[limitChrt] internal artworkGroup;
    // Number of total artworks
    uint constant private limitChrt = 52;
    // This is address of artwork creator
    address constant private creatorAddr = 0x174B3C5f95c9F27Da6758C8Ca941b8FFbD01d330;

    
    // Basic references
    mapping(uint => address) internal tokenIdToOwner;
    mapping(address => uint[]) internal listOfOwnerTokens;
    mapping(uint => string) internal referencedMetadata;
    
    // Events
    event Minted(address indexed _to, uint256 indexed _tokenId);

    // Modifier
    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }


    /////////////////////////
    // Viewer Functions
    /////////////////////////
    // Get and returns the address currently marked as the owner of _tokenID. 
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }
    
    // Get and return the total supply of token held by this contract. 
    function totalSupply() public view returns (uint256 _totalSupply)
    {
        return totalSupply;
    }
    
    //Get and return the balance of token held by _owner. 
    function balanceOf(address _owner) public view returns (uint _balance)
    {
        return listOfOwnerTokens[_owner].length;
    }

    // Get and returns a metadata of _tokenId
    function tokenMetadata(uint _tokenId) public view returns (string _metadata)
    {
        return referencedMetadata[_tokenId];
    }
    
    // Retrive artworkGroup
    function getArtworkGroup() public view returns (address[limitChrt]) {
        return artworkGroup;
    }
    
    
    /////////////////////////
    // Update Functions
    /////////////////////////
    /**
     * @dev Public function to mint a new token with metadata
     * @dev Reverts if the given token ID already exists
     * @param _owner The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender(creator)
     * @param _metadata string of meta data, IPFS hash
     */
    function mintWithMetadata(address _owner, uint256 _tokenId, string _metadata) public onlyNonexistentToken (_tokenId)
    {
        require(totalSupply < limitChrt);
        require(creatorAddr == _owner);
        
        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);
        _insertTokenMetadata(_tokenId, _metadata);

        artworkGroup[_tokenId] = _owner;
        totalSupply = totalSupply.add(1);
        emit Minted(_owner, _tokenId);
    }

    /**
     * @dev Public function to add created token id in group
     * @param _owner The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender(creator)
     * @return _tokenId uint256 ID of the token 
     */
    function group(address _owner, uint _tokenId) public returns (uint) {
        require(_tokenId >= 0 && _tokenId <= limitChrt);
        artworkGroup[_tokenId] = _owner;    
        return _tokenId;
    }

    
    /////////////////////////
    // Internal, helper functions
    /////////////////////////
    function _setTokenOwner(uint _tokenId, address _owner) internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId) internal
    {
        listOfOwnerTokens[_owner].push(_tokenId);
    }

    function _insertTokenMetadata(uint _tokenId, string _metadata) internal
    {
        referencedMetadata[_tokenId] = _metadata;
    }
    
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}