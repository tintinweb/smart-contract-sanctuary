pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
  function balanceOf(address _owner) public view returns (uint256) {
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract VestingToken is StandardToken {
  using SafeMath for uint256;
  mapping(address => uint256) public vested;
  mapping(address => uint256) public released;
  uint256 public totalVested;
  uint256 public vestingStartTime;
  uint256 public vestingStageTime = 2592000; // 30 days

  function vestedTo (address _address) public view returns (uint256) {
    return vested[_address];
  }

  function releasedTo (address _address) public view returns (uint256) {
    return released[_address];
  }

  function getShare () internal view returns (uint8) {
    uint256 elapsedTime = now.sub(vestingStartTime);
    if (elapsedTime > vestingStageTime.mul(3)) return uint8(100);
    if (elapsedTime > vestingStageTime.mul(2)) return uint8(75);
    if (elapsedTime > vestingStageTime) return uint8(50);   
    return uint8(25);
  }

  function release () public returns (bool) {
    uint8 shareForRelease = getShare(); // in percent
    uint256 tokensForRelease = vested[msg.sender].mul(shareForRelease).div(100);
    tokensForRelease = tokensForRelease.sub(released[msg.sender]);
    require(tokensForRelease > 0);
    released[msg.sender] = released[msg.sender].add(tokensForRelease);
    balances[msg.sender] = balances[msg.sender].add(tokensForRelease);
    totalSupply_ = totalSupply_.add(tokensForRelease);
    emit Release(msg.sender, tokensForRelease);
    return true;
  }
  event Vest(address indexed to, uint256 value);
  event Release(address indexed to, uint256 value);
}

contract CrowdsaleToken is VestingToken, Ownable {
  using SafeMath for uint64;
  uint64 public cap = 3170000000;
  uint64 public saleCap = 1866912500;
  uint64 public team = 634000000;
  uint64 public advisors = 317000000;
  uint64 public mlDevelopers = 79250000;
  uint64 public marketing = 87175000;
  uint64 public reserved = 185662500;
  uint64 public basePrice = 18750;
  uint64 public icoPeriodTime = 604800;
  uint256 public sold = 0;
  uint256 public currentIcoPeriodStartDate;
  uint256 public icoEndDate;
  bool public preSaleComplete = false;

  enum Stages {Pause, PreSale, Ico1, Ico2, Ico3, Ico4, IcoEnd}
  Stages currentStage;

  mapping(uint8 => uint64) public stageCap;

  mapping(uint8 => uint256) public stageSupply;

  constructor() public {
    currentStage = Stages.Pause;
    stageCap[uint8(Stages.PreSale)] = 218750000;
    stageCap[uint8(Stages.Ico1)] = 115200000;
    stageCap[uint8(Stages.Ico2)] = 165312500;
    stageCap[uint8(Stages.Ico3)] = 169400000;
    stageCap[uint8(Stages.Ico4)] = 1198250000;
  }

  function startPreSale () public onlyOwner returns (bool) {
    require(currentStage == Stages.Pause);
    require(!preSaleComplete);
    currentStage = Stages.PreSale;
    return true;
  }

  function endPreSale () public onlyOwner returns (bool) {
    require(currentStage == Stages.PreSale);
    currentStage = Stages.Pause;
    preSaleComplete = true;
    return true;
  }

  function startIco () public onlyOwner returns (bool) {
    require(currentStage == Stages.Pause);
    require(preSaleComplete);
    currentStage = Stages.Ico1;
    currentIcoPeriodStartDate = now;
    return true;
  }

  function endIco () public onlyOwner returns (bool) {
    if (currentStage != Stages.Ico1 && currentStage != Stages.Ico2 && currentStage != Stages.Ico3 && currentStage != Stages.Ico4) revert();
    currentStage = Stages.IcoEnd;
    icoEndDate = now;
    vestingStartTime = now;
    uint256 unsoldTokens = saleCap.sub(sold);
    balances[address(this)] = unsoldTokens;
    totalSupply_ = totalSupply_.add(unsoldTokens);
    return true;
  }

  function sendUnsold (address _to, uint256 _value) public onlyOwner {
    require(_value <= balances[address(this)]);
    balances[address(this)] = balances[address(this)].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(address(this), _to, _value);
  }

  function getReserve () public onlyOwner returns (bool) {
    require(reserved > 0);
    balances[owner] = balances[owner].add(reserved);
    totalSupply_ = totalSupply_.add(reserved);
    emit Transfer(address(this), owner, reserved);
    reserved = 0;
    return true;   
  }

  function vest2team (address _address) public onlyOwner returns (bool) {
    require(team > 0);
    vested[_address] = vested[_address].add(team);
    totalVested = totalVested.add(team);
    team = 0;
    emit Vest(_address, team);
    return true;   
  }

  function vest2advisors (address _address) public onlyOwner returns (bool) {
    require(advisors > 0);
    vested[_address] = vested[_address].add(advisors);
    totalVested = totalVested.add(advisors);
    advisors = 0;
    emit Vest(_address, advisors);
    return true;       
  }

  function send2marketing (address _address) public onlyOwner returns (bool) {
    require(marketing > 0);
    balances[_address] = balances[_address].add(marketing);
    totalSupply_ = totalSupply_.add(marketing);
    emit Transfer(address(this), _address, marketing);
    marketing = 0;
    return true;           
  }

  function vest2mlDevelopers (address _address) public onlyOwner returns (bool) {
    require(mlDevelopers > 0);
    vested[_address] = vested[_address].add(mlDevelopers);
    totalVested = totalVested.add(mlDevelopers);
    mlDevelopers = 0;
    emit Vest(_address, mlDevelopers);
    return true;           
  }

  function vest2all (address _address) public onlyOwner returns (bool) {
    if (team > 0) {
      vested[_address] = vested[_address].add(team);
      totalVested = totalVested.add(team);
      team = 0;
      emit Vest(_address, team);      
    }
    if (advisors > 0) {
      vested[_address] = vested[_address].add(advisors);
      totalVested = totalVested.add(advisors);
      advisors = 0;
      emit Vest(_address, advisors);      
    }
    if (mlDevelopers > 0) {
      vested[_address] = vested[_address].add(mlDevelopers);
      totalVested = totalVested.add(mlDevelopers);
      mlDevelopers = 0;
      emit Vest(_address, mlDevelopers);      
    }
    return true;          
  }

  function getBonuses () internal view returns (uint8) {
    if (currentStage == Stages.PreSale) {
      return 25;
    }
    if (currentStage == Stages.Ico1) {
      return 20;
    }
    if (currentStage == Stages.Ico2) {
      return 15;
    }
    if (currentStage == Stages.Ico3) {
      return 10;
    }
    return 0;
  }

  function vestTo (address _to, uint256 _value) public onlyOwner returns (bool) {
    require(currentStage != Stages.Pause);
    require(currentStage != Stages.IcoEnd);
    require(_to != address(0));
    stageSupply[uint8(currentStage)] = stageSupply[uint8(currentStage)].add(_value);
    require(stageSupply[uint8(currentStage)] <= stageCap[uint8(currentStage)]);
    vested[_to] = vested[_to].add(_value);
    sold = sold.add(_value);
    totalVested = totalVested.add(_value);
    emit Vest(_to, _value);
    return true;
  }

  function getTokensAmount (uint256 _wei, address _sender) internal returns (uint256) {
    require(currentStage != Stages.IcoEnd);
    require(currentStage != Stages.Pause);
    uint256 tokens = _wei.mul(basePrice).div(1 ether);
    uint256 extraTokens = 0;
    uint256 stageRemains = 0;
    uint256 stagePrice = 0;
    uint256 stageBonuses = 0;
    uint256 spentWei = 0;
    uint256 change = 0;
    uint8 bonuses = 0;
    if (currentStage == Stages.PreSale) {
      require(_wei >= 100 finney);
      bonuses = getBonuses();
      extraTokens = tokens.mul(bonuses).div(100);
      tokens = tokens.add(extraTokens);
      stageSupply[uint8(currentStage)] = stageSupply[uint8(currentStage)].add(tokens);
      require(stageSupply[uint8(currentStage)] <= stageCap[uint8(currentStage)]);
      return tokens;
    }
    require(_wei >= 1 ether);
    if (currentStage == Stages.Ico4) {
      stageSupply[uint8(currentStage)] = stageSupply[uint8(currentStage)].add(tokens);
      require(stageSupply[uint8(currentStage)] <= stageCap[uint8(currentStage)]);
      return tokens;
    } else {
      if (currentIcoPeriodStartDate.add(icoPeriodTime) < now) nextStage(true);
      bonuses = getBonuses();
      stageRemains = stageCap[uint8(currentStage)].sub(stageSupply[uint8(currentStage)]);
      extraTokens = tokens.mul(bonuses).div(100);
      tokens = tokens.add(extraTokens);
      if (stageRemains > tokens) {
        stageSupply[uint8(currentStage)] = stageSupply[uint8(currentStage)].add(tokens);
        return tokens;
      } else {
        stageBonuses = basePrice.mul(bonuses).div(100);
        stagePrice = basePrice.add(stageBonuses);
        tokens = stageRemains;
        stageSupply[uint8(currentStage)] = stageCap[uint8(currentStage)];
        spentWei = tokens.mul(1 ether).div(stagePrice);
        change = _wei.sub(spentWei);
        nextStage(false);
        _sender.transfer(change);
        return tokens;
      }
    }
  }

  function nextStage (bool _time) internal returns (bool) {
    if (_time) {
      if (currentStage == Stages.Ico1) {
        if (currentIcoPeriodStartDate.add(icoPeriodTime).mul(3) < now) {
          currentStage = Stages.Ico4;
          currentIcoPeriodStartDate = now;
          return true;
        }
        if (currentIcoPeriodStartDate.add(icoPeriodTime).mul(2) < now) {
          currentStage = Stages.Ico3;
          currentIcoPeriodStartDate = now;
          return true;
        }
        currentStage = Stages.Ico2;
        currentIcoPeriodStartDate = now;
        return true;
      }
      if (currentStage == Stages.Ico2) {
        if (currentIcoPeriodStartDate.add(icoPeriodTime).mul(2) < now) {
          currentStage = Stages.Ico4;
          currentIcoPeriodStartDate = now;
          return true;
        }
        currentStage = Stages.Ico3;
        currentIcoPeriodStartDate = now;
        return true;
      }
      if (currentStage == Stages.Ico3) {
        currentStage = Stages.Ico4;
        currentIcoPeriodStartDate = now;
        return true;
      }
    } else {
      if (currentStage == Stages.Ico1) {
        currentStage = Stages.Ico2;
        currentIcoPeriodStartDate = now;
        return true;      
      }
      if (currentStage == Stages.Ico2) {
        currentStage = Stages.Ico3;
        currentIcoPeriodStartDate = now;
        return true;      
      }
      if (currentStage == Stages.Ico3) {
        currentStage = Stages.Ico4;
        currentIcoPeriodStartDate = now;
        return true;      
      }
    }
  }

  function () public payable {
    uint256 tokens = getTokensAmount(msg.value, msg.sender);
    vested[msg.sender] = vested[msg.sender].add(tokens);
    sold = sold.add(tokens);
    totalVested = totalVested.add(tokens);
    emit Vest(msg.sender, tokens);
  }
}

contract Multisign is Ownable {
  address public address1 = address(0);
  address public address2 = address(0);
  address public address3 = address(0);
  mapping(address => address) public withdrawAddress;

  function setAddresses (address _address1, address _address2, address _address3) public onlyOwner returns (bool) {
    require(address1 == address(0) && address2 == address(0) && address3 == address(0));
    require(_address1 != address(0) && _address2 != address(0) && _address3 != address(0));
    address1 = _address1;
    address2 = _address2;
    address3 = _address3;
    return true;
  }

  function signWithdraw (address _address) public returns (bool) {
    assert(msg.sender != address(0));
    require (msg.sender == address1 || msg.sender == address2 || msg.sender == address3);
    require (_address != address(0));
    withdrawAddress[msg.sender] = _address;
    if (withdrawAddress[address1] == withdrawAddress[address2] && withdrawAddress[address1] != address(0)) {
      withdraw(withdrawAddress[address1]);
      return true;
    }
    if (withdrawAddress[address1] == withdrawAddress[address3] && withdrawAddress[address1] != address(0)) {
      withdraw(withdrawAddress[address1]);
      return true;
    }
    if (withdrawAddress[address2] == withdrawAddress[address3] && withdrawAddress[address2] != address(0)) {
      withdraw(withdrawAddress[address2]);
      return true;
    }
    return false;
  }

  function withdraw (address _address) internal returns (bool) {
    require(address(this).balance > 0);
    withdrawAddress[address1] = address(0);
    withdrawAddress[address2] = address(0);
    withdrawAddress[address3] = address(0);
    _address.transfer(address(this).balance);
    return true;
  }
}

contract NSD is CrowdsaleToken, Multisign {
  string public constant name = "NeuroSeed";
  string public constant symbol = "NSD";
  uint32 public constant decimals = 0;
}