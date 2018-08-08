pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract BurnableByOwner is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);
  function burn(address _address, uint256 _value) public onlyOwner{
    require(_value <= balances[_address]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = _address;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract Wolf is Ownable, MintableToken, BurnableByOwner {
  using SafeMath for uint256;    
  string public constant name = "Wolf";
  string public constant symbol = "Wolf";
  uint32 public constant decimals = 18;

  address public addressTeam;
  address public addressCashwolf;
  address public addressFutureInvest;


  uint public summTeam = 15000000000 * 1 ether;
  uint public summCashwolf = 10000000000 * 1 ether;
  uint public summFutureInvest = 10000000000 * 1 ether;


  function Wolf() public {
	addressTeam = 0xb5AB520F01DeE8a42A2bfaEa8075398414774778;
	addressCashwolf = 0x3366e9946DD375d1966c8E09f889Bc18C5E1579A;
	addressFutureInvest = 0x7134121392eE0b6DC9382BBd8E392B4054CdCcEf;
	

    //Founders and supporters initial Allocations
    balances[addressTeam] = balances[addressTeam].add(summTeam);
    balances[addressCashwolf] = balances[addressCashwolf].add(summCashwolf);
	balances[addressFutureInvest] = balances[addressFutureInvest].add(summFutureInvest);

    totalSupply = summTeam.add(summCashwolf).add(summFutureInvest);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
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
  // soft cap
  uint256 public softcap;
  // balances for softcap
  mapping(address => uint) public balancesSoftCap;
  struct BuyInfo {
    uint summEth;
    uint summToken;
    uint dateEndRefund;
  }
  mapping(address => mapping(uint => BuyInfo)) public payments;
  mapping(address => uint) public paymentCounter;
  // The token being offered
  Wolf public token;
  // start and end timestamps where investments are allowed (both inclusive)
  // start
  uint256 public startICO;
  // end
  uint256 public endICO;
  uint256 public period;
  uint256 public endICO14; 
  // token distribution
  uint256 public hardCap;
  uint256 public totalICO;
  // how many token units a Contributor gets per wei
  uint256 public rate;   
  // address where funds are collected
  address public wallet;
  // minimum/maximum quantity values
  uint256 public minNumbPerSubscr; 
  uint256 public maxNumbPerSubscr; 

/**
* event for token Procurement logging
* @param contributor who Pledged for the tokens
* @param beneficiary who got the tokens
* @param value weis Contributed for Procurement
* @param amount amount of tokens Procured
*/
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    token = createTokenContract();
    // soft cap
    softcap = 100 * 1 ether;   
    // minimum quantity values
    minNumbPerSubscr = 10000000000000000; //0.01 eth
    maxNumbPerSubscr = 100 * 1 ether;
    // start and end timestamps where investments are allowed
    // start
    startICO = 1521878400;// 03/24/2018 @ 8:00am (UTC)
    period = 30;
    // end
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;
    // restrictions on amounts during the crowdfunding event stages
    hardCap = 65000000000 * 1 ether;
    // rate;
    rate = 1000000;
    // address where funds are collected
    wallet = 0x7472106A07EbAB5a202e195c0dC22776778b44E6;
  }

  function setStartICO(uint _startICO) public onlyOwner{
    startICO = _startICO;
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;    
  }

  function setPeriod(uint _period) public onlyOwner{
    period = _period;
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;    
  }
  
  function setRate(uint _rate) public  onlyOwner{
    rate = _rate;
  }
  
  function createTokenContract() internal returns (Wolf) {
    return new Wolf();
  }

  // fallback function can be used to Procure tokens
  function () external payable {
    procureTokens(msg.sender);
  }

  // low level token Pledge function
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
    //minimum/maximum amount in ETH
    require(weiAmount >= minNumbPerSubscr && weiAmount <= maxNumbPerSubscr);
    if (now >= startICO && now <= endICO && totalICO < hardCap){
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalICO) < tokens){
        tokens = hardCap.sub(totalICO); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
      totalICO = totalICO.add(tokens);
    }

    require(tokens > 0);
    token.mint(beneficiary, tokens);
    balancesSoftCap[beneficiary] = balancesSoftCap[beneficiary].add(weiAmount);

    uint256 dateEndRefund = now + 14 * 1 days;
    paymentCounter[beneficiary] = paymentCounter[beneficiary] + 1;
    payments[beneficiary][paymentCounter[beneficiary]] = BuyInfo(weiAmount, tokens, dateEndRefund); 
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);  
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

 
  function refund() public{
    require(address(this).balance < softcap && now > endICO);
    require(balancesSoftCap[msg.sender] > 0);
    uint value = balancesSoftCap[msg.sender];
    balancesSoftCap[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function revoke(uint _id) public{
    require(now <= payments[msg.sender][_id].dateEndRefund);
    require(payments[msg.sender][_id].summEth > 0);
    require(payments[msg.sender][_id].summToken > 0);
    uint value = payments[msg.sender][_id].summEth;
    uint valueToken = payments[msg.sender][_id].summToken;
    balancesSoftCap[msg.sender] = balancesSoftCap[msg.sender].sub(value);
    payments[msg.sender][_id].summEth = 0;
    payments[msg.sender][_id].summToken = 0;
    msg.sender.transfer(value);
    token.burn(msg.sender, valueToken);
   }  
  
  function transferToMultisig() public onlyOwner {
    require(address(this).balance >= softcap && now > endICO14);  
      wallet.transfer(address(this).balance);
  }  
}