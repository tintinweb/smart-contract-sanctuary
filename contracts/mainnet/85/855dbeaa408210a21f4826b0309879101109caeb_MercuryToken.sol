pragma solidity 0.4.15;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
 }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract ERC20 {

  uint256 public totalSupply;

  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool);
  function approve(address _spender, uint256 _value) returns (bool);
  function allowance(address _owner, address _spender) constant returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract MercuryToken is ERC20, Ownable {

  using SafeMath for uint256;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  string public constant name = "MERCURY TOKEN";
  string public constant symbol = "MRC";
  uint8 public constant decimals = 18;
  bool public mintingFinished = false;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function MercuryToken() {}


  function() payable {
    revert();
  }

  function balanceOf(address _owner) constant returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) returns (bool) {

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);

    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner  returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function allowMinting() onlyOwner returns (bool) {
    mintingFinished = false;
    return true;
  }

}

contract MercuryPresale is Pausable {
  using SafeMath for uint256;

  MercuryToken public token;


  address public wallet; //wallet towards which the funds are forwarded
  uint256 public weiRaised; //total amount of ether raised
  uint256 public cap; // cap above which the presale ends
  uint256 public minInvestment; // minimum investment
  uint256 public rate; // number of tokens for one ether
  bool public isFinalized;
  string public contactInformation;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event Finalized();


  function MercuryCrowdsale() {

    token = createTokenContract();
    wallet = 0x1dE159F3bb50992b78E06697B6273e326ADCcf75;
    rate = 6000;
    minInvestment = 1 * (10**16);
    cap = 180000000 * (10**18); 

  }

  // creates presale token
  function createTokenContract() internal returns (MercuryToken) {
    return new MercuryToken();
  }

  // fallback function to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) payable whenNotPaused {
    require(beneficiary != 0x0);
    require(validPurchase());
    require(!isFinalized);

    uint256 weiAmount = msg.value;

    weiRaised = weiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(rate);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }


  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {

    uint256 weiAmount = weiRaised.add(msg.value);
    bool notSmallAmount = msg.value >= minInvestment;
    bool withinCap = weiAmount.mul(rate) <= cap;

    return (notSmallAmount && withinCap);
  }

  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    token.finishMinting();
    Finalized();

    isFinalized = true;
  }


  function setContactInformation(string info) onlyOwner {
      contactInformation = info;
  }


  //return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = (weiRaised.mul(rate) >= cap);
    return capReached;
  }

}