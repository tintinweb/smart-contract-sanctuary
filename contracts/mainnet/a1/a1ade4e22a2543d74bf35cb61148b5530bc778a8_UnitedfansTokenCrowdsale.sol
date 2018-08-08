pragma solidity 0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
  function Ownable() {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

/// @title Migration Agent interface
contract MigrationAgent {

    function migrateFrom(address _from, uint256 _value) public;
}

contract UnitedfansToken is MintableToken {
    address public migrationMaster;
    address public migrationAgent;
    address public admin;
    address public crowdSaleAddress;
    uint256 public totalMigrated;
    string public name = "Goal Coin";
    string public symbol = "GC";
    uint256 public decimals = 18;
    bool public locked = true; // Lock the transfer of tokens during the crowdsale

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    event Locked();

    event Unlocked();

    modifier onlyUnlocked() {
        if (locked) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != crowdSaleAddress && msg.sender != admin) 
            revert();
        _;
    }


    function UnitedfansToken(address _admin) public {
        // Lock the transfCrowdsaleer function during the crowdsale
        locked = true; // Lock the transfer of tokens during the crowdsale
        // transferOwnership(_admin);
        admin = _admin;
        crowdSaleAddress = msg.sender;
        migrationMaster = _admin;
    }

    function unlock() public onlyAuthorized {
        locked = false;
        Unlocked();
    }

    function lock() public onlyAuthorized {
        locked = true;
        Locked();
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }



    // Token migration support:

    /// @notice Migrate tokens to the new token contract.
    /// @dev Required state: Operational Migration
    /// @param _value The amount of token to be migrated
    function migrate(uint256 _value) external {
        // Abort if not in Operational Migration state.
        
        if (migrationAgent == 0) 
            revert();
        
        // Validate input value.
        if (_value == 0) 
            revert();
        if (_value > balances[msg.sender]) 
            revert();

        balances[msg.sender] -= _value;
        totalSupply -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }


    /// @notice Set address of migration target contract and enable migration
    /// process.
    /// @dev Required state: Operational Normal
    /// @dev State transition: -> Operational Migration
    /// @param _agent The address of the MigrationAgent contract
    function setMigrationAgent(address _agent) external onlyUnlocked() {
        // Abort if not in Operational Normal state.
        
        require(migrationAgent == 0);
        require(msg.sender == migrationMaster);
        migrationAgent = _agent;
    }

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) external onlyAuthorized() {
        crowdSaleAddress = _newCrowdSaleAddress;
    }
    
    function setMigrationMaster(address _master) external {       
        require(msg.sender == migrationMaster);
        require(_master != 0);
        migrationMaster = _master;
    }
}


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


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
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
  function () payable {
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
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}


contract UnitedfansTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
 
    //operational
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 30303030*toDec;
    uint256 public constant cap = 30303030*toDec;
    uint256 public constant startRate = 12000;

    enum State { BeforeSale, NormalSale, ShouldFinalize, SaleOver }
    State public state = State.BeforeSale;


    // /* --- Time periods --- */

    uint256 public startTimeNumber = 1500000000;

    uint256 public endTimeNumber = 1530316800;// Wed, 31 May 2018 12:00:00 +0000

    event Finalized();

    function UnitedfansTokenCrowdsale(address _admin)
    Crowdsale(
        now + 10, // 2018-02-01T00:00:00+00:00 - 1517443200
        endTimeNumber, // 2018-06-30T00:00:00+00:00 - 
        12000,/* start rate - 1000 */
        _admin
    )  
    public 
    {}

    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new UnitedfansToken(msg.sender);
    }

    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        wallet.transfer(amount);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function buyTokensUpdateState() internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.NormalSale; }
        require(state != State.ShouldFinalize && state != State.SaleOver && msg.value >= toDec.div(10));
        if(msg.value < toDec.mul(25)) { rate = 6000; }
        else { rate = 12000; }
        if(msg.value.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
            super.buyTokens(beneficiary);
        }
    }

    function buyCoinsUpdateState(uint256 amount) internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.NormalSale; }
        require(state != State.ShouldFinalize && state != State.SaleOver);
        if(amount < 25) { rate = 6000; }
        else { rate = 12000; }
        if(amount.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyCoins(address beneficiary, uint256 amount) public onlyOwner {
        buyCoinsUpdateState(amount);
        var numTokens = amount.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
            super.buyTokens(beneficiary);
        }
    }

    function lastTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokensForFullBuy = weiAmount.mul(rate);// must be bigger or equal to tokensLeft to get here
        uint256 tokensToRefundFor = tokensForFullBuy.sub(tokensLeft);
        uint256 tokensRemaining = tokensForFullBuy.sub(tokensToRefundFor);
        uint256 weiAmountToRefund = tokensToRefundFor.div(rate);
        uint256 weiRemaining = weiAmount.sub(weiAmountToRefund);
        
        // update state
        weiRaised = weiRaised.add(weiRemaining);

        token.mint(beneficiary, tokensRemaining);
        TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);

        forwardFundsAmount(weiRemaining);
        refundAmount(weiAmountToRefund);
    }

    function finalizeUpdateState() internal {
        if(now > endTime) { state = State.ShouldFinalize; }
        if(tokensLeft == 0) { state = State.ShouldFinalize; }
    }

    function finalize() public {
        finalizeUpdateState();
        require (state == State.ShouldFinalize);

        finalization();
        Finalized();
    }

    function finalization() internal {
        endTime = block.timestamp;
        state = State.SaleOver;
    }
}