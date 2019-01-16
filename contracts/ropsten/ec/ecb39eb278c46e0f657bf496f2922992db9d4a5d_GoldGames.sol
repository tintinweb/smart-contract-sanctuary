pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/GoldCards.sol

/**

https://goldgames.io          https://goldgames.io        https://goldgames.io


 ██████╗  ██████╗ ██╗     ██████╗  ██████╗ █████╗ ██████╗ ██████╗ ███████╗
██╔════╝ ██╔═══██╗██║     ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
██║  ███╗██║   ██║██║     ██║  ██║██║     ███████║██████╔╝██║  ██║███████╗
██║   ██║██║   ██║██║     ██║  ██║██║     ██╔══██║██╔══██╗██║  ██║╚════██║
╚██████╔╝╚██████╔╝███████╗██████╔╝╚██████╗██║  ██║██║  ██║██████╔╝███████║
 ╚═════╝  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
                                                                          
- by TEAM HELU

**/



contract ERC721 {

  function approve(address _to, uint _tokenId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _tokenId) public view returns (address addr);
  function takeOwnership(uint _tokenId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _tokenId) public;
  function transfer(address _to, uint _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);
}

contract GoldCards is ERC721 {
  using SafeMath for uint;

  /*=================================
  =            MODIFIERS            =
  =================================*/

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  modifier notSelf()
  {
    require (msg.sender != address(this));
    _;
  }

  modifier onlyOnSale()
  {
    require (onSale == true);
    _;
  }

  modifier onlyAdministrators()
  {
    require(administrators[msg.sender]);
    _;
  }

  /*=================================
  =             EVENTS              =
  =================================*/

  /// @dev The Birth event is fired whenever a new dividend card comes into existence.
  event Birth(
    uint tokenId,
    string name,
    address owner
  );

  /// @dev The TokenSold event is fired whenever a token (dividend card, in this case) is sold.
  event TokenSold(
    uint tokenId,
    uint oldPrice,
    uint newPrice,
    address prevOwner,
    address winner,
    string name
  );

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  Ownership is assigned, including births.
  event Transfer(
    address from,
    address to,
    uint tokenId
  );

  event DistributeGameDividend(
    uint dividendAmount
  );

  event onBankrollAddressSet(
    address newBankrollAddress
  );

  /*=================================
  =           CONFIGURABLES         =
  =================================*/

  string public constant NAME           = "GoldCards";
  string public constant SYMBOL         = "GGC";


  /*=================================
  =            DATASET              =
  =================================*/

  mapping (uint => address) public      divCardIndexToOwner;
  mapping (uint => uint) public         divCardRateToIndex;
  mapping (address => uint) private     ownershipDivCardCount;
  mapping (uint => address) public      divCardIndexToApproved;
  mapping (uint => uint) private        divCardIndexToPrice;
  mapping (address => bool) internal    administrators;

  address public                        creator;
  address public                        bankrollAddress;
  bool    public                        onSale;
  bool    public                        isToppingUpBankroll;


  address public goldGamesContractAddress;
  GoldGames GoldGamesContract;

  struct Card {
    string name;
    uint percentIncrease;
  }
  Card[] private divCards;

  /*=================================
  =           INTERFACES            =
  =================================*/

  constructor (address _goldGamesContractAddress, address _bankrollAddress)
  public
  {
    creator = msg.sender;
    goldGamesContractAddress = _goldGamesContractAddress;
    GoldGamesContract = GoldGames(goldGamesContractAddress);
    bankrollAddress = _bankrollAddress;

    createDivCard("11%", 100 ether, 11);
    divCardRateToIndex[11] = 0;

    createDivCard("22%", 100 ether, 22);
    divCardRateToIndex[22] = 1;

    createDivCard("33%", 100 ether, 33);
    divCardRateToIndex[33] = 2;

    createDivCard("MASTER", 100 ether, 10);
    divCardRateToIndex[999] = 3;

    onSale = true;
    isToppingUpBankroll = true;
  }

  function createDivCard(string _name, uint _price, uint _percentIncrease)
  public
  onlyCreator
  {
    _createDivCard(_name, creator, _price, _percentIncrease);
  }

  function purchase(uint _divCardId)
  public
  payable
  onlyOnSale
  notSelf
  {
    address oldOwner  = divCardIndexToOwner[_divCardId];
    address newOwner  = msg.sender;

    // Get the current price of the card
    uint currentPrice = divCardIndexToPrice[_divCardId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= currentPrice);

    // To find the total profit, we need to know the previous price
    // currentPrice      = previousPrice * (100 + percentIncrease);
    // previousPrice     = currentPrice / (100 + percentIncrease);
    uint percentIncrease = divCards[_divCardId].percentIncrease;
    uint previousPrice   = SafeMath.mul(currentPrice, 100).div(100 + percentIncrease);

    // Calculate total profit and allocate 50% to old owner
    uint totalProfit     = SafeMath.sub(currentPrice, previousPrice);
    uint oldOwnerProfit  = SafeMath.div(totalProfit, 2);
    uint dividendProfit  = SafeMath.sub(totalProfit, oldOwnerProfit);
    oldOwnerProfit       = SafeMath.add(oldOwnerProfit, previousPrice);

    // Refund the sender the excess he sent
    uint purchaseExcess  = SafeMath.sub(msg.value, currentPrice);

    // Raise the price by the percentage specified by the card
    divCardIndexToPrice[_divCardId] = SafeMath.div(SafeMath.mul(currentPrice, (100 + percentIncrease)), 100);

    // Transfer ownership
    _transfer(oldOwner, newOwner, _divCardId);

    if(isToppingUpBankroll && bankrollAddress != address(0))
      bankrollAddress.send(dividendProfit);
    else {
      GoldGamesContract.distributeGameDividend.value(dividendProfit).gas(gasleft())();
      emit DistributeGameDividend(dividendProfit);
    }

    // to card&#39;s old owner
    oldOwner.send(oldOwnerProfit);

    msg.sender.transfer(purchaseExcess);
  }

  function receiveDividends(uint _divCardRate)
  public
  payable
  {
    uint _divCardId = divCardRateToIndex[_divCardRate];
    address _regularAddress = divCardIndexToOwner[_divCardId];
    address _masterAddress = divCardIndexToOwner[3];

    uint toMaster = msg.value.div(2);
    uint toRegular = msg.value.sub(toMaster);

    _masterAddress.send(toMaster);
    _regularAddress.send(toRegular);
  }

  /*=================================
  =             GETTERS             =
  =================================*/

  function getDivCard(uint _divCardId)
  public
  view
  returns (string, uint, address)
  {
    Card storage divCard = divCards[_divCardId];
    uint sellingPrice = divCardIndexToPrice[_divCardId];
    address owner = divCardIndexToOwner[_divCardId];

    return (divCard.name, sellingPrice, owner);
  }

  function ownerOf(uint _divCardId)
  public
  view
  returns (address)
  {
    address owner = divCardIndexToOwner[_divCardId];
    require(owner != address(0));
    return owner;
  }

  function priceOf(uint _divCardId)
  public
  view
  returns (uint)
  {
    return divCardIndexToPrice[_divCardId];
  }


  /*=================================
  =     ADMINISTRATION FUNCTIONS    =
  =================================*/

  function startCardSale()
  external
  onlyCreator
  {
    onSale = true;
  }

  function setCreator(address _creator)
  public
  onlyCreator
  {
    require(_creator != address(0));
    creator = _creator;
  }

  function setBankrollAddress(address _bankroll)
  external
  onlyCreator
  {
    bankrollAddress = _bankroll;
    emit onBankrollAddressSet(_bankroll);
  }

  function setToppingUpBankroll(bool flag)
  external
  onlyCreator
  {
    isToppingUpBankroll = flag;
  }


  /*=================================
  =        INTERNAL FUNCTIONS       =
  =================================*/

  function _addressNotNull(address _to)
  private
  pure
  returns (bool)
  {
    return _to != address(0);
  }

  function _approved(address _to, uint _divCardId)
  private
  view
  returns (bool)
  {
    return divCardIndexToApproved[_divCardId] == _to;
  }

  function _createDivCard(string _name, address _owner, uint _price, uint _percentIncrease)
  private
  {
    Card memory _divcard = Card({
      name: _name,
      percentIncrease: _percentIncrease
      });
    uint newCardId = divCards.push(_divcard) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newCardId == uint(uint32(newCardId)));

    emit Birth(newCardId, _name, _owner);

    divCardIndexToPrice[newCardId] = _price;

    // This will assign ownership, and also emit the Transfer event as per ERC721 draft
    _transfer(address(this), _owner, newCardId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint _divCardId)
  private
  view
  returns (bool)
  {
    return claimant == divCardIndexToOwner[_divCardId];
  }

  /// @dev Assigns ownership of a specific Card to an address.
  function _transfer(address _from, address _to, uint _divCardId)
  private
  {
    // Since the number of cards is capped to 2^32 we can&#39;t overflow this
    ownershipDivCardCount[_to]++;
    //transfer ownership
    divCardIndexToOwner[_divCardId] = _to;

    // When creating new div cards _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipDivCardCount[_from]--;
      // clear any previously approved ownership exchange
      delete divCardIndexToApproved[_divCardId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _divCardId);
  }


  /*=================================
  =         ERC721 COMPLIANCE       =
  =================================*/

  function implementsERC721()
  public
  pure
  returns (bool)
  {
    return true;
  }

  function name()
  public
  pure
  returns (string)
  {
    return NAME;
  }

  function symbol()
  public
  pure
  returns (string)
  {
    return SYMBOL;
  }

  function approve(address _to, uint _tokenId)
  public
  notSelf
  {
    require(_owns(msg.sender, _tokenId));
    divCardIndexToApproved[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function balanceOf(address _owner)
  public
  view
  returns (uint)
  {
    return ownershipDivCardCount[_owner];
  }

  function takeOwnership(uint _divCardId)
  public
  notSelf
  {
    address newOwner = msg.sender;
    address oldOwner = divCardIndexToOwner[_divCardId];

    require(_addressNotNull(newOwner));

    require(_approved(newOwner, _divCardId));

    _transfer(oldOwner, newOwner, _divCardId);
  }

  function totalSupply()
  public
  view
  returns (uint)
  {
    return divCards.length;
  }

  function transfer(address _to, uint _divCardId)
  public
  notSelf
  {
    require(_owns(msg.sender, _divCardId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _divCardId);
  }

  function transferFrom(address _from, address _to, uint _divCardId)
  public
  notSelf
  {
    require(_owns(_from, _divCardId));
    require(_approved(_to, _divCardId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _divCardId);
  }

}

// File: contracts/GoldGames.sol

/**

https://goldgames.io          https://goldgames.io        https://goldgames.io


 ██████╗  ██████╗ ██╗     ██████╗  ██████╗  █████╗ ███╗   ███╗███████╗███████╗
██╔════╝ ██╔═══██╗██║     ██╔══██╗██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔════╝
██║  ███╗██║   ██║██║     ██║  ██║██║  ███╗███████║██╔████╔██║█████╗  ███████╗
██║   ██║██║   ██║██║     ██║  ██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║
╚██████╔╝╚██████╔╝███████╗██████╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗███████║
 ╚═════╝  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝

- by TEAM HELU

**/




contract GoldGames is Ownable {
  using SafeMath for uint;

  /*=================================
  =            MODIFIERS            =
  =================================*/
  modifier onlyHolders() {
    require(getMyFrontEndTokens() > 0);
    _;
  }

  modifier onlyDividendHolder() {
    require(getMyDividends(true) > 0);
    _;
  }


  modifier onlyAdministrator() {
    address _customerAddress = msg.sender;
    require(administrators[_customerAddress]);
    _;
  }

  modifier onlySellingPhase() {
    require(sellingPhase);
    _;
  }

  modifier onlyOpenPhases() {
    require(icoPhase || sellingPhase);
    _;
  }

  modifier onlyValidDividendRate(uint8 _divRate) {
    require(validDividendRates_[_divRate]);
    _;
  }

  modifier onlyEnabledGames() {
    require(enabledGames[msg.sender]);
    _;
  }

  // ambassadors are not allowed to sell their tokens within the anti-pump-and-dump phase
  modifier ambassAntiPumpAndDump() {

    // we are still in ambassadors antiPumpAndDump phase
		if (now <= antiPumpAndDumpEnd_) {
			address _customerAddress = msg.sender;
			
			// require sender is not an ambassador
			require(!ambassadors_[_customerAddress]);
		}
	
		// execute
		_;
  }

  /*=================================
  =             EVENTS              =
  =================================*/

  event onTokenPurchase(
    address indexed customerAddress,
    uint incomingEthereum,
    uint8 dividendRate,
    uint tokensMinted,
    address indexed referredBy
  );

  event UserDividendRate(
    address user,
    uint divRate
  );

  event onTokenSell(
    address indexed customerAddress,
    uint tokensBurned,
    uint ethereumEarned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint ethereumReinvested,
    uint tokensMinted
  );

  event onReinvestmentGame(
    address indexed customerAddress,
    uint ethereumReinvested,
    uint tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint ethereumWithdrawn
  );

  event onWithdrawGame(
    address indexed customerAddress,
    uint ethereumWithdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint tokens
  );

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint tokens
  );

  event Allocation(
    uint toReferrer,
    uint toTokenHolders,
    uint toEachTokenHolder,
    uint toBuyer,
    uint toBuyerInTokens
  );

  event Referral(
    address referrer,
    uint amountReceived
  );

  event GameDividend(
    address game,
    uint amount
  );

  event DevFund(
    uint amountReceived
  );

  event CardFund(
    uint amountReceived
  );

  event BankrollFund(
    uint amountReceived
  );

  event onICOStart();
  event onICOEnd();
  event onSellingStart();

  event onSetDividendCardAddress(address divCardAddress);
  event onSetBankrollAddress(address bankrollAddress);
  event onToggleBankrollReachedCap(bool flag);


  /*=================================
  =           CONFIGURABLES         =
  =================================*/

  string public name = "GoldGames";
  string public symbol = "GOLD";


  /*=================================
  =            CONSTANTS            =
  =================================*/

  uint8 constant public  decimals = 18;

  // Initial Token Price
  uint constant internal tokenPriceInitial_     = 0.00001 ether;  // Initial Price: 0.00001 GO
  uint constant internal tokenPriceIncremental_ = 0.000001 ether; // Incremental Step: 0.000001 GO

  uint constant internal magnitude = 2**64;

  uint constant internal MULTIPLIER = 9615;
  uint constant internal MIN_ETH_BUYIN = 0.0001 ether;
  uint constant internal MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal MIN_TOKEN_TRANSFER = 1e10;
  uint8 constant internal DEFAULT_DIVIDEND_RATE = 33;

  // anti pump and dump phase time (default 90 days)
	uint256 constant internal antiPumpAndDumpTime_ = 90 days;	// remember it is constant
	uint256 constant public antiPumpAndDumpEnd_ = ACTIVATION_TIME + antiPumpAndDumpTime_;	// set anti-pump-and-dump time to 90 days after deploying
	uint256 constant internal ACTIVATION_TIME = 1545130800; // 12/18/2018 @ 11:00am (UTC)

  /*=================================
  =            DATASET              =
  =================================*/

  // Phases
  bool public sellingPhase = false;
  bool public icoPhase = false;

  // Admins
  mapping(address => bool) internal administrators;
  address[] public tokenHolders;

  // ambassadors
  mapping(address => bool) internal ambassadors_;

  // Track front-end token & dividend token
  mapping(address => uint) internal frontTokenBalanceLedger_;
  mapping(address => uint) internal dividendTokenBalanceLedger_;
  mapping(address => mapping (address => uint)) public allowed;

  // Tracks dividend rates for users
  mapping(uint8   => bool) internal validDividendRates_;
  mapping(address => bool) internal userSelectedRate;
  mapping(address => uint8) internal userDividendRate;

  // Payout tracking
  mapping(address => uint) internal referralBalance_;
  mapping(address => int256) internal payoutsTo_;
  mapping(address => int256) internal gamePayoutsTo_;

  // Track games
  mapping(address => bool) enabledGames;

  // ICO per-address limit tracking
  mapping(address => uint) internal ICOBuyIn;


  // Token Supply
  uint internal tokenSupply    = 0;
  uint internal divTokenSupply = 0;

  uint public tokensMintedDuringICO;
  uint public ethInvestedDuringICO;

  uint public currentEthInvested;
  uint internal profitPerDivToken;

  uint public currentEthGameDividend;
  uint internal gameProfitPerDivToken;

  bool internal bankrollReachedCap;

  // Preferences
  uint internal icoHardCap = 500000 ether; // Cap 500000 GO
  uint internal addressICOLimit = 15000 ether; // Cap address 15000 GO
  uint internal icoMinBuyIn = 0.1 finney;

  uint internal referrer_percentage = 25;
  uint internal dev_percentage = 10; // 10% to dev, 5% to bankroll
  uint internal bankroll_percentage = 5; // 10% to dev, 5% to bankroll
  uint internal stakingRequirement = 100e18;


  //Bankroll
  address internal bankrollAddress;

  //Div Card
  address internal divCardAddress;
  GoldCards internal divCardContract;

  //DevFund
  address internal devFundAddress;

  /*=================================
  =           INTERFACES            =
  =================================*/

  constructor (address _devFundAddress, address _bankrollAddress)
  public
  {

    // Set Dev Address & BankrollAddress
    devFundAddress = _devFundAddress;
    bankrollAddress = _bankrollAddress;

    // Set administrator addresses
    administrators[msg.sender] = true;
    administrators[0x9A5Aa922CAF550cEfD529bFa23aA94eC074A03Fc] = true; // backup admin

    // Set anti bump and dump ambassador addresses
    ambassadors_[0x646db16775Bc2B5E169dC154a545f5f7Dfd729a7] = true; 
    ambassadors_[0x14C9F1Bd86c227242C43cb49bA2eC7f1890d8805] = true; 
    ambassadors_[0x3442101afd32bcaf8ED9c9FF774281002724Dd7B] = true; 
    ambassadors_[0x4018c9CB81877F399B3d426ceCE71d0680A2E9B5] = true; 
    ambassadors_[0xeF37Dcf8365013295d0689A634a2e72fae390ADc] = true; 
    ambassadors_[0xa81B59D28ea0e9C4E4Af9aa26476A865f096b984] = true; 
    ambassadors_[0xB656947B8a900420227223445b76114Fe1326868] = true; 
    ambassadors_[0x10df6Ec05040D62894f81E3d4BCdFfaff5DEACAe] = true; 
    ambassadors_[0x9Df1AFE9E7354A841Fcc3D8563471407C7FA3213] = true; 
    ambassadors_[0xc55e66841F21dD14B12260F8989ed685F10c1112] = true; 
    ambassadors_[0x09f9F6F2755F67E6D424DD959784af2303cc0AD2] = true; 
    ambassadors_[0x21adD73393635b26710C7689519a98b09ecdc474] = true; 
    ambassadors_[0x11139504c1457D9AdD2E7DFb07191f69c78f94C4] = true; 
    ambassadors_[0x02beFb5d26822f3529460b68731Ad210b976F200] = true; 

    // Set dividend rates
    validDividendRates_[11] = true;
    validDividendRates_[22] = true;
    validDividendRates_[33] = true;
  }

  /**
    TODO : check commit : buyAndSetDividendPercentage()
   */
  function buyAndSetDividendPercentage(address _referredBy, uint8 _divChoice)
  public
  payable
  onlyOpenPhases
  onlyValidDividendRate(_divChoice)
  returns (uint)
  {

    if(icoPhase) {
      // TODO Check ico invitation token
    }

    address _customerAddress = msg.sender;
    userSelectedRate[_customerAddress] = true;
    userDividendRate[_customerAddress] = _divChoice;

    uint _tokensBought = purchaseTokens(msg.value,_referredBy);
    emit onTokenPurchase(
      msg.sender, msg.value, _divChoice,
      _tokensBought, _referredBy
    );
  }

  function buy(address _referredBy)
  public
  payable
  onlyOpenPhases
  returns(uint)
  {

    if(icoPhase) {
      // TODO Check ico invitation token
    }

    address _customerAddress = msg.sender;
    require (userSelectedRate[_customerAddress]);
    uint _tokensBought = purchaseTokens(msg.value, _referredBy);
    emit onTokenPurchase(
      msg.sender, msg.value, userDividendRate[_customerAddress],
      _tokensBought, _referredBy
    );
  }

  function buyAndTransfer(address _referredBy, address _target, uint8 _divChoice)
  public
  payable
  onlySellingPhase
  onlyValidDividendRate(_divChoice)
  {
    address _customerAddress = msg.sender;
    uint256 _frontendBalance = frontTokenBalanceLedger_[_customerAddress];

    if (userSelectedRate[_customerAddress]) {
      buy(_referredBy);
    } else {
      buyAndSetDividendPercentage(_referredBy, _divChoice);
    }
    uint256 _difference = SafeMath.sub(frontTokenBalanceLedger_[msg.sender], _frontendBalance);
    transfer(_target, _difference);
  }

  function reinvest(bool includeGame)
  public
  onlyOpenPhases
  {
    if(getMyDividends(true) > 0) {
      uint _dividends = getMyDividends(false);

      // Pay out requisite `virtual&#39; dividends.
      address _customerAddress            = msg.sender;
      payoutsTo_[_customerAddress]       += (int256) (_dividends * magnitude);

      _dividends                         += referralBalance_[_customerAddress];
      referralBalance_[_customerAddress]  = 0;

      uint _tokens                        = purchaseTokens(_dividends, 0x0);

      // Fire logging event.
      emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    if(includeGame)
      reinvestGameDividend();
  }

  function reinvestGameDividend()
  public
  onlyOpenPhases
  {
    if(getMyGameDividends() > 0) {
      uint _dividends = getMyGameDividends();
      // Pay out requisite `virtual&#39; dividends.
      address _customerAddress            = msg.sender;
      gamePayoutsTo_[_customerAddress]       += (int256) (_dividends * magnitude);
      uint _tokens                        = purchaseTokens(_dividends, 0x0);

      // Fire logging event.
      emit onReinvestmentGame(_customerAddress, _dividends, _tokens);
    }
  }

  function exit()
  public
  {
    // Retrieve token balance for caller, then sell them all.
    address _customerAddress = msg.sender;
    uint _tokens             = frontTokenBalanceLedger_[_customerAddress];

    if(_tokens > 0) sell(_tokens);

    withdraw(true);
  }

  function withdraw(bool includeGame)
  public
  {
    // Setup data
    if(getMyDividends(true) > 0) {
      address _customerAddress           = msg.sender;
      uint _dividends                    = getMyDividends(false);

      // update dividend tracker
      payoutsTo_[_customerAddress]       +=  (int256) (_dividends * magnitude);

      // add ref. bonus
      _dividends                         += referralBalance_[_customerAddress];
      referralBalance_[_customerAddress]  = 0;

      _customerAddress.transfer(_dividends);

      // Fire logging event.
      emit onWithdraw(_customerAddress, _dividends);
    }

    if(includeGame)
      withdrawGame();
  }

  function withdrawGame()
  public
  {
    // Setup data
    if(getMyGameDividends() > 0) {
      address _customerAddress           = msg.sender;
      uint _dividends = getMyGameDividends();

      // update dividend tracker
      gamePayoutsTo_[_customerAddress]       +=  (int256) (_dividends * magnitude);

      _customerAddress.transfer(_dividends);

      // Fire logging event.
      emit onWithdrawGame(_customerAddress, _dividends);
    }
  }

  // Sells front-end tokens.
  // Logic concerning step-pricing of tokens pre/post-ICO is encapsulated in tokensToEthereum_.
  function sell(uint _amountOfTokens)
  public
  onlyHolders
  ambassAntiPumpAndDump
  {
    require(_amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);

    uint _frontEndTokensToBurn = _amountOfTokens;

    // Calculate how many dividend tokens this action burns.
    // Computed as the caller&#39;s average dividend rate multiplied by the number of front-end tokens held.
    // As an additional guard, we ensure that the dividend rate is between 2 and 50 inclusive.

    uint userDivRate  = getUserAverageDividendRate(msg.sender);
    require ((2*magnitude) <= userDivRate && (50*magnitude) >= userDivRate );
    uint _divTokensToBurn = (_frontEndTokensToBurn.mul(userDivRate)).div(magnitude);

    // Calculate ethereum received before dividends
    uint _ethereum = tokensToEthereum_(_frontEndTokensToBurn);

    if (_ethereum > currentEthInvested){
      // Well, congratulations, you&#39;ve emptied the coffers.
      currentEthInvested = 0;
    } else { currentEthInvested = currentEthInvested - _ethereum; }

    // Calculate dividends generated from the sale.
    uint _dividends = (_ethereum.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude);

    uint _toDev = settleDevFund(_dividends);
    _dividends = _dividends.sub(_toDev);

    // Calculate Ethereum receivable net of dividends.
    uint _taxedEthereum = _ethereum.sub(_dividends);

    // Burn the sold tokens (both front-end and back-end variants).
    tokenSupply         = tokenSupply.sub(_frontEndTokensToBurn);
    divTokenSupply      = divTokenSupply.sub(_divTokensToBurn);

    // Subtract the token balances for the seller
    frontTokenBalanceLedger_[msg.sender]    = frontTokenBalanceLedger_[msg.sender].sub(_frontEndTokensToBurn);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].sub(_divTokensToBurn);

    // Update dividends tracker
    int256 _updatedPayouts  = (int256) (profitPerDivToken * _divTokensToBurn + (_taxedEthereum * magnitude));
    payoutsTo_[msg.sender] -= _updatedPayouts;
    gamePayoutsTo_[msg.sender] -= (int256) (gameProfitPerDivToken * _divTokensToBurn);

    // Avoid breaking arithmetic
    if (divTokenSupply > 1 ether) {
      // Update the value of each remaining back-end dividend token.
      profitPerDivToken = profitPerDivToken.add((_dividends * magnitude) / divTokenSupply);
    }

    // Fire logging event.
    emit onTokenSell(msg.sender, _frontEndTokensToBurn, _taxedEthereum);
  }

  function transfer(address _toAddress, uint _amountOfTokens)
  public
  onlyHolders
  returns(bool)
  {
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER && _amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);
    transferFromInternal(msg.sender, _toAddress, _amountOfTokens);
    return true;

  }

  function approve(address spender, uint tokens)
  public
  returns (bool)
  {
    address _customerAddress           = msg.sender;
    allowed[_customerAddress][spender] = tokens;

    emit Approval(_customerAddress, spender, tokens);

    return true;
  }

  function totalSupply()
  public
  view
  returns (uint256)
  {
    return tokenSupply;
  }

  function totalDivSupply()
  public
  view
  returns (uint256)
  {
    return divTokenSupply;
  }


  function()
  payable
  public
  {
    /**
    / If the user has previously set a dividend rate, sending
    /   Ether directly to the contract simply purchases more at
    /   the most recent rate. If this is their first time, they
    /   are automatically placed into the 20% rate `bucket&#39;.
    **/
    require(sellingPhase);
    address _customerAddress = msg.sender;
    if (userSelectedRate[_customerAddress]) {
      purchaseTokens(msg.value, address(0));
    } else {
      buyAndSetDividendPercentage(address(0), DEFAULT_DIVIDEND_RATE);
    }
  }

  /*=================================
  =     ADMINISTRATION FUNCTIONS    =
  =================================*/

  function startICOPhase()
  public
  onlyAdministrator
  {
    icoPhase = true;
    emit onICOStart();
  }

  function endICOPhase()
  public
  onlyAdministrator
  {
    icoPhase = false;
    emit onICOEnd();
  }

  function startSellingPhase()
  public
  onlyAdministrator
  {
    icoPhase = false;
    sellingPhase = true;
    emit onSellingStart();
  }

  function setICOLimit(uint _addressICOLimit)
  external
  onlyAdministrator
  {
    addressICOLimit = _addressICOLimit;
  }

  function setStakingRequirement(uint _amountOfTokens)
  public
  onlyAdministrator
  {
    require (_amountOfTokens >= 100e18);
    stakingRequirement = _amountOfTokens;
  }

  function setName(string _name)
  public
  onlyAdministrator
  {
    name = _name;
  }

  function setSymbol(string _symbol)
  public
  onlyAdministrator
  {
    symbol = _symbol;
  }

  function setDividendCardAddress(address _divCardAddress)
  external
  onlyAdministrator
  {
    divCardAddress = _divCardAddress;
    divCardContract = GoldCards(divCardAddress);
    enabledGames[_divCardAddress] = true;
    emit onSetDividendCardAddress(_divCardAddress);
  }

  function toggleBankrollReachedCap(bool _flag)
  external
  onlyAdministrator
  {
    bankrollReachedCap = _flag;
    emit onToggleBankrollReachedCap(_flag);
  }

  function setBankrollAddress(address _bankrollAddress)
  external
  onlyAdministrator
  {
    administrators[bankrollAddress] = false;
    bankrollAddress = _bankrollAddress;
    administrators[bankrollAddress] = true;
    emit onSetBankrollAddress(_bankrollAddress);
  }

  /*=================================
  =             GETTERS             =
  =================================*/

  function totalEthereumBalance()
  public
  view
  returns(uint)
  {
    return address(this).balance;
  }

  function totalEthereumICOReceived()
  public
  view
  returns(uint)
  {
    return ethInvestedDuringICO;
  }

  /**
   * Retrieves your currently selected dividend rate.
   */
  function getMyDividendRate()
  public
  view
  returns(uint8)
  {
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    return userDividendRate[_customerAddress];
  }

  /**
   * Retrieve the frontend tokens owned by the caller
   */
  function getMyFrontEndTokens()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return getFrontEndTokenBalanceOf(_customerAddress);
  }

  /**
   * Retrieve the dividend tokens owned by the caller
   */
  function getMyDividendTokens()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return getDividendTokenBalanceOf(_customerAddress);
  }

  /**
   * Retrieve the referral dividend tokens owned by the caller
   */
  function getMyReferralDividends()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return referralBalance_[_customerAddress];
  }

  /**
   * Retrieve the referral dividend tokens owned by the caller
   */
  function getMyGameDividends()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return SafeMath.add(gameDividendOf(_customerAddress), 0);
  }

  function getMyDividends(bool _includeReferralBonus)
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? SafeMath.add(dividendsOf(_customerAddress), referralBalance_[_customerAddress]) : dividendsOf(_customerAddress) ;
  }

  function getMyAverageDividendRate() public view returns (uint) {
    return getUserAverageDividendRate(msg.sender);
  }

  function theDividendsOf(bool _includeReferralBonus, address _customerAddress)
  public
  view
  returns(uint)
  {
    return _includeReferralBonus ? SafeMath.add(dividendsOf(_customerAddress), referralBalance_[_customerAddress]) : dividendsOf(_customerAddress) ;
  }

  function getFrontEndTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return frontTokenBalanceLedger_[_customerAddress];
  }

  function balanceOf(address _owner)
  view
  public
  returns(uint)
  {
    return getFrontEndTokenBalanceOf(_owner);
  }

  function getDividendTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return dividendTokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return (uint) ((int256)(profitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

  function gameDividendOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return (uint) ((int256)(gameProfitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - gamePayoutsTo_[_customerAddress]) / magnitude;
  }

  // Get the sell price at the user&#39;s average dividend rate
  function sellPrice()
  public
  view
  returns(uint)
  {
    uint price;

    if(tokenSupply < 1)
      price = tokenPriceInitial_;
    else if (icoPhase || currentEthInvested < ethInvestedDuringICO) {
      price = tokenPriceInitial_;
    } else {

      // Calculate the tokens received for 100 finney.
      // Divide to find the average, to calculate the price.
      uint tokensReceivedForEth = ethereumToTokens_(0.001 ether);

      price = (1e18 * 0.001 ether) / tokensReceivedForEth;
    }

    // Factor in the user&#39;s average dividend rate
    uint theSellPrice = price.sub((price.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude));

    return theSellPrice;
  }

  function buyPrice()
  public
  view
  returns(uint256)
  {
    // our calculation relies on the token supply, so we need supply. Doh.
    if(tokenSupply < 1){
      return tokenPriceInitial_;
    } else {
      uint256 _ethereum = tokensToEthereum_(1e18);
      return _ethereum;
    }
  }

  function calculateTokensReceived(uint _ethereumToSpend)
  public
  view
  returns(uint)
  {
    require(userSelectedRate[msg.sender]);
    uint _dividends      = (_ethereumToSpend.mul(userDividendRate[msg.sender])).div(100);
    uint _taxedEthereum  = _ethereumToSpend.sub(_dividends);
    uint _amountOfTokens = ethereumToTokens_(_taxedEthereum);
    return  _amountOfTokens;
  }

  // When selling tokens, we need to calculate the user&#39;s current dividend rate.
  // This is different from their selected dividend rate.
  function calculateEthereumReceived(uint _tokensToSell)
  public
  view
  returns(uint)
  {
    require(_tokensToSell <= tokenSupply);
    uint _ethereum               = tokensToEthereum_(_tokensToSell);
    uint userAverageDividendRate = getUserAverageDividendRate(msg.sender);
    if(userAverageDividendRate > 0) {
      uint _dividends              = (_ethereum.mul(userAverageDividendRate).div(100)).div(magnitude);
      uint _taxedEthereum          = _ethereum.sub(_dividends);
      return  _taxedEthereum;
    }
    return 0;
  }

  /*
   * Get&#39;s a user&#39;s average dividend rate - which is just their divTokenBalance / tokenBalance
   * We multiply by magnitude to avoid precision errors.
   */
  function getUserAverageDividendRate(address user) public view returns (uint) {
    if(frontTokenBalanceLedger_[user] > 0)
      return (dividendTokenBalanceLedger_[user]).mul(magnitude).div(frontTokenBalanceLedger_[user]);
    else
      return 100;
  }

  /*=================================
  =        GAME INTERFACES          =
  =================================*/


  function enableGame(address gameAddress)
  external
  onlyAdministrator
  {
    enabledGames[gameAddress] = true;
  }

  function disableGame(address gameAddress)
  external
  onlyAdministrator
  {
    enabledGames[gameAddress] = false;
  }

  function distributeGameDividend()
  external
  payable
  onlyEnabledGames
  {
    // 10% goes to dev, 5% to bankroll
    uint toDev = settleDevFund(msg.value);

    // The rest goes to token holders
    uint toTokenHolders = msg.value.sub(toDev);

    if(divTokenSupply > 0)
      gameProfitPerDivToken = gameProfitPerDivToken.add(toTokenHolders.mul(magnitude).div(divTokenSupply));

    emit GameDividend(msg.sender, msg.value);
  }


  /*=================================
  =        INTERNAL FUNCTIONS       =
  =================================*/

  /* Purchase tokens with Ether.
    During ICO phase, dividends should go to the bankroll
    During normal operation:
      25% of dividends should go to the referrer, if any is provided.
      10% of dividends should go to dev fund.
      The rest of dividends go to token holders.
  */
  function purchaseTokens(uint _incomingEthereum, address _referredBy)
  internal
  returns(uint)
  {
    require(_incomingEthereum >= MIN_ETH_BUYIN, "Tried to buy below the min eth buyin threshold.");

    uint toReferrer = 0;
    uint toDev = 0;
    uint toDivCardHolder = calculateCardHolderDividend(_incomingEthereum);
    uint toTokenHolders;

    uint dividendAmount;

    uint tokensBought;
    uint dividendTokensBought;

    uint remainingEth = _incomingEthereum;

    uint fee;

    /* Take card holder dividend */
    remainingEth = remainingEth.sub(toDivCardHolder);

    /* Tax for dividends:
       Dividends = (ethereum * div%) / 100
    */
    // Grab the user&#39;s dividend rate
    uint dividendRate = userDividendRate[msg.sender];

    // Calculate the total dividends on this buy
    dividendAmount = (remainingEth.mul(dividendRate)).div(100);
    remainingEth = remainingEth.sub(dividendAmount);

    // Calculate how many tokens to buy:
    tokensBought = ethereumToTokens_(remainingEth);
    dividendTokensBought = tokensBought.mul(dividendRate);

    // This is where we actually mint tokens:
    tokenSupply = tokenSupply.add(tokensBought);
    divTokenSupply = divTokenSupply.add(dividendTokensBought);

    /* Update the total investment tracker
       Note that this must be done AFTER we calculate how many tokens are bought -
       because ethereumToTokens needs to know the amount *before* investment, not *after* investment. */

    currentEthInvested += remainingEth;


    if(icoPhase) {
      // Contracts aren&#39;t allowed to participate in the ICO.
      require(address(this) != msg.sender);
      // Cannot purchase more then the limit per address during the ICO.
      ICOBuyIn[msg.sender] += remainingEth;
      require(ICOBuyIn[msg.sender] <= addressICOLimit);

      ethInvestedDuringICO = ethInvestedDuringICO + remainingEth;
      tokensMintedDuringICO = tokensMintedDuringICO + tokensBought;

      // Stop the ICO phase if we reach the hard cap
      if (ethInvestedDuringICO >= icoHardCap){
        icoPhase = false;
        sellingPhase = true;
        emit onICOEnd();
        emit onSellingStart();
      }

    }

    // 25% goes to referrers
    if (_referredBy != address(0) &&
      _referredBy != msg.sender &&
      frontTokenBalanceLedger_[_referredBy] >= stakingRequirement)
    {
      toReferrer = (dividendAmount.mul(referrer_percentage)).div(100);
      referralBalance_[_referredBy] += toReferrer;
      emit Referral(_referredBy, toReferrer);
    }

    // Send funds to dev and bankroll
    toDev = settleDevFund(dividendAmount);

    // The rest of the dividends go to token holders
    toTokenHolders = (dividendAmount.sub(toReferrer)).sub(toDev);

    // calculate the amount of tokens the customer receives over his purchase
    fee = toTokenHolders * magnitude;
    fee = fee - (fee - (dividendTokensBought * (toTokenHolders * magnitude / (divTokenSupply))));

    // Finally, increase the divToken value
    profitPerDivToken       = profitPerDivToken.add((toTokenHolders.mul(magnitude)).div(divTokenSupply));

    payoutsTo_[msg.sender] += (int256) ((profitPerDivToken * dividendTokensBought) - fee);
    gamePayoutsTo_[msg.sender] += (int256) (gameProfitPerDivToken * dividendTokensBought);

    // Update the buyer&#39;s token amounts
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].add(tokensBought);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].add(dividendTokensBought);
    if(!userSelectedRate[msg.sender])
      tokenHolders.push(msg.sender);

    if(toDivCardHolder > 0 && divCardAddress != address(0)) {
      divCardContract.receiveDividends.value(toDivCardHolder)(dividendRate);
      emit CardFund(toDivCardHolder);
    }

    // This event should help us track where all the eth is going
    emit Allocation(toReferrer, toTokenHolders, (toTokenHolders.mul(magnitude)).div(divTokenSupply), remainingEth, tokensBought);

    // Sanity checking
    uint sum = toReferrer + toDev + toDivCardHolder + toTokenHolders + remainingEth - _incomingEthereum;
    assert(sum == 0);

    return tokensBought;
  }

  function calculateCardHolderDividend(uint amount)
  internal
  view
  returns(uint)
  {
    uint toDivCardHolder = 0;
    if(divCardAddress != address(0)) {
      toDivCardHolder = amount.mul(2).div(100); //2% : 1% for master card, 1% fir div card
    }
    return toDivCardHolder;
  }

  function settleDevFund(uint amount)
  internal
  returns(uint)
  {
    // max 10% goes to dev, 5% to bankroll
    require(amount > 0);
    uint toDev = amount.mul(dev_percentage).div(100);
    uint toBankroll = amount.mul(bankroll_percentage).div(100);
    uint usedAmount = 0;
    if(devFundAddress != address(0)){
      usedAmount += toDev;
      devFundAddress.send(toDev);
      emit DevFund(toDev);
    }
    if(!bankrollReachedCap && bankrollAddress != address(0)) {
      usedAmount += toBankroll;
      bankrollAddress.send(toBankroll);
      emit BankrollFund(toBankroll);
    }

    return usedAmount;
  }



  function ethereumToTokens_(uint256 _ethereum)
  internal
  view
  returns(uint256)
  {
    uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
    uint256 _tokensReceived =
    (
      (
        // underflow attempts BTFO
        SafeMath.sub(
          (sqrt
            (
              (_tokenPriceInitial**2)
              +
              (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
              +
              (((tokenPriceIncremental_)**2)*(tokenSupply**2))
              +
              (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply)
            )
          ), _tokenPriceInitial
        )
      )/(tokenPriceIncremental_)
    )-(tokenSupply);
    return _tokensReceived;
  }

  /**
    * Calculate token sell value.
    * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
    * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
    */
  function tokensToEthereum_(uint256 _tokens)
  internal
  view
  returns(uint256)
  {

    uint256 tokens_ = (_tokens + 1e18);
    uint256 _tokenSupply = (tokenSupply + 1e18);
    uint256 _etherReceived =
    (
      // underflow attempts BTFO
      SafeMath.sub(
        (
          (
            (
              tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
            )-tokenPriceIncremental_
          )*(tokens_ - 1e18)
        ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
      )
    /1e18);
    return _etherReceived;
  }

  function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens)
  internal
  {
    require(_toAddress != address(0x0));
    address _customerAddress     = _from;
    uint _amountOfFrontEndTokens = _amountOfTokens;

    // Withdraw all outstanding dividends first (including those generated from referrals).
    if(theDividendsOf(true, _customerAddress) > 0) withdrawFrom(_customerAddress);
    if(gameDividendOf(_customerAddress) > 0) gameWithdrawFrom(_customerAddress);

    // Calculate how many back-end dividend tokens to transfer.
    // This amount is proportional to the caller&#39;s average dividend rate multiplied by the proportion of tokens being transferred.
    uint _amountOfDivTokens = _amountOfFrontEndTokens.mul(getUserAverageDividendRate(_customerAddress)).div(magnitude);

    if (_customerAddress != msg.sender){
      // Update the allowed balance.
      // Don&#39;t update this if we are transferring our own tokens (via transfer or buyAndTransfer)
      allowed[_customerAddress][msg.sender] -= _amountOfTokens;
    }

    // Exchange tokens
    frontTokenBalanceLedger_[_customerAddress]    = frontTokenBalanceLedger_[_customerAddress].sub(_amountOfFrontEndTokens);
    frontTokenBalanceLedger_[_toAddress]          = frontTokenBalanceLedger_[_toAddress].add(_amountOfFrontEndTokens);
    dividendTokenBalanceLedger_[_customerAddress] = dividendTokenBalanceLedger_[_customerAddress].sub(_amountOfDivTokens);
    dividendTokenBalanceLedger_[_toAddress]       = dividendTokenBalanceLedger_[_toAddress].add(_amountOfDivTokens);

    // Recipient inherits dividend percentage if they have not already selected one.
    if(!userSelectedRate[_toAddress])
    {
      userSelectedRate[_toAddress] = true;
      userDividendRate[_toAddress] = userDividendRate[_customerAddress];
    }

    // Update dividend trackers
    payoutsTo_[_customerAddress] -= (int256) (profitPerDivToken * _amountOfDivTokens);
    payoutsTo_[_toAddress]       += (int256) (profitPerDivToken * _amountOfDivTokens);

    gamePayoutsTo_[_customerAddress] -= (int256) (gameProfitPerDivToken * _amountOfDivTokens);
    gamePayoutsTo_[_toAddress]       += (int256) (gameProfitPerDivToken * _amountOfDivTokens);

    // Fire logging event.
    emit Transfer(_customerAddress, _toAddress, _amountOfFrontEndTokens);
  }

  // Called from transferFrom. Always checks if _customerAddress has dividends.
  function withdrawFrom(address _customerAddress)
  internal
  {
    // Setup data
    uint _dividends = theDividendsOf(false, _customerAddress);

    // update dividend tracker
    payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

    // add ref. bonus
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    _customerAddress.transfer(_dividends);

    // Fire logging event.
    emit onWithdraw(_customerAddress, _dividends);
  }

  function gameWithdrawFrom(address _customerAddress)
  internal
  {
    uint _dividends = gameDividendOf(_customerAddress);
    // update dividend tracker
    gamePayoutsTo_[_customerAddress]       +=  (int256) (_dividends * magnitude);

    _customerAddress.transfer(_dividends);

    // Fire logging event.
    emit onWithdrawGame(_customerAddress, _dividends);
  }


  /*=======================
   =   MATHS FUNCTIONS    =
   ======================*/

  function toPowerOfThreeHalves(uint x) public pure returns (uint) {
    // m = 3, n = 2
    // sqrt(x^3)
    return sqrt(x**3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns (uint) {
    // m = 2, n = 3
    // cbrt(x^2)
    return cbrt(x**2);
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z*z) + 2 * z) / 3;
    }
  }
}