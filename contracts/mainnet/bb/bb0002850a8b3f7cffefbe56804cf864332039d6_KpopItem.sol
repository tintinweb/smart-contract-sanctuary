// KpopItem is a ERC-721 item (https://github.com/ethereum/eips/issues/721)
// Each KpopItem has its connected KpopToken itemrity card
// Kpop.io is the official website

pragma solidity ^0.4.18;

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

contract ERC721 {
  function approve(address _to, uint _itemId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _itemId) public view returns (address addr);
  function takeOwnership(uint _itemId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _itemId) public;
  function transfer(address _to, uint _itemId) public;

  event Transfer(address indexed from, address indexed to, uint itemId);
  event Approval(address indexed owner, address indexed approved, uint itemId);
}

contract KpopCeleb is ERC721 {
  function ownerOf(uint _celebId) public view returns (address addr);
}

contract KpopItem is ERC721 {
  address public author;
  address public coauthor;
  address public manufacturer;

  string public constant NAME = "KpopItem";
  string public constant SYMBOL = "KpopItem";

  uint public GROWTH_BUMP = 0.4 ether;
  uint public MIN_STARTING_PRICE = 0.001 ether;
  uint public PRICE_INCREASE_SCALE = 120; // 120% of previous price
  uint public DIVIDEND = 3;

  address public KPOP_CELEB_CONTRACT_ADDRESS = 0x0;
  address public KPOP_ARENA_CONTRACT_ADDRESS = 0x0;

  struct Item {
    string name;
  }

  Item[] public items;

  mapping(uint => address) public itemIdToOwner;
  mapping(uint => uint) public itemIdToPrice;
  mapping(address => uint) public userToNumItems;
  mapping(uint => address) public itemIdToApprovedRecipient;
  mapping(uint => uint[6]) public itemIdToTraitValues;
  mapping(uint => uint) public itemIdToCelebId;

  event Transfer(address indexed from, address indexed to, uint itemId);
  event Approval(address indexed owner, address indexed approved, uint itemId);
  event ItemSold(uint itemId, uint oldPrice, uint newPrice, string itemName, address prevOwner, address newOwner);
  event TransferToWinner(uint itemId, uint oldPrice, uint newPrice, string itemName, address prevOwner, address newOwner);

  function KpopItem() public {
    author = msg.sender;
    coauthor = msg.sender;
  }

  function _transfer(address _from, address _to, uint _itemId) private {
    require(ownerOf(_itemId) == _from);
    require(!isNullAddress(_to));
    require(balanceOf(_from) > 0);

    uint prevBalances = balanceOf(_from) + balanceOf(_to);
    itemIdToOwner[_itemId] = _to;
    userToNumItems[_from]--;
    userToNumItems[_to]++;

    delete itemIdToApprovedRecipient[_itemId];

    Transfer(_from, _to, _itemId);

    assert(balanceOf(_from) + balanceOf(_to) == prevBalances);
  }

  function buy(uint _itemId) payable public {
    address prevOwner = ownerOf(_itemId);
    uint currentPrice = itemIdToPrice[_itemId];

    require(prevOwner != msg.sender);
    require(!isNullAddress(msg.sender));
    require(msg.value >= currentPrice);

    // Set dividend
    uint dividend = uint(SafeMath.div(SafeMath.mul(currentPrice, DIVIDEND), 100));

    // Take a cut
    uint payment = uint(SafeMath.div(SafeMath.mul(currentPrice, 90), 100));

    uint leftover = SafeMath.sub(msg.value, currentPrice);
    uint newPrice;

    _transfer(prevOwner, msg.sender, _itemId);

    if (currentPrice < GROWTH_BUMP) {
      newPrice = SafeMath.mul(currentPrice, 2);
    } else {
      newPrice = SafeMath.div(SafeMath.mul(currentPrice, PRICE_INCREASE_SCALE), 100);
    }

    itemIdToPrice[_itemId] = newPrice;

    // Pay the prev owner of the item
    if (prevOwner != address(this)) {
      prevOwner.transfer(payment);
    }

    // Pay dividend to the current owner of the celeb that&#39;s connected to the item
    uint celebId = celebOf(_itemId);
    KpopCeleb KPOP_CELEB = KpopCeleb(KPOP_CELEB_CONTRACT_ADDRESS);
    address celebOwner = KPOP_CELEB.ownerOf(celebId);
    if (celebOwner != address(this) && !isNullAddress(celebOwner)) {
      celebOwner.transfer(dividend);
    }

    ItemSold(_itemId, currentPrice, newPrice,
      items[_itemId].name, prevOwner, msg.sender);

    msg.sender.transfer(leftover);
  }

  function balanceOf(address _owner) public view returns (uint balance) {
    return userToNumItems[_owner];
  }

  function ownerOf(uint _itemId) public view returns (address addr) {
    return itemIdToOwner[_itemId];
  }

  function celebOf(uint _itemId) public view returns (uint celebId) {
    return itemIdToCelebId[_itemId];
  }

  function totalSupply() public view returns (uint total) {
    return items.length;
  }

  function transfer(address _to, uint _itemId) public {
    _transfer(msg.sender, _to, _itemId);
  }

  /** START FUNCTIONS FOR AUTHORS **/

  function createItem(string _name, uint _price, uint _celebId, uint[6] _traitValues) public onlyManufacturer {
    require(_price >= MIN_STARTING_PRICE);

    uint itemId = items.push(Item(_name)) - 1;
    itemIdToOwner[itemId] = author;
    itemIdToPrice[itemId] = _price;
    itemIdToCelebId[itemId] = _celebId;
    itemIdToTraitValues[itemId] = _traitValues; // TODO: fetch celeb traits later
    userToNumItems[author]++;
  }

  function withdraw(uint _amount, address _to) public onlyAuthors {
    require(!isNullAddress(_to));
    require(_amount <= this.balance);

    _to.transfer(_amount);
  }

  function withdrawAll() public onlyAuthors {
    require(author != 0x0);
    require(coauthor != 0x0);

    uint halfBalance = uint(SafeMath.div(this.balance, 2));

    author.transfer(halfBalance);
    coauthor.transfer(halfBalance);
  }

  function setCoAuthor(address _coauthor) public onlyAuthor {
    require(!isNullAddress(_coauthor));

    coauthor = _coauthor;
  }

  function setManufacturer(address _manufacturer) public onlyAuthors {
    require(!isNullAddress(_manufacturer));

    manufacturer = _manufacturer;
  }

  /** END FUNCTIONS FOR AUTHORS **/

  function getItem(uint _itemId) public view returns (
    string name,
    uint price,
    address owner,
    uint[6] traitValues,
    uint celebId
  ) {
    name = items[_itemId].name;
    price = itemIdToPrice[_itemId];
    owner = itemIdToOwner[_itemId];
    traitValues = itemIdToTraitValues[_itemId];
    celebId = celebOf(_itemId);
  }

  /** START FUNCTIONS RELATED TO EXTERNAL CONTRACT INTERACTIONS **/

  function approve(address _to, uint _itemId) public {
    require(msg.sender == ownerOf(_itemId));

    itemIdToApprovedRecipient[_itemId] = _to;

    Approval(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint _itemId) public {
    require(ownerOf(_itemId) == _from);
    require(isApproved(_to, _itemId));
    require(!isNullAddress(_to));

    _transfer(_from, _to, _itemId);
  }

  function takeOwnership(uint _itemId) public {
    require(!isNullAddress(msg.sender));
    require(isApproved(msg.sender, _itemId));

    address currentOwner = itemIdToOwner[_itemId];

    _transfer(currentOwner, msg.sender, _itemId);
  }

  function transferToWinner(address _winner, address _loser, uint _itemId) public onlyArena {
    require(!isNullAddress(_winner));
    require(!isNullAddress(_loser));
    require(ownerOf(_itemId) == _loser);

    // Reset item price
    uint oldPrice = itemIdToPrice[_itemId];
    uint newPrice = MIN_STARTING_PRICE;
    itemIdToPrice[_itemId] = newPrice;

    _transfer(_loser, _winner, _itemId);

    TransferToWinner(_itemId, oldPrice, newPrice, items[_itemId].name, _loser, _winner);
  }

  /** END FUNCTIONS RELATED TO EXTERNAL CONTRACT INTERACTIONS **/

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /** MODIFIERS **/

  modifier onlyAuthor() {
    require(msg.sender == author);
    _;
  }

  modifier onlyAuthors() {
    require(msg.sender == author || msg.sender == coauthor);
    _;
  }

  modifier onlyManufacturer() {
    require(msg.sender == author || msg.sender == coauthor || msg.sender == manufacturer);
    _;
  }

  modifier onlyArena() {
    require(msg.sender == KPOP_ARENA_CONTRACT_ADDRESS);
    _;
  }

  /** FUNCTIONS THAT WONT BE USED FREQUENTLY **/

  function setMinStartingPrice(uint _price) public onlyAuthors {
    MIN_STARTING_PRICE = _price;
  }

  function setGrowthBump(uint _bump) public onlyAuthors {
    GROWTH_BUMP = _bump;
  }

  function setDividend(uint _dividend) public onlyAuthors {
    DIVIDEND = _dividend;
  }

  function setPriceIncreaseScale(uint _scale) public onlyAuthors {
    PRICE_INCREASE_SCALE = _scale;
  }

  function setKpopCelebContractAddress(address _address) public onlyAuthors {
    KPOP_CELEB_CONTRACT_ADDRESS = _address;
  }

  function setKpopArenaContractAddress(address _address) public onlyAuthors {
    KPOP_ARENA_CONTRACT_ADDRESS = _address;
  }

  /** PRIVATE FUNCTIONS **/

  function isApproved(address _to, uint _itemId) private view returns (bool) {
    return itemIdToApprovedRecipient[_itemId] == _to;
  }

  function isNullAddress(address _addr) private pure returns (bool) {
    return _addr == 0x0;
  }
}