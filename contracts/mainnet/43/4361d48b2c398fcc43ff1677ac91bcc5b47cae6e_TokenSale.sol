pragma solidity ^0.4.24;


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
  modifier onlyPayloadSize(uint256 numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

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
  function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
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
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
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
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 */
contract MintableToken is PausableToken {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  address public saleAgent = address(0);
  address public saleAgent2 = address(0);

  function setSaleAgent(address newSaleAgent) onlyOwner public {
    saleAgent = newSaleAgent;
  }

  function setSaleAgent2(address newSaleAgent) onlyOwner public {
    saleAgent2 = newSaleAgent;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) canMint public returns (bool) {
    require(msg.sender == saleAgent || msg.sender == saleAgent2 || msg.sender == owner);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(this), _to, _amount);
    
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


contract LEAD is MintableToken, Claimable {
    string public constant name = "LEADEX"; 
    string public constant symbol = "LEAD";
    uint public constant decimals = 8;
}

contract TokenSale is Ownable {
    
    using SafeMath for uint;
    uint256 public startTime;
    uint256 public endTime;
    uint256 constant dec = 10 ** 8;
    uint256 public tokensToSale = 500000000 * 10 ** 8;
    // address where funds are collected
    address public wallet;
    // one token per one rate
    uint256 public rate = 800;
    LEAD public token;
    // Amount of raised money in wei
    uint256 public weiRaised;
    uint256 public minTokensToSale = 200 * dec;

    uint256 timeBonus1 = 30;
    uint256 timeBonus2 = 20;
    uint256 timeBonus3 = 10;
    uint256 timeStaticBonus = 0;

    // Round 1 bonuses
    uint256 bonus1_1 = 15;
    uint256 bonus1_2 = 25;
    uint256 bonus1_3 = 35;
    uint256 bonus1_4 = 45;

    // Round 2 bonuses
    uint256 bonus2_1 = 10;
    uint256 bonus2_2 = 20;
    uint256 bonus2_3 = 30;
    uint256 bonus2_4 = 40;

    // Round 3 bonuses
    uint256 bonus3_1 = 10;
    uint256 bonus3_2 = 15;
    uint256 bonus3_3 = 25;
    uint256 bonus3_4 = 35;

    // Round 4 bonuses
    uint256 bonus4_1 = 5;
    uint256 bonus4_2 = 10;
    uint256 bonus4_3 = 20;
    uint256 bonus4_4 = 30;

    // Amount bonuses
    uint256 amount1 = 0;
    uint256 amount2 = 2 * dec;
    uint256 amount3 = 3 * dec;
    uint256 amount4 = 5 * dec;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        address _wallet) public {
        require(_token != address(0));
        require(_endTime > _startTime);
        require(_wallet != address(0));
        token = LEAD(_token);
        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
    }

    modifier saleIsOn() {
        uint tokenSupply = token.totalSupply();
        require(now > startTime && now < endTime);
        require(tokenSupply <= tokensToSale);
        _;
    }

    function setMinTokensToSale(
        uint256 _newMinTokensToSale) onlyOwner public {
        minTokensToSale = _newMinTokensToSale;
    }

    function setAmount(
        uint256 _newAmount1,
        uint256 _newAmount2,
        uint256 _newAmount3,
        uint256 _newAmount4) onlyOwner public {
        amount1 = _newAmount1;
        amount2 = _newAmount2;
        amount3 = _newAmount3;
        amount4 = _newAmount4;
    }


    function getBonus(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus1_1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus1_2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus1_3;
        } else if(_value >= amount4) {
            return bonus1_4;
        }
    }

    function getBonus2(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus2_1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus2_2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus2_3;
        } else if(_value >= amount4) {
            return bonus2_4;
        }
    }

    function getBonus3(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus3_1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus3_2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus3_3;
        } else if(_value >= amount4) {
            return bonus3_4;
        }
    }

    function getBonus4(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus4_1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus4_2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus4_3;
        } else if(_value >= amount4) {
            return bonus4_4;
        }
    }

    function getTimeBonus(uint256 _value) public view returns (uint256) {
        if(now < startTime + 61 days) { // Round 1
            return getBonus(_value);
        } else if(now >= startTime + 61 days && now < startTime + 120 days) { // Round 2
            return getBonus2(_value);
        } else if(now >= startTime + 120 days && now < startTime + 181 days) { // Round 3
            return getBonus3(_value);
        } else if(now >= startTime + 181 days && now < endTime) { // Round 4
            return getBonus4(_value);
        }
    }

    function setEndTime(uint256 _newEndTime) onlyOwner public {
        require(now < _newEndTime);
        endTime = _newEndTime;
    }

    function setRate(uint256 _newRate) public onlyOwner {
        rate = _newRate;
    }

    function setTeamAddress(address _newWallet) onlyOwner public {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

    /**
    * events for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPartners(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function buyTokens(address beneficiary) saleIsOn public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = (msg.value).div(10 ** 10);
        uint256 all = 100;
        uint256 timeBonusNow = getTimeBonus(weiAmount);
        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        require(tokens >= minTokensToSale);
        uint256 tokensSumBonus = tokens.add(tokens.mul(timeBonusNow).div(all));
        require(tokensToSale > tokensSumBonus.add(token.totalSupply()));
        weiRaised = weiRaised.add(msg.value);
        token.mint(beneficiary, tokensSumBonus);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokensSumBonus);

        wallet.transfer(msg.value);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // @return true if tokensale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function kill() onlyOwner public { selfdestruct(owner); }
    
}