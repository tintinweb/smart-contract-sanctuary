//SourceUnit: NewShrimp.sol

pragma solidity 0.4.25;

contract TRC20 {
  function totalSupply() public view returns(uint supply);

  function balanceOf(address _owner) public view returns(uint balance);

  function transfer(address _to, uint _value) public returns(bool success);

  function transferFrom(address _from, address _to, uint _value) public returns(bool success);

  function approve(address _spender, uint _value) public returns(bool success);

  function allowance(address _owner, address _spender) public view returns(uint remaining);

  function decimals() public view returns(uint digits);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract JustShrimp {
  //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
  uint256 public EGGS_TO_HATCH_1SHRIMP = 86400; //for final version should be seconds in a day
  uint256 public STARTING_SHRIMP = 5; //reduced from 300
  uint256 PSN = 10000;
  uint256 PSNH = 5000;
  bool public initialized = false;
  address public ceoAddress;
  mapping(address => uint256) public hatcheryShrimp;
  mapping(address => uint256) public claimedEggs;
  mapping(address => uint256) public lastHatch;
  mapping(address => address) public referrals;
  address public jst_address;
  uint256 public marketEggs;

  constructor(address _addr) public {
    ceoAddress = msg.sender;
    jst_address = _addr;
   // seedMarket();
  }

  function hatchEggs(address ref) public {
    require(initialized);
    if (ref == msg.sender) {
      ref = 0;
    }
    if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
      referrals[msg.sender] = ref;
    }
    uint256 eggsUsed = getMyEggs();
    uint256 newShrimp = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1SHRIMP);
    hatcheryShrimp[msg.sender] = SafeMath.add(hatcheryShrimp[msg.sender], newShrimp);
    claimedEggs[msg.sender] = 0;
    lastHatch[msg.sender] = now;

    //send referral eggs
    claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 10));

    //boost market to nerf shrimp hoarding
    marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
  }

   

  function sellEggs() public {
    require(initialized);
    TRC20 tokenContract = TRC20(jst_address);
    uint256 hasEggs = getMyEggs();
    uint256 eggValue = calculateEggSell(hasEggs);
    require(eggValue >= 1e6);
    uint ConvertToJst = (eggValue* 1e18)/1e6;
    uint256 fee = devFee(ConvertToJst);
    claimedEggs[msg.sender] = 0;
    lastHatch[msg.sender] = now;
    marketEggs = SafeMath.add(marketEggs, hasEggs);
    tokenContract.transfer(ceoAddress,fee);
    uint _tran =  SafeMath.sub(ConvertToJst, fee);
    tokenContract.transfer(msg.sender, _tran);
  }

  function buyEggs(uint _amount) public payable {
    require(initialized);
    uint tokenAmount = _amount * 1e18;
    TRC20 tokenContract = TRC20(jst_address);
    require(tokenContract.allowance(msg.sender, address(this)) > 0);
    tokenContract.transferFrom(msg.sender, address(this), tokenAmount);
    uint256 eggsBought = calculateEggBuy(_amount * 1e6, SafeMath.sub(getBalance(), _amount * 1e6));
    eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
    uint feedev = devFee(tokenAmount);
    tokenContract.transfer(ceoAddress,feedev);
    claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
  }
  //magic trade balancing algorithm
  function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
    //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
    return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
  }

  function calculateEggSell(uint256 eggs) public view returns(uint256) {
    TRC20 tokenContract = TRC20(jst_address);
    return calculateTrade(eggs, marketEggs, getBalance());
  }

  function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
    return calculateTrade(eth, contractBalance, marketEggs);
  }

  function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
    TRC20 tokenContract = TRC20(jst_address);
    return calculateEggBuy(eth, ((tokenContract.balanceOf(this)) / 1e18) * 1e6);
  }

  function devFee(uint256 amount) public view returns(uint256) {
    return SafeMath.div(SafeMath.mul(amount, 10), 100);
  }

  function seedMarket() public payable {
    require(marketEggs == 0);
    initialized = true;
    marketEggs = 864000000;
  }

  function getFreeShrimp() public {
    require(initialized);
    require(hatcheryShrimp[msg.sender] == 0);
    lastHatch[msg.sender] = now;
    hatcheryShrimp[msg.sender] = STARTING_SHRIMP;
  }

  function getBalance() public view returns(uint256) {
    TRC20 tokenContract = TRC20(jst_address);
    return ((tokenContract.balanceOf(this)) / 1e18) * 1e6; //convert to tron decimal

  }

  function getMyShrimp() public view returns(uint256) {
    return hatcheryShrimp[msg.sender];
  }

  function getMyEggs() public view returns(uint256) {
    return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
  }

  function getEggsSinceLastHatch(address adr) public view returns(uint256) {
    uint256 secondsPassed = min(EGGS_TO_HATCH_1SHRIMP, SafeMath.sub(now, lastHatch[adr]));
    return SafeMath.mul(secondsPassed, hatcheryShrimp[adr]);
  }

  function min(uint256 a, uint256 b) private pure returns(uint256) {
    return a < b ? a : b;
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