pragma solidity ^0.4.19; // solhint-disable-line

/**
  * Interface for contracts conforming to ERC-721: Non-Fungible Tokens
  * @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f397968796b3928b9a9c9e89969ddd909c">[email&#160;protected]</a>> (https://github.com/dete)
  */
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract LibraryToken is ERC721 {
  using SafeMath for uint256;

  /*** EVENTS ***/

  /**
    * @dev The Created event is fired whenever a new library comes into existence.
    */
  event Created(uint256 indexed _tokenId, string _language, string _name, address indexed _owner);

  /**
    * @dev The Sold event is fired whenever a token is sold.
    */
  event Sold(uint256 indexed _tokenId, address indexed _owner, uint256 indexed _price);

  /**
    * @dev The Bought event is fired whenever a token is bought.
    */
  event Bought(uint256 indexed _tokenId, address indexed _owner, uint256 indexed _price);

  /**
    * @dev Transfer event as defined in current draft of ERC721.
    */
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  /**
    * @dev Approval event as defined in current draft of ERC721.
    */
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  /**
    * @dev FounderSet event fired when founder is set.
    */
  event FounderSet(address indexed _founder, uint256 indexed _tokenId);




  /*** CONSTANTS ***/

  /**
    * @notice Name and symbol of the non-fungible token, as defined in ERC721.
    */
  string public constant NAME = "CryptoLibraries"; // solhint-disable-line
  string public constant SYMBOL = "CL"; // solhint-disable-line

  /**
    * @dev Increase tiers to deterine how much price have to be changed
    */
  uint256 private startingPrice = 0.002 ether;
  uint256 private developersCut = 0 ether;
  uint256 private TIER1 = 0.02 ether;
  uint256 private TIER2 = 0.5 ether;
  uint256 private TIER3 = 2.0 ether;
  uint256 private TIER4 = 5.0 ether;

  /*** STORAGE ***/

  /**
    * @dev A mapping from library IDs to the address that owns them.
    * All libraries have some valid owner address.
    */
  mapping (uint256 => address) public libraryIndexToOwner;

  /**
    * @dev A mapping from library IDs to the address that founder of library.
    */
  mapping (uint256 => address) public libraryIndexToFounder;

  /**
    * @dev A mapping from founder address to token count.
  */
  mapping (address => uint256) public libraryIndexToFounderCount;

  /**
    * @dev A mapping from owner address to count of tokens that address owns.
    * Used internally inside balanceOf() to resolve ownership count.
    */
  mapping (address => uint256) private ownershipTokenCount;

  /**
    * @dev A mapping from LibraryIDs to an address that has been approved to call
    * transferFrom(). Each Library can only have one approved address for transfer
    * at any time. A zero value means no approval is outstanding.
    */
  mapping (uint256 => address) public libraryIndexToApproved;

  /**
    * @dev A mapping from LibraryIDs to the price of the token.
    */
  mapping (uint256 => uint256) private libraryIndexToPrice;

  /**
    * @dev A mapping from LibraryIDs to the funds avaialble for founder.
    */
  mapping (uint256 => uint256) private libraryIndexToFunds;

  /**
    * The addresses of the owner that can execute actions within each roles.
    */
  address public owner;



  /*** DATATYPES ***/
  struct Library {
    string language;
    string name;
  }

  Library[] private libraries;



  /*** ACCESS MODIFIERS ***/

  /**
    * @dev Access modifier for owner functionality.
    */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
    * @dev Access modifier for founder of library.
    */
  modifier onlyFounder(uint256 _tokenId) {
    require(msg.sender == founderOf(_tokenId));
    _;
  }



  /*** CONSTRUCTOR ***/

  function LibraryToken() public {
    owner = msg.sender;
  }



  /*** PUBLIC FUNCTIONS ERC-721 COMPILANCE ***/

  /**
    * @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    * @param _to The address to be granted transfer approval. Pass address(0) to
    * clear all approvals.
    * @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    */
  function approve(
    address _to,
    uint256 _tokenId
  )
    public
  {
    // Caller can&#39;t be approver of request
    require(msg.sender != _to);

    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    libraryIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /**
    * For querying balance of a particular account
    * @param _owner The address for balance query
    * @return balance The number of tokens owned by owner
    */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /**
    * @dev Required for ERC-721 compliance.
    * @return bool
    */
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /**
    * For querying owner of token
    * @dev Required for ERC-721 compliance.
    * @param _tokenId The tokenID for owner inquiry
    * @return tokenOwner address of token owner
    */
  function ownerOf(uint256 _tokenId) public view returns (address tokenOwner) {
    tokenOwner = libraryIndexToOwner[_tokenId];
    require(tokenOwner != address(0));
  }

  /**
    * @notice Allow pre-approved user to take ownership of a token
    * @dev Required for ERC-721 compliance.
    * @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    */
  function takeOwnership(uint256 _tokenId) public {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    address newOwner = msg.sender;
    address oldOwner = libraryIndexToOwner[_tokenId];

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /**
    * totalSupply
    * For querying total numbers of tokens
    * @return total The total supply of tokens
    */
  function totalSupply() public view returns (uint256 total) {
    return libraries.length;
  }

  /**
    * transferFro
    * Third-party initiates transfer of token from address _from to address _to
    * @param _from The address for the token to be transferred from.
    * @param _to The address for the token to be transferred to.
    * @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

  /**
    * Owner initates the transfer of the token to another account
    * @param _to The address for the token to be transferred to.
    * @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    */
  function transfer(
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  /**
    * @dev Required for ERC-721 compliance.
    */
  function name() public pure returns (string) {
    return NAME;
  }

  /**
    * @dev Required for ERC-721 compliance.
    */
  function symbol() public pure returns (string) {
    return SYMBOL;
  }



  /*** PUBLIC FUNCTIONS ***/

  /**
    * @dev Creates a new Library with the given language and name.
    * @param _language The library language
    * @param _name The name of library/framework
    */
  function createLibrary(string _language, string _name) public onlyOwner {
    _createLibrary(_language, _name, address(this), address(0), 0, startingPrice);
  }

  /**
    * @dev Creates a new Library with the given language and name and founder address.
    * @param _language The library language
    * @param _name The name of library/framework
    * @param _founder The founder of library/framework
    */
  function createLibraryWithFounder(string _language, string _name, address _founder) public onlyOwner {
    require(_addressNotNull(_founder));
    _createLibrary(_language, _name, address(this), _founder, 0, startingPrice);
  }

  /**
    * @dev Creates a new Library with the given language and name and owner address and starting price.
    * Itd be used for various bounties prize.
    * @param _language The library language
    * @param _name The name of library/framework
    * @param _owner The owner of library token
    * @param _startingPrice The starting price of library token
    */
  function createLibraryBounty(string _language, string _name, address _owner, uint256 _startingPrice) public onlyOwner {
    require(_addressNotNull(_owner));
    _createLibrary(_language, _name, _owner, address(0), 0, _startingPrice);
  }

  /**
    * @notice Returns all the relevant information about a specific library.
    * @param _tokenId The tokenId of the library of interest.
    */
  function getLibrary(uint256 _tokenId) public view returns (
    string language,
    string libraryName,
    uint256 tokenPrice,
    uint256 funds,
    address tokenOwner,
    address founder
  ) {
    Library storage x = libraries[_tokenId];
    libraryName = x.name;
    language = x.language;
    founder = libraryIndexToFounder[_tokenId];
    funds = libraryIndexToFunds[_tokenId];
    tokenPrice = libraryIndexToPrice[_tokenId];
    tokenOwner = libraryIndexToOwner[_tokenId];
  }

  /**
    * For querying price of token
    * @param _tokenId The tokenID for owner inquiry
    * @return _price The current price of token
    */
  function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
    return libraryIndexToPrice[_tokenId];
  }

  /**
    * For querying next price of token
    * @param _tokenId The tokenID for owner inquiry
    * @return _nextPrice The next price of token
    */
  function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_tokenId));
  }

  /**
    * For querying founder of library
    * @param _tokenId The tokenID for founder inquiry
    * @return _founder The address of library founder
    */
  function founderOf(uint256 _tokenId) public view returns (address _founder) {
    _founder = libraryIndexToFounder[_tokenId];
    require(_founder != address(0));
  }

  /**
    * For querying founder funds of library
    * @param _tokenId The tokenID for founder inquiry
    * @return _funds The funds availale for a fo
    */
  function fundsOf(uint256 _tokenId) public view returns (uint256 _funds) {
    _funds = libraryIndexToFunds[_tokenId];
  }

  /**
    * For querying next price of token
    * @param _price The token actual price
    * @return _nextPrice The next price
    */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < TIER1) {
      return _price.mul(200).div(95);
    } else if (_price < TIER2) {
      return _price.mul(135).div(96);
    } else if (_price < TIER3) {
      return _price.mul(125).div(97);
    } else if (_price < TIER4) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

  /**
    * For querying developer&#39;s cut which is left in the contract by `purchase`
    * @param _price The token actual price
    * @return _devCut The developer&#39;s cut
    */
  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < TIER1) {
      return _price.mul(5).div(100); // 5%
    } else if (_price < TIER2) {
      return _price.mul(4).div(100); // 4%
    } else if (_price < TIER3) {
      return _price.mul(3).div(100); // 3%
    } else if (_price < TIER4) {
      return _price.mul(3).div(100); // 3%
    } else {
      return _price.mul(2).div(100); // 2%
    }
  }

  /**
    * For querying founder cut which is left in the contract by `purchase`
    * @param _price The token actual price
    */
  function calculateFounderCut (uint256 _price) public pure returns (uint256 _founderCut) {
    return _price.mul(1).div(100);
  }

  /**
    * @dev This function withdrawing all of developer&#39;s cut which is left in the contract by `purchase`.
    * User funds are immediately sent to the old owner in `purchase`, no user funds are left in the contract
    * expect funds that stay in the contract that are waiting to be sent to a founder of a library when we would assign him.
    */
  function withdrawAll () onlyOwner() public {
    owner.transfer(developersCut);
    // Set developersCut to 0 to reset counter of possible funds
    developersCut = 0;
  }

  /**
    * @dev This function withdrawing selected amount of developer&#39;s cut which is left in the contract by `purchase`.
    * User funds are immediately sent to the old owner in `purchase`, no user funds are left in the contract
    * expect funds that stay in the contract that are waiting to be sent to a founder of a library when we would assign him.
    * @param _amount The amount to withdraw
    */
  function withdrawAmount (uint256 _amount) onlyOwner() public {
    require(_amount >= developersCut);

    owner.transfer(_amount);
    developersCut = developersCut.sub(_amount);
  }

    /**
    * @dev This function withdrawing selected amount of developer&#39;s cut which is left in the contract by `purchase`.
    * User funds are immediately sent to the old owner in `purchase`, no user funds are left in the contract
    * expect funds that stay in the contract that are waiting to be sent to a founder of a library when we would assign him.
    */
  function withdrawFounderFunds (uint256 _tokenId) onlyFounder(_tokenId) public {
    address founder = founderOf(_tokenId);
    uint256 funds = fundsOf(_tokenId);
    founder.transfer(funds);

    // Set funds to 0 after transfer since founder can only withdraw all funts
    libraryIndexToFunds[_tokenId] = 0;
  }

  /*
     Purchase a library directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All libraries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
  */
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = libraryIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    uint256 price = libraryIndexToPrice[_tokenId];
    require(msg.value >= price);

    uint256 excess = msg.value.sub(price);

    _transfer(oldOwner, newOwner, _tokenId);
    libraryIndexToPrice[_tokenId] = nextPriceOf(_tokenId);

    Bought(_tokenId, newOwner, price);
    Sold(_tokenId, oldOwner, price);

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmount` methods.
    uint256 devCut = calculateDevCut(price);
    developersCut = developersCut.add(devCut);

    // Founders cut which is left in contract and accesed by
    // `withdrawFounderFunds` methods.
    uint256 founderCut = calculateFounderCut(price);
    libraryIndexToFunds[_tokenId] = libraryIndexToFunds[_tokenId].add(founderCut);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(price.sub(devCut.add(founderCut)));
    }

    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

  /**
    * @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    * expensive (it walks the entire Cities array looking for cities belonging to owner),
    * but it also returns a dynamic array, which is only supported for web3 calls, and
    * not contract-to-contract calls.
    * @param _owner The owner whose library tokens we are interested in.
    * @return []ownerTokens The tokens of owner
    */
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalLibraries = totalSupply();
      uint256 resultIndex = 0;

      uint256 libraryId;
      for (libraryId = 0; libraryId <= totalLibraries; libraryId++) {
        if (libraryIndexToOwner[libraryId] == _owner) {
          result[resultIndex] = libraryId;
          resultIndex++;
        }
      }
      return result;
    }
  }

    /**
    * @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    * expensive (it walks the entire Cities array looking for cities belonging to owner),
    * but it also returns a dynamic array, which is only supported for web3 calls, and
    * not contract-to-contract calls.
    * @param _founder The owner whose library tokens we are interested in.
    * @return []founderTokens The tokens of owner
    */
  function tokensOfFounder(address _founder) public view returns(uint256[] founderTokens) {
    uint256 tokenCount = libraryIndexToFounderCount[_founder];
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalLibraries = totalSupply();
      uint256 resultIndex = 0;

      uint256 libraryId;
      for (libraryId = 0; libraryId <= totalLibraries; libraryId++) {
        if (libraryIndexToFounder[libraryId] == _founder) {
          result[resultIndex] = libraryId;
          resultIndex++;
        }
      }
      return result;
    }
  }


    /**
    * @dev 
    * @return []_libraries All tokens
    */
  function allTokens() public pure returns(Library[] _libraries) {
    return _libraries;
  }

  /**
    * @dev Assigns a new address to act as the Owner. Only available to the current Owner.
    * @param _newOwner The address of the new owner
    */
  function setOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    owner = _newOwner;
  }

    /**
    * @dev Assigns a new address to act as the founder of library to let him withdraw collected funds of his library.
    * @param _tokenId The id of a Token
    * @param _newFounder The address of the new owner
    */
  function setFounder(uint256 _tokenId, address _newFounder) public onlyOwner {
    require(_newFounder != address(0));

    address oldFounder = founderOf(_tokenId);

    libraryIndexToFounder[_tokenId] = _newFounder;
    FounderSet(_newFounder, _tokenId);

    libraryIndexToFounderCount[_newFounder] = libraryIndexToFounderCount[_newFounder].add(1);
    libraryIndexToFounderCount[oldFounder] = libraryIndexToFounderCount[oldFounder].sub(1);
  }



  /*** PRIVATE FUNCTIONS ***/

  /**
    * Safety check on _to address to prevent against an unexpected 0x0 default.
    * @param _to The address to validate if not null
    * @return bool The result of check
    */
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /**
    * For checking approval of transfer for address _to
    * @param _to The address to validate if approved
    * @param _tokenId The token id to validate if approved
    * @return bool The result of validation
    */
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return libraryIndexToApproved[_tokenId] == _to;
  }

  /**
    * Function to create a new Library
    * @param _language The language (etc. Python, JavaScript) of library
    * @param _name The name of library/framework (etc. Anguar, Redux, Flask)
    * @param _owner The current owner of Token
    * @param _founder The founder of library/framework
    * @param _funds The funds available to founder of library/framework
    * @param _price The current price of a Token
    */
  function _createLibrary(
    string _language,
    string _name,
    address _owner,
    address _founder,
    uint256 _funds,
    uint256 _price
  )
    private
  {
    Library memory _library = Library({
      name: _name,
      language: _language
    });
    uint256 newLibraryId = libraries.push(_library) - 1;

    Created(newLibraryId, _language, _name, _owner);

    libraryIndexToPrice[newLibraryId] = _price;
    libraryIndexToFounder[newLibraryId] = _founder;
    libraryIndexToFunds[newLibraryId] = _funds;

    // This will assign ownership, and also emit the Transfer event as per ERC721 draft
    _transfer(address(0), _owner, newLibraryId);
  }

  /**
    * Check for token ownership
    * @param claimant The claimant
    * @param _tokenId The token id to check claim
    * @return bool The result of validation
    */
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == libraryIndexToOwner[_tokenId];
  }

  /**
    * @dev Assigns ownership of a specific Library to an address.
    * @param _from The old owner of token
    * @param _to The new owner of token
    * @param _tokenId The id of token to change owner
    */
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of library is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);

    //transfer ownership
    libraryIndexToOwner[_tokenId] = _to;

    // When creating new libraries _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);

      // clear any previously approved ownership exchange
      delete libraryIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}