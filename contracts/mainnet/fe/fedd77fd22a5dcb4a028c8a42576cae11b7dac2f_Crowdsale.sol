pragma solidity ^0.4.21;


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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

  /**
   * @dev Allows the current owner to update a single rate.
   * @param _symbol The symbol to be updated. 
   * @param _rate the rate for the symbol. 
   */
  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[keccak256(_symbol)] = _rate;
    emit RateUpdated(now, keccak256(_symbol), _rate);
  }

  /**
   * @dev Allows the current owner to update multiple rates.
   * @param data an array that alternates sha3 hashes of the symbol and the corresponding rate . 
   */
  function updateRates(uint[] data) public onlyOwner {
    
    require(data.length % 2 <= 0);      
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      emit RateUpdated(now, symbol, rate);
      i++;
    }
  }

  /**
   * @dev Allows the anyone to read the current rate.
   * @param _symbol the symbol to be retrieved. 
   */
  function getRate(string _symbol) public constant returns(uint) {
    return rates[keccak256(_symbol)];
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
    totalSupply_ = totalSupply_.add(_amount);
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




contract SmartCoinFerma is MintableToken {
    
  string public constant name = "Smart Coin Ferma";
   
  string public constant symbol = "SCF";
    
  uint32 public constant decimals = 8;

  HoldersList public list = new HoldersList();
 
  bool public tradingStarted = true;

 
   /**
   * @dev modifier that throws if trading has not started yet
   */
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  } 

  /**
   * @dev Allows the owner to enable the trading. This can not be undone
   */
  function startTrading() public onlyOwner {
    tradingStarted = true;
  }

   /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _to the recipient address of the tokens. 
   * @param _value number of tokens to be transfered. 
   */
  function transfer(address _to, uint _value) hasStartedTrading  public returns (bool) {
    
    
    require(super.transfer(_to, _value) == true);
    list.changeBalance( msg.sender, balances[msg.sender]);
    list.changeBalance( _to, balances[_to]);
    
    return true;
  }

     /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value)  public returns (bool) {
   
    
    require (super.transferFrom(_from, _to, _value) == true);
    list.changeBalance( _from, balances[_from]);
    list.changeBalance( _to, balances[_to]);
    
    return true;
  }
  function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
     require(super.mint(_to, _amount) == true); 
     list.changeBalance( _to, balances[_to]);
     list.setTotal(totalSupply_);
     return true;
  }
  
  
  
}

contract HoldersList is Ownable{
   uint256 public _totalTokens;
   
   struct TokenHolder {
        uint256 balance;
        uint       regTime;
        bool isValue;
    }
    
    mapping(address => TokenHolder) holders;
    address[] public payees;
    
    function changeBalance(address _who, uint _amount)  public onlyOwner {
        
            holders[_who].balance = _amount;
            if (notInArray(_who)){
                payees.push(_who);
                holders[_who].regTime = now;
                holders[_who].isValue = true;
            }
            
        //}
    }
    function notInArray(address _who) internal view returns (bool) {
        if (holders[_who].isValue) {
            return false;
        }
        return true;
    }
    
  /**
   * @dev Defines number of issued tokens. 
   */
  
    function setTotal(uint _amount) public onlyOwner {
      _totalTokens = _amount;
  }
  
  /**
   * @dev Returnes number of issued tokens.
   */
  
   function getTotal() public constant returns (uint)  {
     return  _totalTokens;
  }
  
  /**
   * @dev Returnes holders balance.
   
   */
  function returnBalance (address _who) public constant returns (uint){
      uint _balance;
      
      _balance= holders[_who].balance;
      return _balance;
  }
  
  
  /**
   * @dev Returnes number of holders in array.
   
   */
  function returnPayees () public constant returns (uint){
      uint _ammount;
      
      _ammount= payees.length;
      return _ammount;
  }
  
  
  /**
   * @dev Returnes holders address.
   
   */
  function returnHolder (uint _num) public constant returns (address){
      address _addr;
      
      _addr= payees[_num];
      return _addr;
  }
  
  /**
   * @dev Returnes registration date of holder.
   
   */
  function returnRegDate (address _who) public constant returns (uint){
      uint _redData;
      
      _redData= holders[_who].regTime;
      return _redData;
  }
    
}


