pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

contract CopaCore is Ownable, Pausable {
  using SafeMath for uint256;

  CopaMarket private copaMarket;

  uint256 public packSize;
  uint256 public packPrice;
  uint256 public totalCardCount;

  mapping (address => uint256[1200]) public balances;

  struct PackBuy {
    uint256 packSize;
    uint256 packPrice;
    uint256[] cardIds;
  }
  mapping (address => PackBuy[]) private packBuys;

  event Transfer(address indexed from, address indexed to, uint256 indexed cardId, uint256 count);
  event TransferManual(address indexed from, address indexed to, uint256[] cardIds, uint256[] counts);
  event BuyPack(uint256 indexed id, address indexed buyer, uint256 packSize, uint256 packPrice, uint256[] cardIds);
  event BuyPacks(uint256 indexed id, address indexed buyer, uint256 packSize, uint256 packPrice, uint256 count);

  constructor(uint256 _packSize, uint256 _packPrice, uint256 _totalCardCount) public {
    packSize = _packSize;
    packPrice = _packPrice;
    totalCardCount = _totalCardCount;
  }

  function getCopaMarketAddress() view external onlyOwner returns(address) {
    return address(copaMarket);
  }
  function setCopaMarketAddress(address _copaMarketAddress) external onlyOwner {
    copaMarket = CopaMarket(_copaMarketAddress);
  }
  modifier onlyCopaMarket() {
    require(msg.sender == address(copaMarket));
    _;
  }

  function setPackSize(uint256 _packSize) external onlyOwner {
    require(_packSize > 0);

    packSize = _packSize;
  }
  function setPrice(uint256 _packPrice) external onlyOwner {
    require(_packPrice > 0);

    packPrice = _packPrice;
  }
  function setTotalCardCount(uint256 _totalCardCount) external onlyOwner {
    require(_totalCardCount > 0);

    totalCardCount = _totalCardCount;
  }

  function getEthBalance() view external returns(uint256) {
    return address(this).balance;
  }

  function withdrawEthBalance() external onlyOwner {
    uint256 _ethBalance = address(this).balance;
    owner.transfer(_ethBalance);
  }

  function balanceOf(address _owner, uint256 _cardId) view external returns(uint256) {
    return balances[_owner][_cardId];
  }
  function balancesOf(address _owner) view external returns (uint256[1200]) {
    return balances[_owner];
  }

  function getPackBuy(address _address, uint256 _id) view external returns(uint256, uint256, uint256[]){
    return (packBuys[_address][_id].packSize, packBuys[_address][_id].packPrice, packBuys[_address][_id].cardIds);
  }

  function transfer(address _to, uint256 _cardId, uint256 _count) external whenNotPaused returns(bool) {
    address _from = msg.sender;

    require(_to != address(0));
    require(_count > 0);
    require(_count <= balances[_from][_cardId]);

    balances[_from][_cardId] = balances[_from][_cardId].sub(_count);
    balances[_to][_cardId] = balances[_to][_cardId].add(_count);

    emit Transfer(_from, _to, _cardId, _count);

    return true;
  }

  function transferMultiple(address _to, uint256[] _cardIds, uint256[] _counts) external whenNotPaused returns(bool) {
    address _from = msg.sender;

    require(_to != address(0));

    for (uint256 i = 0; i < _cardIds.length; i++) {
      uint256 _cardId = _cardIds[i];
      uint256 _count = _counts[i];

      require(_count > 0);
      require(_count <= balances[_from][_cardId]);

      balances[_from][_cardId] = balances[_from][_cardId].sub(_count);
      balances[_to][_cardId] = balances[_to][_cardId].add(_count);

      emit Transfer(_from, _to, _cardId, _count);
    }

    emit TransferManual(_from, _to, _cardIds, _counts);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _cardId, uint256 _count) external onlyCopaMarket returns(bool) {
    require(_to != address(0));
    require(_count > 0);
    require(_count <= balances[_from][_cardId]);

    balances[_from][_cardId] = balances[_from][_cardId].sub(_count);
    balances[_to][_cardId] = balances[_to][_cardId].add(_count);

    emit Transfer(_from, _to, _cardId, _count);

    return true;
  }

  function buyPack(uint256 _count) external payable whenNotPaused returns(bool) {
    address _buyer = msg.sender;
    uint256 _ethAmount = msg.value;
    uint256 _totalPrice = packPrice * _count;

    require(_count > 0);
    require(_ethAmount > 0);
    require(_ethAmount >= _totalPrice);

    for (uint256 i = 0; i < _count; i++) {
      uint256[] memory _cardsList = new uint256[](packSize);

      for (uint256 j = 0; j < packSize; j++) {
        uint256 _cardId = dice(totalCardCount);

        balances[_buyer][_cardId] = balances[_buyer][_cardId].add(1);

        _cardsList[j] = _cardId;

        emit Transfer(0x0, _buyer, _cardId, 1);
      }

      uint256 _id = packBuys[_buyer].length;
      packBuys[_buyer].push(PackBuy(packSize, packPrice, _cardsList));

      emit BuyPack(_id, _buyer, packSize, packPrice, _cardsList);
    }

    emit BuyPacks(_id, _buyer, packSize, packPrice, _count);

    return true;
  }

  function getPack(uint256 _count) external onlyOwner whenNotPaused returns(bool) {
    require(_count > 0);

    for (uint256 i = 0; i < _count; i++) {
      uint256[] memory _cardsList = new uint256[](packSize);

      for (uint256 j = 0; j < packSize; j++) {
        uint256 _cardId = dice(totalCardCount);

        balances[owner][_cardId] = balances[owner][_cardId].add(1);

        _cardsList[j] = _cardId;

        emit Transfer(0x0, owner, _cardId, 1);
      }

      uint256 _id = packBuys[owner].length;
      packBuys[owner].push(PackBuy(packSize, 0, _cardsList));

      emit BuyPack(_id, owner, packSize, 0, _cardsList);
    }

    emit BuyPacks(_id, owner, packSize, 0, _count);

    return true;
  }

  uint256 seed = 0;
  function maxDice() private returns (uint256 diceNumber) {
    seed = uint256(keccak256(keccak256(blockhash(block.number - 1), seed), now));
    return seed;
  }
  function dice(uint256 upper) private returns (uint256 diceNumber) {
    return maxDice() % upper;
  }
}

