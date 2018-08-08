pragma solidity ^0.4.18;

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


contract LongevityToken is StandardToken {
    string public name = "Longevity";
    string public symbol = "LTY";
    uint8 public decimals = 2;
    bool public mintingFinished = false;
    mapping (address => bool) owners;
    mapping (address => bool) minters;
    // tap to limit mint speed
    struct Tap {
        uint256 startTime; // reference time point to start measuring
        uint256 tokensIssued; // how much tokens issued from startTime
        uint256 mintSpeed; // token fractions per second
    }
    Tap public mintTap;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event MinterAdded(address indexed newMinter);
    event MinterRemoved(address indexed removedMinter);
    event Burn(address indexed burner, uint256 value);
    event MintTapSet(uint256 startTime, uint256 mintSpeed);

    function LongevityToken() public {
        owners[msg.sender] = true;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {
        require(!mintingFinished);
        passThroughTap(_amount);
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
    function finishMinting() onlyOwner public returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        MintFinished();
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    /**
     * @dev Adds administrative role to address
     * @param _address The address that will get administrative privileges
     */
    function addOwner(address _address) onlyOwner public {
        owners[_address] = true;
        OwnerAdded(_address);
    }

    /**
     * @dev Removes administrative role from address
     * @param _address The address to remove administrative privileges from
     */
    function delOwner(address _address) onlyOwner public {
        owners[_address] = false;
        OwnerRemoved(_address);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    /**
     * @dev Adds minter role to address (able to create new tokens)
     * @param _address The address that will get minter privileges
     */
    function addMinter(address _address) onlyOwner public {
        minters[_address] = true;
        MinterAdded(_address);
    }

    /**
     * @dev Removes minter role from address
     * @param _address The address to remove minter privileges
     */
    function delMinter(address _address) onlyOwner public {
        minters[_address] = false;
        MinterRemoved(_address);
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }

    /**
     * @dev passThroughTap allows minting tokens within the defined speed limit.
     * Throws if requested more than allowed.
     */
    function passThroughTap(uint256 _tokensRequested) internal {
        require(_tokensRequested <= getTapRemaining());
        mintTap.tokensIssued = mintTap.tokensIssued.add(_tokensRequested);
    }

    /**
     * @dev Returns remaining amount of tokens allowed at the moment
     */
    function getTapRemaining() public view returns (uint256) {
        uint256 tapTime = now.sub(mintTap.startTime).add(1);
        uint256 totalTokensAllowed = tapTime.mul(mintTap.mintSpeed);
        uint256 tokensRemaining = totalTokensAllowed.sub(mintTap.tokensIssued);
        return tokensRemaining;
    }

    /**
     * @dev (Re)sets mint tap parameters
     * @param _mintSpeed Allowed token amount to mint per second
     */
    function setMintTap(uint256 _mintSpeed) onlyOwner public {
        mintTap.startTime = now;
        mintTap.tokensIssued = 0;
        mintTap.mintSpeed = _mintSpeed;
        MintTapSet(mintTap.startTime, mintTap.mintSpeed);
    }
}


/**
 * @title LongevityCrowdsale
 * @dev LongevityCrowdsale is a contract for managing a token crowdsale for Longevity project.
 * Crowdsale have phases with start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate and bonuses. Collected funds are forwarded to a wallet
 * as they arrive.
 */
contract LongevityCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    LongevityToken public token;

    // External wallet where funds get forwarded
    address public wallet;

    // Crowdsale administrators
    mapping (address => bool) public owners;

    // External bots updating rates
    mapping (address => bool) public bots;

    // USD cents per ETH exchange rate
    uint256 public rateUSDcETH;

    // Phases list, see schedule in constructor
    mapping (uint => Phase) phases;

    // The total number of phases
    uint public totalPhases = 0;

    // Description for each phase
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 bonusPercent;
    }

    // Minimum Deposit in USD cents
    uint256 public constant minContributionUSDc = 1000;


    // Amount of raised Ethers (in wei).
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param bonusPercent free tokens percantage for the phase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 bonusPercent, uint256 amount);

    // event for rate update logging
    event RateUpdate(uint256 rate);

    // event for wallet update
    event WalletSet(address indexed wallet);

    // owners management events
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);

    // bot management events
    event BotAdded(address indexed newBot);
    event BotRemoved(address indexed removedBot);

    // Phase edit events
    event TotalPhasesChanged(uint value);
    event SetPhase(uint index, uint256 _startTime, uint256 _endTime, uint256 _bonusPercent);
    event DelPhase(uint index);

    function LongevityCrowdsale(address _tokenAddress, uint256 _initialRate) public {
        require(_tokenAddress != address(0));
        token = LongevityToken(_tokenAddress);
        rateUSDcETH = _initialRate;
        wallet = msg.sender;
        owners[msg.sender] = true;
        bots[msg.sender] = true;
        phases[0].bonusPercent = 40;
        phases[0].startTime = 1520453700;
        phases[0].endTime = 1520460000;
    }

    /**
     * @dev Update collecting wallet address
     * @param _address The address to send collected funds
     */
    function setWallet(address _address) onlyOwner public {
        wallet = _address;
        WalletSet(_address);
    }


    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);
        require(isInPhase(now));

        uint256 currentBonusPercent = getBonusPercent(now);

        uint256 weiAmount = msg.value;

        require(calculateUSDcValue(weiAmount) >= minContributionUSDc);

        // calculate token amount to be created
        uint256 tokens = calculateTokenAmount(weiAmount, currentBonusPercent);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, currentBonusPercent, tokens);

        forwardFunds();
    }

    // If phase exists return corresponding bonus for the given date
    // else return 0 (percent)
    function getBonusPercent(uint256 datetime) public view returns (uint256) {
        require(isInPhase(datetime));
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return phases[i].bonusPercent;
            }
        }
        return 0;
    }

    // If phase exists for the given date return true
    function isInPhase(uint256 datetime) public view returns (bool) {
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return true;
            }
        }
    }

    // set rate
    function setRate(uint256 _rateUSDcETH) public onlyBot {
        // don&#39;t allow to change rate more than 10%
        assert(_rateUSDcETH < rateUSDcETH.mul(110).div(100));
        assert(_rateUSDcETH > rateUSDcETH.mul(90).div(100));
        rateUSDcETH = _rateUSDcETH;
        RateUpdate(rateUSDcETH);
    }

    /**
     * @dev Adds administrative role to address
     * @param _address The address that will get administrative privileges
     */
    function addOwner(address _address) onlyOwner public {
        owners[_address] = true;
        OwnerAdded(_address);
    }

    /**
     * @dev Removes administrative role from address
     * @param _address The address to remove administrative privileges from
     */
    function delOwner(address _address) onlyOwner public {
        owners[_address] = false;
        OwnerRemoved(_address);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    /**
     * @dev Adds rate updating bot
     * @param _address The address of the rate bot
     */
    function addBot(address _address) onlyOwner public {
        bots[_address] = true;
        BotAdded(_address);
    }

    /**
     * @dev Removes rate updating bot address
     * @param _address The address of the rate bot
     */
    function delBot(address _address) onlyOwner public {
        bots[_address] = false;
        BotRemoved(_address);
    }

    /**
     * @dev Throws if called by any account other than the bot.
     */
    modifier onlyBot() {
        require(bots[msg.sender]);
        _;
    }

    // calculate deposit value in USD Cents
    function calculateUSDcValue(uint256 _weiDeposit) public view returns (uint256) {

        // wei per USD cent
        uint256 weiPerUSDc = 1 ether/rateUSDcETH;

        // Deposited value converted to USD cents
        uint256 depositValueInUSDc = _weiDeposit.div(weiPerUSDc);
        return depositValueInUSDc;
    }

    // calculates how much tokens will beneficiary get
    // for given amount of wei
    function calculateTokenAmount(uint256 _weiDeposit, uint256 _bonusTokensPercent) public view returns (uint256) {
        uint256 mainTokens = calculateUSDcValue(_weiDeposit);
        uint256 bonusTokens = mainTokens.mul(_bonusTokensPercent).div(100);
        return mainTokens.add(bonusTokens);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    //Change number of phases
    function setTotalPhases(uint value) onlyOwner public {
        totalPhases = value;
        TotalPhasesChanged(value);
    }

    // Set phase: index and values
    function setPhase(uint index, uint256 _startTime, uint256 _endTime, uint256 _bonusPercent) onlyOwner public {
        require(index <= totalPhases);
        phases[index] = Phase(_startTime, _endTime, _bonusPercent);
        SetPhase(index, _startTime, _endTime, _bonusPercent);
    }

    // Delete phase
    function delPhase(uint index) onlyOwner public {
        require(index <= totalPhases);
        delete phases[index];
        DelPhase(index);
    }
}