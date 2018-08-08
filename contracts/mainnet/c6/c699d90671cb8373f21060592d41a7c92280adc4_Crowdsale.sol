pragma solidity ^0.4.18;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Token {
  function totalSupply() constant public returns (uint256 supply);

  function balanceOf(address _owner) constant public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public  returns (bool success) ;
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) ;
  function approve(address _spender, uint256 _value) public  returns (bool success) ;
  function allowance(address _owner, address _spender) constant public  returns (uint256 remaining) ;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where Contributors can make
 * token Contributions and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // totalTokens
  uint256 public totalTokens;
  // soft cap
  uint softcap;
  // hard cap
  uint hardcap;  
  Token public token;
  // balances for softcap
  mapping(address => uint) public balances;
  // balances for softcap
  mapping(address => uint) public balancesToken;  
  // The token being offered

  // start and end timestamps where investments are allowed (both inclusive)
  
  //pre-sale
    //start
  uint256 public startPreSale;
    //end
  uint256 public endPreSale;

  //ico
    //start
  uint256 public startIco;
    //end 
  uint256 public endIco;    

  //token distribution
  uint256 public maxPreSale;
  uint256 public maxIco;

  uint256 public totalPreSale;
  uint256 public totalIco;
  
  // how many token units a Contributor gets per wei
  uint256 public ratePreSale;
  uint256 public rateIco;   

  // address where funds are collected
  address public wallet;

  // minimum quantity values
  uint256 public minQuanValues; 
  uint256 public maxQuanValues; 

/**
* event for token Procurement logging
* @param contributor who Pledged for the tokens
* @param beneficiary who got the tokens
* @param value weis Contributed for Procurement
* @param amount amount of tokens Procured
*/
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    
    //soft cap
    softcap = 5000 * 1 ether; 
    hardcap = 20000 * 1 ether;  	
    // min quantity values
    minQuanValues = 100000000000000000; //0.1 eth
    // max quantity values
    maxQuanValues = 27 * 1 ether; //    
    // start and end timestamps where investments are allowed
    //Pre-sale
      //start
    startPreSale = 1523260800;//09 Apr 2018 08:00:00 +0000
      //end
    endPreSale = 1525507200;//05 May 2018 08:00:00 +0000
  
    //ico
      //start
    startIco = 1525507200;//05 May 2018 08:00:00 +0000
      //end 
    endIco = startIco + 6 * 7 * 1 days;   

    // rate;
    ratePreSale = 382;
    rateIco = 191; 
    
    // restrictions on amounts during the crowdfunding event stages
    maxPreSale = 30000000 * 1 ether;
    maxIco =     60000000 * 1 ether;    
    
    // address where funds are collected
    wallet = 0x04cFbFa64917070d7AEECd20225782240E8976dc;
  }

  function setratePreSale(uint _ratePreSale) public onlyOwner  {
    ratePreSale = _ratePreSale;
  }
 
  function setrateIco(uint _rateIco) public onlyOwner  {
    rateIco = _rateIco;
  }   
  


  // fallback function can be used to Procure tokens
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function setToken(address _address) public onlyOwner {
      token = Token(_address);
  }
    
  // low level token Pledge function
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
    //minimum amount in ETH
    require(weiAmount >= minQuanValues);
    //maximum amount in ETH
    require(weiAmount.add(balances[msg.sender]) <= maxQuanValues);    
    //hard cap
    address _this = this;
    require(hardcap > _this.balance);

    //Pre-sale
    if (now >= startPreSale && now < endPreSale && totalPreSale < maxPreSale){
      tokens = weiAmount.mul(ratePreSale);
	  if (maxPreSale.sub(totalPreSale) <= tokens){
	    endPreSale = now;
	    startIco = now;
	    endIco = startIco + 6 * 7 * 1 days; 
	  }
      if (maxPreSale.sub(totalPreSale) < tokens){
        tokens = maxPreSale.sub(totalPreSale); 
        weiAmount = tokens.div(ratePreSale);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreSale = totalPreSale.add(tokens);
    }
       
    //ico   
    if (now >= startIco && now < endIco && totalIco < maxIco){
      tokens = weiAmount.mul(rateIco);
      if (maxIco.sub(totalIco) < tokens){
        tokens = maxIco.sub(totalIco); 
        weiAmount = tokens.div(rateIco);
        backAmount = msg.value.sub(weiAmount);
      }
      totalIco = totalIco.add(tokens);
    }        

    require(tokens > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    balancesToken[msg.sender] = balancesToken[msg.sender].add(tokens);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }
  function getToken() public{
    address _this = this;
    require(_this.balance >= softcap && now > endIco); 
    uint value = balancesToken[msg.sender];
    balancesToken[msg.sender] = 0;
    token.transfer(msg.sender, value);
  }
  
  function refund() public{
    address _this = this;
    require(_this.balance < softcap && now > endIco);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferTokenToMultisig(address _address) public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    token.transfer(_address, token.balanceOf(_this));
  }   
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    wallet.transfer(_this.balance);
  }  
}