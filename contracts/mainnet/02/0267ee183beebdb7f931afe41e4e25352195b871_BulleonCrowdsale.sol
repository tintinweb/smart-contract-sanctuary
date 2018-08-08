pragma solidity ^0.4.21;

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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



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


 /* Standard SafeMath implementation from Zeppelin */






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
 /* Standard Claimable implementation from Zeppelin */







/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}
 /* Standard Claimable implementation from Zeppelin */













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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}
 // Standard burnable token implementation from Zeppelin









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
 // PausableToken implementation from Zeppelin
 // Claimable implementation from Zeppelin
 /* Standard Claimable implementation from Zeppelin */

interface CrowdsaleContract {
  function isActive() public view returns(bool);
}

contract BulleonToken is StandardBurnableToken, PausableToken, Claimable, CanReclaimToken {
  /* Additional events */
  event AddedToWhitelist(address wallet);
  event RemoveWhitelist(address wallet);

  /* Base params */
  string public constant name = "Bulleon"; /* solium-disable-line uppercase */
  string public constant symbol = "BUL"; /* solium-disable-line uppercase */
  uint8 public constant decimals = 18; /* solium-disable-line uppercase */
  uint256 constant exchangersBalance = 39991750231582759746295 + 14715165984103328399573 + 1846107707643607869274; // YoBit + Etherdelta + IDEX

  /* Premine and start balance settings */
  address constant premineWallet = 0x286BE9799488cA4543399c2ec964e7184077711C;
  uint256 constant premineAmount = 178420 * (10 ** uint256(decimals));

  /* Additional params */
  address public CrowdsaleAddress;
  CrowdsaleContract crowdsale;
  mapping(address=>bool) whitelist; // Users that may transfer tokens before ICO ended

  /**
   * @dev Constructor that gives msg.sender all availabel of existing tokens.
   */
  constructor() public {
    totalSupply_ = 7970000 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply_;
    transfer(premineWallet, premineAmount.add(exchangersBalance));

    addToWhitelist(msg.sender);
    addToWhitelist(premineWallet);
    paused = true; // Lock token at start
  }

  /**
   * @dev Sets crowdsale contract address (used for checking ICO status)
   */
  function setCrowdsaleAddress(address _ico) public onlyOwner {
    CrowdsaleAddress = _ico;
    crowdsale = CrowdsaleContract(CrowdsaleAddress);
    addToWhitelist(CrowdsaleAddress);
  }

  /**
   * @dev called by user the to pause, triggers stopped state
   * not actualy used
   */
  function pause() onlyOwner whenNotPaused public {
    revert();
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused or when sender is whitelisted.
   */
  modifier whenNotPaused() {
    require(!paused || whitelist[msg.sender]);
    _;
  }

  /**
   * @dev called by the user to unpause at ICO end or by owner, returns token to unlocked state
   */
  function unpause() whenPaused public {
    require(!crowdsale.isActive() || msg.sender == owner); // Checks that ICO is ended
    paused = false;
    emit Unpause();
  }

  /**
   * @dev Add wallet address to transfer whitelist (may transfer tokens before ICO ended)
   */
  function addToWhitelist(address wallet) public onlyOwner {
    require(!whitelist[wallet]);
    whitelist[wallet] = true;
    emit AddedToWhitelist(wallet);
  }

  /**
   * @dev Delete wallet address to transfer whitelist (may transfer tokens before ICO ended)
   */
  function delWhitelist(address wallet) public onlyOwner {
    require(whitelist[wallet]);
    whitelist[wallet] = false;
    emit RemoveWhitelist(wallet);
  }

  // DELETE IT!
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}



contract BulleonCrowdsale is Claimable, CanReclaimToken {
    using SafeMath for uint256;
    /* Additionals events */
    event AddedToBlacklist(address wallet);
    event RemovedFromBlacklist(address wallet);

    /* Infomational vars */
    string public version = "2.0";

    /* ICO params */
    address public withdrawWallet = 0xAd74Bd38911fE4C19c95D14b5733372c3978C2D9;
    uint256 public endDate = 1546300799; // Monday, 31-Dec-18 23:59:59 UTC
    BulleonToken public rewardToken;
    // Tokens rate (BUL / ETH) on stage
    uint256[] public tokensRate = [
      1000, // stage 1
      800, // stage 2
      600, // stage 3
      400, // stage 4
      200, // stage 5
      100, // stage 6
      75, // stage 7
      50, // stage 8
      25, // stage 9
      10 // stage 10
    ];
    // Tokens cap (max sold tokens) on stage
    uint256[] public tokensCap = [
      760000, // stage 1
      760000, // stage 2
      760000, // stage 3
      760000, // stage 4
      760000, // stage 5
      760000, // stage 6
      760000, // stage 7
      760000, // stage 8
      760000, // stage 9
      759000  // stage 10
    ];
    mapping(address=>bool) public isBlacklisted;

    /* ICO stats */
    uint256 public totalSold = 329406072304513072322000; // ! Update on publish
    uint256 public soldOnStage = 329406072304513072322000; // ! Update on publish
    uint8 public currentStage = 0;

    /* Bonus params */
    uint256 public bonus = 0;
    uint256 constant BONUS_COEFF = 1000; // Values should be 10x percents, value 1000 = 100%
    mapping(address=>uint256) public investmentsOf; // Investments made by wallet

   /**
    * @dev Returns crowdsale status (if active returns true).
    */
    function isActive() public view returns (bool) {
      return !(availableTokens() == 0 || now > endDate);
    }

    /* ICO stats methods */

    /**
     * @dev Returns tokens amount cap for current stage.
     */
    function stageCap() public view returns(uint256) {
      return tokensCap[currentStage].mul(1 ether);
    }

    /**
     * @dev Returns tokens amount available to sell at current stage.
     */
    function availableOnStage() public view returns(uint256) {
        return stageCap().sub(soldOnStage) > availableTokens() ? availableTokens() : stageCap().sub(soldOnStage);
    }

    /**
     * @dev Returns base rate (BUL/ETH) of current stage.
     */
    function stageBaseRate() public view returns(uint256) {
      return tokensRate[currentStage];
    }

    /**
     * @dev Returns actual (base + bonus %) rate (BUL/ETH) of current stage.
     */
    function stageRate() public view returns(uint256) {
      return stageBaseRate().mul(BONUS_COEFF.add(getBonus())).div(BONUS_COEFF);
    }

    constructor(address token) public {
        require(token != 0x0);
        rewardToken = BulleonToken(token);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Main token puchase function
     */
    function buyTokens(address beneficiary) public payable {
      bool validPurchase = beneficiary != 0x0 && msg.value != 0 && !isBlacklisted[msg.sender];
      uint256 currentTokensAmount = availableTokens();
      // Check that ICO is Active and purchase tx is valid
      require(isActive() && validPurchase);
      investmentsOf[msg.sender] = investmentsOf[msg.sender].add(msg.value);
      uint256 boughtTokens;
      uint256 refundAmount = 0;

      // Calculate tokens and refund amount at multiple stage
      uint256[2] memory tokensAndRefund = calcMultiStage();
      boughtTokens = tokensAndRefund[0];
      refundAmount = tokensAndRefund[1];
      // Check that bought tokens amount less then current
      require(boughtTokens <= currentTokensAmount);

      totalSold = totalSold.add(boughtTokens); // Increase stats variable

      if(soldOnStage >= stageCap()) {
        toNextStage();
      }

      rewardToken.transfer(beneficiary, boughtTokens);

      if (refundAmount > 0)
          refundMoney(refundAmount);

      withdrawFunds(this.balance);
    }

    /**
     * @dev Forcibility withdraw contract ETH balance.
     */
    function forceWithdraw() public onlyOwner {
      withdrawFunds(this.balance);
    }

    /**
     * @dev Calculate tokens amount and refund amount at purchase procedure.
     */
    function calcMultiStage() internal returns(uint256[2]) {
      uint256 stageBoughtTokens;
      uint256 undistributedAmount = msg.value;
      uint256 _boughtTokens = 0;
      uint256 undistributedTokens = availableTokens();

      while(undistributedAmount > 0 && undistributedTokens > 0) {
        bool needNextStage = false;

        stageBoughtTokens = getTokensAmount(undistributedAmount);

        if (stageBoughtTokens > availableOnStage()) {
          stageBoughtTokens = availableOnStage();
          needNextStage = true;
        }

        _boughtTokens = _boughtTokens.add(stageBoughtTokens);
        undistributedTokens = undistributedTokens.sub(stageBoughtTokens);
        undistributedAmount = undistributedAmount.sub(getTokensCost(stageBoughtTokens));
        soldOnStage = soldOnStage.add(stageBoughtTokens);
        if (needNextStage)
          toNextStage();
      }
      return [_boughtTokens,undistributedAmount];
    }

    /**
     * @dev Sets withdraw wallet address. (called by owner)
     */
    function setWithdraw(address _withdrawWallet) public onlyOwner {
        require(_withdrawWallet != 0x0);
        withdrawWallet = _withdrawWallet;
    }

    /**
     * @dev Make partical refund at purchasing procedure
     */
    function refundMoney(uint256 refundAmount) internal {
      msg.sender.transfer(refundAmount);
    }

    /**
     * @dev Give owner ability to burn some tokens amount at ICO contract
     */
    function burnTokens(uint256 amount) public onlyOwner {
      rewardToken.burn(amount);
    }

    /**
     * @dev Returns costs of given tokens amount
     */
    function getTokensCost(uint256 _tokensAmount) public view returns(uint256) {
      return _tokensAmount.div(stageRate());
    }

    function getTokensAmount(uint256 _amountInWei) public view returns(uint256) {
      return _amountInWei.mul(stageRate());
    }



    /**
     * @dev Switch contract to next stage and reset stage stats
     */
    function toNextStage() internal {
        if (
          currentStage < tokensRate.length &&
          currentStage < tokensCap.length
        ) {
          currentStage++;
          soldOnStage = 0;
        }
    }

    function availableTokens() public view returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function withdrawFunds(uint256 amount) internal {
        withdrawWallet.transfer(amount);
    }

    function kill() public onlyOwner {
      require(!isActive()); // Check that ICO is Ended (!= Active)
      rewardToken.burn(availableTokens()); // Burn tokens
      selfdestruct(owner); // Destruct ICO contract
    }

    function setBonus(uint256 bonusAmount) public onlyOwner {
      require(
        bonusAmount < 100 * BONUS_COEFF &&
        bonusAmount >= 0
      );
      bonus = bonusAmount;
    }

    function getBonus() public view returns(uint256) {
      uint256 _bonus = bonus;
      uint256 investments = investmentsOf[msg.sender];
      if(investments > 50 ether)
        _bonus += 250; // 25%
      else
      if(investments > 20 ether)
        _bonus += 200; // 20%
      else
      if(investments > 10 ether)
        _bonus += 150; // 15%
      else
      if(investments > 5 ether)
        _bonus += 100; // 10%
      else
      if(investments > 1 ether)
        _bonus += 50; // 5%

      return _bonus;
    }

    function addBlacklist(address wallet) public onlyOwner {
      require(!isBlacklisted[wallet]);
      isBlacklisted[wallet] = true;
      emit AddedToBlacklist(wallet);
    }

    function delBlacklist(address wallet) public onlyOwner {
      require(isBlacklisted[wallet]);
      isBlacklisted[wallet] = false;
      emit RemovedFromBlacklist(wallet);
    }
    
}