pragma solidity ^0.4.18;


contract InterfaceContentCreatorUniverse {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function priceOf(uint256 _tokenId) public view returns (uint256 price);
  function getNextPrice(uint price, uint _tokenId) public pure returns (uint);
  function lastSubTokenBuyerOf(uint tokenId) public view returns(address);
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address);

  //
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external ;
}

contract InterfaceYCC {
  function payForUpgrade(address user, uint price) external  returns (bool success);
  function mintCoinsForOldCollectibles(address to, uint256 amount, address universeOwner) external  returns (bool success);
  function tradePreToken(uint price, address buyer, address seller, uint burnPercent, address universeOwner) external;
  function payoutForMining(address user, uint amount) external;
  uint256 public totalSupply;
}

contract InterfaceMining {
  function createMineForToken(uint tokenId, uint level, uint xp, uint nextLevelBreak, uint blocknumber) external;
  function payoutMining(uint tokenId, address owner, address newOwner) external;
  function levelUpMining(uint tokenId) external;
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

contract Owned {
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  address private newCeoAddress;
  address private newCooAddress;


  function Owned() public {
      ceoAddress = msg.sender;
      cooAddress = msg.sender;
  }

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    newCeoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    newCooAddress = _newCOO;
  }

  function acceptCeoOwnership() public {
      require(msg.sender == newCeoAddress);
      require(address(0) != newCeoAddress);
      ceoAddress = newCeoAddress;
      newCeoAddress = address(0);
  }

  function acceptCooOwnership() public {
      require(msg.sender == newCooAddress);
      require(address(0) != newCooAddress);
      cooAddress = newCooAddress;
      newCooAddress = address(0);
  }

  mapping (address => bool) public youCollectContracts;
  function addYouCollectContract(address contractAddress, bool active) public onlyCOO {
    youCollectContracts[contractAddress] = active;
  }
  modifier onlyYCC() {
    require(youCollectContracts[msg.sender]);
    _;
  }

  InterfaceYCC ycc;
  InterfaceContentCreatorUniverse yct;
  InterfaceMining ycm;
  function setMainYouCollectContractAddresses(address yccContract, address yctContract, address ycmContract, address[] otherContracts) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    yct = InterfaceContentCreatorUniverse(yctContract);
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[yccContract] = true;
    youCollectContracts[yctContract] = true;
    youCollectContracts[ycmContract] = true;
    for (uint16 index = 0; index < otherContracts.length; index++) {
      youCollectContracts[otherContracts[index]] = true;
    }
  }
  function setYccContractAddress(address yccContract) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    youCollectContracts[yccContract] = true;
  }
  function setYctContractAddress(address yctContract) public onlyCOO {
    yct = InterfaceContentCreatorUniverse(yctContract);
    youCollectContracts[yctContract] = true;
  }
  function setYcmContractAddress(address ycmContract) public onlyCOO {
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[ycmContract] = true;
  }

}

