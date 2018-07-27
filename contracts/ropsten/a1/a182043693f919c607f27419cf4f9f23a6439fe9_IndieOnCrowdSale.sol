pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}







/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


contract IndieOnCrowdSale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public owner;
  address public wallet;

  //Relay allocated amounts here
  address public constant founder1Address = 0xC02845566fdbe6C065dA32b03DbB0860a96bbe39;
  address public constant founder2Address = 0x229b3D1Ee85178700E4b150415c348c6Ecc3705C;
  address public constant founder3Address = 0x72a2547d71ca2f1b49bf07f90a2d565f437e8768;
  address public constant founder4Address = 0xa72563B5bF2FDf5a7ff5b25BF7a529158C6f0dC9;
  address public constant techPartnersAddress = 0x99a64bD692c790F0684bC7191afd419CD1D1Dd27;
  address public constant artistsPoolAddress = 0xadFD2a1c1837aA86571aE815Da5c4a14EEC84b14;

  //Founders, Team and artistPool amounts
  uint256 public constant founder1Amount = 92500000 * (10 ** 18);
  uint256 public constant founder2Amount = 37500000 * (10 ** 18);
  uint256 public constant founder3Amount = 82500000 * (10 ** 18);
  uint256 public constant founder4Amount = 37500000 * (10 ** 18);
  uint256 public constant techPartnersAmount = 10000000 * (10 ** 18);
  uint256 public constant artistsPoolAmount = 447777778 * (10 ** 18);


  uint256 public rate;
  uint256 public openingTime;
  uint256 public closingTime;
  uint256 public weiRaised;
  uint256 public constant BONUS_40 = 140; //40% Bonus
  uint256 public constant BONUS_20 = 120; //10% Bonus
  uint256 public constant BONUS_10 = 110; //10% Bonus
  uint256 public constant BONUS_0 = 100; //No BONUS

  // Four phase soft caps and a hard cap in ethers
  uint256 public constant SOFTCAP_1 = 6000  * (10 ** 18);
  uint256 public constant SOFTCAP_2 = 18800 * (10 ** 18);
  uint256 public constant SOFTCAP_3 = 30000 * (10 ** 18);
  uint256 public constant HARDCAP =   50000 * (10 ** 18);

  uint256 private constant totalSupply = 1000000000 * (10 ** 18);
  uint256 private totalTokenSold = 0;
  bool public isFoundersFundsAllocated = false;

  uint256 public  PHASE1_END = 1534442400; //16 Aug 2018 10AM PST
  uint256 public  PHASE2_END = 1536948000; //14 Sep 2018 10AM PST
  uint256 public  PHASE3_END = 1539453600; //13 Oct 2018 10M PST

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   */
  constructor(uint256 _rate, address _wallet, address _token, uint _openingTime, uint _closingTime)
   public
   {
    require(_rate > 0);
    require(_wallet != address(0));
    require (_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = ERC20(_token);
    openingTime = _openingTime;
    closingTime = _closingTime;
    owner = msg.sender;
  }

  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

  /**
   * @dev Let user make a purchase
   */
   function () external payable {
     purchaseTokens(msg.sender);
   }

   function capReached() public view returns (bool) {
     return weiRaised >= HARDCAP;
   }

   //OnlyOwner function
   function allocateFoundersTokens() onlyWhileOpen onlyOwner public {
     require (!isFoundersFundsAllocated);
     isFoundersFundsAllocated = true;
     token.transfer(address(founder1Address), founder1Amount);
     token.transfer(address(founder2Address), founder2Amount);
     token.transfer(address(founder3Address), founder3Amount);
     token.transfer(address(founder4Address), founder4Amount);

     token.transfer(address(techPartnersAddress), techPartnersAmount);
     token.transfer(address(artistsPoolAddress), artistsPoolAmount);
   }

  function purchaseTokens(address buyer) public payable {

    uint256 weiAmount = msg.value;
    validatePurchase(buyer, weiAmount);

    //Calculate token amount with Bonus
    uint256 tokens = getTokenAmount(weiAmount);
    require(tokens > 0);
    // update fundRaising amount
    totalTokenSold = totalTokenSold.add(tokens);
    require (totalTokenSold <= totalSupply);
    weiRaised = weiRaised.add(weiAmount);
    //Send tokens to token buyer
    token.transfer(buyer, tokens);

    emit TokenPurchase(msg.sender, buyer, weiAmount, tokens);
    sendFundsToWallet();
  }

    function validatePurchase(address buyer, uint256 weiAmount) onlyWhileOpen internal
  {
    require(buyer != address(0));
    require(weiAmount != 0);
    //Revert if we reached hard cap
    require(weiRaised.add(weiAmount) <= HARDCAP);
  }

  function softcap1Reached () internal returns (bool) {
    return weiRaised >= SOFTCAP_1;
  }

  function softcap2Reached () internal returns (bool) {
    return weiRaised >= SOFTCAP_2;
  }

  function softcap3Reached () internal returns (bool) {
    return weiRaised >= SOFTCAP_3;
  }

  /**
   * @dev Calculate the discount based on the current phase of sale.
   * @return Total percentage (base value + Bonus)
   */
    function getBonus() onlyWhileOpen public returns (uint256) {
        if (now >= openingTime && now <= PHASE1_END)  { // we are in first phase
          bool softcap1 = softcap1Reached();
          if (softcap1) return BONUS_20;  //if we reached softcap1 in phase 1, bonus will drop to 20
          else return BONUS_40;
         } else if (now > PHASE1_END && now <= PHASE2_END) { //we are in phase 2
           bool softcap2 = softcap2Reached();
           if (softcap2) return BONUS_10;  //if we reached softcap2 in phase 2, bonus will drop to 10
           else return BONUS_20;
         } else if (now > PHASE2_END && now <= PHASE3_END) {
           bool softcap3 = softcap3Reached();
           if (softcap3) return BONUS_0;  //if we reached softcap3 in phase 3, bonus will drop to 0
           else return BONUS_10;
         }
         return BONUS_0;
    }

  /**
  * @dev Owner to move all the leftover tokens to artistPool.
  * @return left over amount
  */
  function moveLeftOvertokensToartistPool() public onlyOwner returns (uint256) {
      require (now > closingTime); //move only after sale get closed
      uint256 leftOverAmount = token.balanceOf(address(this));
      require (leftOverAmount > 0);
      token.transfer(artistsPoolAddress, leftOverAmount);
      return leftOverAmount;
  }

  /**
   * @dev Calculate amount of tokens considering bonus
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function getTokenAmount(uint256 weiAmount) internal returns (uint256) {
    uint bonus = getBonus();
    return weiAmount.mul(rate).div(100).mul(bonus);
  }

  /**
   * @dev Transfer funds to cold wallet
   */
  function sendFundsToWallet() internal {
    wallet.transfer(msg.value);
  }
}