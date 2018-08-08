pragma solidity ^0.4.18;

// File: contracts/MigrationTarget.sol

//
// Migration target
// @dev Implement this interface to make migration target
//
contract MigrationTarget {
  function migrateFrom(address _from, uint256 _amount, uint256 _rewards, uint256 _trueBuy, bool _devStatus) public;
}

// File: contracts/Ownable.sol

contract Ownable {
  address public owner;

  // Event
  event OwnershipChanged(address indexed oldOwner, address indexed newOwner);

  // Modifier
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }
}

// File: contracts/ERC20.sol

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address _owner) view public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) view public returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/StandardToken.sol

/*  ERC 20 token */
contract StandardToken is ERC20 {
  /**
   * Internal transfer, only can be called by this contract
   */
  function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != address(0));
    // Check if the sender has enough
    require(balances[_from] >= _value);
    // Check for overflows
    require(balances[_to] + _value > balances[_to]);
    // Save this for an assertion in the future
    uint256 previousBalances = balances[_from] + balances[_to];
    // Subtract from the sender
    balances[_from] -= _value;
    // Add the same to the recipient
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(balances[_from] + balances[_to] == previousBalances);

    return true;
  }

  /**
   * Transfer tokens
   *
   * Send `_value` tokens to `_to` from your account
   *
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    return _transfer(msg.sender, _to, _value);
  }

  /**
   * Transfer tokens from other address
   *
   * Send `_value` tokens to `_to` in behalf of `_from`
   *
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);     // Check allowance
    allowed[_from][msg.sender] -= _value;
    return _transfer(_from, _to, _value);
  }

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * Set allowance for other address
   *
   * Allows `_spender` to spend no more than `_value` tokens in your behalf
   *
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;
}

// File: contracts/RoyaltyToken.sol

/*  Royalty token */
contract RoyaltyToken is StandardToken {
  using SafeMath for uint256;
  // restricted addresses	
  mapping(address => bool) public restrictedAddresses;
  
  event RestrictedStatusChanged(address indexed _address, bool status);

  struct Account {
    uint256 balance;
    uint256 lastRoyaltyPoint;
  }

  mapping(address => Account) public accounts;
  uint256 public totalRoyalty;
  uint256 public unclaimedRoyalty;

  /**
   * Get Royalty amount for given account
   *
   * @param account The address for Royalty account
   */
  function RoyaltysOwing(address account) public view returns (uint256) {
    uint256 newRoyalty = totalRoyalty.sub(accounts[account].lastRoyaltyPoint);
    return balances[account].mul(newRoyalty).div(totalSupply);
  }

  /**
   * @dev Update account for Royalty
   * @param account The address of owner
   */
  function updateAccount(address account) internal {
    uint256 owing = RoyaltysOwing(account);
    accounts[account].lastRoyaltyPoint = totalRoyalty;
    if (owing > 0) {
      unclaimedRoyalty = unclaimedRoyalty.sub(owing);
      accounts[account].balance = accounts[account].balance.add(owing);
    }
  }

  function disburse() public payable {
    require(totalSupply > 0);
    require(msg.value > 0);

    uint256 newRoyalty = msg.value;
    totalRoyalty = totalRoyalty.add(newRoyalty);
    unclaimedRoyalty = unclaimedRoyalty.add(newRoyalty);
  }

  /**
   * @dev Send `_value` tokens to `_to` from your account
   *
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    // Require that the sender is not restricted
    require(restrictedAddresses[msg.sender] == false);
    updateAccount(_to);
    updateAccount(msg.sender);
    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from other address. Send `_value` tokens to `_to` in behalf of `_from`
   *
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    updateAccount(_to);
    updateAccount(_from);
    return super.transferFrom(_from, _to, _value);
  }

  function withdrawRoyalty() public {
    updateAccount(msg.sender);

    // retrieve Royalty amount
    uint256 RoyaltyAmount = accounts[msg.sender].balance;
    require(RoyaltyAmount > 0);
    accounts[msg.sender].balance = 0;

    // transfer Royalty amount
    msg.sender.transfer(RoyaltyAmount);
  }
}

// File: contracts/Q2.sol

contract Q2 is Ownable, RoyaltyToken {
  using SafeMath for uint256;

  string public name = "Q2";
  string public symbol = "Q2";
  uint8 public decimals = 18;

  bool public whitelist = true;

  // whitelist addresses
  mapping(address => bool) public whitelistedAddresses;

  // token creation cap
  uint256 public creationCap = 15000000 * (10 ** 18); // 15M
  uint256 public reservedFund = 10000000 * (10 ** 18); // 10M

  // stage info
  struct Stage {
    uint8 number;
    uint256 exchangeRate;
    uint256 startBlock;
    uint256 endBlock;
    uint256 cap;
  }

  // events
  event MintTokens(address indexed _to, uint256 _value);
  event StageStarted(uint8 _stage, uint256 _totalSupply, uint256 _balance);
  event StageEnded(uint8 _stage, uint256 _totalSupply, uint256 _balance);
  event WhitelistStatusChanged(address indexed _address, bool status);
  event WhitelistChanged(bool status);

  // eth wallet
  address public ethWallet;
  mapping (uint8 => Stage) stages;

  // current state info
  uint8 public currentStage;

  function Q2(address _ethWallet) public {
    ethWallet = _ethWallet;

    // reserved tokens
    mintTokens(ethWallet, reservedFund);
  }

  function mintTokens(address to, uint256 value) internal {
    require(value > 0);
    balances[to] = balances[to].add(value);
    totalSupply = totalSupply.add(value);
    require(totalSupply <= creationCap);

    // broadcast event
    emit MintTokens(to, value);
  }

  function () public payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(whitelist==false || whitelistedAddresses[msg.sender] == true);
    require(msg.value > 0);

    Stage memory stage = stages[currentStage];
    require(block.number >= stage.startBlock && block.number <= stage.endBlock);

    uint256 tokens = msg.value * stage.exchangeRate;
    require(totalSupply.add(tokens) <= stage.cap);

    mintTokens(msg.sender, tokens);
  }

  function startStage(
    uint256 _exchangeRate,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock
  ) public onlyOwner {
    require(_exchangeRate > 0 && _cap > 0);
    require(_startBlock > block.number);
    require(_startBlock < _endBlock);

    // stop current stage if it&#39;s running
    Stage memory currentObj = stages[currentStage];
    if (currentObj.endBlock > 0) {
      // broadcast stage end event
      emit StageEnded(currentStage, totalSupply, address(this).balance);
    }

    // increment current stage
    currentStage = currentStage + 1;

    // create new stage object
    Stage memory s = Stage({
      number: currentStage,
      startBlock: _startBlock,
      endBlock: _endBlock,
      exchangeRate: _exchangeRate,
      cap: _cap + totalSupply
    });
    stages[currentStage] = s;

    // broadcast stage started event
    emit StageStarted(currentStage, totalSupply, address(this).balance);
  }

  function withdraw() public onlyOwner {
    ethWallet.transfer(address(this).balance);
  }

  function getCurrentStage() view public returns (
    uint8 number,
    uint256 exchangeRate,
    uint256 startBlock,
    uint256 endBlock,
    uint256 cap
  ) {
    Stage memory currentObj = stages[currentStage];
    number = currentObj.number;
    exchangeRate = currentObj.exchangeRate;
    startBlock = currentObj.startBlock;
    endBlock = currentObj.endBlock;
    cap = currentObj.cap;
  }

  function changeWhitelistStatus(address _address, bool status) public onlyOwner {
    whitelistedAddresses[_address] = status;
    emit WhitelistStatusChanged(_address, status);
  }

  function changeRestrictedtStatus(address _address, bool status) public onlyOwner {
    restrictedAddresses[_address] = status;
    emit RestrictedStatusChanged(_address, status);
  }
  
  function changeWhitelist(bool status) public onlyOwner {
     whitelist = status;
     emit WhitelistChanged(status);
  }
}

// File: contracts/Quarters.sol

interface TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Quarters is Ownable, StandardToken {
  // Public variables of the token
  string public name = "Quarters";
  string public symbol = "Q";
  uint8 public decimals = 0; // no decimals, only integer quarters

  uint16 public ethRate = 4000; // Quarters/ETH
  uint256 public tranche = 40000; // Number of Quarters in initial tranche

  // List of developers
  // address -> status
  mapping (address => bool) public developers;

  uint256 public outstandingQuarters;
  address public q2;

  // number of Quarters for next tranche
  uint8 public trancheNumerator = 2;
  uint8 public trancheDenominator = 1;

  // initial multiples, rates (as percentages) for tiers of developers
  uint32 public mega = 20;
  uint32 public megaRate = 115;
  uint32 public large = 100;
  uint32 public largeRate = 90;
  uint32 public medium = 2000;
  uint32 public mediumRate = 75;
  uint32 public small = 50000;
  uint32 public smallRate = 50;
  uint32 public microRate = 25;

  // rewards related storage
  mapping (address => uint256) public rewards;    // rewards earned, but not yet collected
  mapping (address => uint256) public trueBuy;    // tranche rewards are set based on *actual* purchases of Quarters

  uint256 public rewardAmount = 40;

  uint8 public rewardNumerator = 1;
  uint8 public rewardDenominator = 4;

  // reserve ETH from Q2 to fund rewards
  uint256 public reserveETH=0;

  // ETH rate changed
  event EthRateChanged(uint16 currentRate, uint16 newRate);

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  event QuartersOrdered(address indexed sender, uint256 ethValue, uint256 tokens);
  event DeveloperStatusChanged(address indexed developer, bool status);
  event TrancheIncreased(uint256 _tranche, uint256 _etherPool, uint256 _outstandingQuarters);
  event MegaEarnings(address indexed developer, uint256 value, uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool);
  event Withdraw(address indexed developer, uint256 value, uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool);
  event BaseRateChanged(uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool,  uint256 _totalSupply);
  event Reward(address indexed _address, uint256 value, uint256 _outstandingQuarters, uint256 _totalSupply);

  /**
   * developer modifier
   */
  modifier onlyActiveDeveloper() {
    require(developers[msg.sender] == true);
    _;
  }

  /**
   * Constructor function
   *
   * Initializes contract with initial supply tokens to the owner of the contract
   */
  function Quarters(
    address _q2,
    uint256 firstTranche
  ) public {
    q2 = _q2;
    tranche = firstTranche; // number of Quarters to be sold before increasing price
  }

  function setEthRate (uint16 rate) onlyOwner public {
    // Ether price is set in Wei
    require(rate > 0);
    ethRate = rate;
    emit EthRateChanged(ethRate, rate);
  }

  /**
   * Adjust reward amount
   */
  function adjustReward (uint256 reward) onlyOwner public {
    rewardAmount = reward; // may be zero, no need to check value to 0
  }

  function adjustWithdrawRate(uint32 mega2, uint32 megaRate2, uint32 large2, uint32 largeRate2, uint32 medium2, uint32 mediumRate2, uint32 small2, uint32 smallRate2, uint32 microRate2) onlyOwner public {
    // the values (mega, large, medium, small) are multiples, e.g., 20x, 100x, 10000x
    // the rates (megaRate, etc.) are percentage points, e.g., 150 is 150% of the remaining etherPool
    if (mega2 > 0 && megaRate2 > 0) {
      mega = mega2;
      megaRate = megaRate2;
    }

    if (large2 > 0 && largeRate2 > 0) {
      large = large2;
      largeRate = largeRate2;
    }

    if (medium2 > 0 && mediumRate2 > 0) {
      medium = medium2;
      mediumRate = mediumRate2;
    }

    if (small2 > 0 && smallRate2 > 0){
      small = small2;
      smallRate = smallRate2;
    }

    if (microRate2 > 0) {
      microRate = microRate2;
    }
  }

  /**
   * adjust tranche for next cycle
   */
  function adjustNextTranche (uint8 numerator, uint8 denominator) onlyOwner public {
    require(numerator > 0 && denominator > 0);
    trancheNumerator = numerator;
    trancheDenominator = denominator;
  }

  function adjustTranche(uint256 tranche2) onlyOwner public {
    require(tranche2 > 0);
    tranche = tranche2;
  }

  /**
   * Adjust rewards for `_address`
   */
  function updatePlayerRewards(address _address) internal {
    require(_address != address(0));

    uint256 _reward = 0;
    if (rewards[_address] == 0) {
      _reward = rewardAmount;
    } else if (rewards[_address] < tranche) {
      _reward = trueBuy[_address] * rewardNumerator / rewardDenominator;
    }

    if (_reward > 0) {
      // update rewards record
      rewards[_address] = tranche;

      balances[_address] += _reward;
      allowed[_address][msg.sender] += _reward; // set allowance

      totalSupply += _reward;
      outstandingQuarters += _reward;

      uint256 spentETH = (_reward * (10 ** 18)) / ethRate;
      if (reserveETH >= spentETH) {
          reserveETH -= spentETH;
        } else {
          reserveETH = 0;
        }

      // tranche size change
      _changeTrancheIfNeeded();

      emit Approval(_address, msg.sender, _reward);
      emit Reward(_address, _reward, outstandingQuarters, totalSupply);
    }
  }

  /**
   * Developer status
   */
  function setDeveloperStatus (address _address, bool status) onlyOwner public {
    developers[_address] = status;
    emit DeveloperStatusChanged(_address, status);
  }

  /**
   * Set allowance for other address and notify
   *
   * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
   *
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   * @param _extraData some extra information to send to the approved contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
  public
  returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }

    return false;
  }

  /**
   * Destroy tokens
   *
   * Remove `_value` tokens from the system irreversibly
   *
   * @param _value the amount of money to burn
   */
  function burn(uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);   // Check if the sender has enough
    balances[msg.sender] -= _value;            // Subtract from the sender
    totalSupply -= _value;                     // Updates totalSupply
    outstandingQuarters -= _value;              // Update outstanding quarters
    emit Burn(msg.sender, _value);

    // log rate change
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);
    return true;
  }

  /**
   * Destroy tokens from other account
   *
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   *
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balances[_from] >= _value);                // Check if the targeted balance is enough
    require(_value <= allowed[_from][msg.sender]);     // Check allowance
    balances[_from] -= _value;                         // Subtract from the targeted balance
    allowed[_from][msg.sender] -= _value;              // Subtract from the sender&#39;s allowance
    totalSupply -= _value;                      // Update totalSupply
    outstandingQuarters -= _value;              // Update outstanding quarters
    emit Burn(_from, _value);

    // log rate change
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);
    return true;
  }

  /**
   * Buy quarters by sending ethers to contract address (no data required)
   */
  function () payable public {
    _buy(msg.sender);
  }


  function buy() payable public {
    _buy(msg.sender);
  }

  function buyFor(address buyer) payable public {
    uint256 _value =  _buy(buyer);

    // allow donor (msg.sender) to spend buyer&#39;s tokens
    allowed[buyer][msg.sender] += _value;
    emit Approval(buyer, msg.sender, _value);
  }

  function _changeTrancheIfNeeded() internal {
    if (totalSupply >= tranche) {
      // change tranche size for next cycle
      tranche = (tranche * trancheNumerator) / trancheDenominator;

      // fire event for tranche change
      emit TrancheIncreased(tranche, address(this).balance, outstandingQuarters);
    }
  }

  // returns number of quarters buyer got
  function _buy(address buyer) internal returns (uint256) {
    require(buyer != address(0));

    uint256 nq = (msg.value * ethRate) / (10 ** 18);
    require(nq != 0);
    if (nq > tranche) {
      nq = tranche;
    }

    totalSupply += nq;
    balances[buyer] += nq;
    trueBuy[buyer] += nq;
    outstandingQuarters += nq;

    // change tranche size
    _changeTrancheIfNeeded();

    // event for quarters order (invoice)
    emit QuartersOrdered(buyer, msg.value, nq);

    // log rate change
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);

    // transfer owner&#39;s cut
    Q2(q2).disburse.value(msg.value * 15 / 100)();

    // return nq
    return nq;
  }

  /**
   * Transfer allowance from other address&#39;s allowance
   *
   * Send `_value` tokens to `_to` in behalf of `_from`
   *
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transferAllowance(address _from, address _to, uint256 _value) public returns (bool success) {
    updatePlayerRewards(_from);
    require(_value <= allowed[_from][msg.sender]);     // Check allowance
    allowed[_from][msg.sender] -= _value;

    if (_transfer(_from, _to, _value)) {
      // allow msg.sender to spend _to&#39;s tokens
      allowed[_to][msg.sender] += _value;
      emit Approval(_to, msg.sender, _value);
      return true;
    }

    return false;
  }

  function withdraw(uint256 value) onlyActiveDeveloper public {
    require(balances[msg.sender] >= value);

    uint256 baseRate = getBaseRate();
    require(baseRate > 0); // check if base rate > 0

    uint256 earnings = value * baseRate;
    uint256 rate = getRate(value); // get rate from value and tranche
    uint256 earningsWithBonus = (rate * earnings) / 100;
    if (earningsWithBonus > address(this).balance) {
      earnings = address(this).balance;
    } else {
      earnings = earningsWithBonus;
    }

    balances[msg.sender] -= value;
    outstandingQuarters -= value; // update the outstanding Quarters

    uint256 etherPool = address(this).balance - earnings;
    if (rate == megaRate) {
      emit MegaEarnings(msg.sender, earnings, baseRate, tranche, outstandingQuarters, etherPool); // with current base rate
    }

    // event for withdraw
    emit Withdraw(msg.sender, earnings, baseRate, tranche, outstandingQuarters, etherPool);  // with current base rate

    // log rate change
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);

    // earning for developers
    msg.sender.transfer(earnings);  
}

  function disburse() public payable {
    reserveETH += msg.value;
  }

  function getBaseRate () view public returns (uint256) {
    if (outstandingQuarters > 0) {
      return (address(this).balance - reserveETH) / outstandingQuarters;
    }

    return (address(this).balance - reserveETH);
  }

  function getRate (uint256 value) view public returns (uint32) {
    if (value * mega > tranche) {  // size & rate for mega developer
      return megaRate;
    } else if (value * large > tranche) {   // size & rate for large developer
      return largeRate;
    } else if (value * medium > tranche) {  // size and rate for medium developer
      return mediumRate;
    } else if (value * small > tranche){  // size and rate for small developer
      return smallRate;
    }

    return microRate; // rate for micro developer
  }


  //
  // Migrations
  //

  // Target contract
  address public migrationTarget;
  bool public migrating = false;

  // Migrate event
  event Migrate(address indexed _from, uint256 _value);

  //
  // Migrate tokens to the new token contract.
  //
  function migrate() public {
    require(migrationTarget != address(0));
    uint256 _amount = balances[msg.sender];
    require(_amount > 0);
    balances[msg.sender] = 0;

    totalSupply = totalSupply - _amount;
    outstandingQuarters = outstandingQuarters - _amount;

    rewards[msg.sender] = 0;
    trueBuy[msg.sender] = 0;
    developers[msg.sender] = false;

    emit Migrate(msg.sender, _amount);
    MigrationTarget(migrationTarget).migrateFrom(msg.sender, _amount, rewards[msg.sender], trueBuy[msg.sender], developers[msg.sender]);
  }

  //
  // Set address of migration target contract
  // @param _target The address of the MigrationTarget contract
  //
  function setMigrationTarget(address _target) onlyOwner public {
    migrationTarget = _target;
  }
}