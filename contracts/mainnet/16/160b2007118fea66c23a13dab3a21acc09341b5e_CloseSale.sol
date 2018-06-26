pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20 {
  function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
  function mintFromICO(address _to, uint256 _amount) external  returns(bool);
}

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

contract CloseSale is Ownable {
  
  ERC20 public token;
  
  using SafeMath for uint;
  
  address public backEndOperator = msg.sender;
  
  address team = 0x7DDA135cDAa44Ad3D7D79AAbE562c4cEA9DEB41d; // 25% all
  
  address reserve = 0x34bef601666D7b2E719Ff919A04266dD07706a79; // 15% all
  
  mapping(address=>bool) public whitelist;
  
  uint256 public startCloseSale = 1527638401; // Wednesday, 30-May-18 00:00:01 UTC
  
  uint256 public endCloseSale = 1537228799; // Monday, 17-Sep-18 23:59:59 UTC
  
  uint256 public investors;
  
  uint256 public weisRaised;
  
  uint256 public dollarRaised;
  
  uint256 public buyPrice; //0.01 USD
  
  uint256 public dollarPrice;
  
  uint256 public soldTokens;
  
  event Authorized(address wlCandidate, uint timestamp);
  
  event Revoked(address wlCandidate, uint timestamp);
  
  
  modifier backEnd() {
    require(msg.sender == backEndOperator || msg.sender == owner);
    _;
  }
  
  
  constructor(uint256 _dollareth) public {
    dollarPrice = _dollareth;
    buyPrice = 1e16/dollarPrice; // 16 decimals because 1 cent
  }
  
  
  function setToken (ERC20 _token) public onlyOwner {
    token = _token;
  }
  
  function setDollarRate(uint256 _usdether) public onlyOwner {
    dollarPrice = _usdether;
    buyPrice = 1e16/dollarPrice; // 16 decimals because 1 cent
  }
  
  function setPrice(uint256 newBuyPrice) public onlyOwner {
    buyPrice = newBuyPrice;
  }
  
  function setStartSale(uint256 newStartCloseSale) public onlyOwner {
    startCloseSale = newStartCloseSale;
  }
  
  function setEndSale(uint256 newEndCloseSaled) public onlyOwner {
    endCloseSale = newEndCloseSaled;
  }
  
  function setBackEndAddress(address newBackEndOperator) public onlyOwner {
    backEndOperator = newBackEndOperator;
  }
  
  /*******************************************************************************
   * Whitelist&#39;s section */
  
  
  function authorize(address wlCandidate) public backEnd  {
    require(wlCandidate != address(0x0));
    require(!isWhitelisted(wlCandidate));
    whitelist[wlCandidate] = true;
    investors++;
    emit Authorized(wlCandidate, now);
  }
  
  
  function revoke(address wlCandidate) public  onlyOwner {
    whitelist[wlCandidate] = false;
    investors--;
    emit Revoked(wlCandidate, now);
  }
  
  
  function isWhitelisted(address wlCandidate) public view returns(bool) {
    return whitelist[wlCandidate];
  }
  
  /*******************************************************************************
   * Payable&#39;s section */
  
  
  function isCloseSale() public constant returns(bool) {
    return now >= startCloseSale && now <= endCloseSale;
  }
  
  
  function () public payable {
    require(isCloseSale());
    require(isWhitelisted(msg.sender));
    closeSale(msg.sender, msg.value);
  }
  
  
  function closeSale(address _investor, uint256 _value) internal {
    uint256 tokens = _value.mul(1e18).div(buyPrice);
    token.mintFromICO(_investor, tokens);
    
    uint256 tokensFounders = tokens.mul(5).div(12);
    token.mintFromICO(team, tokensFounders);
    
    uint256 tokensDevelopers = tokens.div(4);
    token.mintFromICO(reserve, tokensDevelopers);
    
    weisRaised = weisRaised.add(msg.value);
    uint256 valueInUSD = msg.value.mul(dollarPrice);
    dollarRaised = dollarRaised.add(valueInUSD);
    soldTokens = soldTokens.add(tokens);
  }
  
  
  function mintManual(address _investor, uint256 _value) public onlyOwner {
    token.mintFromICO(_investor, _value);
    uint256 tokensFounders = _value.mul(5).div(12);
    token.mintFromICO(team, tokensFounders);
    uint256 tokensDevelopers = _value.div(4);
    token.mintFromICO(reserve, tokensDevelopers);
  }
  
  
  function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
    require(amount != 0);
    require(_to != 0x0);
    _to.transfer(amount);
  }
}