pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
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
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused {
    super.transferFrom(_from, _to, _value);
  }
}

/**
 * @title CryptoDailyToken
 * @dev Crypto Daily Token contract
 */
contract CryptoDailyToken is PausableToken, MintableToken {
  using SafeMath for uint256;

  string public name = "Crypto Daily Token";
  string public symbol = "CRDT";
  uint public decimals = 18;

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a CRDT owner
 * as they arrive.
 * Initial ICO coin supply = 155 million tokens
 * 90 million will go to the crowdsale
 * 20 million for Pre ICO-investors (with a discount on token price)
 * 15 million for Owners
 * 10 million for FREE Token giveaway for CryptoDaily readers.
 * 5 million for Team, Advisors
 * 5 million Early ICO Signup Bonuses
 * 10 million reserves for Exchange financing
 */
contract Crowdsale {
    using SafeMath for uint;
    
    uint private million = 1000000;
    uint private decimals = 18;

    /**
     * @notice Crowdsale contract is token contract owner
     * @dev Crowdsale contract is deploying token contract
     */
    CryptoDailyToken private token = new CryptoDailyToken();
    
    address private owner;
    address private constant fundsWallet = 0xD8CAb37A560D8B22104508ac42bd045a5Abcb2E7;//0x05e21637a43A8a1b2DEB75df7aCe5e10A09b8Ff8;
    address private constant tokenWallet = 0xf8Fab9fa6C154bd2A59035283AD508705aa49641;//0xaE29a74F44d930510a9eAAf125C4B38553524a17; 
    
    uint private start = now;
    uint private finish = now + 10 minutes;

    uint private tokensPerEth;
    
    uint private tokensReserved = 65 * million * 10 ** uint256(decimals);
    uint private tokensCrowdsaled = 0;
    uint private tokensLeft = 90 * million * 10 ** uint256(decimals);
    uint private tokensTotal = 155 * million * 10 ** uint256(decimals);
    
    event Mint(address indexed to, uint value);
    event SaleFinished(address target, uint amountRaised);
    
    /**
     * @dev Contract constructor
     * param UnixTimestampOfICOStart Unix timestamp value when crowdsale starts
     * param UnixTimestampOfICOEnd Unix timestamp value when crowdsale ends
     * @param _tokensPerEth the number of tokens that a contributor receives for each ETH
     */
    constructor(
        uint UnixTimestampOfICOStart, 
        uint UnixTimestampOfICOEnd, 
        uint _tokensPerEth
    ) public {
        owner = msg.sender;
        start = UnixTimestampOfICOStart;
        finish = UnixTimestampOfICOEnd;
        tokensPerEth = _tokensPerEth;
        preMinting();
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     * 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev Throws if its not crowdsale period.
     * 
     */
    modifier saleIsOn() {
    	require(now >= start && now <= finish);
    	_;
    }
    
    /**
     * @dev Throws of hardcap is reached.
     * 
     */    
    modifier isUnderHardCap() { 
        require(getTokensReleased() <= tokensTotal); //is 149 cap? 
        _;
    }
    
    //Getters

    /**
     * @return the address of the token that is used as a reward
     * 
     */
    function getAddressOfTokenUsedAsReward() constant public returns(address){
        return token;
    } 
    
    /**
     * @return number of tokens sold
     * 
     */
    function getTokensCrowdsaled() constant public returns(uint){
        return tokensCrowdsaled;
    }
    
    /**
     * @return number of tokens left
     * 
     */ 
    function getTokensLeft() constant public returns(uint){
        return tokensLeft;
    }
    
    /**
     * @return owner
     * 
     */ 
    function getOwner() constant public returns(address){
        return owner;
    }
    
    /**
     * @return datetime ico start timestamp
     * 
     */
    function getStart() constant public returns(uint){
        return start;
    }
    
    /**
     * @return datetime ico end timestamp
     * 
     */
    function getFinish() constant public returns(uint){
        return finish;
    }
    
    /**
     * @return the number of tokens that a contributor receives for each ETH
     * 
     */ 
    function getTokensPerEth() constant public returns(uint){
        return tokensPerEth;
    }
    
    //Setters

    /**
     * @param newStart new Unix timestamp value when crowdsale starts
     * 
     */
    function setStart(uint newStart) onlyOwner public {
        start = newStart; 
    }
    
    /**
     * @param newFinish new Unix timestamp value when crowdsale ends
     * 
     */
    function setFinish(uint newFinish) onlyOwner public {
        finish = newFinish; 
    }
    
    /**
     * @param _tokensPerEth the new number of tokens that a contributor receives for each ETH
     * 
     */
    function setTokensPerEth(uint _tokensPerEth) onlyOwner public {
        tokensPerEth = _tokensPerEth; 
    }
    
    
    //Custom getters and setters 
    /**
     * @return total realised tokens
     * 
     */
    function getTokensReleased() constant public returns(uint){
        return tokensReserved + tokensCrowdsaled;
    }
    
    /**
     * @return true if bonus
     * 
     */
    function getIfBonus() constant public returns(bool){
        return (getTokensCrowdsaled() < 50 * million * 10 ** uint256(decimals));
    }
    

    /**
     * @notice Function must be invoked when ICO has been finished. Transfers unsold tokens to the reserve. Sets crowdsale owner as new token owner. 
     * @dev onlyOwner modifier 
     * 
     */ 
    function setICOIsFinished() onlyOwner public {
        token.mint(tokenWallet, tokensLeft);
        //give ownership back to deployer
        token.transferOwnership(owner);
        tokensLeft = 0;
        emit SaleFinished(fundsWallet, getTokensReleased());
    }
    
    /**
     * @dev Mint reserved tokens to the owner&#39;s wallet
     * 
     */
    function preMinting() private  {
        token.mint(tokenWallet, tokensReserved);
    }
    
    /**
     * @notice fallback function 
     * @dev isUnderHardCap, saleIsOn modifiers
     */
    function() isUnderHardCap saleIsOn public payable {
        
        require(msg.sender != 0x0);
        
        //minimal contribution is 3 ETH
        require(msg.value >= 3 ether);
        fundsWallet.transfer(msg.value);
        
        //first 50 miilon tokens with 10% bonus
        uint firstFifty = 50 * million * 10 ** uint256(decimals);
        uint amount = msg.value;
        uint tokensToMint = 0;

        tokensToMint = amount.mul(tokensPerEth);
        
        //add bonus
        if (tokensCrowdsaled.add(tokensToMint) <= firstFifty){
            tokensToMint = tokensToMint.mul(11).div(10); 
        }
        
        token.mint(msg.sender, tokensToMint);
        emit Mint(msg.sender, tokensToMint);
        
        tokensLeft = tokensLeft.sub(tokensToMint);
        tokensCrowdsaled = tokensCrowdsaled.add(tokensToMint);
    }

}