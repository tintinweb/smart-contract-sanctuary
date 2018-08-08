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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  address public addressTeam =  0x04cFbFa64917070d7AEECd20225782240E8976dc;
  bool public frozenAccountICO = true;
  mapping(address => uint256) balances;
  mapping (address => bool) public frozenAccount;
  function setFrozenAccountICO(bool _frozenAccountICO) public onlyOwner{
    frozenAccountICO = _frozenAccountICO;   
  }
  /* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (msg.sender != owner && msg.sender != addressTeam){  
      require(!frozenAccountICO); 
    }
    require(!frozenAccount[_to]);   // Check if recipient is frozen  
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
    if (msg.sender != owner && msg.sender != addressTeam){  
      require(!frozenAccountICO); 
    }    
    require(!frozenAccount[_from]);                     // Check if sender is frozen
    require(!frozenAccount[_to]);                       // Check if recipient is frozen      
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
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

contract MahalaCoin is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Mahala Coin";
  string public constant symbol = "MHC";
  uint32 public constant decimals = 18;

  // address public addressTeam; 
  uint public summTeam;
  
  function MahalaCoin() public {
    summTeam =     110000000 * 1 ether;
    //Founders and supporters initial Allocations
    mint(addressTeam, summTeam);
	mint(owner, 70000000 * 1 ether);
  }
      /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
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
  // totalTokens
  uint256 public totalTokens;
  // soft cap
  uint softcap;
  // hard cap
  uint hardcap;  
  MahalaCoin public token;
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
    token = createTokenContract();
    //soft cap
    softcap = 5000 * 1 ether; 
    hardcap = 20000 * 1 ether;  	
    // min quantity values
    minQuanValues = 100000000000000000; //0.1 eth
    // max quantity values
    maxQuanValues = 22 * 1 ether; //    
    // start and end timestamps where investments are allowed
    //Pre-sale
      //start
    startPreSale = 1523260800;//09 Apr 2018 08:00:00 +0000
      //end
    endPreSale = startPreSale + 40 * 1 days;
  
    //ico
      //start
    startIco = endPreSale;
      //end 
    endIco = startIco + 40 * 1 days;   

    // rate;
    ratePreSale = 462;
    rateIco = 231; 
    
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
  
  function createTokenContract() internal returns (MahalaCoin) {
    return new MahalaCoin();
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
	    endIco = startIco + 40 * 1 days; 
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
    token.transfer(msg.sender, tokens);
   // balancesToken[msg.sender] = balancesToken[msg.sender].add(tokens);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
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
    require(_this.balance < softcap && now > endIco);  
    token.transfer(_address, token.balanceOf(_this));
  }   
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    require(_this.balance >= softcap && now > endIco);  
    wallet.transfer(_this.balance);
    token.setFrozenAccountICO(false);
  }  
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
  function freezeAccount(address target, bool freeze) onlyOwner public {
    token.freezeAccount(target, freeze);
  }
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
  function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    token.mint(target, mintedAmount);
    }  
    
}