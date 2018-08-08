pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

// File: zeppelin-solidity/contracts/token/MintableToken.sol

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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

// File: libs/BonusCrowdsale.sol

/**
* @dev Parent crowdsale contract with support for time-based and amount based bonuses 
* Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
* 
*/
contract BonusCrowdsale is Crowdsale, Ownable {

    // Constants
    // The following will be populated by main crowdsale contract
    uint32[] public BONUS_TIMES;
    uint32[] public BONUS_TIMES_VALUES;
    uint32[] public BONUS_AMOUNTS;
    uint32[] public BONUS_AMOUNTS_VALUES;
    uint public constant BONUS_COEFF = 1000; // Values should be 10x percents, value 1000 = 100%
    
    // Members
    uint public tokenPriceInCents;

    /**
    * @dev Contructor
    * @param _tokenPriceInCents token price in USD cents. The price is fixed
    */
    function BonusCrowdsale(uint256 _tokenPriceInCents) public {
        tokenPriceInCents = _tokenPriceInCents;
    }

    /**
    * @dev Retrieve length of bonuses by time array
    * @return Bonuses by time array length
    */
    function bonusesForTimesCount() public constant returns(uint) {
        return BONUS_TIMES.length;
    }

    /**
    * @dev Sets bonuses for time
    */
    function setBonusesForTimes(uint32[] times, uint32[] values) public onlyOwner {
        require(times.length == values.length);
        for (uint i = 0; i + 1 < times.length; i++) {
            require(times[i] < times[i+1]);
        }

        BONUS_TIMES = times;
        BONUS_TIMES_VALUES = values;
    }

    /**
    * @dev Retrieve length of bonuses by amounts array
    * @return Bonuses by amounts array length
    */
    function bonusesForAmountsCount() public constant returns(uint) {
        return BONUS_AMOUNTS.length;
    }

    /**
    * @dev Sets bonuses for USD amounts
    */
    function setBonusesForAmounts(uint32[] amounts, uint32[] values) public onlyOwner {
        require(amounts.length == values.length);
        for (uint i = 0; i + 1 < amounts.length; i++) {
            require(amounts[i] > amounts[i+1]);
        }

        BONUS_AMOUNTS = amounts;
        BONUS_AMOUNTS_VALUES = values;
    }

    /**
    * @dev Overrided buyTokens method of parent Crowdsale contract  to provide bonus by changing and restoring rate variable
    * @param beneficiary walelt of investor to receive tokens
    */
    function buyTokens(address beneficiary) public payable {
        // Compute usd amount = wei * catsInEth * usdcentsInCat / usdcentsPerUsd / weisPerEth
        uint256 usdValue = msg.value.mul(rate).mul(tokenPriceInCents).div(1000).div(1 ether);
        
        // Compute time and amount bonus
        uint256 bonus = computeBonus(usdValue);

        // Apply bonus by adjusting and restoring rate member
        uint256 oldRate = rate;
        rate = rate.mul(BONUS_COEFF.add(bonus)).div(BONUS_COEFF);
        super.buyTokens(beneficiary);
        rate = oldRate;
    }

    /**
    * @dev Computes overall bonus based on time of contribution and amount of contribution. 
    * The total bonus is the sum of bonus by time and bonus by amount
    * @return bonus percentage scaled by 10
    */
    function computeBonus(uint256 usdValue) public constant returns(uint256) {
        return computeAmountBonus(usdValue).add(computeTimeBonus());
    }

    /**
    * @dev Computes bonus based on time of contribution relative to the beginning of crowdsale
    * @return bonus percentage scaled by 10
    */
    function computeTimeBonus() public constant returns(uint256) {
        require(now >= startTime);

        for (uint i = 0; i < BONUS_TIMES.length; i++) {
            if (now.sub(startTime) <= BONUS_TIMES[i]) {
                return BONUS_TIMES_VALUES[i];
            }
        }

        return 0;
    }

    /**
    * @dev Computes bonus based on amount of contribution
    * @return bonus percentage scaled by 10
    */
    function computeAmountBonus(uint256 usdValue) public constant returns(uint256) {
        for (uint i = 0; i < BONUS_AMOUNTS.length; i++) {
            if (usdValue >= BONUS_AMOUNTS[i]) {
                return BONUS_AMOUNTS_VALUES[i];
            }
        }

        return 0;
    }

}

// File: libs/TokensCappedCrowdsale.sol

/**
* @dev Parent crowdsale contract is extended with support for cap in tokens
* Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
* 
*/
contract TokensCappedCrowdsale is Crowdsale {

    uint256 public tokensCap;

    function TokensCappedCrowdsale(uint256 _tokensCap) public {
        tokensCap = _tokensCap;
    }

    // overriding Crowdsale#validPurchase to add extra tokens cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal constant returns(bool) {
        uint256 tokens = token.totalSupply().add(msg.value.mul(rate));
        bool withinCap = tokens <= tokensCap;
        return super.validPurchase() && withinCap;
    }

    // overriding Crowdsale#hasEnded to add tokens cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public constant returns(bool) {
        bool capReached = token.totalSupply() >= tokensCap;
        return super.hasEnded() || capReached;
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/token/PausableToken.sol

