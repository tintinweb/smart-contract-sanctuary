pragma solidity ^0.4.18;

contract Redeem {

  struct Item {
    address owner;
    uint price;
    uint nextPrice;
    string slogan;
  }

  address admin;
  uint[] cuts = [50,40,30,30,20];
  uint[] priceUps = [2105,1406,1288,1206,1173];
  uint[] priceMilestones = [20,500,2000,5000];
  uint[] startPrice = [7,7,7,13,13,13,13,13,17,17];
  bool running = true;

  mapping (uint => Item) items;
  uint[] itemIndices;
  function soldItems() view public returns (uint[]) { return itemIndices; }

  event OnSold(uint indexed _iItem, address indexed _oldOwner, address indexed _newOwner, uint _oldPrice, uint _newPrice, string _newSlogan);
  
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }
  modifier enabled() {
    require(running);
    _;
  }

  function Redeem() public {
    admin = msg.sender;
  }

  function itemAt(uint _idx) view public returns (uint iItem, address owner, uint price, uint nextPrice, string slogan) {
    Item memory item = items[_idx];
    if (item.price > 0) {
      return (_idx, item.owner, item.price, item.nextPrice, item.slogan);
    } else {
      uint p = startPrice[_idx % startPrice.length];
      return (_idx, item.owner, p, nextPriceOf(p), "");
    }
  }

  function buy(uint _idx, string _slogan) enabled payable public {
    Item storage item = items[_idx];
    if (item.price == 0) {
      item.price = startPrice[_idx % startPrice.length];
      item.nextPrice = nextPriceOf(item.price);
      itemIndices.push(_idx);
    }
    require(item.price > 0);
    uint curWei = item.price * 1e15;
    require(curWei <= msg.value);
    address oldOwner = item.owner;
    uint oldPrice = item.price;
    if (item.owner != 0x0) {
      require(item.owner != msg.sender);
      item.owner.transfer(curWei * (1000 - cutOf(item.price)) / 1000);
    }
    msg.sender.transfer(msg.value - curWei);
    item.owner = msg.sender;
    item.slogan = _slogan;
    item.price = item.nextPrice;
    item.nextPrice = nextPriceOf(item.price);
    OnSold(_idx, oldOwner, item.owner, oldPrice, item.price, item.slogan);
  }

  function nextPriceOf(uint _price) view internal returns (uint) {
    for (uint i = 0; i<priceUps.length; ++i) {
      if (i >= priceMilestones.length || _price < priceMilestones[i])
        return _price * priceUps[i] / 1000;
    }
    require(false); //should not happen
    return 0;
  }
  
  function cutOf(uint _price) view internal returns (uint) {
    for (uint i = 0; i<cuts.length; ++i) {
      if (i >= priceMilestones.length || _price < priceMilestones[i])
        return cuts[i];
    }
    require(false); //should not happen
    return 0;
  }
  
  function contractInfo() view public returns (bool, address, uint256, uint[], uint[], uint[], uint[]) {
    return (running, admin, this.balance, startPrice, priceMilestones, cuts, priceUps);
  }

  function enable(bool b) onlyAdmin public {
    running = b;
  }

  function changeParameters(uint[] _startPrice, uint[] _priceMilestones, uint[] _priceUps, uint[] _cuts) onlyAdmin public {
    require(_startPrice.length > 0);
    require(_priceUps.length == _priceMilestones.length + 1);
    require(_priceUps.length == _cuts.length);
    for (uint i = 0; i<_priceUps.length; ++i) {
      require(_cuts[i] <= 1000);
      require(_priceUps[i] > 1000 + _cuts[i]);
      if (i < _priceMilestones.length-1) {
        require(_priceMilestones[i] < _priceMilestones[i+1]);
      }
    }
    startPrice = _startPrice;
    priceMilestones = _priceMilestones;
    priceUps = _priceUps;
    cuts = _cuts;
  }

  function withdrawAll() onlyAdmin public { msg.sender.transfer(this.balance); }
  function withdraw(uint _amount) onlyAdmin public { msg.sender.transfer(_amount); }
  function changeAdmin(address _newAdmin) onlyAdmin public { admin = _newAdmin; }
}