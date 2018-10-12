pragma solidity ^0.4.25;

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
  
  
  address public constant restOfTokens = 0x73193200105449c144281C9E5b4c39B255e13d80;
  uint256 public constant endOfFreezing = 1578528000; // Thu, 09 Jan 2020 00:00:00 GMT (18 months)

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
    
    if(msg.sender == restOfTokens && now < endOfFreezing)
    {
        revert();
    }

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
    
    if(_from == restOfTokens && now < endOfFreezing)
    {
        revert();
    }

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
  constructor() public {
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

contract PietaXToken is StandardToken
{   
    string public constant name = "Pieta Token";
    string public constant symbol = "PIETA";
    uint public constant decimals = 18;
    
    constructor() public
    {
        totalSupply_ = 2000000 * 10 ** decimals;
        uint ownersPart = 2000000;
        
        balances[msg.sender] = totalSupply_ - ownersPart;
        emit Transfer(0x0, msg.sender, totalSupply_ - ownersPart);
        
        address owners = 0xa5adabc88d6abbfebf9b9348bd53090ab4f5df1b;
        balances[owners] = ownersPart;
        emit Transfer(0x0, owners, ownersPart);
    }
}


contract Crowdsale is Ownable
{   
    using SafeMath for uint256;
    
    uint256 public constant icoStart = 1538352000; // Mon, 01 Oct 2018 00:00:00 GMT
    uint256 public constant icoEnd = 1541030400; // Thu, 01 Nov 2018 00:00:00 GMT
    
    enum States { NotStarted, PreICO, ICO, Finished }
    States public state;
    
    PietaXToken public token;
    address public constant wallet = 0xa5adabc88d6abbfebf9b9348bd53090ab4f5df1b;
    uint256 public constant rate = 40; // PIETA per 1 ETH

    uint256 public constant preIcoSaleLimit = 2000000 * 10 ** 18; // PIETA
    
    uint256 public constant minIcoPurchase = 120 finney; // 0.12 ETH
    uint256 public constant maxIcoPurchase = 5000 ether;

    uint256 public constant softCap = 5000 ether;
    uint256 public constant hardCap = 50000 ether;
    
    uint256 public soldTokens;
    
    address public constant restOfTokens = 0x73193200105449c144281C9E5b4c39B255e13d80;
    
    uint256 public totalBalance;
    
    mapping(address => uint256) internal balances;

    constructor() public
    {
        token = new PietaXToken();
        state = States.NotStarted;
    }
    
    function nextState() onlyOwner public
    {
        require(state == States.NotStarted || state == States.PreICO || state == States.ICO);
        
        if(state == States.NotStarted)
        {
            state = States.PreICO;
        }
        else if(state == States.PreICO)
        {
            state = States.ICO;
        }
        else if(state == States.ICO)
        {
            state = States.Finished;
            
            if(totalBalance >= softCap)
            {
                address contractAddress = this;
                wallet.transfer(contractAddress.balance);
                uint256 tokens = token.balanceOf(contractAddress);
                token.transfer(restOfTokens, tokens);
            }
        }
    }

    function getBonus(uint time, uint256 tokens, uint256 weiAmount) public constant returns (uint256) 
    {
        uint256 bonus = 0;

        if(state == States.ICO)
        {
            // by time

            if(time >= icoStart && time <= (icoStart + 5 days))
            {
                bonus = tokens.mul(15).div(100);
            }
            else if (time >= (icoStart + 6 days) && time <= (icoStart + 10 days))
            {
                bonus = tokens.mul(10).div(100);
            }
            else if(time >= (icoStart + 11 days) && time <= (icoStart + 15 days))
            {
                bonus = tokens.mul(5).div(100);
            }
            else if(time >= (icoStart + 16 days) && time <= (icoStart + 22 days))
            {
                bonus = tokens.mul(3).div(100);
            }
            else if(time >= (icoStart + 22 days) && time < icoEnd)
            {
                bonus = tokens.mul(1).div(100);
            }
            
            // by sum
            
            if(weiAmount >= 260 ether)
            {
                bonus = bonus.add(tokens.mul(15).div(100));
            }
            else if(weiAmount >= 130 ether)
            {
                bonus = bonus.add(tokens.mul(10).div(100));
            }
            else if(weiAmount >= 26 ether)
            {
                bonus = bonus.add(tokens.mul(5).div(100));
            }
            else if(weiAmount >= 12500 finney) // 12.5 ETH
            {
                bonus = bonus.add(tokens.mul(3).div(100));
            }
        }
        
        return bonus;
    }


    function isValidPeriod(uint time) public constant returns (bool)
    {
        if(state == States.ICO)
        {
            if(time >= icoStart && time <= icoEnd) return true;
        }
        
        return false;
    }

    function isReachedHardCap(uint256 weiAmount) public constant returns (bool)
    {
        address contractAddress = this;
        return weiAmount.add(contractAddress.balance) > hardCap;
    }

    function checkSaleLimit(uint256 tokensAmount) public constant
    {
        if(state == States.PreICO)
        {
            require(soldTokens.add(tokensAmount) <= preIcoSaleLimit);
        }   
    }

    function buyTokens(address to, uint256 weiAmount) internal
    {
        uint256 tokens = calcTokens(weiAmount);
        uint256 bonus = getBonus(now, tokens, weiAmount);
        tokens = tokens.add(bonus);
        checkSaleLimit(tokens);
        totalBalance = totalBalance.add(weiAmount);
        token.transfer(to, tokens);
        soldTokens = soldTokens.add(tokens);
        balances[to] = balances[to].add(msg.value);
    }

    function calcTokens(uint256 weiAmount) public constant returns (uint256) 
    {
        return weiAmount.mul(rate);
    }

    function () public payable 
    {
        require(msg.sender != address(0));
        require(isValidPeriod(now));
        require(!isReachedHardCap(msg.value));
    
        if(state == States.ICO && msg.value < minIcoPurchase)
        {
            revert("too small a sum for ico");
        }
        
        if(state == States.ICO && msg.value > maxIcoPurchase)
        {
            revert("too big a sum for ico");
        }
        
        
        buyTokens(msg.sender, msg.value);
    }

    function refund() public returns (bool)
    {
        require(state == States.Finished);
        require(totalBalance < softCap);
        uint256 value = balances[msg.sender];
        require(value > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
        return true;
    }
    
    // for purchase with other currencies
    function manualTransfer(address to, uint256 weiAmount) onlyOwner public 
    {
        require(to != address(0));
        require(weiAmount > 0);
        require(isValidPeriod(now));
        
        buyTokens(to, weiAmount);
    }
}