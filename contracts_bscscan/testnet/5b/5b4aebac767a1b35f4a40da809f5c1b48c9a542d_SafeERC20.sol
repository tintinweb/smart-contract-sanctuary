/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.4.18;



  contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
      owner = msg.sender;
    }


    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
      require(newOwner != address(0));
      OwnershipTransferred(owner, newOwner);
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

    modifier whenPaused() {
      require(paused);
      _;
    }


    function pause() onlyOwner whenNotPaused public {
      paused = true;
      Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      Unpause();
    }
  }

  contract SRCICO is Pausable{
    using SafeMath for uint256;

    uint constant public minContribAmount = 0.01 ether;

    SRCToken public token;
    uint256 constant public tokenDecimals = 18;


    uint256 public startTime;
    uint256 public endTime;

    bool public icoEnabled;

    address public multisignWallet;

    uint256 public weiRaised;

    uint256 constant public totalSupply = 15000000 * (10 ** tokenDecimals);
    uint256 constant public preSaleCap = 1000 * (10 ** tokenDecimals);
    uint256 constant public initialICOCap = 1000 * (10 ** tokenDecimals);
    uint256 constant public tokensForTeam = 4500000 * (10 ** tokenDecimals);


    uint256 public soldPreSaleTokens;
    uint256 public sentPreSaleTokens;

    uint256 public icoCap;
    uint256 public icoSoldTokens;
    bool public icoEnded = false;


    uint256 constant public RATE_FOR_WEEK1 = 800000;
    uint256 constant public RATE_FOR_WEEK2 = 750000;
    uint256 constant public RATE_NO_DISCOUNT = 700000;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function SRCICO(address _multisignWallet) public {
      require(_multisignWallet != address(0));
      token = createTokenContract();
      uint256 tokensToDao = tokensForTeam;
      multisignWallet = _multisignWallet;
      token.transfer(multisignWallet, tokensToDao);
    }


    function createTokenContract() internal returns (SRCToken) {
      return new SRCToken();
    }


    function enableTokenTransferability() external onlyOwner {
      require(token != address(0));
      token.unpause();
    }

    function disableTokenTransferability() external onlyOwner {
      require(token != address(0));
      token.pause();
    }


    function setSoldPreSaleTokens(uint256 _soldPreSaleTokens) external onlyOwner{
      require(!icoEnabled);
      require(_soldPreSaleTokens <= preSaleCap);
      soldPreSaleTokens = _soldPreSaleTokens;
    }


    function setMultisignWallet(address _multisignWallet) external onlyOwner{
      require(!icoEnabled || now < startTime);
      require(_multisignWallet != address(0));
      multisignWallet = _multisignWallet;
    }


    function setContributionDates(uint64 _startTime, uint64 _endTime) external onlyOwner{
      require(!icoEnabled);
      require(_startTime >= now);
      require(_endTime >= _startTime);
      startTime = _startTime;
      endTime = _endTime;
    }



    function enableICO() external onlyOwner{

      icoEnabled = true;
      icoCap = initialICOCap.add(preSaleCap).sub(soldPreSaleTokens);
    }


    function () payable whenNotPaused public {
      purchaseTokens(msg.sender);
    }

    // low level token purchase function
    function purchaseTokens(address beneficiary) public payable whenNotPaused {
      require(beneficiary != address(0));
      require(validPurchase());

      uint256 weiAmount = msg.value;
      uint256 returnWeiAmount;

      uint rate = getRate();
      assert(rate > 0);
      uint256 tokens = weiAmount.mul(rate);

      uint256 newIcoSoldTokens = icoSoldTokens.add(tokens);

      if (newIcoSoldTokens > icoCap) {
          newIcoSoldTokens = icoCap;
          tokens = icoCap.sub(icoSoldTokens);
          uint256 newWeiAmount = tokens.div(rate);
          returnWeiAmount = weiAmount.sub(newWeiAmount);
          weiAmount = newWeiAmount;
      }

      // update state
      weiRaised = weiRaised.add(weiAmount);

      token.transfer(beneficiary, tokens);
      icoSoldTokens = newIcoSoldTokens;
      if (returnWeiAmount > 0){
          msg.sender.transfer(returnWeiAmount);
      }

      TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

      sendFunds();
    }

    function sendFunds() internal {
      multisignWallet.transfer(this.balance);
    }


    function validPurchase() internal constant returns (bool) {
      bool withinPeriod = now >= startTime && now <= endTime;
      bool nonMinimumPurchase = msg.value >= minContribAmount;
      bool icoTokensAvailable = icoSoldTokens < icoCap;
      return !icoEnded && icoEnabled && withinPeriod && nonMinimumPurchase && icoTokensAvailable;
    }

    function endIco() external onlyOwner {
      require(!icoEnded);
      icoEnded = true;

      uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
      token.transfer(multisignWallet, unsoldTokens);
    }


    function hasEnded() public constant returns (bool) {
      return (icoEnded || icoSoldTokens >= icoCap || now > endTime);
    }


    function getRate() public constant returns(uint){
      require(now >= startTime);
      if (now < startTime.add(4 weeks)){
        // January
        return RATE_FOR_WEEK1;
      }else if (now < startTime.add(8 weeks)){
        // week 2
        return RATE_FOR_WEEK2;
      }else if (now < endTime){
        // no discount
        return RATE_NO_DISCOUNT;
      }
      return 0;
    }

    function drain() external onlyOwner {
      owner.transfer(this.balance);
    }
  }

  contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }

  contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      // SafeMath.sub will throw if there is not enough balance.
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }


    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

  }

  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

  library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
      assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
      assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
      assert(token.approve(spender, value));
    }
  }


  contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_to != address(0));
      require(_value <= balances[_from]);
      require(_value <= allowed[_from][msg.sender]);

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }


    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }


    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

  }

  contract PausableToken is StandardToken, Pausable {
    modifier whenNotPausedOrOwner() {
      require(msg.sender == owner || !paused);
      _;
    }

    function transfer(address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
      return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPausedOrOwner returns (bool) {
      return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPausedOrOwner returns (bool success) {
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPausedOrOwner returns (bool success) {
      return super.decreaseApproval(_spender, _subtractedValue);
    }
  }

  contract SRCToken is PausableToken {
    string constant public name = "SRCOIN";
    string constant public symbol = "SRCOIN";
    uint256 constant public decimals = 18;
    uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);
    uint256 constant INITIAL_SUPPLY = 10500000 * TOKEN_UNIT;

    function SRCToken() public {
      // Set untransferable by default to the token
      paused = true;
      // asign all tokens to the contract creator
      totalSupply = INITIAL_SUPPLY;
      Transfer(0x0, msg.sender, INITIAL_SUPPLY);
      balances[msg.sender] = INITIAL_SUPPLY;
    }
  }

  library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
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