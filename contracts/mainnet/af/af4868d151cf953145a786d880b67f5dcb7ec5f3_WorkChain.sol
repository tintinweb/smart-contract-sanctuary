pragma solidity ^0.4.21;

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
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function () public payable {
    revert();
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract PausableToken is Ownable, StandardToken {
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

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

contract Configurable {
  uint256 public constant totalSaleLimit = 70000000;
  uint256 public constant privateSaleLimit = 27300000;
  uint256 public constant preSaleLimit = 38500000;
  uint256 public constant saleLimit = 4200000;
  uint256 public creationDate = now;
  uint256 public constant teamLimit = 8000000;
  uint256 teamReleased;
  address public constant teamAddress = 0x7a615d4158202318750478432743cA615d0D83aF;
}

contract Staged is Ownable, Configurable {
  using SafeMath for uint256;
  enum Stages {PrivateSale, PreSale, Sale}
  Stages currentStage;
  uint256 privateSale;
  uint256 preSale;
  uint256 sale;

  function Staged() public {
    currentStage = Stages.PrivateSale;
  }

  function setPrivateSale() public onlyOwner returns (bool) {
    currentStage = Stages.PrivateSale;
    return true;
  }

  function setPreSale() public onlyOwner returns (bool) {
    currentStage = Stages.PreSale;
    return true;
  }

  function setSale() public onlyOwner returns (bool) {
    currentStage = Stages.Sale;
    return true;
  }

  function tokensAmount(uint256 _wei) public view returns (uint256) {
    if (_wei < 100000000000000000) return 0;
    uint256 amount = _wei.mul(14005).div(1 ether);
    if (currentStage == Stages.PrivateSale) {
      if (_wei < 50000000000000000000) return 0;
      if (_wei > 3000000000000000000000) return 0;
      amount = amount.mul(130).div(100);
      if (amount > privateSaleLimit.sub(privateSale)) return 0;
    }
    if (currentStage == Stages.PreSale) {
      if (_wei > 30000000000000000000) return 0;
      amount = amount.mul(110).div(100);
      if (amount > preSaleLimit.sub(preSale)) return 0;
    }
    if (currentStage == Stages.Sale) {
      if (amount > saleLimit.sub(sale)) return 0;
    }
    return amount;
  }

  function addStageAmount(uint256 _amount) public {
    if (currentStage == Stages.PrivateSale) {
      require(_amount < privateSaleLimit.sub(privateSale)); 
      privateSale = privateSale.add(_amount);
    }
    if (currentStage == Stages.PreSale) {
      require(_amount < preSaleLimit.sub(preSale));
      privateSale = privateSale.add(_amount);
    }
    if (currentStage == Stages.Sale) {
      require(_amount < saleLimit.sub(sale));
      sale = sale.add(_amount);
    }
  }
}

contract MintableToken is PausableToken, Configurable {
   function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
    require(totalSaleLimit.add(30000000) > totalSupply.add(_amount));
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(address(this), _to, _amount);
    return true;
  }  
}

contract CrowdsaleToken is MintableToken, Staged {
  function CrowdsaleToken() internal {
    balances[owner] = 22000000; // bounty and marketing
    totalSupply.add(22000000);
  }
  
  function() public payable {
    uint256 tokens = tokensAmount(msg.value);
    require (tokens > 0);
    addStageAmount(tokens);
    owner.transfer(msg.value);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    emit Transfer(address(this), msg.sender, tokens);
  }

  function releaseTeamTokens() public {
    uint256 timeSinceCreation = now.sub(creationDate);
    uint256 teamTokens = timeSinceCreation.div(7776000).mul(1000000);
    require (teamReleased < teamTokens);
    teamTokens = teamTokens.sub(teamReleased);
    if (teamReleased.add(teamTokens) > teamLimit) {
      teamTokens = teamLimit.sub(teamReleased);
    }
    require (teamTokens > 0);
    teamReleased = teamReleased.add(teamTokens);
    balances[teamAddress] = balances[teamAddress].add(teamTokens);
    totalSupply = totalSupply.add(teamTokens);
    emit Transfer(address(this), teamAddress, teamTokens);
  }
}

contract WorkChain is CrowdsaleToken {   
  string public constant name = "WorkChain";
  string public constant symbol = "WCH";
  uint32 public constant decimals = 0;
}