contract TransferInterfaceERC721YC {
  function transferToken(address to, uint256 tokenId) public returns (bool success);
}
contract TransferInterfaceERC20 {
  function transfer(address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20.sol
// ----------------------------------------------------------------------------
contract YouCollectBase is Owned {
  using SafeMath for uint256;

  event RedButton(uint value, uint totalSupply);

  // Payout
  function payout(address _to) public onlyCLevel {
    _payout(_to, this.balance);
  }
  function payout(address _to, uint amount) public onlyCLevel {
    if (amount>this.balance)
      amount = this.balance;
    _payout(_to, amount);
  }
  function _payout(address _to, uint amount) private {
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyCEO returns (bool success) {
      return TransferInterfaceERC20(tokenAddress).transfer(ceoAddress, tokens);
  }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC721YC is YouCollectBase {
  //
  // ERC721

    /*** STORAGE ***/
    string public constant NAME = "YouCollectTokens";
    string public constant SYMBOL = "YCT";
    uint256[] public tokens;

    /// @dev A mapping from collectible IDs to the address that owns them. All collectibles have
    ///  some valid owner address.
    mapping (uint256 => address) public tokenIndexToOwner;

    /// @dev A mapping from CollectibleIDs to an address that has been approved to call
    ///  transferFrom(). Each Collectible can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public tokenIndexToApproved;

    // @dev A mapping from CollectibleIDs to the price of the token.
    mapping (uint256 => uint256) public tokenIndexToPrice;

    /*** EVENTS ***/
    /// @dev The Birth event is fired whenever a new collectible comes into existence.
    event Birth(uint256 tokenId, uint256 startPrice);
    /// @dev The TokenSold event is fired whenever a token is sold.
    event TokenSold(uint256 indexed tokenId, uint256 price, address prevOwner, address winner);
    // ERC721 Transfer
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    // ERC721 Approval
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    /*** PUBLIC FUNCTIONS ***/
    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approveToken(
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
      // Caller must own token.
      require(_ownsToken(msg.sender, _tokenId));

      tokenIndexToApproved[_tokenId] = _to;

      Approval(msg.sender, _to, _tokenId);
      return true;
    }


    function getTotalSupply() public view returns (uint) {
      return tokens.length;
    }

    function implementsERC721() public pure returns (bool) {
      return true;
    }


    /// For querying owner of token
    /// @param _tokenId The tokenID for owner inquiry
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
      public
      view
      returns (address owner)
    {
      owner = tokenIndexToOwner[_tokenId];
    }


    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
      price = tokenIndexToPrice[_tokenId];
    }


    /// @notice Allow pre-approved user to take ownership of a token
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public {
      address newOwner = msg.sender;
      address oldOwner = tokenIndexToOwner[_tokenId];

      // Safety check to prevent against an unexpected 0x0 default.
      require(newOwner != address(0));

      // Making sure transfer is approved
      require(_approved(newOwner, _tokenId));

      _transfer(oldOwner, newOwner, _tokenId);
    }

    /// Owner initates the transfer of the token to another account
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transfer(
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
      require(_ownsToken(msg.sender, _tokenId));
      _transfer(msg.sender, _to, _tokenId);
      return true;
    }

    /// Third-party initiates transfer of token from address _from to address _to
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
      require(_ownsToken(_from, _tokenId));
      require(_approved(_to, _tokenId));

      _transfer(_from, _to, _tokenId);
      return true;
    }


    /// For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
      return tokenIndexToApproved[_tokenId] == _to;
    }

    /// Check for token ownership
    function _ownsToken(address claimant, uint256 _tokenId) internal view returns (bool) {
      return claimant == tokenIndexToOwner[_tokenId];
    }
    // For Upcoming Price Change Features
    function changeTokenPrice(uint256 newPrice, uint256 _tokenId) external onlyYCC {
      tokenIndexToPrice[_tokenId] = newPrice;
    }

    /// For querying balance of a particular account
    /// @param _owner The address for balance query
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 result) {
        uint256 totalTokens = tokens.length;
        uint256 tokenIndex;
        uint256 tokenId;
        result = 0;
        for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
          tokenId = tokens[tokenIndex];
          if (tokenIndexToOwner[tokenId] == _owner) {
            result++;
          }
        }
        return result;
    }

    /// @dev Assigns ownership of a specific Collectible to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
      //transfer ownership
      tokenIndexToOwner[_tokenId] = _to;

      // When creating new collectibles _from is 0x0, but we can&#39;t account that address.
      if (_from != address(0)) {
        // clear any previously approved ownership exchange
        delete tokenIndexToApproved[_tokenId];
      }

      // Emit the transfer event.
      Transfer(_from, _to, _tokenId);
    }


    /// @param _owner The owner whose celebrity tokens we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire tokens array looking for tokens belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
          // Return an empty array
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalTokens = getTotalSupply();
        uint256 resultIndex = 0;

        uint256 tokenIndex;
        uint256 tokenId;
        for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
          tokenId = tokens[tokenIndex];
          if (tokenIndexToOwner[tokenId] == _owner) {
            result[resultIndex] = tokenId;
            resultIndex = resultIndex.add(1);
          }
        }
        return result;
      }
    }


      // uint256[] storage _result = new uint256[]();
      // uint256 totalTokens = getTotalSupply();

      // for (uint256 tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
      //   if (tokenIndexToOwner[tokens[tokenIndex]] == _owner) {
      //     _result.push(tokens[tokenIndex]);
      //   }
      // }
      // return _result;


    /// @dev returns an array with all token ids
    function getTokenIds() public view returns(uint256[]) {
      return tokens;
    }

  //
  //  ERC721 end
  //
}

