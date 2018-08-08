pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/EubChainIco.sol

contract EubChainIco is PausableToken {

  using SafeMath for uint;
  using SafeMath for uint256;
  using SafeERC20 for StandardToken;

  string public name = &#39;EUB Chain&#39;;
  string public symbol = &#39;EUBC&#39;;
  uint8 public decimals = 8;

  uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);  // 1 billion tokens

  uint public startTime;  // contract deployed timestamp

  uint256 public tokenSold = 0; // total token sold

  uint8 private teamShare = 10; // 10 percent
  uint8 private teamExtraShare = 2; // 2 percent
  uint8 private communityShare = 10; // 10 percent
  uint8 private foundationShare = 10; // 10 percent
  uint8 private operationShare = 40; // 40 percent

  uint8 private icoShare = 30; // 30 percent
  uint256 private icoCap = totalSupply.mul(icoShare).div(100);

  uint256 private teamLockPeriod = 365 days;
  uint256 private minVestLockMonths = 3;

  address private fundsWallet;
  address private teamWallet; // for team, lock for 1 year (can not transfer)
  address private communityWallet; // for community group
  address private foundationWallet; // for the foundation group

  struct Locking {
    uint256 amount;
    uint endTime;
  }
  struct Vesting {
    uint256 amount;
    uint startTime;
    uint lockMonths;
    uint256 released;
  }

  mapping (address => Locking) private lockingMap;
  mapping (address => Vesting) private vestingMap;

  event VestTransfer(
    address indexed from,
    address indexed to,
    uint256 amount, 
    uint startTime, 
    uint lockMonths
  );
  event Release(address indexed to, uint256 amount);

  /*
    Contract constructor

    @param _fundsWallet - funding wallet address
    @param _teamWallet - team wallet address

    @return address of created contract
  */
  constructor () public {

    startTime = now;
    uint teamLockEndTime = startTime.add(teamLockPeriod);

    // save wallet addresses
    fundsWallet = 0x1D64D9957e54711bf681985dB11Ac4De6508d2d8;
    teamWallet = 0xe0f58e3b40d5B97aa1C72DD4853cb462E8628386;
    communityWallet = 0x12bEfdd7D64312353eA0Cb0803b14097ee4cE28F;
    foundationWallet = 0x8e037d80dD9FF654a17A4a009B49BfB71a992Cab;

    // calculate token/allocation for each wallet type
    uint256 teamTokens = totalSupply.mul(teamShare).div(100);
    uint256 teamExtraTokens = totalSupply.mul(teamExtraShare).div(100);
    uint256 communityTokens = totalSupply.mul(communityShare).div(100);
    uint256 foundationTokens = totalSupply.mul(foundationShare).div(100);
    uint256 operationTokens = totalSupply.mul(operationShare).div(100);

    // team wallet enter vesting period after lock period
    Vesting storage teamVesting = vestingMap[teamWallet];
    teamVesting.amount = teamTokens;
    teamVesting.startTime = teamLockEndTime;
    teamVesting.lockMonths = 6;
    emit VestTransfer(0x0, teamWallet, teamTokens, teamLockEndTime, teamVesting.lockMonths);

    // transfer tokens to wallets
    balances[communityWallet] = communityTokens;
    emit Transfer(0x0, communityWallet, communityTokens);
    balances[foundationWallet] = foundationTokens;
    emit Transfer(0x0, foundationWallet, foundationTokens);

    // transfer extra tokens from community wallet to team wallet
    balances[communityWallet] = balances[communityWallet].sub(teamExtraTokens);
    balances[teamWallet] = balances[teamWallet].add(teamExtraTokens);
    emit Transfer(communityWallet, teamWallet, teamExtraTokens);
  
    // assign the rest to the funds wallet
    uint256 restOfTokens = (
      totalSupply
        .sub(teamTokens)
        .sub(communityTokens)
        .sub(foundationTokens)
        .sub(operationTokens)
    );
    balances[fundsWallet] = restOfTokens;
    emit Transfer(0x0, fundsWallet, restOfTokens);
    
  }

  /*
    transfer vested tokens to receiver with lock period in months

    @param _to - address of token receiver 
    @param _amount - amount of token allocate 
    @param _lockMonths - number of months to vest

    @return true if the transfer is done
  */
  function vestedTransfer(address _to, uint256 _amount, uint _lockMonths) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    require(
      msg.sender == fundsWallet ||
      msg.sender == teamWallet
    );
  
    // minimum vesting 3 months
    require(_lockMonths >= minVestLockMonths);

    // make sure it is a brand new vesting on the address
    Vesting storage vesting = vestingMap[_to];
    require(vesting.amount == 0);

    if (msg.sender == fundsWallet) {
      // check if token amount exceeds ico token cap
      require(allowPurchase(_amount));
      require(isPurchaseWithinCap(tokenSold, _amount));
    
      // check if msg.sender allow to send the amount
      require(allowTransfer(msg.sender, _amount));

      uint256 transferAmount = _amount.mul(15).div(100);
      uint256 vestingAmount = _amount.sub(transferAmount);

      vesting.amount = vestingAmount;
      vesting.startTime = now;
      vesting.lockMonths = _lockMonths;

      emit VestTransfer(msg.sender, _to, vesting.amount, vesting.startTime, _lockMonths);

      balances[msg.sender] = balances[msg.sender].sub(_amount);
      tokenSold = tokenSold.add(_amount);

      balances[_to] = balances[_to].add(transferAmount);
      emit Transfer(msg.sender, _to, transferAmount);
    } else if (msg.sender == teamWallet) {
      Vesting storage teamVesting = vestingMap[teamWallet];

      require(now < teamVesting.startTime);
      require(
        teamVesting.amount.sub(teamVesting.released) > _amount
      );

      teamVesting.amount = teamVesting.amount.sub(_amount);

      vesting.amount = _amount;
      vesting.startTime = teamVesting.startTime;
      vesting.lockMonths = _lockMonths;

      emit VestTransfer(msg.sender, _to, vesting.amount, vesting.startTime, _lockMonths);
    }

    return true;
  }

  // @return true if ico is open
  function isIcoOpen() public view returns (bool) {
    bool capReached = tokenSold >= icoCap;
    return !capReached;
  }

  /*
    check if purchase amount exists ico cap

    @param _tokenSold - amount of token sold 
    @param _purchaseAmount - amount of token want to purchase

    @return true if _purchaseAmount is allowed
  */
  function isPurchaseWithinCap(uint256 _tokenSold, uint256 _purchaseAmount) internal view returns(bool) {
    bool isLessThanCap = _tokenSold.add(_purchaseAmount) <= icoCap;
    return isLessThanCap;
  }

  /*
    @param _amount - amount of token
    @return true if the purchase is valid
  */
  function allowPurchase(uint256 _amount) internal view returns (bool) {
    bool nonZeroPurchase = _amount != 0;
    return nonZeroPurchase && isIcoOpen();
  }

  /*
    @param _wallet - wallet address of the token sender
    @param _amount - amount of token
    @return true if the transfer is valid
  */
  function allowTransfer(address _wallet, uint256 _amount) internal view returns (bool) {
    Locking memory locking = lockingMap[_wallet];
    if (locking.endTime > now) {
      return balances[_wallet].sub(_amount) >= locking.amount;
    } else {
      return balances[_wallet] >= _amount;
    }
  }

  /*
    transfer token from caller to receiver

    @param _to - wallet address of the token receiver
    @param _value - amount of token to be transferred

    @return true if the transfer is done
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(allowTransfer(msg.sender, _value));
    return super.transfer(_to, _value);
  }

  /*
    transfer token from sender to receiver 

    @param _from - wallet address of the token sender
    @param _to - wallet address of the token receiver
    @param _value - amount of token to be transferred

    @return true if the transfer is done
  */
  function transferFrom(address _from, address _to, uint256 _value)  onlyPayloadSize(3 * 32) public returns (bool) {
    require(allowTransfer(_from, _value));
    return super.transferFrom(_from, _to, _value);
  }

  /*
    @param _wallet - wallet address wanted to check
    @return amount of token allocated
  */
  function allocationOf(address _wallet) public view returns (uint256) {
    Vesting memory vesting = vestingMap[_wallet];
    return vesting.amount;
  }

  /*
    get the releasable tokens
    @return amount of released tokens
  */
  function release() public onlyPayloadSize(0 * 32) returns (uint256) {
    uint256 unreleased = releasableAmount(msg.sender);
    Vesting storage vesting = vestingMap[msg.sender];

    if (unreleased > 0) {
      vesting.released = vesting.released.add(unreleased);
      emit Release(msg.sender, unreleased);

      balances[msg.sender] = balances[msg.sender].add(unreleased);
      emit Transfer(0x0, msg.sender, unreleased);
    }

    return unreleased;
  }

  /*
    @param _wallet - wallet address wanted to check
    @return amount of releasable token
  */
  function releasableAmount(address _wallet) public view returns (uint256) {
    Vesting memory vesting = vestingMap[_wallet];
    return vestedAmount(_wallet).sub(vesting.released);
  }

  /*
    @param _wallet - wallet address wanted to check
    @return amount of vested token
  */
  function vestedAmount(address _wallet) public view returns (uint256) {
    uint amonth = 30 days;
    Vesting memory vesting = vestingMap[_wallet];
    uint lockPeriod = vesting.lockMonths.mul(amonth);
    uint lockEndTime = vesting.startTime.add(lockPeriod);

    if (now >= lockEndTime) {
      return vesting.amount;
    } else if (now > vesting.startTime) {
      // vest a portion of token each month
      
      uint roundedPeriod = now
        .sub(vesting.startTime)
        .div(amonth)
        .mul(amonth);

      return vesting.amount
        .mul(roundedPeriod)
        .div(lockPeriod);
    } else {
      return 0;
    }
  }

  /*
    modifiers to avoid short address attack
  */
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  } 
  
}