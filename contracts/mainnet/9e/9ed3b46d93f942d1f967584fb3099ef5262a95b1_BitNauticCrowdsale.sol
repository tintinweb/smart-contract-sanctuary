pragma solidity ^0.4.13;

contract Ownable {
  address internal owner;


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
  function transferOwnership(address newOwner) onlyOwner public returns (bool) {
    require(newOwner != address(0x0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;

    return true;
  }
}

contract BitNauticWhitelist is Ownable {
    using SafeMath for uint256;

    uint256 public usdPerEth;

    constructor(uint256 _usdPerEth) public {
        usdPerEth = _usdPerEth;
    }

    mapping(address => bool) public AMLWhitelisted;
    mapping(address => uint256) public contributionCap;

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function setKYCLevel(address addr, uint8 level) onlyOwner public returns (bool) {
        if (level >= 3) {
            contributionCap[addr] = 50000 ether; // crowdsale hard cap
        } else if (level == 2) {
            contributionCap[addr] = SafeMath.div(500000 * 10 ** 18, usdPerEth); // KYC Tier 2 - 500k USD
        } else if (level == 1) {
            contributionCap[addr] = SafeMath.div(3000 * 10 ** 18, usdPerEth); // KYC Tier 1 - 3k USD
        } else {
            contributionCap[addr] = 0;
        }

        return true;
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function setKYCLevelsBulk(address[] addrs, uint8[] levels) onlyOwner external returns (bool success) {
        require(addrs.length == levels.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setKYCLevel(addrs[i], levels[i]));
        }

        return true;
    }

    function setAMLWhitelisted(address addr, bool whitelisted) onlyOwner public returns (bool) {
        AMLWhitelisted[addr] = whitelisted;

        return true;
    }

    function setAMLWhitelistedBulk(address[] addrs, bool[] whitelisted) onlyOwner external returns (bool) {
        require(addrs.length == whitelisted.length);

        for (uint256 i = 0; i < addrs.length; i++) {
            assert(setAMLWhitelisted(addrs[i], whitelisted[i]));
        }

        return true;
    }
}

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

contract Crowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    // The token being sold
    MintableToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public ICOStartTime;
    uint256 public ICOEndTime;

    // wallet address where funds will be saved
    address internal wallet;

    // amount of raised money in wei
    uint256 public weiRaised; // internal

    // Public Supply
    uint256 public publicSupply;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // BitNautic Crowdsale constructor
    constructor(MintableToken _token, uint256 _publicSupply, uint256 _startTime, uint256 _endTime, address _wallet) public {
        require(_endTime >= _startTime);
        require(_wallet != 0x0);

        // BitNautic token creation
        token = _token;

        // total supply of token for the crowdsale
        publicSupply = _publicSupply;

        // Pre-ICO start Time
        ICOStartTime = _startTime;

        // ICO end Time
        ICOEndTime = _endTime;

        // wallet where funds will be saved
        wallet = _wallet;
    }

    // fallback function can be used to buy tokens
    function() public payable {
        buyTokens(msg.sender);
    }

    // High level token purchase function
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        // minimum investment should be 0.05 ETH
        uint256 lowerPurchaseLimit = 0.05 ether;
        require(msg.value >= lowerPurchaseLimit);

        assert(_tokenPurchased(msg.sender, beneficiary, msg.value));

        // update state
        weiRaised = weiRaised.add(msg.value);

        forwardFunds();
    }

    function _tokenPurchased(address /* buyer */, address /* beneficiary */, uint256 /* weiAmount */) internal returns (bool) {
        // TO BE OVERLOADED IN SUBCLASSES
        return true;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = ICOStartTime <= now && now <= ICOEndTime;
        bool nonZeroPurchase = msg.value != 0;

        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > ICOEndTime;
    }

    bool public checkBurnTokens = false;

    function burnTokens() onlyOwner public returns (bool) {
        require(hasEnded());
        require(!checkBurnTokens);

        token.mint(0x0, publicSupply);
        token.burnTokens(publicSupply);
        publicSupply = 0;
        checkBurnTokens = true;

        return true;
    }

    function getTokenAddress() onlyOwner public view returns (address) {
        return address(token);
    }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 internal cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract FinalizableCrowdsale is Crowdsale {
    using SafeMath for uint256;

    bool isFinalized = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalizeCrowdsale() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

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

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  constructor(address _wallet) public {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 internal goal;
    bool internal _goalReached = false;
    // refund vault used to hold funds while crowdsale is running
    RefundVault private vault;

    constructor(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    // We&#39;re overriding the fund forwarding from Crowdsale.
    // In addition to sending the funds, we want to call
    // the RefundVault deposit function
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    // vault finalization task, called when owner calls finalize()
    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        super.finalization();
    }

    function goalReached() public returns (bool) {
        if (weiRaised >= goal) {
            _goalReached = true;
        }

        return _goalReached;
    }

    //  function updateGoalCheck() onlyOwner public {
    //    _goalReached = true;
    //  }

    function getVaultAddress() onlyOwner public view returns (address) {
        return vault;
    }
}

contract BitNauticCrowdsale is CappedCrowdsale, RefundableCrowdsale {
    uint256 constant public crowdsaleInitialSupply = 35000000 * 10 ** 18; // 70% of token cap
//    uint256 constant public crowdsaleSoftCap = 2 ether;
//    uint256 constant public crowdsaleHardCap = 10 ether;
    uint256 constant public crowdsaleSoftCap = 5000 ether;
    uint256 constant public crowdsaleHardCap = 50000 ether;

    uint256 constant public preICOStartTime = 1525132800;          // 2018-05-01 00:00 GMT+0
    uint256 constant public mainICOStartTime = 1527811200;         // 2018-06-01 00:00 GMT+0
    uint256 constant public mainICOFirstWeekEndTime = 1528416000;  // 2018-06-08 00:00 GMT+0
    uint256 constant public mainICOSecondWeekEndTime = 1529020800; // 2018-06-15 00:00 GMT+0
    uint256 constant public mainICOThirdWeekEndTime = 1529625600;  // 2018-06-22 00:00 GMT+0
    uint256 constant public mainICOFourthWeekEndTime = 1530403200; // 2018-07-01 00:00 GMT+0
    uint256 constant public mainICOEndTime = 1532995200;           // 2018-07-31 00:00 GMT+0

//    uint256 public preICOStartTime = now;          // 2018-05-01 00:00 GMT+0
//    uint256 constant public mainICOStartTime = preICOStartTime;         // 2018-06-01 00:00 GMT+0
//    uint256 constant public mainICOFirstWeekEndTime = mainICOStartTime;  // 2018-06-08 00:00 GMT+0
//    uint256 constant public mainICOSecondWeekEndTime = mainICOFirstWeekEndTime; // 2018-06-15 00:00 GMT+0
//    uint256 constant public mainICOThirdWeekEndTime = mainICOSecondWeekEndTime;  // 2018-06-22 00:00 GMT+0
//    uint256 constant public mainICOFourthWeekEndTime = mainICOThirdWeekEndTime; // 2018-07-01 00:00 GMT+0
//    uint256 constant public mainICOEndTime = mainICOFourthWeekEndTime + 5 minutes;           // 2018-07-30 00:00 GMT+0

    uint256 constant public tokenBaseRate = 500; // 1 ETH = 500 BTNT

    // bonuses in percentage
    uint256 constant public preICOBonus = 30;
    uint256 constant public firstWeekBonus = 20;
    uint256 constant public secondWeekBonus = 15;
    uint256 constant public thirdWeekBonus = 10;
    uint256 constant public fourthWeekBonus = 5;

    uint256 public teamSupply =     3000000 * 10 ** 18; // 6% of token cap
    uint256 public bountySupply =   2500000 * 10 ** 18; // 5% of token cap
    uint256 public reserveSupply =  5000000 * 10 ** 18; // 10% of token cap
    uint256 public advisorSupply =  2500000 * 10 ** 18; // 5% of token cap
    uint256 public founderSupply =  2000000 * 10 ** 18; // 4% of token cap

    // amount of tokens each address will receive at the end of the crowdsale
    mapping (address => uint256) public creditOf;

    mapping (address => uint256) public weiInvestedBy;

    BitNauticWhitelist public whitelist;

    /** Constructor BitNauticICO */
    constructor(BitNauticToken _token, BitNauticWhitelist _whitelist, address _wallet)
    CappedCrowdsale(crowdsaleHardCap)
    FinalizableCrowdsale()
    RefundableCrowdsale(crowdsaleSoftCap)
    Crowdsale(_token, crowdsaleInitialSupply, preICOStartTime, mainICOEndTime, _wallet) public
    {
        whitelist = _whitelist;
    }

    function _tokenPurchased(address buyer, address beneficiary, uint256 weiAmount) internal returns (bool) {
        require(SafeMath.add(weiInvestedBy[buyer], weiAmount) <= whitelist.contributionCap(buyer));

        uint256 tokens = SafeMath.mul(weiAmount, tokenBaseRate);

        tokens = tokens.add(SafeMath.mul(tokens, getCurrentBonus()).div(100));

        require(publicSupply >= tokens);

        publicSupply = publicSupply.sub(tokens);

        creditOf[beneficiary] = creditOf[beneficiary].add(tokens);
        weiInvestedBy[buyer] = SafeMath.add(weiInvestedBy[buyer], weiAmount);

        emit TokenPurchase(buyer, beneficiary, weiAmount, tokens);

        return true;
    }

    address constant public privateSaleWallet = 0x5A01D561AE864006c6B733f21f8D4311d1E1B42a;

    function goalReached() public returns (bool) {
        if (weiRaised + privateSaleWallet.balance >= goal) {
            _goalReached = true;
        }

        return _goalReached;
    }

    function getCurrentBonus() public view returns (uint256) {
        if (now < mainICOStartTime) {
            return preICOBonus;
        } else if (now < mainICOFirstWeekEndTime) {
            return firstWeekBonus;
        } else if (now < mainICOSecondWeekEndTime) {
            return secondWeekBonus;
        } else if (now < mainICOThirdWeekEndTime) {
            return thirdWeekBonus;
        } else if (now < mainICOFourthWeekEndTime) {
            return fourthWeekBonus;
        } else {
            return 0;
        }
    }

    function claimBitNauticTokens() public returns (bool) {
        return grantInvestorTokens(msg.sender);
    }

    function grantInvestorTokens(address investor) public returns (bool) {
        require(creditOf[investor] > 0);
        require(now > mainICOEndTime && whitelist.AMLWhitelisted(investor));
        require(goalReached());

        assert(token.mint(investor, creditOf[investor]));
        creditOf[investor] = 0;

        return true;
    }

    function grantInvestorsTokens(address[] investors) public returns (bool) {
        require(now > mainICOEndTime);
        require(goalReached());

        for (uint256 i = 0; i < investors.length; i++) {
            if (creditOf[investors[i]] > 0 && whitelist.AMLWhitelisted(investors[i])) {
                token.mint(investors[i], creditOf[investors[i]]);
                creditOf[investors[i]] = 0;
            }
        }

        return true;
    }

    function bountyDrop(address[] recipients, uint256[] values) onlyOwner public returns (bool) {
        require(now > mainICOEndTime);
        require(goalReached());
        require(recipients.length == values.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = SafeMath.mul(values[i], 1 ether);
            if (bountySupply >= values[i]) {
                return false;
            }
            bountySupply = SafeMath.sub(bountySupply, values[i]);
            token.mint(recipients[i], values[i]);
        }

        return true;
    }

    uint256 public teamTimeLock = mainICOEndTime;
    uint256 public founderTimeLock = mainICOEndTime + 365 days;
    uint256 public advisorTimeLock = mainICOEndTime + 180 days;
    uint256 public reserveTimeLock = mainICOEndTime;

    function grantAdvisorTokens(address advisorAddress) onlyOwner public {
        require((advisorSupply > 0) && (advisorTimeLock < now));
        require(goalReached());

        token.mint(advisorAddress, advisorSupply);
        advisorSupply = 0;
    }

    uint256 public teamVestingCounter = 0; // months of vesting

    function grantTeamTokens(address teamAddress) onlyOwner public {
        require((teamVestingCounter < 12) && (teamTimeLock < now));
        require(goalReached());

        teamTimeLock = SafeMath.add(teamTimeLock, 4 weeks);
        token.mint(teamAddress, SafeMath.div(teamSupply, 12));
        teamVestingCounter = SafeMath.add(teamVestingCounter, 1);
    }

    function grantFounderTokens(address founderAddress) onlyOwner public {
        require((founderSupply > 0) && (founderTimeLock < now));
        require(goalReached());

        token.mint(founderAddress, founderSupply);
        founderSupply = 0;
    }

    function grantReserveTokens(address beneficiary) onlyOwner public {
        require((reserveSupply > 0) && (now > reserveTimeLock));
        require(goalReached());

        token.mint(beneficiary, reserveSupply);
        reserveSupply = 0;
    }

    function transferTokenOwnership(address newTokenOwner) onlyOwner public returns (bool) {
        return token.transferOwnership(newTokenOwner);
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
}

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
    totalSupply = SafeMath.add(totalSupply, _amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
//  function finishMinting() onlyOwner public returns (bool) {
//    mintingFinished = true;
//    emit MintFinished();
//    return true;
//  }

  function burnTokens(uint256 _unsoldTokens) onlyOwner canMint public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
  }
}

contract CappedToken is MintableToken {
  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }
}

contract BitNauticToken is CappedToken {
  string public constant name = "BitNautic Token";
  string public constant symbol = "BTNT";
  uint8 public constant decimals = 18;

  uint256 public totalSupply = 0;

  constructor()
  CappedToken(50000000 * 10 ** uint256(decimals)) public
  {

  }
}