contract Crowdsale is Ownable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  

  SmartCoinFerma public token = new SmartCoinFerma();


     
  //prod
  address multisigVaultFirst = 0xAD7C50cfeb60B6345cb428c5820eD073f35283e7;
  address multisigVaultSecond = 0xA9B04eF1901A0d720De14759bC286eABC344b3BA;
  address multisigVaultThird = 0xF1678Cc0727b354a9B0612dd40D275a3BBdE5979;
  
  uint restrictedPercent = 50;
  
 
  bool pause = false;
  
  
  
  //prod
  address restricted = 0x217d44b5c4bffC5421bd4bb9CC85fBf61d3fbdb6;
  address restrictedAdditional = 0xF1678Cc0727b354a9B0612dd40D275a3BBdE5979;
  
  ExchangeRate exchangeRate;

  
  uint public start = 1523491200; 
  uint period = 365;
  uint _rate;

  /**
   * @dev modifier to allow token creation only when the sale IS ON
   */
  modifier saleIsOn() {
    require(now >= start && now < start + period * 1 days);
    require(pause!=true);
    _;
  }
    
    /**
   * @dev Allows owner to pause the crowdsale
   */
    function setPause( bool _newPause ) onlyOwner public {
        pause = _newPause;
    }


   /**
   * @dev Allows anyone to create tokens by depositing ether.
   * @param recipient the recipient to receive tokens. 
   */
  function createTokens(address recipient) saleIsOn payable {
    uint256 sum;
    uint256 halfSum;  
    uint256 quatSum; 
    uint256 rate;
    uint256 tokens;
    uint256 restrictedTokens;
   
    uint256 tok1;
    uint256 tok2;
    
    
    
    require( msg.value > 0 );
    sum = msg.value;
    halfSum = sum.div(2);
    quatSum = halfSum.div(2);
    rate = exchangeRate.getRate("ETH"); 
    tokens = rate.mul(sum).div(1 ether);
    require( tokens > 0 );
    
    token.mint(recipient, tokens);
    
    
    multisigVaultFirst.transfer(halfSum);
    multisigVaultSecond.transfer(quatSum);
    multisigVaultThird.transfer(quatSum);
    /*
    * "dev Create restricted tokens
    */
    restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
    tok1 = restrictedTokens.mul(60).div(100);
    tok2 = restrictedTokens.mul(40).div(100);
    require (tok1 + tok2==restrictedTokens );
    
    token.mint(restricted, tok1);
    token.mint(restrictedAdditional, tok2);
    
    
    emit TokenSold(recipient, msg.value, tokens, rate);
  }

    /**
   * @dev Allows the owner to set the starting time.
   * @param _start the new _start
   */
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

    /**
   * @dev Allows the owner to set the exchangerate contract.
   * @param _exchangeRate the exchangerate address
   */
  function setExchangeRate(address _exchangeRate) public onlyOwner {
    exchangeRate = ExchangeRate(_exchangeRate);
  }


  /**
   * @dev Allows the owner to finish the minting. This will create the 
   * restricted tokens and then close the minting.
   * Then the ownership of the PAY token contract is transfered 
   * to this owner.
   */
  function finishMinting() public onlyOwner {
    //uint issuedTokenSupply = token.totalSupply();
    //uint restrictedTokens = issuedTokenSupply.mul(49).div(51);
    //token.mint(multisigVault, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    }

  /**
   * @dev Fallback function which receives ether and created the appropriate number of tokens for the 
   * msg.sender.
   */
  function() external payable {
      createTokens(msg.sender);
  }

}