contract CopaMarket is Ownable, Pausable {
  using SafeMath for uint256;

  CopaCore private copaCore;

  uint256 private lockedEth;
  uint256 public cut;
  uint256 public tradingFee;
  bool private secureFees;

  struct Buy {
    uint256 cardId;
    uint256 count;
    uint256 ethAmount;
    bool open;
  }
  mapping (address => Buy[]) private buyers;

  struct Sell {
    uint256 cardId;
    uint256 count;
    uint256 ethAmount;
    bool open;
  }
  mapping (address => Sell[]) private sellers;

  struct Trade {
    uint256[] offeredCardIds;
    uint256[] offeredCardCounts;
    uint256[] requestedCardIds;
    uint256[] requestedCardCounts;
    bool open;
  }
  mapping (address => Trade[]) private traders;

  event NewBuy( address indexed buyer, uint256 indexed id, uint256 cardId, uint256 count, uint256 ethAmount );
  event CardSold( address indexed buyer, uint256 indexed id, address indexed seller, uint256 cardId, uint256 count, uint256 ethAmount );
  event CancelBuy( address indexed buyer, uint256 indexed id, uint256 cardId, uint256 count, uint256 ethAmount );

  event NewSell( address indexed seller, uint256 indexed id, uint256 cardId, uint256 count, uint256 ethAmount );
  event CardBought( address indexed seller, uint256 indexed id, address indexed buyer, uint256 cardId, uint256 count, uint256 ethAmount );
  event CancelSell( address indexed seller, uint256 indexed id, uint256 cardId, uint256 count, uint256 ethAmount );

  event NewTrade( address indexed seller, uint256 indexed id, uint256[] offeredCardIds, uint256[] offeredCardCounts, uint256[] requestedCardIds, uint256[] requestedCardCounts);
  event CardsTraded( address indexed seller, uint256 indexed id, address indexed buyer, uint256[] offeredCardIds, uint256[] offeredCardCounts, uint256[] requestedCardIds, uint256[] requestedCardCounts);
  event CancelTrade( address indexed seller, uint256 indexed id, uint256[] offeredCardIds, uint256[] offeredCardCounts, uint256[] requestedCardIds, uint256[] requestedCardCounts);

  constructor(address _copaCoreAddress, uint256 _cut, uint256 _tradingFee, bool _secureFees) public {
    copaCore = CopaCore(_copaCoreAddress);
    cut = _cut;
    tradingFee = _tradingFee;
    secureFees = _secureFees;

    lockedEth = 0;
  }

  function getCopaCoreAddress() view external onlyOwner returns(address) {
    return address(copaCore);
  }
  function setCopaCoreAddress(address _copaCoreAddress) external onlyOwner {
    copaCore = CopaCore(_copaCoreAddress);
  }

  function setCut(uint256 _cut) external onlyOwner {
    require(_cut > 0);
    require(_cut < 10000);

    cut = _cut;
  }
  function setTradingFee(uint256 _tradingFee) external onlyOwner {
    require(_tradingFee > 0);

    tradingFee = _tradingFee;
  }

  function getSecureFees() view external onlyOwner returns(bool) {
    return secureFees;
  }
  function setSecureFees(bool _secureFees) external onlyOwner {
    secureFees = _secureFees;
  }

  function getLockedEth() view external onlyOwner returns(uint256) {
    return lockedEth;
  }
  function getEthBalance() view external returns(uint256) {
    return address(this).balance;
  }

  function withdrawEthBalanceSave() external onlyOwner {
    uint256 _ethBalance = address(this).balance;
    owner.transfer(_ethBalance - lockedEth);
  }
  function withdrawEthBalance() external onlyOwner {
    uint256 _ethBalance = address(this).balance;
    owner.transfer(_ethBalance);
  }

  function getBuy(uint256 _id, address _address) view external returns(uint256, uint256, uint256, bool){
    return (buyers[_address][_id].cardId, buyers[_address][_id].count, buyers[_address][_id].ethAmount, buyers[_address][_id].open);
  }
  function getSell(uint256 _id, address _address) view external returns(uint256, uint256, uint256, bool){
    return (sellers[_address][_id].cardId, sellers[_address][_id].count, sellers[_address][_id].ethAmount, sellers[_address][_id].open);
  }
  function getTrade(uint256 _id, address _address) view external returns(uint256[], uint256[], uint256[], uint256[], bool){
    return (traders[_address][_id].offeredCardIds, traders[_address][_id].offeredCardCounts, traders[_address][_id].requestedCardIds, traders[_address][_id].requestedCardCounts, traders[_address][_id].open);
  }

  function addToBuyList(uint256 _cardId, uint256 _count) external payable whenNotPaused returns(bool) {
    address _buyer = msg.sender;
    uint256 _ethAmount = msg.value;

    require( _ethAmount > 0 );
    require( _count > 0 );

    uint256 _id = buyers[_buyer].length;
    buyers[_buyer].push(Buy(_cardId, _count, _ethAmount, true));

    lockedEth += _ethAmount;

    emit NewBuy(_buyer, _id, _cardId, _count, _ethAmount);

    return true;
  }

  function sellCard(address _buyer, uint256 _id, uint256 _cardId, uint256 _count, uint256 _ethAmount) external whenNotPaused returns(bool) {
    address _seller = msg.sender;

    uint256 _cut = 10000 - cut;
    uint256 _ethAmountAfterCut = (_ethAmount * _cut) / 10000;
    uint256 _fee = _ethAmount - _ethAmountAfterCut;

    require( buyers[_buyer][_id].open == true );
    require( buyers[_buyer][_id].cardId == _cardId );
    require( buyers[_buyer][_id].count == _count );
    require( buyers[_buyer][_id].ethAmount == _ethAmount );

    buyers[_buyer][_id].open = false;
    lockedEth -= _ethAmount;

    copaCore.transferFrom(_seller, _buyer, _cardId, _count);
    _seller.transfer(_ethAmountAfterCut);

    if(secureFees) {
      owner.transfer(_fee);
    }

    emit CardSold(_buyer, _id, _seller, _cardId, _count, _ethAmount);

    return true;
  }

  function cancelBuy(uint256 _id, uint256 _cardId, uint256 _count, uint256 _ethAmount) external whenNotPaused returns(bool) {
    address _buyer = msg.sender;

    require( buyers[_buyer][_id].open == true );
    require( buyers[_buyer][_id].cardId == _cardId );
    require( buyers[_buyer][_id].count == _count );
    require( buyers[_buyer][_id].ethAmount == _ethAmount );

    lockedEth -= _ethAmount;
    buyers[_buyer][_id].open = false;

    _buyer.transfer(_ethAmount);

    emit CancelBuy(_buyer, _id, _cardId, _count, _ethAmount);

    return true;
  }

  function addToSellList(uint256 _cardId, uint256 _count, uint256 _ethAmount) external whenNotPaused returns(bool) {
    address _seller = msg.sender;

    require( _ethAmount > 0 );
    require( _count > 0 );

    uint256 _id = sellers[_seller].length;
    sellers[_seller].push(Sell(_cardId, _count, _ethAmount, true));

    copaCore.transferFrom(_seller, address(this), _cardId, _count);

    emit NewSell(_seller, _id, _cardId, _count, _ethAmount);

    return true;
  }

  function buyCard(address _seller, uint256 _id, uint256 _cardId, uint256 _count) external payable whenNotPaused returns(bool) {
    address _buyer = msg.sender;
    uint256 _ethAmount = msg.value;

    uint256 _cut = 10000 - cut;
    uint256 _ethAmountAfterCut = (_ethAmount * _cut)/10000;
    uint256 _fee = _ethAmount - _ethAmountAfterCut;

    require( sellers[_seller][_id].open == true );
    require( sellers[_seller][_id].cardId == _cardId );
    require( sellers[_seller][_id].count == _count );
    require( sellers[_seller][_id].ethAmount <= _ethAmount );

    sellers[_seller][_id].open = false;

    copaCore.transfer(_buyer, _cardId, _count);
    _seller.transfer(_ethAmountAfterCut);

    if(secureFees) {
      owner.transfer(_fee);
    }

    emit CardBought(_seller, _id, _buyer, _cardId, _count, _ethAmount);

    return true;
  }

  function cancelSell(uint256 _id, uint256 _cardId, uint256 _count, uint256 _ethAmount) external whenNotPaused returns(bool) {
    address _seller = msg.sender;

    require( sellers[_seller][_id].open == true );
    require( sellers[_seller][_id].cardId == _cardId );
    require( sellers[_seller][_id].count == _count );
    require( sellers[_seller][_id].ethAmount == _ethAmount );

    sellers[_seller][_id].open = false;

    copaCore.transfer(_seller, _cardId, _count);

    emit CancelSell(_seller, _id, _cardId, _count, _ethAmount);

    return true;
  }

  function addToTradeList(uint256[] _offeredCardIds, uint256[] _offeredCardCounts, uint256[] _requestedCardIds, uint256[] _requestedCardCounts) external whenNotPaused returns(bool) {
    address _seller = msg.sender;

    require(_offeredCardIds.length > 0);
    require(_offeredCardCounts.length > 0);
    require(_requestedCardIds.length > 0);
    require(_requestedCardCounts.length > 0);

    uint256 _id = traders[_seller].length;
    traders[_seller].push(Trade(_offeredCardIds, _offeredCardCounts, _requestedCardIds, _requestedCardCounts, true));

    for (uint256 i = 0; i < _offeredCardIds.length; i++) {
      copaCore.transferFrom(_seller, address(this), _offeredCardIds[i], _offeredCardCounts[i]);
    }

    emit NewTrade(_seller, _id, _offeredCardIds, _offeredCardCounts, _requestedCardIds, _requestedCardCounts);

    return true;
  }

  function tradeCards(address _seller, uint256 _id) external payable whenNotPaused returns(bool) {
    address _buyer = msg.sender;
    uint256 _ethAmount = msg.value;
    uint256[] memory _offeredCardIds = traders[_seller][_id].offeredCardIds;
    uint256[] memory _offeredCardCounts = traders[_seller][_id].offeredCardCounts;
    uint256[] memory _requestedCardIds = traders[_seller][_id].requestedCardIds;
    uint256[] memory _requestedCardCounts = traders[_seller][_id].requestedCardCounts;

    require( traders[_seller][_id].open == true );
    require( _ethAmount >= tradingFee );

    traders[_seller][_id].open = false;

    for (uint256 i = 0; i < _offeredCardIds.length; i++) {
      copaCore.transfer(_buyer, _offeredCardIds[i], _offeredCardCounts[i]);
    }
    for (uint256 j = 0; j < _requestedCardIds.length; j++) {
      copaCore.transferFrom(_buyer, _seller, _requestedCardIds[j], _requestedCardCounts[j]);
    }

    if(secureFees) {
      owner.transfer(_ethAmount);
    }

    emit CardsTraded(_seller, _id, _buyer, _offeredCardIds, _offeredCardCounts, _requestedCardIds, _requestedCardCounts);

    return true;
  }

  function cancelTrade(uint256 _id) external whenNotPaused returns(bool) {
    address _seller = msg.sender;
    uint256[] memory _offeredCardIds = traders[_seller][_id].offeredCardIds;
    uint256[] memory _offeredCardCounts = traders[_seller][_id].offeredCardCounts;
    uint256[] memory _requestedCardIds = traders[_seller][_id].requestedCardIds;
    uint256[] memory _requestedCardCounts = traders[_seller][_id].requestedCardCounts;

    require( traders[_seller][_id].open == true );

    traders[_seller][_id].open = false;

    for (uint256 i = 0; i < _offeredCardIds.length; i++) {
      copaCore.transfer(_seller, _offeredCardIds[i], _offeredCardCounts[i]);
    }

    emit CancelTrade(_seller, _id, _offeredCardIds, _offeredCardCounts, _requestedCardIds, _requestedCardCounts);

    return true;
  }
}