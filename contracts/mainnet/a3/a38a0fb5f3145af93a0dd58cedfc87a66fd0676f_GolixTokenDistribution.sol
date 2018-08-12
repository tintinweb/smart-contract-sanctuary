pragma solidity 0.4.24;

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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
    totalSupply_ = totalSupply_.add(_amount);
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

// File: contracts/GolixToken.sol

/**
 * @title Golix Token contract - ERC20 compatible token contract.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f79082848396819890829e9a9685969284b7909a969e9bd994989a">[email&#160;protected]</a>>
 */
contract GolixToken is PausableToken, MintableToken {
    string public constant name = "Golix Token";
    string public constant symbol = "GLX";
    uint8 public constant decimals = 18;

    /**
     * @dev Allow for staking of GLX tokens
     * function is called only from owner which is the GLX token distribution contract
     * is only triggered for a period of time and only if there are still tokens from crowdsale
     * @param staker Address of token holder
     * @param glxStakingContract Address where staking tokens goes to
     */
    function stakeGLX(address staker, address glxStakingContract) public onlyOwner {
        uint256 stakerGLXBalance = balanceOf(staker);
        balances[staker] = 0;
        balances[glxStakingContract] = balances[glxStakingContract].add(stakerGLXBalance);
        emit Transfer(staker, glxStakingContract, stakerGLXBalance);
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

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/VestTokenAllocation.sol

/**
 * @title VestTokenAllocation contract
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ec8b999f988d9a838b9985818d9e8d899fac8b818d8580c28f8381">[email&#160;protected]</a>>
 */
contract VestTokenAllocation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public allocatedTokens;
    uint256 public canSelfDestruct;

    mapping (address => uint256) public totalTokensLocked;
    mapping (address => uint256) public releasedTokens;

    ERC20 public golix;
    address public tokenDistribution;

    event Released(address beneficiary, uint256 amount);

    /**
     * @dev creates the locking contract with vesting mechanism
     * as well as ability to set tokens for addresses and time contract can self-destruct
     * @param _token GolixToken address
     * @param _tokenDistribution GolixTokenDistribution contract address
     * @param _start timestamp representing the beginning of the token vesting process
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest. ie 1 year in secs
     * @param _duration time in seconds of the period in which the tokens completely vest. ie 4 years in secs
     * @param _canSelfDestruct timestamp of when contract is able to selfdestruct
     */
    function VestTokenAllocation
        (
            ERC20 _token,
            address _tokenDistribution,
            uint256 _start,
            uint256 _cliff,
            uint256 _duration,
            uint256 _canSelfDestruct
        )
        public
    {
        require(_token != address(0) && _cliff != 0);
        require(_cliff <= _duration);
        require(_start > now);
        require(_canSelfDestruct > _duration.add(_start));

        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;

        golix = ERC20(_token);
        tokenDistribution = _tokenDistribution;
        canSelfDestruct = _canSelfDestruct;
    }

    modifier onlyOwnerOrTokenDistributionContract() {
        require(msg.sender == address(owner) || msg.sender == address(tokenDistribution));
        _;
    }
    /**
     * @dev Adds vested token allocation
     * @param beneficiary Ethereum address of a person
     * @param allocationValue Number of tokens allocated to person
     */
    function addVestTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwnerOrTokenDistributionContract
    {
        require(totalTokensLocked[beneficiary] == 0 && beneficiary != address(0)); // can only add once.

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= golix.balanceOf(this));

        totalTokensLocked[beneficiary] = allocationValue;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0);

        releasedTokens[msg.sender] = releasedTokens[msg.sender].add(unreleased);

        golix.safeTransfer(msg.sender, unreleased);

        emit Released(msg.sender, unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(releasedTokens[msg.sender]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = totalTokensLocked[msg.sender];

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }

    /**
     * @dev allow for selfdestruct possibility and sending funds to owner
     */
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = golix.balanceOf(this);

        if (balance > 0) {
            golix.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
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
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
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

// File: contracts/GolixTokenDistribution.sol

/**
 * @title Golix token distribution contract - crowdsale contract for the Golix tokens.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9cfbe9efe8fdeaf3fbe9f5f1fdeefdf9efdcfbf1fdf5f0b2fff3f1">[email&#160;protected]</a>>
 */
contract GolixTokenDistribution is FinalizableCrowdsale {
    uint256 constant public TOTAL_TOKENS_SUPPLY = 1274240097e18; // 1,274,240,097 tokens
    // =~ 10% for Marketing, investment fund, partners
    uint256 constant public MARKETING_SHARE = 127424009e18;
    // =~ 15% for issued to investors, shareholders
    uint256 constant public SHAREHOLDERS_SHARE = 191136015e18;
    // =~ 25% for founding team, future employees
    uint256 constant public FOUNDERS_SHARE = 318560024e18;
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = 637120049e18; // =~ 50 % of total token supply

    VestTokenAllocation public teamVestTokenAllocation;
    VestTokenAllocation public contributorsVestTokenAllocation;
    address public marketingWallet;
    address public shareHoldersWallet;

    bool public canFinalizeEarly;
    bool public isStakingPeriod;

    mapping (address => uint256) public icoContributions;

    event MintedTokensFor(address indexed investor, uint256 tokensPurchased);
    event GLXStaked(address indexed staker, uint256 amount);

    /**
     * @dev Contract constructor function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _rate The token rate per ETH
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     * @param _marketingWallet address that will hold tokens for marketing campaign.
     * @param _shareHoldersWallet address that will distribute shareholders tokens.
     */
    function GolixTokenDistribution
        (
            uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            address _wallet,
            address _marketingWallet,
            address _shareHoldersWallet
        )
        public
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_marketingWallet != address(0) && _shareHoldersWallet != address(0));
        require(
            MARKETING_SHARE + SHAREHOLDERS_SHARE + FOUNDERS_SHARE + TOTAL_TOKENS_FOR_CROWDSALE
            == TOTAL_TOKENS_SUPPLY
        );

        marketingWallet = _marketingWallet;
        shareHoldersWallet = _shareHoldersWallet;

        GolixToken(token).pause();
    }

    /**
     * @dev Mint tokens for crowdsale participants
     * @param investorsAddress List of Purchasers addresses
     * @param amountOfTokens List of token amounts for investor
     */
    function mintTokensForCrowdsaleParticipants(address[] investorsAddress, uint256[] amountOfTokens)
        external
        onlyOwner
    {
        require(investorsAddress.length == amountOfTokens.length);

        for (uint256 i = 0; i < investorsAddress.length; i++) {
            require(token.totalSupply().add(amountOfTokens[i]) <= TOTAL_TOKENS_FOR_CROWDSALE);

            token.mint(investorsAddress[i], amountOfTokens[i]);
            icoContributions[investorsAddress[i]] = icoContributions[investorsAddress[i]].add(amountOfTokens[i]);

            emit MintedTokensFor(investorsAddress[i], amountOfTokens[i]);
        }
    }
    
    // override buytokens so all minting comes from Golix
    function buyTokens(address beneficiary) public payable {
        revert();
    }
    
    /**
     * @dev Set addresses which should receive the vested team tokens share on finalization
     * @param _teamVestTokenAllocation address of team and advisor allocation contract
     * @param _contributorsVestTokenAllocation address of ico contributors
     * who for glx staking event in case there is still left over tokens from crowdsale
     */
    function setVestTokenAllocationAddresses
        (
            address _teamVestTokenAllocation,
            address _contributorsVestTokenAllocation
        )
        public
        onlyOwner
    {
        require(_teamVestTokenAllocation != address(0) && _contributorsVestTokenAllocation != address(0));

        teamVestTokenAllocation = VestTokenAllocation(_teamVestTokenAllocation);
        contributorsVestTokenAllocation = VestTokenAllocation(_contributorsVestTokenAllocation);
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        if (canFinalizeEarly) {
            return true;
        }

        return super.hasEnded();
    }

    /**
     * @dev Allow for staking of GLX tokens from crowdsale participants
     * only works if tokens from token distribution are not sold out.
     * investors must have GLX tokens in the same amount as it purchased during crowdsale
     */
    function stakeGLXForContributors() public {
        uint256 senderGlxBalance = token.balanceOf(msg.sender);
        require(senderGlxBalance == icoContributions[msg.sender] && isStakingPeriod);

        GolixToken(token).stakeGLX(msg.sender, contributorsVestTokenAllocation);
        contributorsVestTokenAllocation.addVestTokenAllocation(msg.sender, senderGlxBalance);
        emit GLXStaked(msg.sender, senderGlxBalance);
    }

    /**
    * @dev enables early finalization of crowdsale
    */
    function prepareForEarlyFinalization() public onlyOwner {
        canFinalizeEarly = true;
    }

    /**
    * @dev disables staking period
    */
    function disableStakingPeriod() public onlyOwner {
        isStakingPeriod = false;
    }

    /**
     * @dev Creates Golix token contract. This is called on the constructor function of the Crowdsale contract
     */
    function createTokenContract() internal returns (MintableToken) {
        return new GolixToken();
    }

    /**
     * @dev finalizes crowdsale
     */
    function finalization() internal {
        // This must have been set manually prior to finalize() call.
        require(teamVestTokenAllocation != address(0) && contributorsVestTokenAllocation != address(0));

        if (TOTAL_TOKENS_FOR_CROWDSALE > token.totalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            token.mint(contributorsVestTokenAllocation, remainingTokens);
            isStakingPeriod = true;
        }

        // final minting
        token.mint(marketingWallet, MARKETING_SHARE);
        token.mint(shareHoldersWallet, SHAREHOLDERS_SHARE);
        token.mint(teamVestTokenAllocation, FOUNDERS_SHARE);

        token.finishMinting();
        GolixToken(token).unpause();
        super.finalization();
    }
}