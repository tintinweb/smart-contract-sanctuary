pragma solidity ^0.4.18;

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



//  https://github.com/ethereum/EIPs/issues/179
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// ERC20 interface, see https://github.com/ethereum/EIPs/issues/20
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// Basic version of StandardToken, with no allowances.
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
    Transfer(msg.sender, _to, _value);
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
 * Standard ERC20 token
 * Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//
contract EXOToken is StandardToken, Ownable {
    uint8 constant PERCENT_BOUNTY=3;
    uint8 constant PERCENT_TEAM=12;
    uint8 constant PERCENT_FOUNDATION=25;
    uint8 constant PERCENT_PRE_ICO=10;
    uint8 constant PERCENT_ICO=50;
    uint256 constant UNFREEZE_FOUNDATION  = 1546214400;
    //20180901 = 1535760000
    //20181231 = 1546214400
    ///////////////
    // VAR       //
    ///////////////
    // Implementation of frozen funds
    mapping(address => bool) public frozenAccounts;

    string public  name;
    string public  symbol;
    uint8  public  decimals;
    uint256 public UNFREEZE_TEAM_BOUNTY = 1535760000; //Plan end of ICO

    address public accForBounty;
    address public accForTeam;
    address public accFoundation;
    address public accPreICO;
    address public accICO;
    address public currentMinter;


    ///////////////
    // EVENTS    //
    ///////////////
    event NewFreeze(address acc, bool isFrozen);
    event Mint(address indexed to, uint256 amount);

    // Constructor,  
    function EXOToken(
        address _accForBounty, 
        address _accForTeam, 
        address _accFoundation, 
        address _accPreICO, 
        address _accICO) 
    public 
    {
        name = "EXOLOVER";
        symbol = "EXO";
        decimals = 18;
        totalSupply_ = 100000000 * (10 ** uint256(decimals));// All EXO tokens in the world
        //Initial token distribution
        balances[_accForBounty] = totalSupply()/100*PERCENT_BOUNTY;
        balances[_accForTeam]   = totalSupply()/100*PERCENT_TEAM;
        balances[_accFoundation]= totalSupply()/100*PERCENT_FOUNDATION;
        balances[_accPreICO]    = totalSupply()/100*PERCENT_PRE_ICO;
        balances[_accICO]       = totalSupply()/100*PERCENT_ICO;
        //save for public
        accForBounty  = _accForBounty;
        accForTeam    = _accForTeam;
        accFoundation = _accFoundation;
        accPreICO     = _accPreICO;
        accICO        = _accICO;
        //Fixe emission
        emit Transfer(address(0), _accForBounty,  totalSupply()/100*PERCENT_BOUNTY);
        emit Transfer(address(0), _accForTeam,    totalSupply()/100*PERCENT_TEAM);
        emit Transfer(address(0), _accFoundation, totalSupply()/100*PERCENT_FOUNDATION);
        emit Transfer(address(0), _accPreICO,     totalSupply()/100*PERCENT_PRE_ICO);
        emit Transfer(address(0), _accICO,        totalSupply()/100*PERCENT_ICO);

        frozenAccounts[accFoundation] = true;
        emit NewFreeze(accFoundation, true);
    }

    function isFrozen(address _acc) internal view returns(bool frozen) {
        if (_acc == accFoundation && now < UNFREEZE_FOUNDATION) 
            return true;
        return (frozenAccounts[_acc] && now < UNFREEZE_TEAM_BOUNTY);    
    }

    //Override some function for freeze functionality
    function transfer(address _to, uint256 _value) public  returns (bool) {
      require(!isFrozen(msg.sender));
      assert(msg.data.length >= 64 + 4);//Short Address Attack
      //Lets freeze any accounts, who recieve tokens from accForBounty and accForTeam
      // - auto freeze
      if (msg.sender == accForBounty || msg.sender == accForTeam) {
          frozenAccounts[_to] = true;
          emit NewFreeze(_to, true);
      }
      return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
      require(!isFrozen(_from));
      assert(msg.data.length >= 96 + 4); //Short Address Attack
       if (_from == accForBounty || _from == accForTeam) {
          frozenAccounts[_to] = true;
          emit NewFreeze(_to, true);
      }
      return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public  returns (bool) {
      require(!isFrozen(msg.sender));
      return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public  returns (bool success) {
      require(!isFrozen(msg.sender));
      return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool success) {
      require(!isFrozen(msg.sender));
      return super.decreaseApproval(_spender, _subtractedValue);
    }

    function freezeUntil(address _acc, bool _isfrozen) external onlyOwner returns (bool success){
        require(now <= UNFREEZE_TEAM_BOUNTY);// nobody cant freeze after ICO finish
        frozenAccounts[_acc] = _isfrozen;
        emit NewFreeze(_acc, _isfrozen);
        return true;
    }

    function setMinter(address _minter) external onlyOwner returns (bool success) {
        currentMinter = _minter;
        return true;
    }

    function setBountyTeamUnfreezeTime(uint256 _newDate) external onlyOwner {
       UNFREEZE_TEAM_BOUNTY = _newDate;
    }

    function mintTokens(address _to, uint256 _amount) external returns (bool) {
        require(msg.sender==currentMinter);
        totalSupply_  = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true; 
    }
    
    
  //***************************************************************
  // ERC20 part of this contract based on https://github.com/OpenZeppelin/zeppelin-solidity
  // Adapted and amended by IBERGroup, email:<span class="__cf_email__" data-cfemail="7a171b0209130017151813161f3a13181f08541d08150f0a">[email&#160;protected]</span>; 
  //     Telegram: https://t.me/msmobile
  //               https://t.me/alexamuek
  // Code released under the MIT License(see git root).
  ////**************************************************************

}