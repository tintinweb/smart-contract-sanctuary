pragma solidity ^0.4.11;


contract Storage {
    struct Crate {
        mapping(bytes32 => uint256) uints;
        mapping(bytes32 => address) addresses;
        mapping(bytes32 => bool) bools;
        mapping(address => uint256) bals;
    }

    mapping(bytes32 => Crate) crates;

    function setUInt(bytes32 _crate, bytes32 _key, uint256 _value)  {
        crates[_crate].uints[_key] = _value;
    }

    function getUInt(bytes32 _crate, bytes32 _key) constant returns(uint256) {
        return crates[_crate].uints[_key];
    }

    function setAddress(bytes32 _crate, bytes32 _key, address _value)  {
        crates[_crate].addresses[_key] = _value;
    }

    function getAddress(bytes32 _crate, bytes32 _key) constant returns(address) {
        return crates[_crate].addresses[_key];
    }

    function setBool(bytes32 _crate, bytes32 _key, bool _value)  {
        crates[_crate].bools[_key] = _value;
    }

    function getBool(bytes32 _crate, bytes32 _key) constant returns(bool) {
        return crates[_crate].bools[_key];
    }

    function setBal(bytes32 _crate, address _key, uint256 _value)  {
        crates[_crate].bals[_key] = _value;
    }

    function getBal(bytes32 _crate, address _key) constant returns(uint256) {
        return crates[_crate].bals[_key];
    }
}

