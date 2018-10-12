pragma solidity ^0.4.24;

/***
 * https://apexgold.io
 *
 * apexgold Solids - Solids is an eternal smart contract game.
 * 
 * The solids are priced by number of faces.
 * Price increases by 35% every flip.
 * Over 4 hours price will fall to base.
 * Holders after 4 hours with no flip can collect the holder fund.
 * 
 * 10% of rise buyer gets APG tokens in the ApexGold exchange.
 * 5% of rise goes to holder fund.
 * 5% of rise goes to team and promoters.
 * The rest (110%) goes to previous owner.
 * 
 */
contract ERC721 {

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

}

contract apexGoldInterface {
  function isStarted() public view returns (bool);
  function buyFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract APGSolids is ERC721 {

  /*=================================
  =            MODIFIERS            =
  =================================*/

  /// @dev Access modifier for owner functions
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  /// @dev Prevent contract calls.
  modifier notContract() {
    require(tx.origin == msg.sender);
    _;
  }

  /// @dev notPaused
  modifier notPaused() {
    require(paused == false);
    _;
  }

  /// @dev notGasbag
  modifier notGasbag() {
    require(tx.gasprice < 99999999999);
    _;
  }

  /* @dev notMoron (childish but fun)
    modifier notMoron() {
      require(msg.sender != 0x41FE3738B503cBaFD01C1Fd8DD66b7fE6Ec11b01);
      _;
    }
  */
  
  /*==============================
  =            EVENTS            =
  ==============================*/

  event onTokenSold(
       uint256 indexed tokenId,
       uint256 price,
       address prevOwner,
       address newOwner,
       string name
    );


  /*==============================
  =            CONSTANTS         =
  ==============================*/

  string public constant NAME = "APG Solids";
  string public constant SYMBOL = "APGS";

  uint256 private increaseRatePercent =  135;
  uint256 private devFeePercent =  5;
  uint256 private bagHolderFundPercent =  5;
  uint256 private exchangeTokenPercent =  10;
  uint256 private previousOwnerPercent =  110;
  uint256 private priceFallDuration =  4 hours;

  /*==============================
  =            STORAGE           =
  ==============================*/

  /// @dev A mapping from solid IDs to the address that owns them.
  mapping (uint256 => address) public solidIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from SolidID to an address that has been approved to call
  mapping (uint256 => address) public solidIndexToApproved;

  // @dev The address of the owner
  address public contractOwner;

  // @dev Current dev fee
  uint256 public currentDevFee = 0;

  // @dev The address of the exchange contract
  address public apexGoldaddress;

  // @dev paused
  bool public paused;

  /*==============================
  =            DATATYPES         =
  ==============================*/

  struct Solid {
    string name;
    uint256 basePrice;
    uint256 highPrice;
    uint256 fallDuration;
    uint256 saleTime; // when was sold last
    uint256 bagHolderFund;
  }

  Solid [6] public solids;

  constructor () public {

    contractOwner = msg.sender;
    paused=true;

    Solid memory _Tetrahedron = Solid({
            name: "Tetrahedron",
            basePrice: 0.014 ether,
            highPrice: 0.014 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[1] =  _Tetrahedron;

    Solid memory _Cube = Solid({
            name: "Cube",
            basePrice: 0.016 ether,
            highPrice: 0.016 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[2] =  _Cube;

    Solid memory _Octahedron = Solid({
            name: "Octahedron",
            basePrice: 0.018 ether,
            highPrice: 0.018 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[3] =  _Octahedron;

    Solid memory _Dodecahedron = Solid({
            name: "Dodecahedron",
            basePrice: 0.02 ether,
            highPrice: 0.02 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[4] =  _Dodecahedron;

    Solid memory _Icosahedron = Solid({
            name: "Icosahedron",
            basePrice: 0.03 ether,
            highPrice: 0.03 ether,
            fallDuration: priceFallDuration,
            saleTime: now,
            bagHolderFund: 0
            });

    solids[5] =  _Icosahedron;

    _transfer(0x0, contractOwner, 1);
    _transfer(0x0, contractOwner, 2);
    _transfer(0x0, contractOwner, 3);
    _transfer(0x0, contractOwner, 4);
    _transfer(0x0, contractOwner, 5);

  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    solidIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @notice Returns all the relevant information about a specific solid.
  /// @param _tokenId The tokenId of the solid of interest.
  function getSolid(uint256 _tokenId) public view returns (
    string solidName,
    uint256 price,
    address currentOwner,
    uint256 bagHolderFund,
    bool isBagFundAvailable
  ) {
    Solid storage solid = solids[_tokenId];
    solidName = solid.name;
    price = priceOf(_tokenId);
    currentOwner = solidIndexToOwner[_tokenId];
    bagHolderFund = solid.bagHolderFund;
    isBagFundAvailable = now > (solid.saleTime + priceFallDuration);
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = solidIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId , address _referredBy) public payable notContract notPaused notGasbag /*notMoron*/ {

    address oldOwner = solidIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 currentPrice = priceOf(_tokenId);

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= currentPrice);

    uint256 previousOwnerGets = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),previousOwnerPercent);
    uint256 exchangeTokensAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),exchangeTokenPercent);
    uint256 devFeeAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),devFeePercent);
    uint256 bagHolderFundAmount = SafeMath.mul(SafeMath.div(currentPrice,increaseRatePercent),bagHolderFundPercent);

    currentDevFee = currentDevFee + devFeeAmount;

    if (exchangeContract.isStarted()) {
        exchangeContract.buyFor.value(exchangeTokensAmount)(_referredBy, msg.sender);
    }else{
        // send excess back because exchange is not ready
        msg.sender.transfer(exchangeTokensAmount);
    }

    // do the sale
    _transfer(oldOwner, newOwner, _tokenId);

    // set new price and saleTime
    solids[_tokenId].highPrice = SafeMath.mul(SafeMath.div(currentPrice,100),increaseRatePercent);
    solids[_tokenId].saleTime = now;
    solids[_tokenId].bagHolderFund+=bagHolderFundAmount;

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      if (oldOwner.send(previousOwnerGets)){}
    }

    emit onTokenSold(_tokenId, currentPrice, oldOwner, newOwner, solids[_tokenId].name);

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {

    Solid storage solid = solids[_tokenId];
    uint256 secondsPassed  = now - solid.saleTime;

    if (secondsPassed >= solid.fallDuration || solid.highPrice==solid.basePrice) {
            return solid.basePrice;
    }

    uint256 totalPriceChange = solid.highPrice - solid.basePrice;
    uint256 currentPriceChange = totalPriceChange * secondsPassed /solid.fallDuration;
    uint256 currentPrice = solid.highPrice - currentPriceChange;

    return currentPrice;
  }

  function collectBagHolderFund(uint256 _tokenId) public notPaused {
      require(msg.sender == solidIndexToOwner[_tokenId]);
      uint256 bagHolderFund;
      bool isBagFundAvailable = false;
       (
        ,
        ,
        ,
        bagHolderFund,
        isBagFundAvailable
        ) = getSolid(_tokenId);
        require(isBagFundAvailable && bagHolderFund > 0);
        uint256 amount = bagHolderFund;
        solids[_tokenId].bagHolderFund = 0;
        msg.sender.transfer(amount);
  }


  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = solidIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
        if (solidIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return 5;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
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
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return solidIndexToApproved[_tokenId] == _to;
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == solidIndexToOwner[_tokenId];
  }

  /// @dev Assigns ownership of a specific token to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {

    // no transfer to contract
    uint length;
    assembly { length := extcodesize(_to) }
    require (length == 0);

    ownershipTokenCount[_to]++;
    //transfer ownership
    solidIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete solidIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  }

  /// @dev Not a charity
  function collectDevFees() public onlyOwner {
      if (currentDevFee < address(this).balance){
         uint256 amount = currentDevFee;
         currentDevFee = 0;
         contractOwner.transfer(amount);
      }
  }

  /// @dev Interface to exchange
   apexGoldInterface public exchangeContract;

  function setExchangeAddresss(address _address) public onlyOwner {
    exchangeContract = apexGoldInterface(_address);
    apexGoldaddress = _address;
   }

   /// @dev stop and start
   function setPaused(bool _paused) public onlyOwner {
     paused = _paused;
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