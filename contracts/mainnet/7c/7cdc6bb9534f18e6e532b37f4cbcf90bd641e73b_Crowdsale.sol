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
    uint _allowance = allowed[_from][msg.sender];

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

contract MSPT is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "MySmartProperty Tokens";
  string public constant symbol = "MSPT";
  uint32 public constant decimals = 18;

  address public addressSupporters;
  address public addressEccles;
  address public addressJenkins;
  address public addressLeskiw;
  address public addressBilborough;

  uint public summSupporters = 1000000 * 1 ether;
  uint public summEccles = 2000000 * 1 ether;
  uint public summJenkins = 2000000 * 1 ether;
  uint public summLeskiw = 2000000 * 1 ether;
  uint public summBilborough = 3000000 * 1 ether;

  function MSPT() public {
    addressSupporters = 0x49ce9f664d9fe7774fE29F5ab17b46266e4437a4;
    addressEccles = 0xF59C5199FCd7e29b2979831e39EfBcf16b90B485;
    addressJenkins = 0x974e94C33a37e05c4cE292b43e7F50a57fAA5Bc7;
    addressLeskiw = 0x3a7e8Eb6DDAa74e58a6F3A39E3d073A9eFA22160;
    addressBilborough = 0xAabb89Ade1Fc2424b7FE837c40E214375Dcf9840;  
      
    //Founders and supporters initial Allocations
    balances[addressSupporters] = balances[addressSupporters].add(summSupporters);
    balances[addressEccles] = balances[addressEccles].add(summEccles);
    balances[addressJenkins] = balances[addressJenkins].add(summJenkins);
    balances[addressLeskiw] = balances[addressLeskiw].add(summLeskiw);
    balances[addressBilborough] = balances[addressBilborough].add(summBilborough);
    totalSupply = summSupporters.add(summEccles).add(summJenkins).add(summLeskiw).add(summBilborough);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  // The token being sold
  MSPT public token;
  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startPreICO;
  uint256 public startICO;
  uint256 public endPreICO;
  uint256 public endICO;           
  
  uint256 public maxAmountPreICO;
  uint256 public maxAmountICO;
  
  uint256 public totalPreICOAmount;
  uint256 public totalICOAmount;
  
  // Remaining Token Allocation
  uint public mintStart1; //15th July 2018
  uint public mintStart2; //15th August 2018
  uint public mintStart3; //15th December 2018
  uint public mintStart4; //15th January 2018
  uint public mintStart5; //15th July 2019     
  
  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public ratePreICO;
  uint256 public rateICO;      

  // minimum quantity values
  uint256 public minQuanValues; 
  
  // Remaining Token Allocation
  uint256 public totalMintAmount; 
  uint256 public allowTotalMintAmount;
  uint256 public mintAmount1;
  uint256 public mintAmount2;
  uint256 public mintAmount3;
  uint256 public mintAmount4;
  uint256 public mintAmount5;
  // totalTokens
  uint256 public totalTokens;
  
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    token = createTokenContract();
    // total number of tokens
    totalTokens = 100000000 * 1 ether;
    // minimum quantity values
    minQuanValues = 100000000000000000;
    // start and end timestamps where investments are allowed
    startPreICO = 1527948000; //3 June 2018 00:00:00 +10 GMT
    endPreICO = 1530280800; //30 June 2018 00:00:00 +10 GMT
    startICO = 1530280800; //30 June 2018 00:00:00 +10 GMT
    endICO = startICO +  30 * 1 days;           
    // restrictions on amounts during the ico stages
    maxAmountPreICO = 12000000  * 1 ether;
    maxAmountICO = 24000000  * 1 ether;
    // rate decimals = 2;
    ratePreICO = 79294;
    rateICO = 59470;
    // Remaining Token Allocation    
    mintAmount1 = 10000000 * 1 ether;
    mintAmount2 = 10000000 * 1 ether;
    mintAmount3 = 10000000 * 1 ether;
    mintAmount4 = 10000000 * 1 ether;
    mintAmount5 = 10000000 * 1 ether;
    
    mintStart1 = 1538316000; //1st October  2018 +10 GMT
    mintStart2 = 1540994400; //1st November 2018 +10 GMT
    mintStart3 = 1551362400; //1st March    2019 +10 GMT
    mintStart4 = 1554040800; //1st April    2019 +10 GMT
    mintStart5 = 1569852000; //1st October  2019 +10 GMT
    // address where funds are collected
    wallet = 0x7Ac93a7A1F8304c003274512F6c46C132106FE8E;
  }
  function setRatePreICO(uint _ratePreICO) public {
    ratePreICO = _ratePreICO;
  }  
  function setRateICO(uint _rateICO) public {
    rateICO = _rateICO;
  }    
  
  function createTokenContract() internal returns (MSPT) {
    return new MSPT();
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
    //minimum amount in ETH
    require(weiAmount >= minQuanValues);
    if (now >= startPreICO && now < endPreICO && totalPreICOAmount < maxAmountPreICO && tokens == 0){
      tokens = weiAmount.div(100).mul(ratePreICO);
      if (maxAmountPreICO.sub(totalPreICOAmount) < tokens){
        tokens = maxAmountPreICO.sub(totalPreICOAmount); 
        weiAmount = tokens.mul(100).div(ratePreICO);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreICOAmount = totalPreICOAmount.add(tokens);
      if (totalPreICOAmount >= maxAmountPreICO){
        startICO = now;
        endICO = startICO + 30 * 1 days;
      }   
    }    
    if (now >= startICO && totalICOAmount < maxAmountICO  && tokens == 0){
      tokens = weiAmount.div(100).mul(rateICO);
      if (maxAmountICO.sub(totalICOAmount) < tokens){
        tokens = maxAmountICO.sub(totalICOAmount); 
        weiAmount = tokens.mul(100).div(rateICO);
        backAmount = msg.value.sub(weiAmount);
      }
      totalICOAmount = totalICOAmount.add(tokens);
    }     
    require(tokens > 0);
    token.mint(beneficiary, tokens);
    wallet.transfer(weiAmount);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

  function mintTokens(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_amount > 0);
    require(_to != address(0));
    if (now >= mintStart1 && now < mintStart2){
      allowTotalMintAmount = mintAmount1;  
    }
    if (now >= mintStart2 && now < mintStart3){
      allowTotalMintAmount = mintAmount1.add(mintAmount2);  
    }  
    if (now >= mintStart3 && now < mintStart4){
      allowTotalMintAmount = mintAmount1.add(mintAmount2).add(mintAmount3);  
    }       
    if (now >= mintStart4 && now < mintStart5){
      allowTotalMintAmount = mintAmount1.add(mintAmount2).add(mintAmount3).add(mintAmount4);  
    }       
    if (now >= mintStart5){
      allowTotalMintAmount = totalMintAmount.add(totalTokens.sub(token.getTotalSupply()));
    }       
    require(_amount.add(totalMintAmount) <= allowTotalMintAmount);
    token.mint(_to, _amount);
    totalMintAmount = totalMintAmount.add(_amount);
    return true;
  }
  function finishMintingTokens() onlyOwner public returns (bool) {
    token.finishMinting(); 
  }
}