contract StorageEnabled {

  // satelite contract addresses
  address public storageAddr;

  function StorageEnabled(address _storageAddr) {
    storageAddr = _storageAddr;
  }


  // ############################################
  // ########### NUTZ FUNCTIONS  ################
  // ############################################


  // all Nutz balances
  function babzBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal(&#39;Nutz&#39;, _owner);
  }
  function _setBabzBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal(&#39;Nutz&#39;, _owner, _newValue);
  }
  // active supply - sum of balances above
  function activeSupply() constant returns (uint256) {
    return Storage(storageAddr).getUInt(&#39;Nutz&#39;, &#39;activeSupply&#39;);
  }
  function _setActiveSupply(uint256 _newActiveSupply) internal {
    Storage(storageAddr).setUInt(&#39;Nutz&#39;, &#39;activeSupply&#39;, _newActiveSupply);
  }
  // burn pool - inactive supply
  function burnPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt(&#39;Nutz&#39;, &#39;burnPool&#39;);
  }
  function _setBurnPool(uint256 _newBurnPool) internal {
    Storage(storageAddr).setUInt(&#39;Nutz&#39;, &#39;burnPool&#39;, _newBurnPool);
  }
  // power pool - inactive supply
  function powerPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt(&#39;Nutz&#39;, &#39;powerPool&#39;);
  }
  function _setPowerPool(uint256 _newPowerPool) internal {
    Storage(storageAddr).setUInt(&#39;Nutz&#39;, &#39;powerPool&#39;, _newPowerPool);
  }





  // ############################################
  // ########### POWER   FUNCTIONS  #############
  // ############################################

  // all power balances
  function powerBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal(&#39;Power&#39;, _owner);
  }

  function _setPowerBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal(&#39;Power&#39;, _owner, _newValue);
  }

  function outstandingPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt(&#39;Power&#39;, &#39;outstandingPower&#39;);
  }

  function _setOutstandingPower(uint256 _newOutstandingPower) internal {
    Storage(storageAddr).setUInt(&#39;Power&#39;, &#39;outstandingPower&#39;, _newOutstandingPower);
  }

  function authorizedPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt(&#39;Power&#39;, &#39;authorizedPower&#39;);
  }

  function _setAuthorizedPower(uint256 _newAuthorizedPower) internal {
    Storage(storageAddr).setUInt(&#39;Power&#39;, &#39;authorizedPower&#39;, _newAuthorizedPower);
  }


  function downs(address _user) constant public returns (uint256 total, uint256 left, uint256 start) {
    uint256 rawBytes = Storage(storageAddr).getBal(&#39;PowerDown&#39;, _user);
    start = uint64(rawBytes);
    left = uint96(rawBytes >> (64));
    total = uint96(rawBytes >> (96 + 64));
    return;
  }

  function _setDownRequest(address _holder, uint256 total, uint256 left, uint256 start) internal {
    uint256 result = uint64(start) + (left << 64) + (total << (96 + 64));
    Storage(storageAddr).setBal(&#39;PowerDown&#39;, _holder, result);
  }

}


contract Governable {

  // list of admins, council at first spot
  address[] public admins;

  function Governable() {
    admins.length = 1;
    admins[0] = msg.sender;
  }

  modifier onlyAdmins() {
    bool isAdmin = false;
    for (uint256 i = 0; i < admins.length; i++) {
      if (msg.sender == admins[i]) {
        isAdmin = true;
      }
    }
    require(isAdmin == true);
    _;
  }

  function addAdmin(address _admin) public onlyAdmins {
    for (uint256 i = 0; i < admins.length; i++) {
      require(_admin != admins[i]);
    }
    require(admins.length < 10);
    admins[admins.length++] = _admin;
  }

  function removeAdmin(address _admin) public onlyAdmins {
    uint256 pos = admins.length;
    for (uint256 i = 0; i < admins.length; i++) {
      if (_admin == admins[i]) {
        pos = i;
      }
    }
    require(pos < admins.length);
    // if not last element, switch with last
    if (pos < admins.length - 1) {
      admins[pos] = admins[admins.length - 1];
    }
    // then cut off the tail
    admins.length--;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Governable {

  bool public paused = true;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyAdmins whenNotPaused {
    paused = true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyAdmins whenPaused {
    //TODO: do some checks
    paused = false;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract NutzEnabled is Pausable, StorageEnabled {
  using SafeMath for uint;

  // satelite contract addresses
  address public nutzAddr;


  modifier onlyNutz() {
    require(msg.sender == nutzAddr);
    _;
  }

  function NutzEnabled(address _nutzAddr, address _storageAddr)
    StorageEnabled(_storageAddr) {
    nutzAddr = _nutzAddr;
  }

  // ############################################
  // ########### NUTZ FUNCTIONS  ################
  // ############################################

  // total supply
  function totalSupply() constant returns (uint256) {
    return activeSupply().add(powerPool()).add(burnPool());
  }

  // allowances according to ERC20
  // not written to storage, as not very critical
  mapping (address => mapping (address => uint)) internal allowed;

  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _owner, address _spender, uint256 _amountBabz) public onlyNutz whenNotPaused {
    require(_owner != _spender);
    allowed[_owner][_spender] = _amountBabz;
  }

  function _transfer(address _from, address _to, uint256 _amountBabz, bytes _data) internal {
    require(_to != address(this));
    require(_to != address(0));
    require(_amountBabz > 0);
    require(_from != _to);
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setBabzBalanceOf(_to, babzBalanceOf(_to).add(_amountBabz));
  }

  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    _transfer(_from, _to, _amountBabz, _data);
  }

  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    _transfer(_from, _to, _amountBabz, _data);
  }

}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments.
 */
contract PullPayment {

  modifier onlyNutz() {
      _;
  }
  
modifier onlyOwner() {
      _;
  }

  modifier whenNotPaused () {_;}

  function balanceOf(address _owner) constant returns (uint256 value);

  function paymentOf(address _owner) constant returns (uint256 value, uint256 date) ;

  /// @dev Allows to change the daily limit. Transaction has to be sent by wallet.
  /// @param _dailyLimit Amount in wei.
  function changeDailyLimit(uint _dailyLimit) public ;

  function changeWithdrawalDate(address _owner, uint256 _newDate)  public ;

  function asyncSend(address _dest) public payable ;


  function withdraw() public ;

  /*
   * Internal functions
   */
  /// @dev Returns if amount is within daily limit and resets spentToday after one day.
  /// @param amount Amount to withdraw.
  /// @return Returns if amount is under daily limit.
  function isUnderLimit(uint amount) internal returns (bool);

}


/**
 * Nutz implements a price floor and a price ceiling on the token being
 * sold. It is based of the zeppelin token contract.
 */
contract Nutz {


  // returns balances of active holders
  function balanceOf(address _owner) constant returns (uint);

  function totalSupply() constant returns (uint256);

  function activeSupply() constant returns (uint256);

  // return remaining allowance
  // if calling return allowed[address(this)][_spender];
  // returns balance of ether parked to be withdrawn
  function allowance(address _owner, address _spender) constant returns (uint256);

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function floor() constant returns (uint256);

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function ceiling() constant returns (uint256);

  function powerPool() constant returns (uint256);


  function _checkDestination(address _from, address _to, uint256 _value, bytes _data) internal;



  // ############################################
  // ########### ADMIN FUNCTIONS ################
  // ############################################

  function powerDown(address powerAddr, address _holder, uint256 _amountBabz) public ;


  function asyncSend(address _pullAddr, address _dest, uint256 _amountWei) public ;


  // ############################################
  // ########### PUBLIC FUNCTIONS ###############
  // ############################################

  function approve(address _spender, uint256 _amountBabz) public;

  function transfer(address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transfer(address _to, uint256 _amountBabz) public returns (bool);

  function transData(address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _amountBabz);

  function () public payable;

  function purchase(uint256 _price) public payable;

  function sell(uint256 _price, uint256 _amountBabz);

  function powerUp(uint256 _amountBabz) public;

}


contract MarketEnabled is NutzEnabled {

  uint256 constant INFINITY = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  // address of the pull payemnt satelite
  address public pullAddr;

  // the Token sale mechanism parameters:
  // purchasePrice is the number of NTZ received for purchase with 1 ETH
  uint256 internal purchasePrice;

  // floor is the number of NTZ needed, to receive 1 ETH in sell
  uint256 internal salePrice;

  function MarketEnabled(address _pullAddr, address _storageAddr, address _nutzAddr)
    NutzEnabled(_nutzAddr, _storageAddr) {
    pullAddr = _pullAddr;
  }


  function ceiling() constant returns (uint256) {
    return purchasePrice;
  }

  // returns either the salePrice, or if reserve does not suffice
  // for active supply, returns maxFloor
  function floor() constant returns (uint256) {
    if (nutzAddr.balance == 0) {
      return INFINITY;
    }
    uint256 maxFloor = activeSupply().mul(1000000).div(nutzAddr.balance); // 1,000,000 WEI, used as price factor
    // return max of maxFloor or salePrice
    return maxFloor >= salePrice ? maxFloor : salePrice;
  }

  function moveCeiling(uint256 _newPurchasePrice) public onlyAdmins {
    require(_newPurchasePrice <= salePrice);
    purchasePrice = _newPurchasePrice;
  }

  function moveFloor(uint256 _newSalePrice) public onlyAdmins {
    require(_newSalePrice >= purchasePrice);
    // moveFloor fails if the administrator tries to push the floor so low
    // that the sale mechanism is no longer able to buy back all tokens at
    // the floor price if those funds were to be withdrawn.
    if (_newSalePrice < INFINITY) {
      require(nutzAddr.balance >= activeSupply().mul(1000000).div(_newSalePrice)); // 1,000,000 WEI, used as price factor
    }
    salePrice = _newSalePrice;
  }

  function purchase(address _sender, uint256 _value, uint256 _price) public onlyNutz whenNotPaused returns (uint256) {
    // disable purchases if purchasePrice set to 0
    require(purchasePrice > 0);
    require(_price == purchasePrice);

    uint256 amountBabz = purchasePrice.mul(_value).div(1000000); // 1,000,000 WEI, used as price factor
    // avoid deposits that issue nothing
    // might happen with very high purchase price
    require(amountBabz > 0);

    // make sure power pool grows proportional to economy
    uint256 activeSup = activeSupply();
    uint256 powPool = powerPool();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(amountBabz).div(activeSup.add(burnPool()));
      _setPowerPool(powPool.add(powerShare));
    }
    _setActiveSupply(activeSup.add(amountBabz));
    _setBabzBalanceOf(_sender, babzBalanceOf(_sender).add(amountBabz));
    return amountBabz;
  }

  function sell(address _from, uint256 _price, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 effectiveFloor = floor();
    require(_amountBabz != 0);
    require(effectiveFloor != INFINITY);
    require(_price == effectiveFloor);

    uint256 amountWei = _amountBabz.mul(1000000).div(effectiveFloor);  // 1,000,000 WEI, used as price factor
    require(amountWei > 0);
    // make sure power pool shrinks proportional to economy
    uint256 powPool = powerPool();
    uint256 activeSup = activeSupply();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(_amountBabz).div(activeSup);
      _setPowerPool(powPool.sub(powerShare));
    }
    _setActiveSupply(activeSup.sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    Nutz(nutzAddr).asyncSend(pullAddr, _from, amountWei);
  }


  // withdraw excessive reserve - i.e. milestones
  function allocateEther(uint256 _amountWei, address _beneficiary) public onlyAdmins {
    require(_amountWei > 0);
    // allocateEther fails if allocating those funds would mean that the
    // sale mechanism is no longer able to buy back all tokens at the floor
    // price if those funds were to be withdrawn.
    require(nutzAddr.balance.sub(_amountWei) >= activeSupply().mul(1000000).div(salePrice)); // 1,000,000 WEI, used as price factor
    Nutz(nutzAddr).asyncSend(pullAddr, _beneficiary, _amountWei);
  }

}



contract Power {



  function balanceOf(address _holder) constant returns (uint256);

  function totalSupply() constant returns (uint256);

  function activeSupply() constant returns (uint256);


  // ############################################
  // ########### ADMIN FUNCTIONS ################
  // ############################################

  function slashPower(address _holder, uint256 _value, bytes32 _data) public ;

  function powerUp(address _holder, uint256 _value) public ;

  // ############################################
  // ########### PUBLIC FUNCTIONS ###############
  // ############################################

  // registers a powerdown request
  function transfer(address _to, uint256 _amountPower) public returns (bool success);

  function downtime() public returns (uint256);

  function downTick(address _owner) public;

  function downs(address _owner) constant public returns (uint256, uint256, uint256);

}


contract PowerEnabled is MarketEnabled {

  // satelite contract addresses
  address public powerAddr;

  // maxPower is a limit of total power that can be outstanding
  // maxPower has a valid value between outstandingPower and authorizedPow/2
  uint256 public maxPower = 0;

  // time it should take to power down
  uint256 public downtime;

  modifier onlyPower() {
    require(msg.sender == powerAddr);
    _;
  }

  function PowerEnabled(address _powerAddr, address _pullAddr, address _storageAddr, address _nutzAddr)
    MarketEnabled(_pullAddr, _nutzAddr, _storageAddr) {
    powerAddr = _powerAddr;
  }

  function setMaxPower(uint256 _maxPower) public onlyAdmins {
    require(outstandingPower() <= _maxPower && _maxPower < authorizedPower());
    maxPower = _maxPower;
  }

  function setDowntime(uint256 _downtime) public onlyAdmins {
    downtime = _downtime;
  }

  // this is called when NTZ are deposited into the burn pool
  function dilutePower(uint256 _amountBabz, uint256 _amountPower) public onlyAdmins {
    uint256 authorizedPow = authorizedPower();
    uint256 totalBabz = totalSupply();
    if (authorizedPow == 0) {
      // during the first capital increase, set value directly as authorized shares
      _setAuthorizedPower((_amountPower > 0) ? _amountPower : _amountBabz.add(totalBabz));
    } else {
      // in later increases, expand authorized shares at same rate like economy
      _setAuthorizedPower(authorizedPow.mul(totalBabz.add(_amountBabz)).div(totalBabz));
    }
    _setBurnPool(burnPool().add(_amountBabz));
  }

  function _slashPower(address _holder, uint256 _value, bytes32 _data) internal {
    uint256 previouslyOutstanding = outstandingPower();
    _setOutstandingPower(previouslyOutstanding.sub(_value));
    // adjust size of power pool
    uint256 powPool = powerPool();
    uint256 slashingBabz = _value.mul(powPool).div(previouslyOutstanding);
    _setPowerPool(powPool.sub(slashingBabz));
    // put event into satelite contract
    Power(powerAddr).slashPower(_holder, _value, _data);
  }

  function slashPower(address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    _setPowerBalanceOf(_holder, powerBalanceOf(_holder).sub(_value));
    _slashPower(_holder, _value, _data);
  }

  function slashDownRequest(uint256 _pos, address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    var (total, left, start) = downs(_holder);
    left = left.sub(_value);
    _setDownRequest(_holder, total, left, start);
    _slashPower(_holder, _value, _data);
  }

  // this is called when NTZ are deposited into the power pool
  function powerUp(address _sender, address _from, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 authorizedPow = authorizedPower();
    require(authorizedPow != 0);
    require(_amountBabz != 0);
    uint256 totalBabz = totalSupply();
    require(totalBabz != 0);
    uint256 amountPow = _amountBabz.mul(authorizedPow).div(totalBabz);
    // check pow limits
    uint256 outstandingPow = outstandingPower();
    require(outstandingPow.add(amountPow) <= maxPower);

    if (_sender != _from) {
      allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    }

    _setOutstandingPower(outstandingPow.add(amountPow));

    uint256 powBal = powerBalanceOf(_from).add(amountPow);
    require(powBal >= authorizedPow.div(10000)); // minShare = 10000
    _setPowerBalanceOf(_from, powBal);
    _setActiveSupply(activeSupply().sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setPowerPool(powerPool().add(_amountBabz));
    Power(powerAddr).powerUp(_from, amountPow);
  }

  function powerTotalSupply() constant returns (uint256) {
    uint256 issuedPower = authorizedPower().div(2);
    // return max of maxPower or issuedPower
    return maxPower >= issuedPower ? maxPower : issuedPower;
  }

  function _vestedDown(uint256 _total, uint256 _left, uint256 _start, uint256 _now) internal constant returns (uint256) {
    if (_now <= _start) {
      return 0;
    }
    // calculate amountVested
    // amountVested is amount that can be withdrawn according to time passed
    uint256 timePassed = _now.sub(_start);
    if (timePassed > downtime) {
     timePassed = downtime;
    }
    uint256 amountVested = _total.mul(timePassed).div(downtime);
    uint256 amountFrozen = _total.sub(amountVested);
    if (_left <= amountFrozen) {
      return 0;
    }
    return _left.sub(amountFrozen);
  }

  function createDownRequest(address _owner, uint256 _amountPower) public onlyPower whenNotPaused {
    // prevent powering down tiny amounts
    // when powering down, at least totalSupply/minShare Power should be claimed
    require(_amountPower >= authorizedPower().div(10000)); // minShare = 10000;
    _setPowerBalanceOf(_owner, powerBalanceOf(_owner).sub(_amountPower));

    var (, left, ) = downs(_owner);
    uint256 total = _amountPower.add(left);
    _setDownRequest(_owner, total, total, now);
  }

  // executes a powerdown request
  function downTick(address _holder, uint256 _now) public onlyPower whenNotPaused {
    var (total, left, start) = downs(_holder);
    uint256 amountPow = _vestedDown(total, left, start, _now);

    // prevent power down in tiny steps
    uint256 minStep = total.div(10);
    require(left <= minStep || minStep <= amountPow);

    // calculate token amount representing share of power
    uint256 amountBabz = amountPow.mul(totalSupply()).div(authorizedPower());

    // transfer power and tokens
    _setOutstandingPower(outstandingPower().sub(amountPow));
    left = left.sub(amountPow);
    _setPowerPool(powerPool().sub(amountBabz));
    _setActiveSupply(activeSupply().add(amountBabz));
    _setBabzBalanceOf(_holder, babzBalanceOf(_holder).add(amountBabz));
    // down request completed
    if (left == 0) {
      start = 0;
      total = 0;
    }
    // TODO
    _setDownRequest(_holder, total, left, start);
    Nutz(nutzAddr).powerDown(powerAddr, _holder, amountBabz);
  }
}


contract Controller is PowerEnabled {

  function Controller(address _powerAddr, address _pullAddr, address _nutzAddr, address _storageAddr) 
    PowerEnabled(_powerAddr, _pullAddr, _nutzAddr, _storageAddr) {
  }

  function setContracts(address _storageAddr, address _nutzAddr, address _powerAddr, address _pullAddr) public onlyAdmins whenPaused {
    storageAddr = _storageAddr;
    nutzAddr = _nutzAddr;
    powerAddr = _powerAddr;
    pullAddr = _pullAddr;
  }

  function changeDailyLimit(uint256 _dailyLimit) public onlyAdmins {
    PullPayment(pullAddr).changeDailyLimit(_dailyLimit);
  }

  function kill(address _newController) public onlyAdmins whenPaused {
    if (powerAddr != address(0)) { Ownable(powerAddr).transferOwnership(msg.sender); }
    if (pullAddr != address(0)) { Ownable(pullAddr).transferOwnership(msg.sender); }
    if (nutzAddr != address(0)) { Ownable(nutzAddr).transferOwnership(msg.sender); }
    if (storageAddr != address(0)) { Ownable(storageAddr).transferOwnership(msg.sender); }
    selfdestruct(_newController);
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}