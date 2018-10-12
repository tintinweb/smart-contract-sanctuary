pragma solidity ^0.4.24;

/*** @title SafeMath
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20 {
  function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
  function mintFromICO(address _to, uint256 _amount) external  returns(bool);
  function isWhitelisted(address wlCandidate) external returns(bool);
}

/**
 * @title Ownable
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol */
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title PreCrowdSale
 * @dev https://github.com/elephant-marketing/*/

contract PreSale is Ownable {

  ERC20 public token;

  ERC20 public authorize;

  using SafeMath for uint;

  address public backEndOperator = msg.sender;

  address team = 0xe56E60dE6d2649d9Cd0c82cb1f9d00365f07BA92; // 10 % - founders

  address bounty = 0x5731340239D8105F9F4e436021Ad29D3098AB6f8; // 2 % - bounty


  mapping(address => uint256) public investedEther;


  uint256 public startPreSale = 1539561600; // Monday, 15 October 2018 г., 0:00:00

  uint256 public endPreSale = 1542240000; // Thursday, 15 November 2018 г., 0:00:00


  uint256 stage1Sale = startPreSale + 2 days; // 0- 2  days

  uint256 stage2Sale = startPreSale + 10 days; // 3 - 10 days

  uint256 stage3Sale = startPreSale + 18 days; // 11 - 18  days

  uint256 stage4Sale = startPreSale + 26 days; // 19 - 26 days

  uint256 stage5Sale = startPreSale + 31 days; // 27 - 31  days

  uint256 public weisRaised;

  uint256 public buyPrice; // 1 USD

  uint256 public dollarPrice;

  uint256 public soldTokensPreSale;

  uint256 public softcapPreSale = 4200000*1e18; // 4,200,000 VIONcoin

  uint256 public hardCapPreSale = 34200000*1e18; // 34,200,000 VIONcoin

  event UpdateDollar(uint256 time, uint256 _rate);

  event Refund(uint256 sum, address investor);



  modifier backEnd() {
    require(msg.sender == backEndOperator || msg.sender == owner);
    _;
  }


  constructor(ERC20 _token,ERC20 _authorize, uint256 usdETH) public {
    token = _token;
    authorize = _authorize;
    dollarPrice = usdETH;
    buyPrice = (1e18/dollarPrice).div(10); // 0.1 usd
  }


  function setStartPreSale(uint256 newStartPreSale) public onlyOwner {
    startPreSale = newStartPreSale;
  }

  function setEndPreSale(uint256 newEndPreSale) public onlyOwner {
    endPreSale = newEndPreSale;
  }

  function setBackEndAddress(address newBackEndOperator) public onlyOwner {
    backEndOperator = newBackEndOperator;
  }

  function setBuyPrice(uint256 _dollar) public backEnd {
    dollarPrice = _dollar;
    buyPrice = (1e18/dollarPrice).div(10); // 0.1 usd
    emit UpdateDollar(now, dollarPrice);
  }


  /*******************************************************************************
   * Payable&#39;s section */

  function isPreSale() public constant returns(bool) {
    return now >= startPreSale && now <= endPreSale;
  }


  function () public payable {
    require(authorize.isWhitelisted(msg.sender));
    require(isPreSale());
    preSale(msg.sender, msg.value);
    require(soldTokensPreSale<=hardCapPreSale);
    investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
  }


  function preSale(address _investor, uint256 _value) internal {
    uint256 tokens = _value.mul(1e18).div(buyPrice);
    uint256 tokensByDate = tokens.mul(bonusDate()).div(100);
    tokens = tokens.add(tokensByDate);
    token.mintFromICO(_investor, tokens);
    soldTokensPreSale = soldTokensPreSale.add(tokens); // only sold

    uint256 tokensTeam = tokens.mul(10).div(44); // 20 %
    token.mintFromICO(team, tokensTeam);

    uint256 tokensBoynty = tokens.mul(3).div(200); // 1.5 %
    token.mintFromICO(bounty, tokensBoynty);

    weisRaised = weisRaised.add(_value);
  }


  function bonusDate() private view returns (uint256){
    if (now > startPreSale && now < stage1Sale) {  // 0 - 2 days preSale
      return 50;
    }
    else if (now > stage1Sale && now < stage2Sale) { // 3 - 10 days preSale
      return 40;
    }
    else if (now > stage2Sale && now < stage3Sale) { // 11 - 18 days preSale
      return 33;
    }
    else if (now > stage3Sale && now < stage4Sale) { // 19 - 26 days preSale
      return 30;
    }
    else if (now > stage4Sale && now < stage5Sale) { // 27 - 31 days preSale
      return 25;
    }

    else {
      return 0;
    }
  }

  function mintManual(address receiver, uint256 _tokens) public backEnd {
    token.mintFromICO(receiver, _tokens);
    soldTokensPreSale = soldTokensPreSale.add(_tokens);

    uint256 tokensTeam = _tokens.mul(10).div(44); // 20 %
    token.mintFromICO(team, tokensTeam);

    uint256 tokensBoynty = _tokens.mul(3).div(200); // 1.5 %
    token.mintFromICO(bounty, tokensBoynty);
  }


  function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
    _to.transfer(amount);
  }


  function refundPreSale() public {
    require(soldTokensPreSale < softcapPreSale && now > endPreSale);
    uint256 rate = investedEther[msg.sender];
    require(investedEther[msg.sender] >= 0);
    investedEther[msg.sender] = 0;
    msg.sender.transfer(rate);
    weisRaised = weisRaised.sub(rate);
    emit Refund(rate, msg.sender);
  }
}