/**
 * @title Pausable token
 *
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

// File: zeppelin-solidity/contracts/token/SafeERC20.sol

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

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: zeppelin-solidity/contracts/token/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint64 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: zeppelin-solidity/contracts/token/TokenVesting.sol

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

// File: contracts/MDKToken.sol

contract MDKToken is MintableToken, PausableToken {
  string public constant name = "MDKToken";
  string public constant symbol = "MDK";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  TokenTimelock public reserveTokens;
  TokenVesting public teamTokens;

  address public PreICO = address(0);
  address public ICO = address(0);

  /**
  * @dev Constructor
  * Initializing token contract, locking team and reserve funds, sending renumeration fund to owner
  */
  function MDKToken(address _teamFund) public {
    lockTeamTokens(_teamFund);
    lockReserveTokens(_teamFund);

    mint(_teamFund, 250000000 * (10 ** uint256(decimals)));
    pause();
  }

  /**
  * @dev Lock team tokens for 3 years with vesting contract. Team can receive first portion of tokens 3 months after contract created, after that they can get portion of tokens proportional to time left until full unlock
  */
  function lockTeamTokens(address _teamFund) private {
    teamTokens = new TokenVesting(_teamFund, now, 90 days, 1095 days, false);
    mint(teamTokens, 200000000 * (10 ** uint256(decimals)));
  }

  /**
  * @dev Lock reserve tokens for 1 year
  */
  function lockReserveTokens(address _teamFund) private {
    reserveTokens = new TokenTimelock(this, _teamFund, uint64(now + 1 years));
    mint(reserveTokens, 50000000 * (10 ** uint256(decimals)));
  }

  /**
  * @dev Starts ICO, making ICO contract owner, so it can mint
  */
  function startICO(address _icoAddress) onlyOwner public {
    require(ICO == address(0));
    require(PreICO != address(0));
    require(_icoAddress != address(0));

    ICO = _icoAddress;
    transferOwnership(_icoAddress);
  }

  /**
  * @dev Starts PreICO, making PreICO contract owner, so it can mint
  */
  function startPreICO(address _icoAddress) onlyOwner public {
    require(PreICO == address(0));
    require(_icoAddress != address(0));

    PreICO = _icoAddress;
    transferOwnership(_icoAddress);
  }

}

// File: zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

// File: contracts/MDKICO.sol

contract MDKICO is TokensCappedCrowdsale(MDKICO.TOKENS_CAP), FinalizableCrowdsale, BonusCrowdsale(MDKICO.TOKEN_USDCENT_PRICE) {

  uint8 public constant decimals = 18;
  uint256 constant TOKENS_CAP = 600000000 * (10 ** uint256(decimals));
  uint256 public constant TOKEN_USDCENT_PRICE = 18;

  event RateChange(uint256 rate);

  /**
  * @dev Contructor
  * @param _startTime startTime of crowdsale
  * @param _endTime endTime of crowdsale
  * @param _rate MDK / ETH rate
  * @param _token Address of MDKToken contract
  */
  function MDKICO(
    uint _startTime,
    uint _endTime,
    uint256 _rate,
    address _token,
    address _teamWallet
  ) public
    Crowdsale(_startTime, _endTime, _rate, _teamWallet)
  {
    require(_token != address(0));
    token = MintableToken(_token);
  }

  /**
  * @dev Sets MDK to Ether rate. Will be called multiple times durign the crowdsale to adjsut the rate
  * since MDK cost is fixed in USD, but USD/ETH rate is changing
  * @param _rate defines MDK/ETH rate: 1 ETH = _rate MDKs
  */
  function setRate(uint256 _rate) external onlyOwner {
      require(_rate != 0x0);
      rate = _rate;
      RateChange(_rate);
  }

  /**
  * @dev Gives user tokens for contribution in bitcoins
  * @param _beneficiary User who&#39;ll receive tokens
  * @param tokens Amount of tokens
  */
  function buyForBitcoin(address _beneficiary, uint256 tokens) public onlyOwner {
    mintTokens(_beneficiary, tokens);
  }

  function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
    require(beneficiary != 0);
    require(tokens > 0);
    require(now <= endTime);                               // Crowdsale (without startTime check)
    require(!isFinalized);                                 // FinalizableCrowdsale
    require(token.totalSupply().add(tokens) <= TOKENS_CAP); // TokensCappedCrowdsale

    token.mint(beneficiary, tokens);
  }

  /**
  * @dev Allows to adjust the crowdsale end time
  */
  function setEndTime(uint256 _endTime) external onlyOwner {
    require(!isFinalized);
    require(_endTime >= startTime);
    require(_endTime >= now);
    endTime = _endTime;
  }

  /**
  * @dev Override super createTokenContract, so it&#39;ll not deploy MintableToke
  */
  function createTokenContract() internal returns (MintableToken) {
    return MintableToken(0);
  }

  /**
  * @dev Give not bought tokens to owner, also give back ownership of MDKToken contract
  */
  function finalization() internal {
    /*
    We don&#39;t call finishMinting in finalization,
    because after ICO we will held main round of ICO few months later
    */
    token.transferOwnership(owner);
  }


}