contract Universe is ERC721YC {

  mapping (uint => address) private subTokenCreator;
  mapping (uint => address) private lastSubTokenBuyer;

  uint16 constant MAX_WORLD_INDEX = 1000;
  uint24 constant MAX_CONTINENT_INDEX = 10000000;
  uint64 constant MAX_SUBCONTINENT_INDEX = 10000000000000;
  uint64 constant MAX_COUNTRY_INDEX = 10000000000000000000;
  uint128 constant FIFTY_TOKENS_INDEX = 100000000000000000000000000000000;
  uint256 constant TRIBLE_TOKENS_INDEX = 1000000000000000000000000000000000000000000000;
  uint256 constant DOUBLE_TOKENS_INDEX = 10000000000000000000000000000000000000000000000000000000000;
  uint8 constant UNIVERSE_TOKEN_ID = 0;
  uint public minSelfBuyPrice = 10 ether;
  uint public minPriceForMiningUpgrade = 5 ether;

  /*** CONSTRUCTOR ***/
  function Universe() public {
  }

  function changePriceLimits(uint _minSelfBuyPrice, uint _minPriceForMiningUpgrade) public onlyCOO {
    minSelfBuyPrice = _minSelfBuyPrice;
    minPriceForMiningUpgrade = _minPriceForMiningUpgrade;
  }

  function getNextPrice(uint price, uint _tokenId) public pure returns (uint) {
    if (_tokenId>DOUBLE_TOKENS_INDEX)
      return price.mul(2);
    if (_tokenId>TRIBLE_TOKENS_INDEX)
      return price.mul(3);
    if (_tokenId>FIFTY_TOKENS_INDEX)
      return price.mul(3).div(2);
    if (price < 1.2 ether)
      return price.mul(200).div(91);
    if (price < 5 ether)
      return price.mul(150).div(91);
    return price.mul(120).div(91);
  }


  function buyToken(uint _tokenId) public payable {
    address oldOwner = tokenIndexToOwner[_tokenId];
    uint256 sellingPrice = tokenIndexToPrice[_tokenId];
    require(oldOwner!=msg.sender || sellingPrice > minSelfBuyPrice);
    require(msg.value >= sellingPrice);
    require(sellingPrice > 0);

    uint256 purchaseExcess = msg.value.sub(sellingPrice);
    uint256 payment = sellingPrice.mul(91).div(100);
    uint256 feeOnce = sellingPrice.sub(payment).div(9);

    // Update prices
    tokenIndexToPrice[_tokenId] = getNextPrice(sellingPrice, _tokenId);
    // Transfers the Token
    tokenIndexToOwner[_tokenId] = msg.sender;
    // clear any previously approved ownership exchange
    delete tokenIndexToApproved[_tokenId];
    // payout mining reward
    if (_tokenId>MAX_SUBCONTINENT_INDEX) {
      ycm.payoutMining(_tokenId, oldOwner, msg.sender);
      if (sellingPrice > minPriceForMiningUpgrade)
        ycm.levelUpMining(_tokenId);
    }

    if (_tokenId > 0) {
      // Taxes for Universe owner
      if (tokenIndexToOwner[UNIVERSE_TOKEN_ID]!=address(0))
        tokenIndexToOwner[UNIVERSE_TOKEN_ID].transfer(feeOnce);
      if (_tokenId > MAX_WORLD_INDEX) {
        // Taxes for world owner
        if (tokenIndexToOwner[_tokenId % MAX_WORLD_INDEX]!=address(0))
          tokenIndexToOwner[_tokenId % MAX_WORLD_INDEX].transfer(feeOnce);
        if (_tokenId > MAX_CONTINENT_INDEX) {
          // Taxes for continent owner
          if (tokenIndexToOwner[_tokenId % MAX_CONTINENT_INDEX]!=address(0))
            tokenIndexToOwner[_tokenId % MAX_CONTINENT_INDEX].transfer(feeOnce);
          if (_tokenId > MAX_SUBCONTINENT_INDEX) {
            // Taxes for subcontinent owner
            if (tokenIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX]!=address(0))
              tokenIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX].transfer(feeOnce);
            if (_tokenId > MAX_COUNTRY_INDEX) {
              // Taxes for country owner
              if (tokenIndexToOwner[_tokenId % MAX_COUNTRY_INDEX]!=address(0))
                tokenIndexToOwner[_tokenId % MAX_COUNTRY_INDEX].transfer(feeOnce);
              lastSubTokenBuyer[UNIVERSE_TOKEN_ID] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_WORLD_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_CONTINENT_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_SUBCONTINENT_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_COUNTRY_INDEX] = msg.sender;
            } else {
              if (lastSubTokenBuyer[_tokenId] != address(0))
                lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
            }
          } else {
            if (lastSubTokenBuyer[_tokenId] != address(0))
              lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
          }
        } else {
          if (lastSubTokenBuyer[_tokenId] != address(0))
            lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
        }
      } else {
        if (lastSubTokenBuyer[_tokenId] != address(0))
          lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
      }
    } else {
      if (lastSubTokenBuyer[_tokenId] != address(0))
        lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
    }
    // Taxes for collectible creator (first owner)
    if (subTokenCreator[_tokenId]!=address(0))
      subTokenCreator[_tokenId].transfer(feeOnce);
    // Payment for old owner
    if (oldOwner != address(0)) {
      oldOwner.transfer(payment);
    }

    TokenSold(_tokenId, sellingPrice, oldOwner, msg.sender);
    Transfer(oldOwner, msg.sender, _tokenId);
    // refund when paid too much
    if (purchaseExcess>0)
      msg.sender.transfer(purchaseExcess);
  }
  
  /// For creating Collectible
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external onlyYCC {
    tokenIndexToPrice[tokenId] = _price;
    tokenIndexToOwner[tokenId] = owner;
    subTokenCreator[tokenId] = creator;
    Birth(tokenId, _price);
    tokens.push(tokenId);
  }

  function lastSubTokenBuyerOf(uint tokenId) public view returns(address) {
    return lastSubTokenBuyer[tokenId];
  }
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address) {
    return subTokenCreator[tokenId];
  }

}