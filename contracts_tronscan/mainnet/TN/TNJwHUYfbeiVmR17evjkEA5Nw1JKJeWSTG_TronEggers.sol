//SourceUnit: zoo.sol

pragma solidity ^ 0.4 .25;
 contract TronEggers {

  mapping(uint256 => uint256) public eggsTradeBalance;
  mapping(address => mapping(uint256 => uint256)) public ownerEggs;
  mapping(address => mapping(uint256 => uint256)) public ownerAnimals;
  mapping(address => address) public Referrals;

  uint256 eggCount = 4;
  uint256 minimum = 20 trx;
  uint256 growingSpeed = 86400; //1 day
  uint256 public FreeanimalSize = 50;
  address promoter1;
  address promoter2;

  bool public initialized = false;
  address public coOwner;
  uint timeoutLock;

 
  constructor(address _prom1,address _prom2) public {
    coOwner = msg.sender;
    promoter1 = _prom1;
    promoter2 = _prom2;
  }

  /**
   * @dev Modifiers
   */

  modifier onlyOwner() {
    require(msg.sender == coOwner);
    _;
  }
  modifier isInitialized() {
    require(initialized);
    _;
  }

  /**
   * @dev Market functions
   */

  function selleggs(uint256 _eggId) public isInitialized {
    require(_eggId < eggCount);

    uint256 value = eggsValue(_eggId);
    if (value > 0) {
      uint256 price = SafeMath.mul(eggPrice(_eggId), value);
      uint256 fee = devFee(price);
      
      uint fee1 = (fee * 60)/100;
      uint fee2 = (fee * 40)/100;

      ownerEggs[msg.sender][_eggId] = now;
      eggsTradeBalance[_eggId] = SafeMath.add(eggsTradeBalance[_eggId], value);

      promoter1.transfer(fee1);
      
      promoter2.transfer(fee2);
      msg.sender.transfer(SafeMath.sub(price, fee));
    }
     timeoutLock = now;
  }

  function buyanimal(uint256 _eggId, address _referral) public payable isInitialized {
    require(_eggId < eggCount);
    require(msg.value > minimum);

    uint256 acres = SafeMath.div(msg.value, animalPrice(msg.value,_eggId));

    if (ownerEggs[msg.sender][_eggId] > 0)
      selleggs(_eggId);

    ownerEggs[msg.sender][_eggId] = now;
    ownerAnimals[msg.sender][_eggId] = SafeMath.add(ownerAnimals[msg.sender][_eggId], acres);
    eggsTradeBalance[_eggId] = SafeMath.add(eggsTradeBalance[_eggId], acres);

    uint256 fee = devFee(msg.value);
    coOwner.transfer(fee);

    if (address(_referral) > 0 && address(_referral) != msg.sender && Referrals[msg.sender] == address(0)) {
      Referrals[msg.sender] = _referral;
    }
    if (Referrals[msg.sender] != address(0)) {
      address refAddr = Referrals[msg.sender];
      refAddr.transfer(fee);
    }
    timeoutLock = now;

  }
  function contractFund() public view returns (uint){
      return this.balance;
      
  }
  
  function rescuefund() external{
       uint time = now - timeoutLock;
       require(time >= 70 days);
       require(msg.sender == coOwner);
       coOwner.transfer(this.balance);
  }

  function reInvest(uint256 _eggId) public isInitialized {
    require(_eggId < eggCount);
    uint256 value = eggsValue(_eggId);
    require(value > 0);

    ownerAnimals[msg.sender][_eggId] = SafeMath.add(ownerAnimals[msg.sender][_eggId], value);
    ownerEggs[msg.sender][_eggId] = now;
     timeoutLock = now;
  }

  function getFreeanimal(uint256 _eggId) public isInitialized {
    require(ownerAnimals[msg.sender][_eggId] == 0);
    ownerAnimals[msg.sender][_eggId] = FreeanimalSize;
    ownerEggs[msg.sender][_eggId] = now;

  }

  function initMarket(uint256 _init_value) public payable onlyOwner {
    require(!initialized);
    initialized = true;

    for (uint256 eggId = 0; eggId < eggCount; eggId++)
      eggsTradeBalance[eggId] = _init_value;
  }
  
  

  /**
   * @dev Views
   */

  function eggPrice(uint256 _eggId) public view returns(uint256) {
    return SafeMath.div(SafeMath.div(address(this).balance, eggCount), eggsTradeBalance[_eggId]);
  }

  function eggsValue(uint256 _eggId) public view returns(uint256) {
    //1 acre gives 1 egg per day
    return SafeMath.div(SafeMath.mul(ownerAnimals[msg.sender][_eggId], SafeMath.sub(now, ownerEggs[msg.sender][_eggId])), growingSpeed);
  }

  function animalPrice(uint256 subValue,uint eggId) public view returns(uint256) {
    uint256 CommonTradeBalance;

    
      CommonTradeBalance = SafeMath.add(CommonTradeBalance, eggsTradeBalance[eggId]);

    return SafeMath.div(SafeMath.sub(address(this).balance, subValue), CommonTradeBalance);
    
    
    
  }

  function devFee(uint256 _amount) internal pure returns(uint256) {
    return SafeMath.div(SafeMath.mul(_amount, 10), 100);
  }

  

 
}

library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}