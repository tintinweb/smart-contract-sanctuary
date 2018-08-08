pragma solidity 0.4.24;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
  }

  function square(uint256 a) internal pure returns (uint256) {
    return mul(a, a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
  }

}


contract ERC20Interface {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function totalSupply() public view returns (uint256);
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance( address _owner, address _spender) public view returns (uint256);

}


/**
 * @title CHStock
 * @author M.H. Kang
 */
contract CHStock is ERC20Interface {

  using SafeMath for uint256;

  /* EVENT */

  event RedeemShares(
    address indexed user,
    uint256 shares,
    uint256 dividends
  );

  /* STORAGE */

  string public name = "ChickenHuntStock";
  string public symbol = "CHS";
  uint8 public decimals = 18;
  uint256 public totalShares;
  uint256 public dividendsPerShare;
  uint256 public constant CORRECTION = 1 << 64;
  mapping (address => uint256) public ethereumBalance;
  mapping (address => uint256) internal shares;
  mapping (address => uint256) internal refund;
  mapping (address => uint256) internal deduction;
  mapping (address => mapping (address => uint256)) internal allowed;

  /* FUNCTION */

  function redeemShares() public {
    uint256 _shares = shares[msg.sender];
    uint256 _dividends = dividendsOf(msg.sender);

    delete shares[msg.sender];
    delete refund[msg.sender];
    delete deduction[msg.sender];
    totalShares = totalShares.sub(_shares);
    ethereumBalance[msg.sender] = ethereumBalance[msg.sender].add(_dividends);

    emit RedeemShares(msg.sender, _shares, _dividends);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool)
  {
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function dividendsOf(address _shareholder) public view returns (uint256) {
    return dividendsPerShare.mul(shares[_shareholder]).add(refund[_shareholder]).sub(deduction[_shareholder]) / CORRECTION;
  }

  function totalSupply() public view returns (uint256) {
    return totalShares;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return shares[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /* INTERNAL FUNCTION */

  function _giveShares(address _user, uint256 _ethereum) internal {
    if (_ethereum > 0) {
      totalShares = totalShares.add(_ethereum);
      deduction[_user] = deduction[_user].add(dividendsPerShare.mul(_ethereum));
      shares[_user] = shares[_user].add(_ethereum);
      dividendsPerShare = dividendsPerShare.add(_ethereum.mul(CORRECTION) / totalShares);

      emit Transfer(address(0), _user, _ethereum);
    }
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    require(_value <= shares[_from]);
    uint256 _rawProfit = dividendsPerShare.mul(_value);

    uint256 _refund = refund[_from].add(_rawProfit);
    uint256 _min = _refund < deduction[_from] ? _refund : deduction[_from];
    refund[_from] = _refund.sub(_min);
    deduction[_from] = deduction[_from].sub(_min);
    deduction[_to] = deduction[_to].add(_rawProfit);

    shares[_from] = shares[_from].sub(_value);
    shares[_to] = shares[_to].add(_value);

    emit Transfer(_from, _to, _value);
  }

}


/**
 * @title CHGameBase
 * @author M.H. Kang
 */
contract CHGameBase is CHStock {

  /* DATA STRUCT */

  struct House {
    Hunter hunter;
    uint256 huntingPower;
    uint256 offensePower;
    uint256 defensePower;
    uint256 huntingMultiplier;
    uint256 offenseMultiplier;
    uint256 defenseMultiplier;
    uint256 depots;
    uint256[] pets;
  }

  struct Hunter {
    uint256 strength;
    uint256 dexterity;
    uint256 constitution;
    uint256 resistance;
  }

  struct Store {
    address owner;
    uint256 cut;
    uint256 cost;
    uint256 balance;
  }

  /* STORAGE */

  Store public store;
  uint256 public devCut;
  uint256 public devFee;
  uint256 public altarCut;
  uint256 public altarFund;
  uint256 public dividendRate;
  uint256 public totalChicken;
  address public chickenTokenDelegator;
  mapping (address => uint256) public lastSaveTime;
  mapping (address => uint256) public savedChickenOf;
  mapping (address => House) internal houses;

  /* FUNCTION */

  function saveChickenOf(address _user) public returns (uint256) {
    uint256 _unclaimedChicken = _unclaimedChickenOf(_user);
    totalChicken = totalChicken.add(_unclaimedChicken);
    uint256 _chicken = savedChickenOf[_user].add(_unclaimedChicken);
    savedChickenOf[_user] = _chicken;
    lastSaveTime[_user] = block.timestamp;
    return _chicken;
  }

  function transferChickenFrom(address _from, address _to, uint256 _value)
    public
    returns (bool)
  {
    require(msg.sender == chickenTokenDelegator);
    require(saveChickenOf(_from) >= _value);
    savedChickenOf[_from] = savedChickenOf[_from] - _value;
    savedChickenOf[_to] = savedChickenOf[_to].add(_value);

    return true;
  }

  function chickenOf(address _user) public view returns (uint256) {
    return savedChickenOf[_user].add(_unclaimedChickenOf(_user));
  }

  /* INTERNAL FUNCTION */

  function _payChicken(address _user, uint256 _chicken) internal {
    uint256 _unclaimedChicken = _unclaimedChickenOf(_user);
    uint256 _extraChicken;

    if (_chicken > _unclaimedChicken) {
      _extraChicken = _chicken - _unclaimedChicken;
      require(savedChickenOf[_user] >= _extraChicken);
      savedChickenOf[_user] -= _extraChicken;
      totalChicken -= _extraChicken;
    } else {
      _extraChicken = _unclaimedChicken - _chicken;
      totalChicken = totalChicken.add(_extraChicken);
      savedChickenOf[_user] += _extraChicken;
    }

    lastSaveTime[_user] = block.timestamp;
  }

  function _payEthereumAndDistribute(uint256 _cost) internal {
    require(_cost * 100 / 100 == _cost);
    _payEthereum(_cost);

    uint256 _toShareholders = _cost * dividendRate / 100;
    uint256 _toAltar = _cost * altarCut / 100;
    uint256 _toStore = _cost * store.cut / 100;
    devFee = devFee.add(_cost - _toShareholders - _toAltar - _toStore);

    _giveShares(msg.sender, _toShareholders);
    altarFund = altarFund.add(_toAltar);
    store.balance = store.balance.add(_toStore);
  }

  function _payEthereum(uint256 _cost) internal {
    uint256 _extra;
    if (_cost > msg.value) {
      _extra = _cost - msg.value;
      require(ethereumBalance[msg.sender] >= _extra);
      ethereumBalance[msg.sender] -= _extra;
    } else {
      _extra = msg.value - _cost;
      ethereumBalance[msg.sender] = ethereumBalance[msg.sender].add(_extra);
    }
  }

  function _unclaimedChickenOf(address _user) internal view returns (uint256) {
    uint256 _timestamp = lastSaveTime[_user];
    if (_timestamp > 0 && _timestamp < block.timestamp) {
      return houses[_user].huntingPower.mul(
        houses[_user].huntingMultiplier
      ).mul(block.timestamp - _timestamp) / 100;
    } else {
      return 0;
    }
  }

  function _houseOf(address _user)
    internal
    view
    returns (House storage _house)
  {
    _house = houses[_user];
    require(_house.depots > 0);
  }

}


/**
 * @title CHHunter
 * @author M.H. Kang
 */
contract CHHunter is CHGameBase {

  /* EVENT */

  event UpgradeHunter(
    address indexed user,
    string attribute,
    uint256 to
  );

  /* DATA STRUCT */

  struct Config {
    uint256 chicken;
    uint256 ethereum;
    uint256 max;
  }

  /* STORAGE */

  Config public typeA;
  Config public typeB;

  /* FUNCTION */

  function upgradeStrength(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.strength;
    require(typeA.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeA);

    uint256 _increment = _house.hunter.dexterity.mul(2).add(8).mul(_to.square() - _from ** 2);
    _house.hunter.strength = _to;
    _house.huntingPower = _house.huntingPower.add(_increment);
    _house.offensePower = _house.offensePower.add(_increment);

    emit UpgradeHunter(msg.sender, "strength", _to);
  }

  function upgradeDexterity(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.dexterity;
    require(typeB.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeB);

    uint256 _increment = _house.hunter.strength.square().mul((_to - _from).mul(2));
    _house.hunter.dexterity = _to;
    _house.huntingPower = _house.huntingPower.add(_increment);
    _house.offensePower = _house.offensePower.add(_increment);

    emit UpgradeHunter(msg.sender, "dexterity", _to);
  }

  function upgradeConstitution(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.constitution;
    require(typeA.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeA);

    uint256 _increment = _house.hunter.resistance.mul(2).add(8).mul(_to.square() - _from ** 2);
    _house.hunter.constitution = _to;
    _house.defensePower = _house.defensePower.add(_increment);

    emit UpgradeHunter(msg.sender, "constitution", _to);
  }

  function upgradeResistance(uint256 _to) external payable {
    House storage _house = _houseOf(msg.sender);
    uint256 _from = _house.hunter.resistance;
    require(typeB.max >= _to && _to > _from);
    _payForUpgrade(_from, _to, typeB);

    uint256 _increment = _house.hunter.constitution.square().mul((_to - _from).mul(2));
    _house.hunter.resistance = _to;
    _house.defensePower = _house.defensePower.add(_increment);

    emit UpgradeHunter(msg.sender, "resistance", _to);
  }

  /* INTERNAL FUNCTION */

  function _payForUpgrade(uint256 _from, uint256 _to, Config _type) internal {
    uint256 _chickenCost = _type.chicken.mul(_gapOfCubeSum(_from, _to));
    _payChicken(msg.sender, _chickenCost);
    uint256 _ethereumCost = _type.ethereum.mul(_gapOfSquareSum(_from, _to));
    _payEthereumAndDistribute(_ethereumCost);
  }

  function _gapOfSquareSum(uint256 _before, uint256 _after)
    internal
    pure
    returns (uint256)
  {
    // max value is capped to uint32
    return (_after * (_after - 1) * (2 * _after - 1) - _before * (_before - 1) * (2 * _before - 1)) / 6;
  }

  function _gapOfCubeSum(uint256 _before, uint256 _after)
    internal
    pure
    returns (uint256)
  {
    // max value is capped to uint32
    return ((_after * (_after - 1)) ** 2 - (_before * (_before - 1)) ** 2) >> 2;
  }

}


/**
 * @title CHHouse
 * @author M.H. Kang
 */
contract CHHouse is CHHunter {

  /* EVENT */

  event UpgradePet(
    address indexed user,
    uint256 id,
    uint256 to
  );

  event UpgradeDepot(
    address indexed user,
    uint256 to
  );

  event BuyItem(
    address indexed from,
    address indexed to,
    uint256 indexed id,
    uint256 cost
  );

  event BuyStore(
    address indexed from,
    address indexed to,
    uint256 cost
  );

  /* DATA STRUCT */

  struct Pet {
    uint256 huntingPower;
    uint256 offensePower;
    uint256 defensePower;
    uint256 chicken;
    uint256 ethereum;
    uint256 max;
  }

  struct Item {
    address owner;
    uint256 huntingMultiplier;
    uint256 offenseMultiplier;
    uint256 defenseMultiplier;
    uint256 cost;
  }

  struct Depot {
    uint256 ethereum;
    uint256 max;
  }

  /* STORAGE */

  uint256 public constant INCREMENT_RATE = 12; // 120% for Item and Store
  Depot public depot;
  Pet[] public pets;
  Item[] public items;

  /* FUNCTION */

  function buyDepots(uint256 _amount) external payable {
    House storage _house = _houseOf(msg.sender);
    _house.depots = _house.depots.add(_amount);
    require(_house.depots <= depot.max);
    _payEthereumAndDistribute(_amount.mul(depot.ethereum));

    emit UpgradeDepot(msg.sender, _house.depots);
  }

  function buyPets(uint256 _id, uint256 _amount) external payable {
    require(_id < pets.length);
    Pet memory _pet = pets[_id];
    uint256 _chickenCost = _amount * _pet.chicken;
    _payChicken(msg.sender, _chickenCost);
    uint256 _ethereumCost = _amount * _pet.ethereum;
    _payEthereumAndDistribute(_ethereumCost);

    House storage _house = _houseOf(msg.sender);
    if (_house.pets.length < _id + 1) {
      _house.pets.length = _id + 1;
    }
    _house.pets[_id] = _house.pets[_id].add(_amount);
    require(_house.pets[_id] <= _pet.max);

    _house.huntingPower = _house.huntingPower.add(_pet.huntingPower * _amount);
    _house.offensePower = _house.offensePower.add(_pet.offensePower * _amount);
    _house.defensePower = _house.defensePower.add(_pet.defensePower * _amount);

    emit UpgradePet(msg.sender, _id, _house.pets[_id]);
  }

  // This is independent of Stock and Altar.
  function buyItem(uint256 _id) external payable {
    Item storage _item = items[_id];
    address _from = _item.owner;
    uint256 _price = _item.cost.mul(INCREMENT_RATE) / 10;
    _payEthereum(_price);

    saveChickenOf(_from);
    House storage _fromHouse = _houseOf(_from);
    _fromHouse.huntingMultiplier = _fromHouse.huntingMultiplier.sub(_item.huntingMultiplier);
    _fromHouse.offenseMultiplier = _fromHouse.offenseMultiplier.sub(_item.offenseMultiplier);
    _fromHouse.defenseMultiplier = _fromHouse.defenseMultiplier.sub(_item.defenseMultiplier);

    saveChickenOf(msg.sender);
    House storage _toHouse = _houseOf(msg.sender);
    _toHouse.huntingMultiplier = _toHouse.huntingMultiplier.add(_item.huntingMultiplier);
    _toHouse.offenseMultiplier = _toHouse.offenseMultiplier.add(_item.offenseMultiplier);
    _toHouse.defenseMultiplier = _toHouse.defenseMultiplier.add(_item.defenseMultiplier);

    uint256 _halfMargin = _price.sub(_item.cost) / 2;
    devFee = devFee.add(_halfMargin);
    ethereumBalance[_from] = ethereumBalance[_from].add(_price - _halfMargin);

    items[_id].cost = _price;
    items[_id].owner = msg.sender;

    emit BuyItem(_from, msg.sender, _id, _price);
  }

  // This is independent of Stock and Altar.
  function buyStore() external payable {
    address _from = store.owner;
    uint256 _price = store.cost.mul(INCREMENT_RATE) / 10;
    _payEthereum(_price);

    uint256 _halfMargin = (_price - store.cost) / 2;
    devFee = devFee.add(_halfMargin);
    ethereumBalance[_from] = ethereumBalance[_from].add(_price - _halfMargin).add(store.balance);

    store.cost = _price;
    store.owner = msg.sender;
    delete store.balance;

    emit BuyStore(_from, msg.sender, _price);
  }

  function withdrawStoreBalance() public {
    ethereumBalance[store.owner] = ethereumBalance[store.owner].add(store.balance);
    delete store.balance;
  }

}


/**
 * @title CHArena
 * @author M.H. Kang
 */
contract CHArena is CHHouse {

  /* EVENT */

  event Attack(
    address indexed attacker,
    address indexed defender,
    uint256 booty
  );

  /* STORAGE */

  mapping(address => uint256) public attackCooldown;
  uint256 public cooldownTime;

  /* FUNCTION */

  function attack(address _target) external {
    require(attackCooldown[msg.sender] < block.timestamp);
    House storage _attacker = houses[msg.sender];
    House storage _defender = houses[_target];
    if (_attacker.offensePower.mul(_attacker.offenseMultiplier)
        > _defender.defensePower.mul(_defender.defenseMultiplier)) {
      uint256 _chicken = saveChickenOf(_target);
      _chicken = _defender.depots > 0 ? _chicken / _defender.depots : _chicken;
      savedChickenOf[_target] = savedChickenOf[_target] - _chicken;
      savedChickenOf[msg.sender] = savedChickenOf[msg.sender].add(_chicken);
      attackCooldown[msg.sender] = block.timestamp + cooldownTime;

      emit Attack(msg.sender, _target, _chicken);
    }
  }

}


/**
 * @title CHAltar
 * @author M.H. Kang
 */
contract CHAltar is CHArena {

  /* EVENT */

  event NewAltarRecord(uint256 id, uint256 ethereum);
  event ChickenToAltar(address indexed user, uint256 id, uint256 chicken);
  event EthereumFromAltar(address indexed user, uint256 id, uint256 ethereum);

  /* DATA STRUCT */

  struct AltarRecord {
    uint256 ethereum;
    uint256 chicken;
  }

  struct TradeBook {
    uint256 altarRecordId;
    uint256 chicken;
  }

  /* STORAGE */

  uint256 public genesis;
  mapping (uint256 => AltarRecord) public altarRecords;
  mapping (address => TradeBook) public tradeBooks;

  /* FUNCTION */

  function chickenToAltar(uint256 _chicken) external {
    require(_chicken > 0);

    _payChicken(msg.sender, _chicken);
    uint256 _id = _getCurrentAltarRecordId();
    AltarRecord storage _altarRecord = _getAltarRecord(_id);
    require(_altarRecord.ethereum * _chicken / _chicken == _altarRecord.ethereum);
    TradeBook storage _tradeBook = tradeBooks[msg.sender];
    if (_tradeBook.altarRecordId < _id) {
      _resolveTradeBook(_tradeBook);
      _tradeBook.altarRecordId = _id;
    }
    _altarRecord.chicken = _altarRecord.chicken.add(_chicken);
    _tradeBook.chicken += _chicken;

    emit ChickenToAltar(msg.sender, _id, _chicken);
  }

  function ethereumFromAltar() external {
    uint256 _id = _getCurrentAltarRecordId();
    TradeBook storage _tradeBook = tradeBooks[msg.sender];
    require(_tradeBook.altarRecordId < _id);
    _resolveTradeBook(_tradeBook);
  }

  function tradeBookOf(address _user)
    public
    view
    returns (
      uint256 _id,
      uint256 _ethereum,
      uint256 _totalChicken,
      uint256 _chicken,
      uint256 _income
    )
  {
    TradeBook memory _tradeBook = tradeBooks[_user];
    _id = _tradeBook.altarRecordId;
    _chicken = _tradeBook.chicken;
    AltarRecord memory _altarRecord = altarRecords[_id];
    _totalChicken = _altarRecord.chicken;
    _ethereum = _altarRecord.ethereum;
    _income = _totalChicken > 0 ? _ethereum.mul(_chicken) / _totalChicken : 0;
  }

  /* INTERNAL FUNCTION */

  function _resolveTradeBook(TradeBook storage _tradeBook) internal {
    if (_tradeBook.chicken > 0) {
      AltarRecord memory _oldAltarRecord = altarRecords[_tradeBook.altarRecordId];
      uint256 _ethereum = _oldAltarRecord.ethereum.mul(_tradeBook.chicken) / _oldAltarRecord.chicken;
      delete _tradeBook.chicken;
      ethereumBalance[msg.sender] = ethereumBalance[msg.sender].add(_ethereum);

      emit EthereumFromAltar(msg.sender, _tradeBook.altarRecordId, _ethereum);
    }
  }

  function _getCurrentAltarRecordId() internal view returns (uint256) {
    return (block.timestamp - genesis) / 86400;
  }

  function _getAltarRecord(uint256 _id) internal returns (AltarRecord storage _altarRecord) {
    _altarRecord = altarRecords[_id];
    if (_altarRecord.ethereum == 0) {
      uint256 _ethereum = altarFund / 10;
      _altarRecord.ethereum = _ethereum;
      altarFund -= _ethereum;

      emit NewAltarRecord(_id, _ethereum);
    }
  }

}


/**
 * @title CHCommittee
 * @author M.H. Kang
 */
contract CHCommittee is CHAltar {

  /* EVENT */

  event NewPet(
    uint256 id,
    uint256 huntingPower,
    uint256 offensePower,
    uint256 defense,
    uint256 chicken,
    uint256 ethereum,
    uint256 max
  );

  event ChangePet(
    uint256 id,
    uint256 chicken,
    uint256 ethereum,
    uint256 max
  );

  event NewItem(
    uint256 id,
    uint256 huntingMultiplier,
    uint256 offenseMultiplier,
    uint256 defenseMultiplier,
    uint256 ethereum
  );

  event SetDepot(uint256 ethereum, uint256 max);

  event SetConfiguration(
    uint256 chickenA,
    uint256 ethereumA,
    uint256 maxA,
    uint256 chickenB,
    uint256 ethereumB,
    uint256 maxB
  );

  event SetDistribution(
    uint256 dividendRate,
    uint256 altarCut,
    uint256 storeCut,
    uint256 devCut
  );

  event SetCooldownTime(uint256 cooldownTime);
  event SetNameAndSymbol(string name, string symbol);
  event SetDeveloper(address developer);
  event SetCommittee(address committee);

  /* STORAGE */

  address public committee;
  address public developer;

  /* FUNCTION */

  function callFor(address _to, uint256 _value, uint256 _gas, bytes _code)
    external
    payable
    onlyCommittee
    returns (bool)
  {
    return _to.call.value(_value).gas(_gas)(_code);
  }

  function addPet(
    uint256 _huntingPower,
    uint256 _offensePower,
    uint256 _defense,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  )
    public
    onlyCommittee
  {
    require(_max > 0);
    require(_max == uint256(uint32(_max)));
    uint256 _newLength = pets.push(
      Pet(_huntingPower, _offensePower, _defense, _chicken, _ethereum, _max)
    );

    emit NewPet(
      _newLength - 1,
      _huntingPower,
      _offensePower,
      _defense,
      _chicken,
      _ethereum,
      _max
    );
  }

  function changePet(
    uint256 _id,
    uint256 _chicken,
    uint256 _ethereum,
    uint256 _max
  )
    public
    onlyCommittee
  {
    require(_id < pets.length);
    Pet storage _pet = pets[_id];
    require(_max >= _pet.max && _max == uint256(uint32(_max)));

    _pet.chicken = _chicken;
    _pet.ethereum = _ethereum;
    _pet.max = _max;

    emit ChangePet(_id, _chicken, _ethereum, _max);
  }

  function addItem(
    uint256 _huntingMultiplier,
    uint256 _offenseMultiplier,
    uint256 _defenseMultiplier,
    uint256 _price
  )
    public
    onlyCommittee
  {
    uint256 _cap = 1 << 16;
    require(
      _huntingMultiplier < _cap &&
      _offenseMultiplier < _cap &&
      _defenseMultiplier < _cap
    );
    saveChickenOf(committee);
    House storage _house = _houseOf(committee);
    _house.huntingMultiplier = _house.huntingMultiplier.add(_huntingMultiplier);
    _house.offenseMultiplier = _house.offenseMultiplier.add(_offenseMultiplier);
    _house.defenseMultiplier = _house.defenseMultiplier.add(_defenseMultiplier);

    uint256 _newLength = items.push(
      Item(
        committee,
        _huntingMultiplier,
        _offenseMultiplier,
        _defenseMultiplier,
        _price
      )
    );

    emit NewItem(
      _newLength - 1,
      _huntingMultiplier,
      _offenseMultiplier,
      _defenseMultiplier,
      _price
    );
  }

  function setDepot(uint256 _price, uint256 _max) public onlyCommittee {
    require(_max >= depot.max);

    depot.ethereum = _price;
    depot.max = _max;

    emit SetDepot(_price, _max);
  }

  function setConfiguration(
    uint256 _chickenA,
    uint256 _ethereumA,
    uint256 _maxA,
    uint256 _chickenB,
    uint256 _ethereumB,
    uint256 _maxB
  )
    public
    onlyCommittee
  {
    require(_maxA >= typeA.max && (_maxA == uint256(uint32(_maxA))));
    require(_maxB >= typeB.max && (_maxB == uint256(uint32(_maxB))));

    typeA.chicken = _chickenA;
    typeA.ethereum = _ethereumA;
    typeA.max = _maxA;

    typeB.chicken = _chickenB;
    typeB.ethereum = _ethereumB;
    typeB.max = _maxB;

    emit SetConfiguration(_chickenA, _ethereumA, _maxA, _chickenB, _ethereumB, _maxB);
  }

  function setDistribution(
    uint256 _dividendRate,
    uint256 _altarCut,
    uint256 _storeCut,
    uint256 _devCut
  )
    public
    onlyCommittee
  {
    require(_storeCut > 0);
    require(
      _dividendRate.add(_altarCut).add(_storeCut).add(_devCut) == 100
    );

    dividendRate = _dividendRate;
    altarCut = _altarCut;
    store.cut = _storeCut;
    devCut = _devCut;

    emit SetDistribution(_dividendRate, _altarCut, _storeCut, _devCut);
  }

  function setCooldownTime(uint256 _cooldownTime) public onlyCommittee {
    cooldownTime = _cooldownTime;

    emit SetCooldownTime(_cooldownTime);
  }

  function setNameAndSymbol(string _name, string _symbol)
    public
    onlyCommittee
  {
    name = _name;
    symbol = _symbol;

    emit SetNameAndSymbol(_name, _symbol);
  }

  function setDeveloper(address _developer) public onlyCommittee {
    require(_developer != address(0));
    withdrawDevFee();
    developer = _developer;

    emit SetDeveloper(_developer);
  }

  function setCommittee(address _committee) public onlyCommittee {
    require(_committee != address(0));
    committee = _committee;

    emit SetCommittee(_committee);
  }

  function withdrawDevFee() public {
    ethereumBalance[developer] = ethereumBalance[developer].add(devFee);
    delete devFee;
  }

  /* MODIFIER */

  modifier onlyCommittee {
    require(msg.sender == committee);
    _;
  }

}


/**
 * @title ChickenHunt
 * @author M.H. Kang
 */
contract ChickenHunt is CHCommittee {

  /* EVENT */

  event Join(address user);

  /* CONSTRUCTOR */

  constructor() public {
    committee = msg.sender;
    developer = msg.sender;
  }

  /* FUNCTION */

  function init(address _chickenTokenDelegator) external onlyCommittee {
    require(chickenTokenDelegator == address(0));
    chickenTokenDelegator = _chickenTokenDelegator;
    genesis = 1525791600;
    join();
    store.owner = msg.sender;
    store.cost = 0.1 ether;
    setConfiguration(100, 0.00001 ether, 99, 100000, 0.001 ether, 9);
    setDistribution(20, 75, 1, 4);
    setCooldownTime(600);
    setDepot(0.05 ether, 9);
    addItem(5, 5, 0, 0.01 ether);
    addItem(0, 0, 5, 0.01 ether);
    addPet(1000, 0, 0, 100000, 0.01 ether, 9);
    addPet(0, 1000, 0, 100000, 0.01 ether, 9);
    addPet(0, 0, 1000, 202500, 0.01 ether, 9);
  }

  function withdraw() external {
    uint256 _ethereum = ethereumBalance[msg.sender];
    delete ethereumBalance[msg.sender];
    msg.sender.transfer(_ethereum);
  }

  function join() public {
    House storage _house = houses[msg.sender];
    require(_house.depots == 0);
    _house.hunter = Hunter(1, 1, 1, 1);
    _house.depots = 1;
    _house.huntingPower = 10;
    _house.offensePower = 10;
    _house.defensePower = 110;
    _house.huntingMultiplier = 10;
    _house.offenseMultiplier = 10;
    _house.defenseMultiplier = 10;
    lastSaveTime[msg.sender] = block.timestamp;

    emit Join(msg.sender);
  }

  function hunterOf(address _user)
    public
    view
    returns (
      uint256 _strength,
      uint256 _dexterity,
      uint256 _constitution,
      uint256 _resistance
    )
  {
    Hunter memory _hunter = houses[_user].hunter;
    return (
      _hunter.strength,
      _hunter.dexterity,
      _hunter.constitution,
      _hunter.resistance
    );
  }

  function detailsOf(address _user)
    public
    view
    returns (
      uint256[2] _hunting,
      uint256[2] _offense,
      uint256[2] _defense,
      uint256[4] _hunter,
      uint256[] _pets,
      uint256 _depots,
      uint256 _savedChicken,
      uint256 _lastSaveTime,
      uint256 _cooldown
    )
  {
    House memory _house = houses[_user];

    _hunting = [_house.huntingPower, _house.huntingMultiplier];
    _offense = [_house.offensePower, _house.offenseMultiplier];
    _defense = [_house.defensePower, _house.defenseMultiplier];
    _hunter = [
      _house.hunter.strength,
      _house.hunter.dexterity,
      _house.hunter.constitution,
      _house.hunter.resistance
    ];
    _pets = _house.pets;
    _depots = _house.depots;
    _savedChicken = savedChickenOf[_user];
    _lastSaveTime = lastSaveTime[_user];
    _cooldown = attackCooldown[_user];
  }

}